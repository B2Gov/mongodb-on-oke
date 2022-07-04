#!/bin/sh

if [ $# -lt 4 ]
  then
    echo "Not enough arguments. Usage: ./get_mongo_data.sh db_name auth_type username namespace"
    echo "Example: ./get_mongo_data.sh example-mongodb admin my-user mongodbdatabase" 
    exit 1

else
    export NAME=$1
    export AUTH_DB=$2
    export USERNAME=$3
    export NAMESPACE=$4

    kubectl get secret $NAME-$AUTH_DB-$USERNAME -n $NAMESPACE -o json | jq -r '.data | with_entries(.value |= @base64d)'

fi