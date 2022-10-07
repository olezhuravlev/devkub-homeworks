{
  get(ns)::
  {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "metadata": {
      "name": "backend",
      "namespace": ns,
      "labels": {
        "app": "web-news",
        "component": "backend"
      }
    },
    "spec": {
      "replicas": 2,
      "selector": {
        "matchLabels": {
          "app": "web-news",
          "component": "backend"
        }
      },
      "template": {
        "metadata": {
          "labels": {
            "app": "web-news",
            "component": "backend"
          }
        },
        "spec": {
          "containers": [
            {
              "name": "backend",
              "image": "olezhuravlev/backend:1.0.0",
              "ports": [
                {
                  "name": "backend-port",
                  "containerPort": 9000,
                  "protocol": "TCP"
                }
              ]
            }
          ]
        }
      }
    }
  }
}
