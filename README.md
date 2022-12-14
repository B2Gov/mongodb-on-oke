# MongoDB on OKE

- [MongoDB on OKE](#mongodb-on-oke)
  - [Implementation](#implementation)
  - [Secret usage](#secret-usage)


The following implementation is based on: 

- [Mongodb Kubernetes Operator](https://www.mongodb.com/docs/kubernetes-operator/master/tutorial/install-k8s-operator/)
- [MongoDB Github Documentation](https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/README.md)
- [Community Edition Implementation Details](https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/docs/deploy-configure.md)
- [Storage Support](https://github.com/mongodb/mongodb-kubernetes-operator/issues/961)


---

## Implementation

1. Create namespace for mongodb

```shell
kubectl create namespace mongodbdatabase
namespace/mongodbdatabase created
```

2. Update the helm charts

```shell
helm repo add mongodb https://mongodb.github.io/helm-charts
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/ubuntu/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/ubuntu/.kube/config
"mongodb" has been added to your repositories

helm repo update
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/ubuntu/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/ubuntu/.kube/config
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "mongodb" chart repository
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈
```

3. Install the operator

```shell
helm install community-operator mongodb/community-operator --namespace mongodbdatabase
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: /home/ubuntu/.kube/config
WARNING: Kubernetes configuration file is world-readable. This is insecure. Location: /home/ubuntu/.kube/config
NAME: community-operator
LAST DEPLOYED: Mon Jul  4 19:24:55 2022
NAMESPACE: mongodbdatabase
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

4. From operator repo, get file [cr.yaml](https://github.com/mongodb/mongodb-kubernetes-operator/blob/master/config/samples/mongodb.com_v1_mongodbcommunity_cr.yaml) and update it with your passwords. Define password in line 36 and apply. Name this `01_mongodb.yaml`

```shell
kubectl apply -f 00_secret.yaml
secret/my-user-password created

kubectl apply -f 01_mongodb.yaml 
mongodbcommunity.mongodbcommunity.mongodb.com/example-mongodb created

```

**NOTE**

1. Each mongodb node uses two block storages. One for logs and one for data. To customize these sizes, update the following, in file `01_mongodb.yaml`: 

```yaml
    spec:
      volumeClaimTemplates:
        - metadata:
            name: data-volume
          spec:
            accessModes: ["ReadWriteOnce"]
            storageClassName: oci-bv
            resources:
              requests:
                storage: 67G
        - metadata:
            name: logs-volume
          spec:
            accessModes: [ "ReadWriteOnce" ]
            storageClassName: oci-bv
            resources:
              requests:
                storage: 52G  
```
2. The secret created under yaml `00_secret.yaml` can be safely discarded. It is only needed at the beginning as initial condition for creating this. It can be safely added into `.gitinore` 

Content of this file is: 

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-user-password
  namespace: mongodbdatabase
type: Opaque
stringData:
  password: W3lc0m31.
```

---

## Secret usage

1. To get details of required strings, execute script `get_mongo_data.sh` as follows: 


`./get_mongo_data.sh example-mongodb admin my-user mongodbdatabase`

```yaml
{
  "connectionString.standard": "mongodb://my-user:W3lc0m31.@example-mongodb-0.example-mongodb-svc.mongodbdatabase.svc.cluster.local:27017,example-mongodb-1.example-mongodb-svc.mongodbdatabase.svc.cluster.local:27017,example-mongodb-2.example-mongodb-svc.mongodbdatabase.svc.cluster.local:27017/admin?replicaSet=example-mongodb&ssl=false",
  "connectionString.standardSrv": "mongodb+srv://my-user:W3lc0m31.@example-mongodb-svc.mongodbdatabase.svc.cluster.local/admin?replicaSet=example-mongodb&ssl=false",
  "password": "W3lc0m31.",
  "username": "my-user"
}
```

For this example: 

 | Variable | Description | Value in Sample |
   |----|----|----|
   | `<metadata.name>` | Name of the MongoDB database resource. | `example-mongodb` |
   | `<auth-db>` | [Authentication database](https://www.mongodb.com/docs/manual/core/security-users/#std-label-user-authentication-database) where you defined the database user. | `admin` |
   | `<username>` | Username of the database user. | `my-user` |


2. If you want to use the secrets to connect to MongoDB from inside the pod, add the following entry on your env init

```yaml
containers:
 - name: test-app
   env:
    - name: "CONNECTION_STRING"
      valueFrom:
        secretKeyRef:
          name: <metadata.name>-<auth-db>-<username>
          key: connectionString.standardSrv
```
