{
  get(ns)::
    {
      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
        "name": "backend-nodeport-svc",
        "namespace": ns,
        "labels": {
          "app": "web-news",
          "component": "backend"
        }
      },
      "spec": {
        "type": "NodePort",
        "selector": {
          "app": "web-news",
          "component": "backend"
        },
        "ports": [
          {
            "name": "backend-nodeport",
            "protocol": "TCP",
            "nodePort": 30001,
            "port": 9000,
            "targetPort": "backend-port"
          }
        ]
      }
    }
}
