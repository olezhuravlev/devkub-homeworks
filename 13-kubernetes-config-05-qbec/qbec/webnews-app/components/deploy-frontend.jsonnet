local params = import '../params.libsonnet';
[
{
  "apiVersion": "apps/v1",
  "kind": "Deployment",
  "metadata": {
    "name": "frontend",
    "namespace": params.ns,
    "labels": {
      "app": "web-news",
      "component": "frontend"
    }
  },
  "spec": {
    "replicas":  params.frontend.replicas,
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
},
{
  "apiVersion": "v1",
  "kind": "Service",
  "metadata": {
    "name": "frontend-nodeport-svc",
    "namespace": params.ns,
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
]
