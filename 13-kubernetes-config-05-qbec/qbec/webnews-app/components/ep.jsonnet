local params = import '../params.libsonnet';
[
{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": "my-external-ip",
    "namespace": params.ns,
    "labels": {
      "app": "ep-example"
    }
  },
  "spec": {
    "type": "ClusterIP",
    "clusterIP": "None",
    "ports": [
      {
        "port": 8111
      }
    ]
  }
},
{
  "apiVersion": "v1",
  "kind": "Endpoints",
  "metadata": {
    "name": "my-external-ip",
    "namespace": params.ns,
    "labels": {
      "app": "ep-example"
    }
  },
  "subsets": [
    {
      "addresses": [
        {
          "ip": "45.35.72.106"
        }
      ]
    }
  ]
}
]
