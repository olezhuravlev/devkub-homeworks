{
  get(ns)::
    {
      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
        "name": "db",
        "namespace": ns,
        "labels": {
          "app": "web-news",
          "component": "dbase"
        }
      },
      "spec": {
        "type": "NodePort",
        "selector": {
          "app": "web-news",
          "component": "dbase"
        },
        "ports": [
          {
            "name": "postgres-nodeport",
            "protocol": "TCP",
            "nodePort": 30002,
            "port": 5432,
            "targetPort": "postgres-port"
          }
        ]
      }
    }
}
