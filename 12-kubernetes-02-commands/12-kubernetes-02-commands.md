# Домашнее задание к занятию "12.2 Команды для работы с Kubernetes"
Кластер — это сложная система, с которой крайне редко работает один человек. Квалифицированный devops умеет наладить работу всей команды, занимающейся каким-либо сервисом.
После знакомства с кластером вас попросили выдать доступ нескольким разработчикам. Помимо этого требуется служебный аккаунт для просмотра логов.

## Задание 1: Запуск пода из образа в деплойменте
Для начала следует разобраться с прямым запуском приложений из консоли. Такой подход поможет быстро развернуть инструменты отладки в кластере. Требуется запустить деплоймент на основе образа из hello world уже через deployment. Сразу стоит запустить 2 копии приложения (replicas=2). 

Требования:
 * пример из hello world запущен в качестве deployment
 * количество реплик в deployment установлено в 2
 * наличие deployment можно проверить командой kubectl get deployment
 * наличие подов можно проверить командой kubectl get pods


---

### Решение:

Конфигурация Ansible находится [здесь](./infrastructure/site.yml).

> Она аналогична конфигурации из предыдущего задания за исключением того, что количество реплик
> создаваемого деплоймента задано как `replicas=2`, а также добавлены команды для вывода
> списков деплойментов и подов.

<details>
  <summary><b>Применим её.</b></summary>

````bash
$ ansible-playbook site.yml -i inventory/hosts.yml -K
BECOME password: 

PLAY [Setup Minikube infrastructure] ****************************************************************************************************************************************************************************************************

TASK [Gathering Facts] ******************************************************************************************************************************************************************************************************************
ok: [vm-01]

TASK [Downloading "minikube"] ***********************************************************************************************************************************************************************************************************
ok: [vm-01]

TASK [Downloading "kubectl"] ************************************************************************************************************************************************************************************************************
ok: [vm-01]

TASK [Downloading "kubeadm"] ************************************************************************************************************************************************************************************************************
ok: [vm-01]

TASK [Downloading "kubelet"] ************************************************************************************************************************************************************************************************************
ok: [vm-01]

TASK [Copying file "minikube"] **********************************************************************************************************************************************************************************************************
ok: [vm-01]

TASK [Copying file "kubectl"] ***********************************************************************************************************************************************************************************************************
ok: [vm-01]

TASK [Copying file "kubeadm"] ***********************************************************************************************************************************************************************************************************
ok: [vm-01]

TASK [Copying file "kubelet"] ***********************************************************************************************************************************************************************************************************
ok: [vm-01]

TASK [Run minikube (--driver=docker)] ***************************************************************************************************************************************************************************************************
changed: [vm-01]

TASK [debug] ****************************************************************************************************************************************************************************************************************************
ok: [vm-01] => {
    "msg": [
        "* minikube v1.26.1 on Arch 21.3.7",
        "* Using the docker driver based on user configuration",
        "* Using Docker driver with root privileges",
        "* Starting control plane node minikube in cluster minikube",
        "* Pulling base image ...",
        "* Creating docker container (CPUs=2, Memory=16000MB) ...",
        "* Preparing Kubernetes v1.24.3 on Docker 20.10.17 ...",
        "  - Generating certificates and keys ...",
        "  - Booting up control plane ...",
        "  - Configuring RBAC rules ...",
        "* Verifying Kubernetes components...",
        "  - Using image gcr.io/k8s-minikube/storage-provisioner:v5",
        "* Enabled addons: storage-provisioner, default-storageclass",
        "* Done! kubectl is now configured to use \"minikube\" cluster and \"default\" namespace by default"
    ]
}

TASK [Get minikube status] **************************************************************************************************************************************************************************************************************
changed: [vm-01]

TASK [debug] ****************************************************************************************************************************************************************************************************************************
ok: [vm-01] => {
    "msg": [
        "minikube",
        "type: Control Plane",
        "host: Running",
        "kubelet: Running",
        "apiserver: Running",
        "kubeconfig: Configured"
    ]
}

TASK [Creating 'hello-node' deployment] *************************************************************************************************************************************************************************************************
changed: [vm-01]

TASK [debug] ****************************************************************************************************************************************************************************************************************************
ok: [vm-01] => {
    "msg": [
        "deployment.apps/hello-node created"
    ]
}

TASK [Exposing 'hello-node' deployment] *************************************************************************************************************************************************************************************************
changed: [vm-01]

TASK [debug] ****************************************************************************************************************************************************************************************************************************
ok: [vm-01] => {
    "msg": [
        "service/hello-node exposed"
    ]
}

TASK [Enabling addon 'dashboard'] *******************************************************************************************************************************************************************************************************
changed: [vm-01]

TASK [debug] ****************************************************************************************************************************************************************************************************************************
ok: [vm-01] => {
    "msg": [
        "* dashboard is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.",
        "You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS",
        "  - Using image kubernetesui/dashboard:v2.6.0",
        "  - Using image kubernetesui/metrics-scraper:v1.0.8",
        "* Some dashboard features require the metrics-server addon. To enable all features please run:",
        "",
        "\tminikube addons enable metrics-server\t",
        "",
        "",
        "* The 'dashboard' addon is enabled"
    ]
}

TASK [Enabling addon 'ingress'] *********************************************************************************************************************************************************************************************************
changed: [vm-01]

TASK [debug] ****************************************************************************************************************************************************************************************************************************
ok: [vm-01] => {
    "msg": [
        "* ingress is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.",
        "You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS",
        "  - Using image k8s.gcr.io/ingress-nginx/controller:v1.2.1",
        "  - Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1",
        "  - Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1",
        "* Verifying ingress addon...",
        "* The 'ingress' addon is enabled"
    ]
}

TASK [Forwarding 'hello-node' to port 8081] *********************************************************************************************************************************************************************************************
changed: [vm-01]

TASK [Checking 'hello-node' port accessibility - http://localhost:8081] *****************************************************************************************************************************************************************
ok: [vm-01]

TASK [Showing deployments] **************************************************************************************************************************************************************************************************************
changed: [vm-01]

TASK [debug] ****************************************************************************************************************************************************************************************************************************
ok: [vm-01] => {
    "msg": [
        "NAME         READY   UP-TO-DATE   AVAILABLE   AGE",
        "hello-node   2/2     2            2           65s"
    ]
}

TASK [Showing pods] *********************************************************************************************************************************************************************************************************************
changed: [vm-01]

TASK [debug] ****************************************************************************************************************************************************************************************************************************
ok: [vm-01] => {
    "msg": [
        "NAME                          READY   STATUS    RESTARTS   AGE",
        "hello-node-6d5f754cc9-66jsl   1/1     Running   0          55s",
        "hello-node-6d5f754cc9-pt84z   1/1     Running   0          55s"
    ]
}

PLAY RECAP ******************************************************************************************************************************************************************************************************************************
vm-01                      : ok=27   changed=9    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
````
</details>

Как видим из вывода последних команд, создан один деплоймент и два пода:
````bash
TASK [Showing deployments] *************************************************************************
changed: [vm-01]

TASK [debug] ***************************************************************************************
ok: [vm-01] => {
    "msg": [
        "NAME         READY   UP-TO-DATE   AVAILABLE   AGE",
        "hello-node   2/2     2            2           65s"
    ]
}

TASK [Showing pods] ********************************************************************************
changed: [vm-01]

TASK [debug] ***************************************************************************************
ok: [vm-01] => {
    "msg": [
        "NAME                          READY   STATUS    RESTARTS   AGE",
        "hello-node-6d5f754cc9-66jsl   1/1     Running   0          55s",
        "hello-node-6d5f754cc9-pt84z   1/1     Running   0          55s"
    ]
}
````

---

## Задание 2: Просмотр логов для разработки
Разработчикам крайне важно получать обратную связь от штатно работающего приложения и, еще важнее, об ошибках в его работе. 
Требуется создать пользователя и выдать ему доступ на чтение конфигурации и логов подов в app-namespace.

Требования: 
 * создан новый токен доступа для пользователя
 * пользователь прописан в локальный конфиг (~/.kube/config, блок users)
 * пользователь может просматривать логи подов и их конфигурацию (kubectl logs pod <pod_id>, kubectl describe pod <pod_id>)

---

### Решение:

Проверим, что RBAC подключен:
````bash
$ kubectl api-versions | grep rbac
rbac.authorization.k8s.io/v1
````
RBAC в конфигурации API присутствует, значит подключен.

Создадим сервисный аккаунт:
````bash
$ kubectl create serviceaccount ro-user -n default
serviceaccount/ro-user created

$ kubectl get serviceaccounts -n default
NAME      SECRETS   AGE
default   0         85s
ro-user   0         5s
````

Создадим для кластера роль с необходимыми полномочиями (чтение конфигурации и логов подов
в указанном пространстве имен):
````bash
$ kubectl create clusterrole ro-role --verb=get,list,watch --resource=pods,pods/log
clusterrole.rbac.authorization.k8s.io/ro-role created

$ kubectl get clusterroles
NAME                                                                   CREATED AT
admin                                                                  2022-09-12T06:09:11Z
cluster-admin                                                          2022-09-12T06:09:11Z
edit                                                                   2022-09-12T06:09:11Z
ingress-nginx                                                          2022-09-12T06:09:19Z
ingress-nginx-admission                                                2022-09-12T06:09:19Z
kubeadm:get-nodes                                                      2022-09-12T06:09:13Z
kubernetes-dashboard                                                   2022-09-12T06:09:18Z
ro-role                                                                2022-09-12T06:11:12Z
system:aggregate-to-admin                                              2022-09-12T06:09:11Z
system:aggregate-to-edit                                               2022-09-12T06:09:11Z
system:aggregate-to-view                                               2022-09-12T06:09:11Z
system:auth-delegator                                                  2022-09-12T06:09:11Z
system:basic-user                                                      2022-09-12T06:09:11Z
system:certificates.k8s.io:certificatesigningrequests:nodeclient       2022-09-12T06:09:11Z
system:certificates.k8s.io:certificatesigningrequests:selfnodeclient   2022-09-12T06:09:11Z
system:certificates.k8s.io:kube-apiserver-client-approver              2022-09-12T06:09:11Z
system:certificates.k8s.io:kube-apiserver-client-kubelet-approver      2022-09-12T06:09:11Z
system:certificates.k8s.io:kubelet-serving-approver                    2022-09-12T06:09:11Z
system:certificates.k8s.io:legacy-unknown-approver                     2022-09-12T06:09:11Z
system:controller:attachdetach-controller                              2022-09-12T06:09:11Z
system:controller:certificate-controller                               2022-09-12T06:09:11Z
system:controller:clusterrole-aggregation-controller                   2022-09-12T06:09:11Z
system:controller:cronjob-controller                                   2022-09-12T06:09:11Z
system:controller:daemon-set-controller                                2022-09-12T06:09:11Z
system:controller:deployment-controller                                2022-09-12T06:09:11Z
system:controller:disruption-controller                                2022-09-12T06:09:11Z
system:controller:endpoint-controller                                  2022-09-12T06:09:11Z
system:controller:endpointslice-controller                             2022-09-12T06:09:11Z
system:controller:endpointslicemirroring-controller                    2022-09-12T06:09:11Z
system:controller:ephemeral-volume-controller                          2022-09-12T06:09:11Z
system:controller:expand-controller                                    2022-09-12T06:09:11Z
system:controller:generic-garbage-collector                            2022-09-12T06:09:11Z
system:controller:horizontal-pod-autoscaler                            2022-09-12T06:09:11Z
system:controller:job-controller                                       2022-09-12T06:09:11Z
system:controller:namespace-controller                                 2022-09-12T06:09:11Z
system:controller:node-controller                                      2022-09-12T06:09:11Z
system:controller:persistent-volume-binder                             2022-09-12T06:09:11Z
system:controller:pod-garbage-collector                                2022-09-12T06:09:11Z
system:controller:pv-protection-controller                             2022-09-12T06:09:11Z
system:controller:pvc-protection-controller                            2022-09-12T06:09:11Z
system:controller:replicaset-controller                                2022-09-12T06:09:11Z
system:controller:replication-controller                               2022-09-12T06:09:11Z
system:controller:resourcequota-controller                             2022-09-12T06:09:11Z
system:controller:root-ca-cert-publisher                               2022-09-12T06:09:11Z
system:controller:route-controller                                     2022-09-12T06:09:11Z
system:controller:service-account-controller                           2022-09-12T06:09:11Z
system:controller:service-controller                                   2022-09-12T06:09:11Z
system:controller:statefulset-controller                               2022-09-12T06:09:11Z
system:controller:ttl-after-finished-controller                        2022-09-12T06:09:11Z
system:controller:ttl-controller                                       2022-09-12T06:09:11Z
system:coredns                                                         2022-09-12T06:09:13Z
system:discovery                                                       2022-09-12T06:09:11Z
system:heapster                                                        2022-09-12T06:09:11Z
system:kube-aggregator                                                 2022-09-12T06:09:11Z
system:kube-controller-manager                                         2022-09-12T06:09:11Z
system:kube-dns                                                        2022-09-12T06:09:11Z
system:kube-scheduler                                                  2022-09-12T06:09:11Z
system:kubelet-api-admin                                               2022-09-12T06:09:11Z
system:monitoring                                                      2022-09-12T06:09:11Z
system:node                                                            2022-09-12T06:09:11Z
system:node-bootstrapper                                               2022-09-12T06:09:11Z
system:node-problem-detector                                           2022-09-12T06:09:11Z
system:node-proxier                                                    2022-09-12T06:09:11Z
system:persistent-volume-provisioner                                   2022-09-12T06:09:11Z
system:public-info-viewer                                              2022-09-12T06:09:11Z
system:service-account-issuer-discovery                                2022-09-12T06:09:11Z
system:volume-scheduler                                                2022-09-12T06:09:11Z
view                                                                   2022-09-12T06:09:11Z
````

Создадим связку сервисного аккаунта и роли:
````bash
$ kubectl create clusterrolebinding ro-binding --clusterrole=ro-role --serviceaccount=default:ro-user
clusterrolebinding.rbac.authorization.k8s.io/ro-binding created

$ kubectl get clusterrolebindings
NAME                                                   ROLE                                                                               AGE
cluster-admin                                          ClusterRole/cluster-admin                                                          2m37s
ingress-nginx                                          ClusterRole/ingress-nginx                                                          2m29s
ingress-nginx-admission                                ClusterRole/ingress-nginx-admission                                                2m29s
kubeadm:get-nodes                                      ClusterRole/kubeadm:get-nodes                                                      2m35s
kubeadm:kubelet-bootstrap                              ClusterRole/system:node-bootstrapper                                               2m35s
kubeadm:node-autoapprove-bootstrap                     ClusterRole/system:certificates.k8s.io:certificatesigningrequests:nodeclient       2m35s
kubeadm:node-autoapprove-certificate-rotation          ClusterRole/system:certificates.k8s.io:certificatesigningrequests:selfnodeclient   2m35s
kubeadm:node-proxier                                   ClusterRole/system:node-proxier                                                    2m35s
kubernetes-dashboard                                   ClusterRole/cluster-admin                                                          2m30s
minikube-rbac                                          ClusterRole/cluster-admin                                                          2m34s
ro-binding                                             ClusterRole/ro-role                                                                5s
storage-provisioner                                    ClusterRole/system:persistent-volume-provisioner                                   2m33s
system:basic-user                                      ClusterRole/system:basic-user                                                      2m37s
system:controller:attachdetach-controller              ClusterRole/system:controller:attachdetach-controller                              2m36s
system:controller:certificate-controller               ClusterRole/system:controller:certificate-controller                               2m36s
system:controller:clusterrole-aggregation-controller   ClusterRole/system:controller:clusterrole-aggregation-controller                   2m36s
system:controller:cronjob-controller                   ClusterRole/system:controller:cronjob-controller                                   2m36s
system:controller:daemon-set-controller                ClusterRole/system:controller:daemon-set-controller                                2m36s
system:controller:deployment-controller                ClusterRole/system:controller:deployment-controller                                2m36s
system:controller:disruption-controller                ClusterRole/system:controller:disruption-controller                                2m36s
system:controller:endpoint-controller                  ClusterRole/system:controller:endpoint-controller                                  2m36s
system:controller:endpointslice-controller             ClusterRole/system:controller:endpointslice-controller                             2m36s
system:controller:endpointslicemirroring-controller    ClusterRole/system:controller:endpointslicemirroring-controller                    2m36s
system:controller:ephemeral-volume-controller          ClusterRole/system:controller:ephemeral-volume-controller                          2m36s
system:controller:expand-controller                    ClusterRole/system:controller:expand-controller                                    2m36s
system:controller:generic-garbage-collector            ClusterRole/system:controller:generic-garbage-collector                            2m36s
system:controller:horizontal-pod-autoscaler            ClusterRole/system:controller:horizontal-pod-autoscaler                            2m36s
system:controller:job-controller                       ClusterRole/system:controller:job-controller                                       2m36s
system:controller:namespace-controller                 ClusterRole/system:controller:namespace-controller                                 2m36s
system:controller:node-controller                      ClusterRole/system:controller:node-controller                                      2m36s
system:controller:persistent-volume-binder             ClusterRole/system:controller:persistent-volume-binder                             2m36s
system:controller:pod-garbage-collector                ClusterRole/system:controller:pod-garbage-collector                                2m36s
system:controller:pv-protection-controller             ClusterRole/system:controller:pv-protection-controller                             2m36s
system:controller:pvc-protection-controller            ClusterRole/system:controller:pvc-protection-controller                            2m36s
system:controller:replicaset-controller                ClusterRole/system:controller:replicaset-controller                                2m36s
system:controller:replication-controller               ClusterRole/system:controller:replication-controller                               2m36s
system:controller:resourcequota-controller             ClusterRole/system:controller:resourcequota-controller                             2m36s
system:controller:root-ca-cert-publisher               ClusterRole/system:controller:root-ca-cert-publisher                               2m36s
system:controller:route-controller                     ClusterRole/system:controller:route-controller                                     2m36s
system:controller:service-account-controller           ClusterRole/system:controller:service-account-controller                           2m36s
system:controller:service-controller                   ClusterRole/system:controller:service-controller                                   2m36s
system:controller:statefulset-controller               ClusterRole/system:controller:statefulset-controller                               2m36s
system:controller:ttl-after-finished-controller        ClusterRole/system:controller:ttl-after-finished-controller                        2m36s
system:controller:ttl-controller                       ClusterRole/system:controller:ttl-controller                                       2m36s
system:coredns                                         ClusterRole/system:coredns                                                         2m35s
system:discovery                                       ClusterRole/system:discovery                                                       2m37s
system:kube-controller-manager                         ClusterRole/system:kube-controller-manager                                         2m36s
system:kube-dns                                        ClusterRole/system:kube-dns                                                        2m36s
system:kube-scheduler                                  ClusterRole/system:kube-scheduler                                                  2m36s
system:monitoring                                      ClusterRole/system:monitoring                                                      2m37s
system:node                                            ClusterRole/system:node                                                            2m36s
system:node-proxier                                    ClusterRole/system:node-proxier                                                    2m36s
system:public-info-viewer                              ClusterRole/system:public-info-viewer                                              2m37s
system:service-account-issuer-discovery                ClusterRole/system:service-account-issuer-discovery                                2m36s
system:volume-scheduler                                ClusterRole/system:volume-scheduler                                                2m36s
````

Создадим токен для сервисного аккаунта:
````bash
# Request a token to authenticate to the kube-apiserver as the service account "myapp" in the namespace
$ kubectl create token ro-user -n default
eyJhbGciOiJSUzI1NiIsImtpZCI6IjdJSEFnUjhUWDhuWmROTWpjeFYyeXAwbjVVbHd5S0V3VnFqWEZWTTZ3YWcifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjYyOTY2NzUyLCJpYXQiOjE2NjI5NjMxNTIsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0Iiwic2VydmljZWFjY291bnQiOnsibmFtZSI6InJvLXVzZXIiLCJ1aWQiOiJhMGI2NjFhYi1mNGUwLTRkYjgtODVjMy0zYTU3ZTI3NTkyMTgifX0sIm5iZiI6MTY2Mjk2MzE1Miwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6cm8tdXNlciJ9.HTXzL0NwUZY00u_tPM788_zTgDVHrs3zFXzQ90Zm30tzHvgFo2t6_bnZI4AFG-n6ogLojwVkiFgNT7dDoOQEiX8F2CG3tk0_90n_lsq5SuA-d8jDtzi1no1g5Vl5av1iXgKIWFNAO4efNkF2TXyJyfsUT-PE_CraV_8ovz5d4KT9lCiVg_P313emC9QX_78n2B-YZU8YF7aaK78EQQ_H3LXfwoZFwA_4qUzNFwxWSsPh9_-UkH8q4bXNtFxwlkiqhnWJ12UxW0hdMbQcxTxZ87wH5mAtVXS-uZWwnt81To08-nYUbVIYsw5C8DnM-ZICVhD9EybQGX0gvuUWQojPPg

$ kubectl describe serviceaccount ro-user
Name:                ro-user
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   <none>
Tokens:              <none>
Events:              <none>
````

Установим полномочия пользователю "ro-user":
````bash
$ kubectl config set-credentials ro-user --token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjdJSEFnUjhUWDhuWmROTWpjeFYyeXAwbjVVbHd5S0V3VnFqWEZWTTZ3YWcifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjYyOTY2NzUyLCJpYXQiOjE2NjI5NjMxNTIsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0Iiwic2VydmljZWFjY291bnQiOnsibmFtZSI6InJvLXVzZXIiLCJ1aWQiOiJhMGI2NjFhYi1mNGUwLTRkYjgtODVjMy0zYTU3ZTI3NTkyMTgifX0sIm5iZiI6MTY2Mjk2MzE1Miwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6cm8tdXNlciJ9.HTXzL0NwUZY00u_tPM788_zTgDVHrs3zFXzQ90Zm30tzHvgFo2t6_bnZI4AFG-n6ogLojwVkiFgNT7dDoOQEiX8F2CG3tk0_90n_lsq5SuA-d8jDtzi1no1g5Vl5av1iXgKIWFNAO4efNkF2TXyJyfsUT-PE_CraV_8ovz5d4KT9lCiVg_P313emC9QX_78n2B-YZU8YF7aaK78EQQ_H3LXfwoZFwA_4qUzNFwxWSsPh9_-UkH8q4bXNtFxwlkiqhnWJ12UxW0hdMbQcxTxZ87wH5mAtVXS-uZWwnt81To08-nYUbVIYsw5C8DnM-ZICVhD9EybQGX0gvuUWQojPPg
User "ro-user" set.
````

Пользователь и его токен доступа запишутся в файл `~/.kube/config` в секцию `users`:
````yaml
users:
  - name: ro-user
    user:
      token: eyJhbGciOiJSUzI1NiIsImtpZCI6IjdJSEFnUjhUWDhuWmROTWpjeFYyeXAwbjVVbHd5S0V3VnFqWEZWTTZ3YWcifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjYyOTY2NzUyLCJpYXQiOjE2NjI5NjMxNTIsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0Iiwic2VydmljZWFjY291bnQiOnsibmFtZSI6InJvLXVzZXIiLCJ1aWQiOiJhMGI2NjFhYi1mNGUwLTRkYjgtODVjMy0zYTU3ZTI3NTkyMTgifX0sIm5iZiI6MTY2Mjk2MzE1Miwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6cm8tdXNlciJ9.HTXzL0NwUZY00u_tPM788_zTgDVHrs3zFXzQ90Zm30tzHvgFo2t6_bnZI4AFG-n6ogLojwVkiFgNT7dDoOQEiX8F2CG3tk0_90n_lsq5SuA-d8jDtzi1no1g5Vl5av1iXgKIWFNAO4efNkF2TXyJyfsUT-PE_CraV_8ovz5d4KT9lCiVg_P313emC9QX_78n2B-YZU8YF7aaK78EQQ_H3LXfwoZFwA_4qUzNFwxWSsPh9_-UkH8q4bXNtFxwlkiqhnWJ12UxW0hdMbQcxTxZ87wH5mAtVXS-uZWwnt81To08-nYUbVIYsw5C8DnM-ZICVhD9EybQGX0gvuUWQojPPg
...
````

Создадим контекст, дав ему имя "ro-context":
````bash
$ kubectl config set-context ro-context --cluster=minikube --user=ro-user --namespace default
Context "ro-context" created.
````

Пользователь и его контекст запишутся в файл `~/.kube/config` в секцию `contexts`:
````yaml
contexts:
- context:
    cluster: minikube
    namespace: default
    user: ro-user
  name: ro-context
````

Список контекстов:
````bash
$ kubectl config get-contexts
CURRENT   NAME                                  CLUSTER                               AUTHINFO                              NAMESPACE
*         minikube                              minikube                              minikube                              default
          ro-context                            minikube                              ro-user                               default
          yc-applications                       yc-managed-k8s-catn5krminfk7q30kgrr   yc-managed-k8s-catn5krminfk7q30kgrr   
          yc-managed-k8s-cat6nrs83aq6vrhrdj1i   yc-managed-k8s-cat6nrs83aq6vrhrdj1i   yc-managed-k8s-cat6nrs83aq6vrhrdj1i   
          yc-managed-k8s-catehd6jbquigdfpo4hj   yc-managed-k8s-catehd6jbquigdfpo4hj   yc-managed-k8s-catehd6jbquigdfpo4hj   
````

Проверим текущие полномочия:
````bash
$ kubectl auth can-i '*' '*' --namespace=default
yes
````
Возвращенный результат `yes` означает, что мы обладаем всеми полномочиями в рамках указанного
пространства имен.

Теперь переключимся на созданный контекст:
````bash
$ kubectl config use-context ro-context
Switched to context "ro-context".
````

Контекст переключен:
````bash
$ kubectl config get-contexts
CURRENT   NAME                                  CLUSTER                               AUTHINFO                              NAMESPACE
          minikube                              minikube                              minikube                              default
*         ro-context                            minikube                              ro-user                               default
          yc-applications                       yc-managed-k8s-catn5krminfk7q30kgrr   yc-managed-k8s-catn5krminfk7q30kgrr   
          yc-managed-k8s-cat6nrs83aq6vrhrdj1i   yc-managed-k8s-cat6nrs83aq6vrhrdj1i   yc-managed-k8s-cat6nrs83aq6vrhrdj1i   
          yc-managed-k8s-catehd6jbquigdfpo4hj   yc-managed-k8s-catehd6jbquigdfpo4hj   yc-managed-k8s-catehd6jbquigdfpo4hj   
````

Находясь в новом контексте, проверим наличие всех полномочия:
````bash
$ kubectl auth can-i '*' '*' --namespace=default
no
````

Полномочия ограничены. Проверим доступ к подам:
````bash
$ kubectl auth can-i get pods
yes

$ kubectl auth can-i create pods
no

$ kubectl auth can-i delete pods
no

$ kubectl auth can-i list deployments
no

# Check to see if I can read pod logs
$ kubectl auth can-i get pods --subresource=log
yes
````

Соответственно, находясь в данном контексте возможно считывать состояние подов и их логи, но
нельзя их создавать или удалять. Также отсутствует доступ к деплойментам.

---

## Задание 3: Изменение количества реплик 
Поработав с приложением, вы получили запрос на увеличение количества реплик приложения для нагрузки. Необходимо изменить запущенный deployment, увеличив количество реплик до 5. Посмотрите статус запущенных подов после увеличения реплик. 

Требования:
 * в deployment из задания 1 изменено количество реплик на 5
 * проверить что все поды перешли в статус running (kubectl get pods)

---

### Решение:

Для изменения деплоймента (т.е. "Desired State") "на лету" следует командой `edit` изменить его
конфигурационный файл, указав требуемые для применения параметры.
В нашем случае - это параметр `replicas`.

Сначала найдем наш деплоймент в списке и узнаем его имя:
````bash
$ kubectl get deployments -o wide                    
NAME         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                      SELECTOR
hello-node   2/2     2            2           13m   echoserver   k8s.gcr.io/echoserver:1.4   app=hello-node
````

Отредактируем деплоймент (откроется консольный редактор):
````bash
$ kubectl edit deployments -n default hello-node
````

Здесь следует изменить параметр `replicas` на желаемое значение (`5`):
````yaml
spec:
  ...
  replicas: 5
  ...
````

Когда конфигурационный файл будет изменен, то контроллер развёртывания (Deployment Controller)
приведет "Actual State" к "Desired State" и мы увидим эти изменения:
````bash
$ kubectl get deployments -o wide                 
NAME         READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                      SELECTOR
hello-node   5/5     5            5           17m   echoserver   k8s.gcr.io/echoserver:1.4   app=hello-node
````

Проверим и состояние подов:
````bash
$ kubectl get pods               
NAME                          READY   STATUS    RESTARTS   AGE
hello-node-6d5f754cc9-66jsl   1/1     Running   0          22m
hello-node-6d5f754cc9-pt84z   1/1     Running   0          22m
hello-node-6d5f754cc9-t4g9d   1/1     Running   0          5m14s
hello-node-6d5f754cc9-vphdl   1/1     Running   0          5m14s
hello-node-6d5f754cc9-xn6rq   1/1     Running   0          5m14s
````

Подов стало 5 штук и все они активны. По времени жизни подов легко заметить, что
среди них 2 первоначальных пода и 3 новых.

Т.о. в результате наших действий количество реплик было увеличено до 5.

---

### Приложение - полезные команды:

Новый токен и вывод команды на его присоединение:
````bash
$ kubeadm token create --print-join-command
````

Описание пода:
````bash
$ kubectl describe -n default pod
````

Описание ноды:
````bash
$ kubectl describe nodes minikube
````

Редактирование конфиг-файла ноды:
````bash
$ kubectl describe nodes minikube
````

С ярлыками:
````bash
$ kubectl get pods --all-namespaces --show-labels
````

Больше информации (показывает IP и ноды):
````bash
$ kubectl get pods --all-namespaces -o wide                                                 
NAMESPACE              NAME                                         READY   STATUS      RESTARTS       AGE    IP             NODE       NOMINATED NODE   READINESS GATES
default                hello-node-6d5f754cc9-8jb8j                  1/1     Running     0              109m   172.17.0.7     minikube   <none>           <none>
ingress-nginx          ingress-nginx-admission-create-8mxl8         0/1     Completed   0              109m   172.17.0.3     minikube   <none>           <none>
ingress-nginx          ingress-nginx-admission-patch-4s2pf          0/1     Completed   1              109m   172.17.0.2     minikube   <none>           <none>
ingress-nginx          ingress-nginx-controller-755dfbfc65-gvxmj    1/1     Running     0              109m   172.17.0.2     minikube   <none>           <none>
kube-system            coredns-6d4b75cb6d-vfv8j                     1/1     Running     0              109m   172.17.0.4     minikube   <none>           <none>
kube-system            etcd-minikube                                1/1     Running     0              109m   192.168.49.2   minikube   <none>           <none>
kube-system            kube-apiserver-minikube                      1/1     Running     0              109m   192.168.49.2   minikube   <none>           <none>
kube-system            kube-controller-manager-minikube             1/1     Running     0              109m   192.168.49.2   minikube   <none>           <none>
kube-system            kube-proxy-rln2n                             1/1     Running     0              109m   192.168.49.2   minikube   <none>           <none>
kube-system            kube-scheduler-minikube                      1/1     Running     0              109m   192.168.49.2   minikube   <none>           <none>
kube-system            storage-provisioner                          1/1     Running     1 (108m ago)   109m   192.168.49.2   minikube   <none>           <none>
kubernetes-dashboard   dashboard-metrics-scraper-78dbd9dbf5-mxpbt   1/1     Running     0              109m   172.17.0.6     minikube   <none>           <none>
kubernetes-dashboard   kubernetes-dashboard-5fd5574d9f-hdmcq        1/1     Running     0              109m   172.17.0.5     minikube   <none>           <none>
````

С селектором:
````bash
$ kubectl get pods --all-namespaces --selector app.kubernetes.io/component=admission-webhook
````

Выполнение команды на поде (ключ `-c` для указания контейнера):
````bash
$ kubectl get pods
...
$ kubectl exec -n default hello-node-6d5f754cc9-8jb8j -- cat /etc/os-release
````

Создание ресурса на основе файлового описания:
````bash
$ kubectl apply -f /home/oleg/kubernetes-for-beginners/10-usage/templates/20-deployment-main.yaml       
deployment.apps/main created
$ kubectl get deployments --all-namespaces
NAMESPACE              NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
default                hello-node                  1/1     1            1           107m
default                main                        3/3     3            3           28m
ingress-nginx          ingress-nginx-controller    1/1     1            1           107m
kube-system            coredns                     1/1     1            1           107m
kubernetes-dashboard   dashboard-metrics-scraper   1/1     1            1           107m
kubernetes-dashboard   kubernetes-dashboard        1/1     1            1           107m
````

Редактируем ресурс:
````bash
$ kubectl edit deployments -n default main
````

Меняем кол-во реплик с 1 на 3, сохраняем файл и смотрим количество подов - уже 3 пода:
````bash
$ kubectl get pods --all-namespaces
````

Логи пода:
````bash
$ kubectl logs -n default hello-node-6d5f754cc9-8jb8j -f
127.0.0.1 - - [11/Sep/2022:07:15:36 +0000] "GET / HTTP/1.1" 200 426 "-" "ansible-httpget"
127.0.0.1 - - [11/Sep/2022:07:47:05 +0000] "GET / HTTP/1.1" 200 1486 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
127.0.0.1 - - [11/Sep/2022:07:47:05 +0000] "GET /favicon.ico HTTP/1.1" 200 1420 "http://localhost:8081/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36"
````

Отключить ноду от планировщика (SchedulingDisabled):
````bash
$ kubectl cordon minikube                                               
node/minikube cordoned
$ kubectl get nodes 
NAME       STATUS                     ROLES           AGE    VERSION
minikube   Ready,SchedulingDisabled   control-plane   111m   v1.24.3
````

Удаление пода (после удаление состояние восстановлено - `replicas: 2` - но на другом ресурсе):
````bash
$ kubectl get pods -n default -o wide
NAME                          READY   STATUS    RESTARTS   AGE    IP          NODE      NOMINATED NODE   READINESS GATES
hello-node-6d5f754cc9-8jb8j   1/1     Running   0          127m   172.17.0.7  minikube  <none>           <none>
main-cdf75f8b4-n49zh          1/1     Running   0          5m34s  172.17.0.3  minikube  <none>           <none>
main-cdf75f8b4-pjznl          1/1     Running   0          4m18s  172.17.0.8  minikube  <none>           <none>

$ kubectl delete -n default pod main-cdf75f8b4-n49zh
pod "main-cdf75f8b4-n49zh" deleted

$ kubectl get pods -n default -o wide
NAME                          READY   STATUS    RESTARTS   AGE    IP           NODE       NOMINATED NODE   READINESS GATES
hello-node-6d5f754cc9-8jb8j   1/1     Running   0          134m   172.17.0.7   minikube   <none>           <none>
main-cdf75f8b4-bdwxs          1/1     Running   0          41s    172.17.0.9   minikube   <none>           <none>
main-cdf75f8b4-pjznl          1/1     Running   0          11m    172.17.0.8   minikube   <none>           <none>
````

Получить деплоймент в виде yaml-файла:
````bash
$ kubectl get deployments main -o yaml
````
---