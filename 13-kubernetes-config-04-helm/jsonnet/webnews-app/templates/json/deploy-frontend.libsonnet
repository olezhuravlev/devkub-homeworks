{
  get(ns)::
    {
      "apiVersion": "apps/v1",
      "kind": "Deployment",
      "metadata": {
        "name": "frontend",
        "namespace": ns,
        "labels": {
          "app": "web-news",
          "component": "frontend"
        }
      },
      "spec": {
        "replicas": 2,
        "selector": {
          "matchLabels": {
            "app": "web-news",
            "component": "frontend"
          }
        },
        "template": {
          "metadata": {
            "labels": {
              "app": "web-news",
              "component": "frontend"
            }
          },
          "spec": {
            "containers": [
              {
                "name": "frontend",
                "image": "olezhuravlev/frontend:1.1.2",
                "ports": [
                  {
                    "name": "frontend-port",
                    "containerPort": 80,
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
