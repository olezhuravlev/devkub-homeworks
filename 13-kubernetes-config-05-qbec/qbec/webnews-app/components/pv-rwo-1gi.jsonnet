local params = import '../params.libsonnet';
{
   "apiVersion": "v1",
   "kind": "PersistentVolume",
   "metadata": {
      "name": "persistent-volume-1gb",
      "labels": {
         "app": "web-news",
         "component": "dbase"
      },
      "annotations": {
         "meta.helm.sh/release-name": "webnews",
         "meta.helm.sh/release-namespace": params.ns,
      }
   },
   "spec": {
      "accessModes": [
         "ReadWriteOnce"
      ],
      "capacity": {
         "storage": "1Gi"
      },
      "hostPath": {
         "path": "/persistentVolume1gb"
      },
      "persistentVolumeReclaimPolicy": "Retain"
   }
}
