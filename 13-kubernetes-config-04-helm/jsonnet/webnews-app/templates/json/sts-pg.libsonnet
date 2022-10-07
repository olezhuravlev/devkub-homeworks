{
  get(ns)::
    {
      "apiVersion": "apps/v1",
      "kind": "StatefulSet",
      "metadata": {
        "name": "postgres-sts",
        "namespace": ns,
        "labels": {
          "app": "web-news",
          "component": "dbase"
        }
      },
      "spec": {
        "serviceName": "postgres-svc",
        "replicas": 1,
        "selector": {
          "matchLabels": {
            "app": "web-news",
            "component": "dbase"
          }
        },
        "template": {
          "metadata": {
            "labels": {
              "app": "web-news",
              "component": "dbase"
            }
          },
          "spec": {
            "containers": [
              {
                "name": "postgres",
                "image": "postgres:13-alpine",
                "volumeMounts": [
                  {
                    "name": "postgres-volume",
                    "mountPath": "/postgresVolume"
                  }
                ],
                "ports": [
                  {
                    "name": "postgres-port",
                    "containerPort": 5432,
                    "protocol": "TCP"
                  }
                ],
                "env": [
                  {
                    "name": "POSTGRES_PASSWORD",
                    "value": "postgres"
                  },
                  {
                    "name": "POSTGRES_USER",
                    "value": "postgres"
                  },
                  {
                    "name": "POSTGRES_DB",
                    "value": "news"
                  },
                  {
                    "name": "PGDATA",
                    "value": "/postgresVolume/data"
                  }
                ]
              }
            ]
          }
        },
        "volumeClaimTemplates": [
          {
            "metadata": {
              "name": "postgres-volume",
              "labels": {
                "component": "dbase"
              }
            },
            "spec": {
              "accessModes": [
                "ReadWriteOnce"
              ],
              "resources": {
                "requests": {
                  "storage": "1Gi"
                }
              }
            }
          }
        ]
      }
    }
}
