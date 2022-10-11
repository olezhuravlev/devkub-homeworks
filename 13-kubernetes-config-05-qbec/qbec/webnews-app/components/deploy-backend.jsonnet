local params = import '../params.libsonnet';
[
{
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "name": "backend",
    "namespace": params.ns,
    "labels": {
      "app": "web-news",
      "component": "backend"
    }
  },
  "spec": {
    "replicas": params.backend.replicas,
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
},
{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": "backend-nodeport-svc",
    "namespace": params.ns,
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
]
