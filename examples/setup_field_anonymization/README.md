#  Setup with field anonymization


Example [configuration](https://docs.search-guard.com/latest/field-anonymization) use of a new field anonymization implementation, which provides better efficiency and functionality. However, this implementation can only be used if you have completely updated your cluster to Search Guard FLX and it is available from version FLX 1.0



To install this usage example, go to your `search-guard-helm` folder with pre-installed dependencies and do:
```
helm install -f examples/setup_field_anonymization/values.yaml sg-elk ./
```


Below is an example showing the use of the field anonymization option:


Create a connection to port 9200:
```
export POD_NAME=$(kubectl get pods -l "component=sg-elk-search-guard-flx,role=client" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward  $POD_NAME 9200:9200
```
Open the secon terminal.

Retrieve for the user `admin` using the command:

```
export SG_ADMIN_PWD=$(kubectl get secrets sg-elk-search-guard-flx-passwd-secret  -o jsonpath="{.data.SG_ADMIN_PWD}" | base64 -d)
```

Retrieve the password for the user `fieldanonymization` using the command:

```
export SG_FIELDANONYMIZATION_PWD=$(kubectl get secrets sg-elk-search-guard-flx-passwd-secret  -o jsonpath="{.data.SG_FIELDANONYMIZATION_PWD}" | base64 -d)
```

Create sample data:

```
curl -k -u admin:$SG_ADMIN_PWD -X POST "https://127.0.0.1:9200/humanresources/employees/" -H 'Content-Type: application/json' -d '{
    "Designation": "Manager",
    "Salary": 154000,
    "Address": "Sample street",
    "FirstName": "John",
    "LastName": "Doe"
}'
```

Search for data using the `admin` user:

```
curl -k -u admin:$SG_ADMIN_PWD -X GET "https://127.0.0.1:9200/humanresources/_search"
```

Fields `Address`, `FirstName`, and `LastName` should not return anonymized values:
```
 {"took":56,"timed_out":false,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0},"hits":{"total":{"value":1,"relation":"eq"},"max_score":1.0,"hits":[{"_index":"humanresources","_type":"employees","_id":"jZT9QIoB2j3gTnEUDwvV","_score":1.0,"_source":{
    "Designation": "Manager",
    "Salary": 154000,
    "Address": "Sample street",
    "FirstName": "John",
    "LastName": "Doe"
}}]}
 ```

Search for data using the `fieldanonymization` user:
 
```
curl -k -u fieldanonymization:$SG_FIELDANONYMIZATION_PWD -X GET "https://127.0.0.1:9200/humanresources/_search"
```
Fields `Address`, `FirstName`, and `LastName` should return anonymized values:

```
{"took":2,"timed_out":false,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0},"hits":{"total":{"value":1,"relation":"eq"},"max_score":1.0,"hits":[{"_index":"humanresources","_type":"employees","_id":"jZT9QIoB2j3gTnEUDwvV","_score":1.0,"_source":{"Designation":"Manager","Salary":154000,"Address":"6f0d9efb49db8d5244b779672b4ed59280dfad0e24511ed24656a65d4b1475d0","FirstName":"555c357473b7171af7d61d3b45478425588b175b0746b49cd9c5dcec13f9f535","LastName":"5b54779ea602d432b5799f5dda205a7323cd25eb6b0c6692a8a957de7204bc4e"}}]}}
```


To uninstall this usage example, run this command:
```
helm uninstall sg-elk  
```