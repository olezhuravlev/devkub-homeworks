{
  get(ns)::
    {
      "apiVersion": "v1",
      "kind": "Service",
      "metadata": {
        "name": "frontend-nodeport-svc",
        "namespace": ns,
        "labels": {
          "app": "web-news",
          "component": "frontend"
        }
      },
      "spec": {
        "type": "NodePort",
        "selector": {
          "app": "web-news",
          "component": "frontend"
        },
        "ports": [
          {
            "name": "frontend-nodeport",
            "protocol": "TCP",
            "nodePort": 30000,
            "port": 80,
            "targetPort": "frontend-port"
          }
        ]
      }
    }
}
