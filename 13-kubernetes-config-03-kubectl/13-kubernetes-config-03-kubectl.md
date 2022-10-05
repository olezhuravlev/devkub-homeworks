# Домашнее задание к занятию "13.3 работа с kubectl"
## Задание 1: проверить работоспособность каждого компонента
Для проверки работы можно использовать 2 способа: port-forward и exec. Используя оба способа, проверьте каждый компонент:
* сделайте запросы к бекенду;
* сделайте запросы к фронту;
* подключитесь к базе данных.

## Задание 2: ручное масштабирование

При работе с приложением иногда может потребоваться вручную добавить пару копий. Используя команду kubectl scale, попробуйте увеличить количество бекенда и фронта до 3. Проверьте, на каких нодах оказались копии после каждого действия (kubectl describe, kubectl get pods -o wide). После уменьшите количество копий до 1.

---

## Решение

### Развернем приложение в кластере Kubernetes

С помощью [конфигурации Terraform](./terraform/main.tf) подготовим виртуальную инфраструктуру:

![](images/yc_vms_3.png)

Создание нашей программной инфраструктуры подразумевает развертывание в ней контейнеризированных приложений для бекенда
и фронтенда, поэтому произведем сборку и публикацию этих компонентов в репозиторий.

<details>
  <summary>Описание процедуры сборки и публикации Docker-образов компонентов</summary>

> [Бекенд-компонента](../13-kubernetes-config/backend/Dockerfile) нашего приложения использует переменную окружения
> [DATABASE_URL](../13-kubernetes-config/backend/.env), хранящую строку подключения к базе данных.
> ````bash
> DATABASE_URL=postgres://postgres:postgres@db:5432/news
> ````
> Имеющую следующий формат:
> ````
> postgres://<USER>:<PASSWORD>@<HOST>:<PORT>/<DB_NAME>
> ````
>
> Изменять строку подключения мы не будем, а вместо этого сконфигурируем
> [Kubernetes-сервис NodePort](./infrastructure/playbooks/templates/deploy-pg.yaml) нашей базы данных
> таким образом, чтобы его имя совпадало с используемым именем базы данных в этой строке подключения - `"db"`:
> ````bash
> kind: Service
> metadata:
>   name: db
> ````
> В свою очередь, во [фронтэнд-компоненте](../13-kubernetes-config/frontend/Dockerfile)
> приложения из раздела [13-kubernetes-config](../13-kubernetes-config/frontend) используется переменная окружения
> [BASE_URL](../13-kubernetes-config/frontend/.env), хранящая адрес, по которому следует обращаться к нашей
> [бекенд-компоненте](../13-kubernetes-config/backend/Dockerfile):
> ````bash
> BASE_URL=http://51.250.86.193:30001
> ````
> В данном случае в качестве IPv4-адреса мы используем адрес кластера Kubernetes (точнее, внешний адрес любой
> из его нод). Понятно, что такое контейнеризированное приложение будет работать только
> с данным конкретным IPv4-адресом и при изменение адреса контейнер придётся пересобирать.
>
> Конечно же переменные окружения нужно сконфигурировать **до** контейнеризации этих компонентов нашего
> приложения.

Cобираем [бекенд-компоненту](../13-kubernetes-config/backend/Dockerfile) приложения из раздела
[13-kubernetes-config](../13-kubernetes-config/backend) и размещаем его в нашем Dockerhub-репозитории:
````bash
$ docker build -t olezhuravlev/backend:1.0.0 .
Sending build context to Docker daemon  19.46kB
Step 1/8 : FROM python:3.9-buster
...
Successfully built eef394d2d216
Successfully tagged olezhuravlev/backend:1.0.0

$ docker push olezhuravlev/backend:1.0.0      
The push refers to repository [docker.io/olezhuravlev/backend]
...
1.0.0: digest: sha256:aacf6b01c9639370928af5f1d9539159b9c59d6240e028e8982b6a0ab136c7bf size: 3264
````

![](./images/dockerhub_backend.png)

Аналогичным образом собираем [фронтэнд-компоненту](../13-kubernetes-config/frontend/Dockerfile)
и размещаем его в нашем Dockerhub-репозитории:
````bash
$ docker build -t olezhuravlev/frontend:1.0.1 .
Sending build context to Docker daemon  429.6kB
Step 1/14 : FROM node:lts-buster as builder
...
Successfully built dd8bb8ac5232
Successfully tagged olezhuravlev/frontend:1.0.1

$ docker push olezhuravlev/frontend:1.0.1      
The push refers to repository [docker.io/olezhuravlev/frontend]
...
1.0.1: digest: sha256:3913230be2d49d54eba2b1b298d9f22263880e1b01243ab198609720d4ec9304 size: 2400
````

![](./images/dockerhub_frontend.png)

> Здесь стоит обратить внимание на версию, которую мы присвоили создаваемому Docker-образу - `frontend:1.0.1`.
> Это связано с тем, что ранее этот образ уже использовался в задании
> ["13.1 контейнеры, поды, deployment, statefulset, services, endpoints"](../13-kubernetes-config-01-objects/13-kubernetes-config-01-objects.md),
> но тогда у нас был другой IP-адрес кластера. А **при изменении образов нужно давать им новые версии**, что гарантирует
> получение Kubernetes-ом именно новой версии образа, а не использование старой версии из кэша.

</details>

<br/>

<details>
  <summary>Описание разворачивания кластера</summary>

Когда образы бекенд- и фронтенд-компонент нашего приложения подготовлены (для БД используется стандартный публичный
образ, не нуждающийся в какой-либо подготовке), наполним нашу виртуальную инфраструктуру программным содержимым
с помощью [конфигурации Ansible](./infrastructure/site.yaml).
Для разворачивания кластера Kubernetes [используем Kubespray](./infrastructure/playbooks/mount-cluster.ansible.yaml).

Развернутый кластер состоит из следующих компонентов:
````bash
$ kubectl get all,pvc,pv,ep,sc,netpol,ingress -o wide                                                                                                                                                                                                              oleg-office: Thu Oct  6 14:11:20 2022

NAME                            READY   STATUS    RESTARTS      AGE     IP               NODE    NOMINATED NODE   READINESS GATES
pod/frontend-757fc9f598-n7s62   1/1     Running   1 (23m ago)   4h33m   10.200.166.159   node1   <none>           <none>
pod/frontend-757fc9f598-tftzs   1/1     Running   1 (23m ago)   4h33m   10.200.104.35    node2   <none>           <none>
pod/backend-76b5c84476-xjc67    1/1     Running   0             13m     10.200.166.163   node1   <none>           <none>
pod/backend-76b5c84476-52rfz    1/1     Running   0             13m     10.200.104.37    node2   <none>           <none>
pod/postgres-sts-0              1/1     Running   1 (23m ago)   4h33m   10.200.166.160   node1   <none>           <none>

NAME                            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE     SELECTOR
service/frontend-nodeport-svc   NodePort    10.32.48.86    <none>        80:30000/TCP     21h     app=web-news,component=frontend
service/backend-nodeport-svc    NodePort    10.32.67.115   <none>        9000:30001/TCP   7h40m   app=web-news,component=backend
service/db                      NodePort    10.32.93.186   <none>        5432:30002/TCP   22h     app=web-news,component=dbase
service/kubernetes              ClusterIP   10.32.0.1      <none>        443/TCP          23h     <none>

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                        SELECTOR
deployment.apps/frontend   2/2     2            2           21h   frontend     olezhuravlev/frontend:1.0.1   app=web-news,component=frontend
deployment.apps/backend    2/2     2            2           13m   backend      olezhuravlev/backend:1.0.0    app=web-news,component=backend

NAME                                  DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                        SELECTOR
replicaset.apps/frontend-757fc9f598   2         2         2       21h   frontend     olezhuravlev/frontend:1.0.1   app=web-news,component=frontend,pod-template-hash=757fc9f598
replicaset.apps/backend-76b5c84476    2         2         2       13m   backend      olezhuravlev/backend:1.0.0    app=web-news,component=backend,pod-template-hash=76b5c84476

NAME                            READY   AGE   CONTAINERS   IMAGES
statefulset.apps/postgres-sts   1/1     22h   postgres     postgres:13-alpine

NAME                                                   STATUS   VOLUME                  CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/postgres-volume-postgres-sts-0   Bound    persistent-volume-1gb   1Gi        RWO                           22h   Filesystem

NAME                                     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                    STORAGECLASS   REASON   AGE   VOLUMEMODE
persistentvolume/persistent-volume-1gb   1Gi        RWO            Retain           Bound    default/postgres-volume-postgres-sts-0                           22h   Filesystem

NAME                              ENDPOINTS                                AGE
endpoints/frontend-nodeport-svc   10.200.104.35:80,10.200.166.159:80       21h
endpoints/backend-nodeport-svc    10.200.104.37:9000,10.200.166.163:9000   7h40m
endpoints/db                      10.200.166.160:5432                      22h
endpoints/kubernetes              10.240.0.11:6443                         23h

NAME                             CLASS           HOSTS   ADDRESS   PORTS   AGE
ingress.networking.k8s.io/demo   nginx-example   *                 80      5h19m
````

После развертывания кластера приложение (и перезапуска бекенда для заполнения базы данных) доступно к использованию
через веб-интерфейс:

![](images/app_on.png)

</details>

---

### Проверим работоспособность каждого из компонентов нашей системы.

Получим список используемых компонентами портов:
````bash
$ kubectl get svc                                                                                                                                                        
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
frontend-nodeport-svc   NodePort    10.32.48.86    <none>        80:30000/TCP     21h
backend-nodeport-svc    NodePort    10.32.67.115   <none>        9000:30001/TCP   7h45m
db                      NodePort    10.32.93.186   <none>        5432:30002/TCP   23h
````

Будем выполнять перенаправление портов и проверку доступности компонентов системы, используя доступ через `localhost`.

#### Проверка работоспособности базы данных PostgreSQL с использованием "port-forward"

<details>
  <summary>Для подключения к базе данных PostgreSQL сначала установим клиента.</summary>

Скачаем дистрибутив:
````bash
$ sudo pacman -S postgresql
````

Залогинимся как пользователь `postgres` и инициализируем кластер БД:
````bash
$ sudo -iu postgres
[postgres@oleg-office ~]$ initdb --locale $LANG -E UTF8 -D '/var/lib/postgres/data/'
Файлы, относящиеся к этой СУБД, будут принадлежать пользователю "postgres".
От его имени также будет запускаться процесс сервера.

Кластер баз данных будет инициализирован с локалью "en_US.UTF-8".
Выбрана конфигурация текстового поиска по умолчанию "english".

Контроль целостности страниц данных отключён.

исправление прав для существующего каталога /var/lib/postgres/data... ок
создание подкаталогов... ок
выбирается реализация динамической разделяемой памяти... posix
выбирается значение max_connections по умолчанию... 100
выбирается значение shared_buffers по умолчанию... 128MB
выбирается часовой пояс по умолчанию... Europe/Berlin
создание конфигурационных файлов... ок
выполняется подготовительный скрипт... ок
выполняется заключительная инициализация... ок
сохранение данных на диске... ок

initdb: предупреждение: включение метода аутентификации "trust" для локальных подключений
Другой метод можно выбрать, отредактировав pg_hba.conf или используя ключи -A,
--auth-local или --auth-host при следующем выполнении initdb.

Готово. Теперь вы можете запустить сервер баз данных:

    pg_ctl -D /var/lib/postgres/data/ -l файл_журнала start

[postgres@oleg-office ~]$ exit
````

Активируем сервис `postgresql.service`:
````bash
$ sudo systemctl enable --now postgresql.service
````

Проверим статус сервиса:
````bash
$ sudo systemctl status postgresql              
● postgresql.service - PostgreSQL database server
     Loaded: loaded (/usr/lib/systemd/system/postgresql.service; enabled; preset: disabled)
     Active: active (running) since Thu 2022-10-06 14:37:37 CEST; 1s ago
    Process: 19923 ExecStartPre=/usr/bin/postgresql-check-db-dir ${PGROOT}/data (code=exited, status=0/SUCCESS)
   Main PID: 19925 (postgres)
      Tasks: 7 (limit: 77004)
     Memory: 15.4M
        CPU: 106ms
     CGroup: /system.slice/postgresql.service
             ├─19925 /usr/bin/postgres -D /var/lib/postgres/data
             ├─19927 "postgres: checkpointer "
             ├─19928 "postgres: background writer "
             ├─19929 "postgres: walwriter "
             ├─19930 "postgres: autovacuum launcher "
             ├─19931 "postgres: stats collector "
             └─19932 "postgres: logical replication launcher "

окт 06 14:37:36 oleg-office systemd[1]: Starting PostgreSQL database server...
окт 06 14:37:37 oleg-office postgres[19925]: 2022-10-06 14:37:37.110 CEST [19925] LOG:  starting PostgreSQL 14.5>
окт 06 14:37:37 oleg-office postgres[19925]: 2022-10-06 14:37:37.110 CEST [19925] LOG:  listening on IPv6 addres>
окт 06 14:37:37 oleg-office postgres[19925]: 2022-10-06 14:37:37.110 CEST [19925] LOG:  listening on IPv4 addres>
окт 06 14:37:37 oleg-office postgres[19925]: 2022-10-06 14:37:37.117 CEST [19925] LOG:  listening on Unix socket>
окт 06 14:37:37 oleg-office postgres[19926]: 2022-10-06 14:37:37.130 CEST [19926] LOG:  database system was shut>
````

Сервис работает, можно к нему обратиться проверим, например, установленную версию:
````bash
$ postgres --version
postgres (PostgreSQL) 14.5
````

</details>

Для доступа к этой компоненте Kubernetes через `localhost` произведем перенаправление порта, используемого сервисом:
````bash
$ kubectl get svc                                                                                                                                                        
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
db                      NodePort    10.32.93.186   <none>        5432:30002/TCP   23h
...
````

на любой свободный локальный порт. Пусть это будет порт №`5442`:
````bash
$ kubectl port-forward svc/db 5442:5432
Forwarding from 127.0.0.1:5442 -> 5432
Forwarding from [::1]:5442 -> 5432
````

> ВНИМАНИЕ! Мы использовали локальный порт `5442`, отличный от используемого в кластере `5432`, по причине того,
> что установленный локально клиент PostgreSQL сам запускает локальный сервер базы данных на порту `5432` и если
> мы попытаемся выполнить перенаправление на него же, то получим конфликт портов.
> В этой ситуации можно либо перенастроить локальный сервер PostgreSQL на использование другого порта, либо просто
> задействовать для перенаправления любой другой свободный порт.

Когда клиент PostgreSQL установлен, то залогинимся как пользователь `postgres` и запустим клиента PostgreSQL
в режиме подключения к удалённой базе данных,
указав такую же строку подключения, какую мы использовали при
[подключении бекенд-компонента](../13-kubernetes-config/backend/.env), за исключением того, что здесь мы используем
не имя сервиса `db`, а `localhost` :

Сделаем пробный запрос к базе данных, получив первые 3 строки колонки `title` таблицы `news`: 
````bash
$ sudo -iu postgres
[sudo] пароль для oleg: **************
[postgres@oleg-office ~]$ psql postgres://postgres:postgres@localhost:5442/news -c "SELECT title FROM news LIMIT 3;"
  title  
---------
 title 0
 title 1
 title 2
(3 строки)
````

> Т.к. мы на `localhost`, то можно выполнять запросы более наглядно, подключившись к нашей базе данных с помощью какого-либо GUI-клиента:
>
> ![](images/dbeaver_connection.png)
>
> Выполнив такой же запрос, получим такой же результат:
>
> ![](images/dbeaver_query.png)

Таким образом мы выяснили, что база данных как компонент кластера Kubernetes работает и доступна.

#### Проверка работоспособности компоненты бекенда с использованием "port-forward"

Для доступа к этой компоненте Kubernetes через `localhost` произведем перенаправление порта, используемого сервисом:
````bash
$ kubectl get svc                                                                                                                                                        
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
backend-nodeport-svc    NodePort    10.32.67.115   <none>        9000:30001/TCP   7h45m
...
````

на такой же локальный порт:
````bash
$ kubectl port-forward svc/backend-nodeport-svc 9000     
Forwarding from 127.0.0.1:9000 -> 9000
Forwarding from [::1]:9000 -> 9000
````

Мы помним, что бекенд отдаёт данные при обращении к нему через GET-запрос. Получим эти данные:
````bash
$ curl localhost:9000/api/news/1
{
  "id":1,
  "title":"title 0",
  "short_description":"small text 0small text 0small text 0small text 0small text 0small text 0small text 0small text 0small text 0small text 0",
  "description":"0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, ",
  "preview":"/static/image.png"
}
````

Получение корректного ответа является достаточным основание полагать, что бекенд доступен и работает правильно.

#### Проверка работоспособности компоненты фронтенда с использованием "port-forward"

Для доступа к этой компоненте Kubernetes через `localhost` произведем перенаправление порта, используемого сервисом:
````bash
$ kubectl get svc                                                                                                                                                        
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
frontend-nodeport-svc   NodePort    10.32.48.86    <none>        80:30000/TCP     21h
...
````

на любой свободный локальный порт. Пусть это будет порт №`8080`:
````bash
$ kubectl port-forward svc/frontend-nodeport-svc 8080:80      
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
````

Далее, достаточно выполнить запрос к `localhost:8080`:
````bash
$ curl localhost:8080           
<!DOCTYPE html>
<html lang="ru">
<head>
    <title>Список</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="/build/main.css" rel="stylesheet">
</head>
<body>
    <main class="b-page">
        <h1 class="b-page__title">Список</h1>
        <div class="b-page__content b-items js-list"></div>
    </main>
    <script src="/build/main.js"></script>
</body>
</html>
````

В ответ получена корректная HTML-страница, значит сервис фронтенда доступен и работает.

И действительно, если мы обратимся к этому же URL через браузер, то получим требуемую страницу уже
с работающими скриптами:

![](images/localhost_8080_browser.png)

Наш фронтенд-сервис находится в работоспособном состоянии.


#### Проверка работоспособности компонентов (базы данных, бекенда и фронтенда) с использованием "kubectl exec"

> Обращение к сервисам по именам возможно только из контекста кластера Kubernetes, поскольку за пределами кластера
> внутренняя служба DNS (`coredns`) работать не будет. Поэтому для проверки работоспособности сервисов через обращение
> к ним имени будем использовать команду "kubectl exec".

Сервисы, представляющие компоненты нашего кластера Kubernetes, имеют следующие имена:
````bash
$ kubectl get svc                                       
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
frontend-nodeport-svc   NodePort    10.32.48.86    <none>        80:30000/TCP     23h
backend-nodeport-svc    NodePort    10.32.67.115   <none>        9000:30001/TCP   9h
db                      NodePort    10.32.93.186   <none>        5432:30002/TCP   25h
````

Для проверки работоспособности базы данных с задействованием внутренней DNS мы подключимся к поду,
имеющему соответствующего клиента для PostgreSQL, и выполним запрос к базе данных оттуда.

Для этого, а также в целях помощи в отладке создадим один дополнительный
[под с DNS-утилитами](./infrastructure/playbooks/templates/debug/dnsutils.ansible.yaml)
и другой дополнительный под - [с минимальной версией PostgreSQL](./infrastructure/playbooks/templates/debug/minipg.ansible.yaml).

Инсталлируем эти поды в наш кластер Kubernetes:
````bash
$ kubectl apply -f ./infrastructure/playbooks/templates/debug/dnsutils.ansible.yaml
pod/dnsutils created

$ kubectl apply -f ./infrastructure/playbooks/templates/debug/minipg.ansible.yaml
pod/minipg created
````

Для проверки работоспособности базы данных выясним сначала полное имя нашего сервиса баз данных `db` в кластере.
Для этого воспользуемся утилитой `nslookup`:
````bash
$ kubectl exec -i -t dnsutils -- nslookup db
Server:		169.254.25.10
Address:	169.254.25.10#53

Name:	db.default.svc.cluster.local
Address: 10.32.93.186
````

Это имя - `db.default.svc.cluster.local` и теперь через наш специально созданный под (с минимальной версией PostgreSQL) выполняем запрос к нашей базе данных: 
````bash
$ kubectl exec -i -t minipg -- psql postgres://postgres:postgres@db.default.svc.cluster.local:5432/news -c "SELECT title FROM news LIMIT 3;"
  title  
---------
 title 0
 title 1
 title 2
(3 rows)
````

Данные получены, а значит **наша база данных работает и доступна*** в пределах кластера Kubernetes.

Теперь подобным образом проверим работоспособность нашего бекенда, только клиент PostgreSQL уже не понадобится.
Имя сервиса бекенда у нас `backend-nodeport-svc`:
````bash
$ kubectl get svc                              
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
backend-nodeport-svc    NodePort    10.32.67.115   <none>        9000:30001/TCP   11h
...
````

Получим полное DNS-имя сервиса бекенда:
````bash
$ kubectl exec -i -t dnsutils -- nslookup backend-nodeport-svc                               
Server:		169.254.25.10
Address:	169.254.25.10#53

Name:	backend-nodeport-svc.default.svc.cluster.local
Address: 10.32.67.115
````

Это имя - `backend-nodeport-svc.default.svc.cluster.local`. Обратимся к сервису бекенда:
````bash
$ kubectl exec -i -t minipg -- curl http://backend-nodeport-svc.default.svc.cluster.local:9000/api/news/1
{
  "id":1,
  "title":"title 0",
  "short_description":"small text 0small text 0small text 0small text 0small text 0small text 0small text 0small text 0small text 0small text 0",
  "description":"0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, 0 some more text, ",
  "preview":"/static/image.png"
}
````

Данные возвращены корректно, а значит **бекенд-сервис в пределах нашего кластера Kubernetes доступен и работает**.

Аналогично проверяем фронтенд. Имя сервиса у нас `frontend-nodeport-svc`:
````bash
$ kubectl get svc
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
frontend-nodeport-svc   NodePort    10.32.48.86    <none>        80:30000/TCP     25h
...
````

Получим полное DNS-имя сервиса фронтенда:
````bash
$ kubectl exec -i -t dnsutils -- nslookup frontend-nodeport-svc
Server:		169.254.25.10
Address:	169.254.25.10#53

Name:	frontend-nodeport-svc.default.svc.cluster.local
Address: 10.32.48.86
````

Выполним запрос, обратившись к сервису по его имени `frontend-nodeport-svc.default.svc.cluster.local`:
````bash
$ kubectl exec -i -t minipg -- curl http://frontend-nodeport-svc.default.svc.cluster.local:80  
<!DOCTYPE html>
<html lang="ru">
<head>
    <title>Список</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="/build/main.css" rel="stylesheet">
</head>
<body>
    <main class="b-page">
        <h1 class="b-page__title">Список</h1>
        <div class="b-page__content b-items js-list"></div>
    </main>
    <script src="/build/main.js"></script>
</body>
</html>
````

Получена корректная HTML-страница, а значит **фронтенд-сервис в пределах нашего кластера Kubernetes доступен и работает**.

Таким образом мы проверили работоспособность наших компонентов с использованием двух способов - сначала "port-forward",
а затем через "kubectl exec", получив одинаковые результаты.

---

#### Произведем ручное масштабирование компонентов нашей системы.

Имеем набор деплойментов, составляющих наше приложение:
````bash
$ kubectl get deployments.apps -o wide --show-labels
NAME       READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES                        SELECTOR                          LABELS
frontend   2/2     2            2           25h     frontend     olezhuravlev/frontend:1.0.1   app=web-news,component=frontend   app=web-news,component=frontend
backend    2/2     2            2           4h31m   backend      olezhuravlev/backend:1.0.0    app=web-news,component=backend    app=web-news,component=backend
````

И соответствующий набор подов:
````bash
$ kubectl get pod -o wide
NAME                        READY   STATUS    RESTARTS        AGE     IP               NODE    NOMINATED NODE   READINESS GATES
backend-76b5c84476-52rfz    1/1     Running   0               4h29m   10.200.104.37    node2   <none>           <none>
backend-76b5c84476-xjc67    1/1     Running   0               4h29m   10.200.166.163   node1   <none>           <none>
frontend-757fc9f598-n7s62   1/1     Running   1 (4h39m ago)   8h      10.200.166.159   node1   <none>           <none>
frontend-757fc9f598-tftzs   1/1     Running   1 (4h39m ago)   8h      10.200.104.35    node2   <none>           <none>
postgres-sts-0              1/1     Running   1 (4h39m ago)   8h      10.200.166.160   node1   <none>           <none>
minipg                      1/1     Running   0               33m     10.200.166.165   node1   <none>           <none>
dnsutils                    1/1     Running   0               33m     10.200.104.48    node2   <none>           <none>
````

Увеличиваем количество работающих экземпляров до трех:
````bash
$ kubectl scale --replicas=3 deploy/frontend       
deployment.apps/frontend scaled

$ kubectl scale --replicas=3 deploy/backend 
deployment.apps/backend scaled

$ kubectl get deployments.apps -o wide --show-labels
NAME       READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES                        SELECTOR                          LABELS
frontend   3/3     3            3           25h     frontend     olezhuravlev/frontend:1.0.1   app=web-news,component=frontend   app=web-news,component=frontend
backend    3/3     3            3           4h33m   backend      olezhuravlev/backend:1.0.0    app=web-news,component=backend    app=web-news,component=backend
````

Подов, соответственно, тоже стало больше:
````bash
$ kubectl get pod -o wide
NAME                        READY   STATUS    RESTARTS        AGE     IP               NODE    NOMINATED NODE   READINESS GATES
backend-76b5c84476-52rfz    1/1     Running   0               4h34m   10.200.104.37    node2   <none>           <none>
backend-76b5c84476-xjc67    1/1     Running   0               4h34m   10.200.166.163   node1   <none>           <none>
backend-76b5c84476-5g7tr    1/1     Running   0               88s     10.200.166.166   node1   <none>           <none>
frontend-757fc9f598-n7s62   1/1     Running   1 (4h44m ago)   8h      10.200.166.159   node1   <none>           <none>
frontend-757fc9f598-tftzs   1/1     Running   1 (4h44m ago)   8h      10.200.104.35    node2   <none>           <none>
frontend-757fc9f598-2nlr6   1/1     Running   0               92s     10.200.104.49    node2   <none>           <none>
postgres-sts-0              1/1     Running   1 (4h44m ago)   8h      10.200.166.160   node1   <none>           <none>
minipg                      1/1     Running   0               38m     10.200.166.165   node1   <none>           <none>
dnsutils                    1/1     Running   0               38m     10.200.104.48    node2   <none>           <none>
````

Причем поды распределились по нодам относительно равномерно. Уменьшим количество экземляров до одного:

````bash
$ kubectl scale --replicas=1 deploy/frontend       
deployment.apps/frontend scaled

$ kubectl scale --replicas=1 deploy/backend 
deployment.apps/backend scaled

$ kubectl get deployments.apps -o wide --show-labels
NAME       READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES                        SELECTOR                          LABELS
frontend   1/1     1            1           26h     frontend     olezhuravlev/frontend:1.0.1   app=web-news,component=frontend   app=web-news,component=frontend
backend    1/1     1            1           4h37m   backend      olezhuravlev/backend:1.0.0    app=web-news,component=backend    app=web-news,component=backend
````

Соответственно уменьшилось и количество подов:
````bash
$ kubectl get pod -o wide
NAME                        READY   STATUS    RESTARTS        AGE     IP               NODE    NOMINATED NODE   READINESS GATES
frontend-757fc9f598-n7s62   1/1     Running   1 (4h47m ago)   8h      10.200.166.159   node1   <none>           <none>
backend-76b5c84476-52rfz    1/1     Running   0               4h38m   10.200.104.37    node2   <none>           <none>
postgres-sts-0              1/1     Running   1 (4h47m ago)   8h      10.200.166.160   node1   <none>           <none>
minipg                      1/1     Running   0               42m     10.200.166.165   node1   <none>           <none>
dnsutils                    1/1     Running   0               42m     10.200.104.48    node2   <none>           <none>
````

Таким образом мы наблюдаем, что Kubernetes стремится к равномерному распределению подов по нодам. 

---

<details>
  <summary>Приложение 1 - Лекция</summary>

Получение списка API-ресурсов, поддерживаемых сервером:
````bash
$ kubectl api-resources                                                                                                                                    
NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
bindings                                       v1                                     true         Binding
componentstatuses                 cs           v1                                     false        ComponentStatus
configmaps                        cm           v1                                     true         ConfigMap
endpoints                         ep           v1                                     true         Endpoints
events                            ev           v1                                     true         Event
limitranges                       limits       v1                                     true         LimitRange
namespaces                        ns           v1                                     false        Namespace
nodes                             no           v1                                     false        Node
persistentvolumeclaims            pvc          v1                                     true         PersistentVolumeClaim
persistentvolumes                 pv           v1                                     false        PersistentVolume
pods                              po           v1                                     true         Pod
podtemplates                                   v1                                     true         PodTemplate
replicationcontrollers            rc           v1                                     true         ReplicationController
resourcequotas                    quota        v1                                     true         ResourceQuota
secrets                                        v1                                     true         Secret
serviceaccounts                   sa           v1                                     true         ServiceAccount
services                          svc          v1                                     true         Service
mutatingwebhookconfigurations                  admissionregistration.k8s.io/v1        false        MutatingWebhookConfiguration
validatingwebhookconfigurations                admissionregistration.k8s.io/v1        false        ValidatingWebhookConfiguration
customresourcedefinitions         crd,crds     apiextensions.k8s.io/v1                false        CustomResourceDefinition
apiservices                                    apiregistration.k8s.io/v1              false        APIService
controllerrevisions                            apps/v1                                true         ControllerRevision
daemonsets                        ds           apps/v1                                true         DaemonSet
deployments                       deploy       apps/v1                                true         Deployment
replicasets                       rs           apps/v1                                true         ReplicaSet
statefulsets                      sts          apps/v1                                true         StatefulSet
tokenreviews                                   authentication.k8s.io/v1               false        TokenReview
localsubjectaccessreviews                      authorization.k8s.io/v1                true         LocalSubjectAccessReview
selfsubjectaccessreviews                       authorization.k8s.io/v1                false        SelfSubjectAccessReview
selfsubjectrulesreviews                        authorization.k8s.io/v1                false        SelfSubjectRulesReview
subjectaccessreviews                           authorization.k8s.io/v1                false        SubjectAccessReview
horizontalpodautoscalers          hpa          autoscaling/v2                         true         HorizontalPodAutoscaler
cronjobs                          cj           batch/v1                               true         CronJob
jobs                                           batch/v1                               true         Job
certificatesigningrequests        csr          certificates.k8s.io/v1                 false        CertificateSigningRequest
leases                                         coordination.k8s.io/v1                 true         Lease
bgpconfigurations                              crd.projectcalico.org/v1               false        BGPConfiguration
bgppeers                                       crd.projectcalico.org/v1               false        BGPPeer
blockaffinities                                crd.projectcalico.org/v1               false        BlockAffinity
caliconodestatuses                             crd.projectcalico.org/v1               false        CalicoNodeStatus
clusterinformations                            crd.projectcalico.org/v1               false        ClusterInformation
felixconfigurations                            crd.projectcalico.org/v1               false        FelixConfiguration
globalnetworkpolicies                          crd.projectcalico.org/v1               false        GlobalNetworkPolicy
globalnetworksets                              crd.projectcalico.org/v1               false        GlobalNetworkSet
hostendpoints                                  crd.projectcalico.org/v1               false        HostEndpoint
ipamblocks                                     crd.projectcalico.org/v1               false        IPAMBlock
ipamconfigs                                    crd.projectcalico.org/v1               false        IPAMConfig
ipamhandles                                    crd.projectcalico.org/v1               false        IPAMHandle
ippools                                        crd.projectcalico.org/v1               false        IPPool
ipreservations                                 crd.projectcalico.org/v1               false        IPReservation
kubecontrollersconfigurations                  crd.projectcalico.org/v1               false        KubeControllersConfiguration
networkpolicies                                crd.projectcalico.org/v1               true         NetworkPolicy
networksets                                    crd.projectcalico.org/v1               true         NetworkSet
endpointslices                                 discovery.k8s.io/v1                    true         EndpointSlice
events                            ev           events.k8s.io/v1                       true         Event
flowschemas                                    flowcontrol.apiserver.k8s.io/v1beta2   false        FlowSchema
prioritylevelconfigurations                    flowcontrol.apiserver.k8s.io/v1beta2   false        PriorityLevelConfiguration
ingressclasses                                 networking.k8s.io/v1                   false        IngressClass
ingresses                         ing          networking.k8s.io/v1                   true         Ingress
networkpolicies                   netpol       networking.k8s.io/v1                   true         NetworkPolicy
runtimeclasses                                 node.k8s.io/v1                         false        RuntimeClass
poddisruptionbudgets              pdb          policy/v1                              true         PodDisruptionBudget
podsecuritypolicies               psp          policy/v1beta1                         false        PodSecurityPolicy
clusterrolebindings                            rbac.authorization.k8s.io/v1           false        ClusterRoleBinding
clusterroles                                   rbac.authorization.k8s.io/v1           false        ClusterRole
rolebindings                                   rbac.authorization.k8s.io/v1           true         RoleBinding
roles                                          rbac.authorization.k8s.io/v1           true         Role
priorityclasses                   pc           scheduling.k8s.io/v1                   false        PriorityClass
csidrivers                                     storage.k8s.io/v1                      false        CSIDriver
csinodes                                       storage.k8s.io/v1                      false        CSINode
csistoragecapacities                           storage.k8s.io/v1                      true         CSIStorageCapacity
storageclasses                    sc           storage.k8s.io/v1                      false        StorageClass
volumeattachments                              storage.k8s.io/v1                      false        VolumeAttachment
````

Содержимое файла `~/.kube/config`:
````yaml
contexts:
- context:
    cluster: cluster.local             # Кластер, на который ссылается контекст.
    user: kubernetes-admin             # Пользователь, от имени которого идет обращение к кластеру.
    namespace:                         # Используемое пространство имен.
  name: kubernetes-admin@cluster.local # Имя контекста.
current-context: kubernetes-admin@cluster.local
users:
  - name: kubernetes-admin
    user:
      client-certificate: certs/efox/admin.crt # Путь к текстовому файлу сертификата.
      client-key: certs/efox/admin.key         # Путь к текстовому файлу ключа.
  - name: netology-user
    user:
      client-certificate-data: LS0tLS1CRU... # base64-строка сертификата.
      client-key-data: LS0tLS1CRUdJTiBSU0... # base64-строка ключа.
````

Использование контекста в команде:
````bash
$ kubectl --context=kubernetes-admin@cluster.local get deployments.apps backend 
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
backend   2/2     2            2           31m
````

Списки кластеров, пользователей и контекстов:
````bash
$ kubectl config get-clusters                                          
NAME
cluster.local

$ kubectl config get-users   
NAME
kubernetes-admin

$ kubectl config get-contexts
CURRENT   NAME                             CLUSTER         AUTHINFO           NAMESPACE
*         kubernetes-admin@cluster.local   cluster.local   kubernetes-admin

$ kubectl config current-context 
kubernetes-admin@cluster.local
````

Переключение на контекст (т.е. на кластер):
````bash
$ kubectl config use-context kubernetes-admin@cluster.local 
Switched to context "kubernetes-admin@cluster.local".
````

````bash
# kubectl config set-credentials
````

````bash
# kubectl config delete-user
````

Создание нового объекта (без изменение старого, если он есть):
````bash
# kubectl create -f <FILENAME>
````

Создание нового объекта (с заменой старого, если он есть):
````bash
# kubectl apply -f <FILENAME>
````

Удаление всех объектов, указанных в файле:
````bash
# kubectl delete -f <FILENAME>
$ kubectl delete -f ./infrastructure/playbooks/templates/deploy-frontend.yaml
deployment.apps "frontend" deleted
service "frontend-nodeport-svc" deleted

$ kubectl create -f ./infrastructure/playbooks/templates/deploy-frontend.yaml 
deployment.apps/frontend created
service/frontend-nodeport-svc created
````

Можно указать папку, тогда удалятся все объекты, описанные в ней:
````bash
$ kubectl delete -f ./infrastructure/playbooks/templates/back-and-front
deployment.apps "backend" deleted
service "backend-nodeport-svc" deleted
deployment.apps "frontend" deleted
service "frontend-nodeport-svc" deleted

$ kubectl create -f ./infrastructure/playbooks/templates/back-and-front
deployment.apps/backend created
service/backend-nodeport-svc created
deployment.apps/frontend created
service/frontend-nodeport-svc created
````

Просмотр в пространстве имен:
````bash
$ kubectl get po -o wide -n default
NAME                        READY   STATUS    RESTARTS      AGE     IP               NODE    NOMINATED NODE   READINESS GATES
backend-76b5c84476-nzfzp    1/1     Running   0             4m59s   10.200.104.17    node2   <none>           <none>
backend-76b5c84476-q2v6g    1/1     Running   0             4m59s   10.200.166.145   node1   <none>           <none>
frontend-757fc9f598-6ghkc   1/1     Running   0             4m59s   10.200.104.18    node2   <none>           <none>
frontend-757fc9f598-gcrkw   1/1     Running   0             4m59s   10.200.166.146   node1   <none>           <none>
postgres-sts-0              1/1     Running   1 (82m ago)   84m     10.200.166.134   node1   <none>           <none>
````

Получение сведений из JSON:
````bash
$ kubectl -n default get deploy frontend -o jsonpath="{.spec.template.spec.containers[0].image}"
olezhuravlev/frontend:1.0.1

$ kubectl -n default get deploy frontend -o jsonpath="{.spec.template.spec.containers[0].image}"
olezhuravlev/frontend:1.0.1

$ kubectl -n default get deploy frontend -o jsonpath="{.spec.template.spec.containers[0]}"
{"image":"olezhuravlev/frontend:1.0.1","imagePullPolicy":"IfNotPresent","name":"frontend","ports":[{"containerPort":80,"name":"frontend-port","protocol":"TCP"}],"resources":{},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}                                                                                                                                                                                                             

$ kubectl -n default get deploy frontend -o jsonpath="{.spec.template.spec.containers}"
[{"image":"olezhuravlev/frontend:1.0.1","imagePullPolicy":"IfNotPresent","name":"frontend","ports":[{"containerPort":80,"name":"frontend-port","protocol":"TCP"}],"resources":{},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}]                                                                                                                                                                                                           

$ kubectl -n default get deploy frontend -o jsonpath="{.spec.template.spec}"
{"containers":[{"image":"olezhuravlev/frontend:1.0.1","imagePullPolicy":"IfNotPresent","name":"frontend","ports":[{"containerPort":80,"name":"frontend-port","protocol":"TCP"}],"resources":{},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}],"dnsPolicy":"ClusterFirst","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"terminationGracePeriodSeconds":30}                                            

$ kubectl -n default get deploy frontend -o jsonpath="{.spec.template}"
{"metadata":{"creationTimestamp":null,"labels":{"app":"web-news","component":"frontend"}},"spec":{"containers":[{"image":"olezhuravlev/frontend:1.0.1","imagePullPolicy":"IfNotPresent","name":"frontend","ports":[{"containerPort":80,"name":"frontend-port","protocol":"TCP"}],"resources":{},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}],"dnsPolicy":"ClusterFirst","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"terminationGracePeriodSeconds":30}}                                                                                                                                                                                  

$ kubectl -n default get deploy frontend -o jsonpath="{.spec}"
{"progressDeadlineSeconds":600,"replicas":2,"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"web-news","component":"frontend"}},"strategy":{"rollingUpdate":{"maxSurge":"25%","maxUnavailable":"25%"},"type":"RollingUpdate"},"template":{"metadata":{"creationTimestamp":null,"labels":{"app":"web-news","component":"frontend"}},"spec":{"containers":[{"image":"olezhuravlev/frontend:1.0.1","imagePullPolicy":"IfNotPresent","name":"frontend","ports":[{"containerPort":80,"name":"frontend-port","protocol":"TCP"}],"resources":{},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File"}],"dnsPolicy":"ClusterFirst","restartPolicy":"Always","schedulerName":"default-scheduler","securityContext":{},"terminationGracePeriodSeconds":30}}}           
````

Подсчитать количество подов на ноде "node2" во всех пространствах имен (`wc -l` считает количество строк в выводе):
````bash
$ kubectl get po -o wide -A | grep node2 | wc -l
8
````

Описание ноды помимо прочего позволяет получить информацию о её загрузке:
````bash
$ kubectl describe node node1
Name:               node1
Roles:              <none>
Labels:             beta.kubernetes.io/arch=amd64
                    beta.kubernetes.io/os=linux
                    kubernetes.io/arch=amd64
                    kubernetes.io/hostname=node1
                    kubernetes.io/os=linux
Annotations:        kubeadm.alpha.kubernetes.io/cri-socket: unix:////var/run/containerd/containerd.sock
                    node.alpha.kubernetes.io/ttl: 0
                    projectcalico.org/IPv4Address: 10.240.0.21/16
                    projectcalico.org/IPv4VXLANTunnelAddr: 10.200.166.128
                    volumes.kubernetes.io/controller-managed-attach-detach: true
CreationTimestamp:  Wed, 05 Oct 2022 14:40:58 +0200
Taints:             <none>
Unschedulable:      false
Lease:
  HolderIdentity:  node1
  AcquireTime:     <unset>
  RenewTime:       Wed, 05 Oct 2022 17:31:53 +0200
Conditions:
  Type                 Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----                 ------  -----------------                 ------------------                ------                       -------
  NetworkUnavailable   False   Wed, 05 Oct 2022 15:16:03 +0200   Wed, 05 Oct 2022 15:16:03 +0200   CalicoIsUp                   Calico is running on this node
  MemoryPressure       False   Wed, 05 Oct 2022 17:31:55 +0200   Wed, 05 Oct 2022 14:40:58 +0200   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure         False   Wed, 05 Oct 2022 17:31:55 +0200   Wed, 05 Oct 2022 14:40:58 +0200   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure          False   Wed, 05 Oct 2022 17:31:55 +0200   Wed, 05 Oct 2022 14:40:58 +0200   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready                True    Wed, 05 Oct 2022 17:31:55 +0200   Wed, 05 Oct 2022 14:43:23 +0200   KubeletReady                 kubelet is posting ready status. AppArmor enabled
Addresses:
  InternalIP:  10.240.0.21
  Hostname:    node1
Capacity:
  cpu:                2
  ephemeral-storage:  52574180Ki
  hugepages-2Mi:      0
  memory:             2030664Ki
  pods:               110
Allocatable:
  cpu:                1900m
  ephemeral-storage:  48452364208
  hugepages-2Mi:      0
  memory:             1666120Ki
  pods:               110
System Info:
  Machine ID:                 23000007c6cce07e92a130b95728bddb
  System UUID:                23000007-c6cc-e07e-92a1-30b95728bddb
  Boot ID:                    705ff29e-11f6-45b9-83d0-5f06941bdc90
  Kernel Version:             5.4.0-124-generic
  OS Image:                   Ubuntu 20.04.4 LTS
  Operating System:           linux
  Architecture:               amd64
  Container Runtime Version:  containerd://1.6.8
  Kubelet Version:            v1.24.4
  Kube-Proxy Version:         v1.24.4
PodCIDR:                      10.200.1.0/24
PodCIDRs:                     10.200.1.0/24
Non-terminated Pods:          (8 in total)
  Namespace                   Name                                     CPU Requests  CPU Limits  Memory Requests  Memory Limits  Age
  ---------                   ----                                     ------------  ----------  ---------------  -------------  ---
  default                     backend-76b5c84476-q2v6g                 0 (0%)        0 (0%)      0 (0%)           0 (0%)         59m
  default                     frontend-757fc9f598-gcrkw                0 (0%)        0 (0%)      0 (0%)           0 (0%)         59m
  default                     postgres-sts-0                           0 (0%)        0 (0%)      0 (0%)           0 (0%)         139m
  kube-system                 calico-node-gk26k                        150m (7%)     300m (15%)  64M (3%)         500M (29%)     170m
  kube-system                 kube-proxy-pzwzc                         0 (0%)        0 (0%)      0 (0%)           0 (0%)         170m
  kube-system                 nginx-proxy-node1                        25m (1%)      0 (0%)      32M (1%)         0 (0%)         170m
  kube-system                 nodelocaldns-pn9qq                       100m (5%)     0 (0%)      70Mi (4%)        200Mi (12%)    169m
  kubernetes-dashboard        kubernetes-dashboard-6c75475678-bc9q2    0 (0%)        0 (0%)      0 (0%)           0 (0%)         167m
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests        Limits
  --------           --------        ------
  cpu                275m (14%)      300m (15%)
  memory             169400320 (9%)  709715200 (41%)
  ephemeral-storage  0 (0%)          0 (0%)
  hugepages-2Mi      0 (0%)          0 (0%)
Events:              <none>
````

Получение дополнительны данных (параметр `v` можно менять): 
````bash
$ kubectl get nodes --v=6 
I1005 17:36:23.710612  159968 loader.go:372] Config loaded from file:  /home/oleg/.kube/config
I1005 17:36:23.890855  159968 round_trippers.go:553] GET https://51.250.86.193:6443/api/v1/nodes?limit=500 200 OK in 175 milliseconds
NAME    STATUS   ROLES           AGE    VERSION
cp1     Ready    control-plane   176m   v1.24.4
node1   Ready    <none>          175m   v1.24.4
node2   Ready    <none>          175m   v1.24.4
````

Просмотр компонентов кластера по метке:
````bash
$ kubectl get all -l component=backend 
NAME                           READY   STATUS    RESTARTS   AGE
pod/backend-76b5c84476-nzfzp   1/1     Running   0          77m
pod/backend-76b5c84476-q2v6g   1/1     Running   0          77m

NAME                           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/backend-nodeport-svc   NodePort   10.32.174.194   <none>        9000:30001/TCP   77m

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/backend   2/2     2            2           77m

NAME                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/backend-76b5c84476   2         2         2       77m
````

Просмотр логов контейнера `backend` в поде `backend-76b5c84476-nzfzp` (последние 5 записей):
````bash
$ kubectl logs -f pod/backend-76b5c84476-nzfzp -c backend --tail=5
INFO:     Started server process [9]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     10.200.176.0:11605 - "GET /api/news/ HTTP/1.1" 200 OK
INFO:     10.200.176.0:11605 - "GET /api/news/ HTTP/1.1" 200 OK
````

Просмотр логов компонентов по метке `app=web-news`:
````bash
$ kubectl logs -l app=web-news -f                 
INFO:     Uvicorn running on http://0.0.0.0:9000 (Press CTRL+C to quit)
INFO:     Started reloader process [7] using statreload
INFO:     Uvicorn running on http://0.0.0.0:9000 (Press CTRL+C to quit)
2022/10/05 14:32:35 [notice] 1#1: start worker process 31
10.200.176.0 - - [05/Oct/2022:14:34:30 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36" "-"
10.200.176.0 - - [05/Oct/2022:14:34:31 +0000] "GET / HTTP/1.1" 200 448 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36" "-"
10.200.176.0 - - [05/Oct/2022:14:34:31 +0000] "GET /build/main.css HTTP/1.1" 200 2515 "http://51.250.86.193:30000/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36" "-"
10.200.176.0 - - [05/Oct/2022:14:34:31 +0000] "GET /favicon.ico HTTP/1.1" 200 448 "http://51.250.86.193:30000/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36" "-"
INFO:     Started reloader process [6] using statreload
INFO:     Started server process [9]
...
````

Просмотр DaemonSets:
````bash
$ kubectl get ds -A -o wide              
NAMESPACE     NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE     CONTAINERS    IMAGES                                          SELECTOR
kube-system   calico-node    3         3         3       3            3           kubernetes.io/os=linux   3h24m   calico-node   quay.io/calico/node:v3.23.3                     k8s-app=calico-node
kube-system   kube-proxy     3         3         3       3            3           kubernetes.io/os=linux   3h26m   kube-proxy    registry.k8s.io/kube-proxy:v1.24.4              k8s-app=kube-proxy
kube-system   nodelocaldns   3         3         3       3            3           kubernetes.io/os=linux   3h23m   node-cache    registry.k8s.io/dns/k8s-dns-node-cache:1.21.1   k8s-app=nodelocaldns
````

Просмотр логов демона:
````bash
$ kubectl -n kube-system logs daemonsets/calico-node -f --tail=10
Found 3 pods, using pod/calico-node-gk26k
Defaulted container "calico-node" out of: calico-node, upgrade-ipam (init), install-cni (init), flexvol-driver (init)
2022-10-05 16:10:14.751 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="node2"
2022-10-05 16:10:14.751 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="node2"
2022-10-05 16:10:15.784 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="node1"
2022-10-05 16:10:15.785 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="node1"
2022-10-05 16:10:22.896 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="cp1"
2022-10-05 16:10:22.896 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="cp1"
2022-10-05 16:10:25.052 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="node2"
2022-10-05 16:10:25.052 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="node2"
2022-10-05 16:10:26.200 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="node1"
2022-10-05 16:10:26.200 [INFO][89] felix/vxlan_resolver.go 328: VTEP information has not changed, skipping duplicate update node="node1"
...
````

Получим список подов, чтобы увидеть счетчик перезапусков:
````bash
$ kubectl get po -o wide                                   
NAME                        READY   STATUS    RESTARTS        AGE   IP               NODE    NOMINATED NODE   READINESS GATES
postgres-sts-0              1/1     Running   3 (9m49s ago)   15h   10.200.166.153   node1   <none>           <none>
...
````

Посмотрим лог предыдущего экземпляра контейнера в поде чтобы увидеть причину перезапуска (ключ `-p`):
````bash
$ kubectl logs -c postgres po/postgres-sts-0 -p

PostgreSQL Database directory appears to contain a database; Skipping initialization

2022-10-05 16:14:02.796 UTC [1] LOG:  starting PostgreSQL 13.8 on x86_64-pc-linux-musl, compiled by gcc (Alpine 11.2.1_git20220219) 11.2.1 20220219, 64-bit
2022-10-05 16:14:02.796 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2022-10-05 16:14:02.797 UTC [1] LOG:  listening on IPv6 address "::", port 5432
2022-10-05 16:14:02.822 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2022-10-05 16:14:02.879 UTC [21] LOG:  database system was shut down at 2022-10-05 16:12:02 UTC
2022-10-05 16:14:02.961 UTC [1] LOG:  database system is ready to accept connections
2022-10-05 16:15:00.850 UTC [1] LOG:  received smart shutdown request
2022-10-05 16:15:00.922 UTC [1] LOG:  background worker "logical replication launcher" (PID 27) exited with exit code 1
2022-10-05 16:15:00.922 UTC [22] LOG:  shutting down
````

Изменение редактора для использования командой `kubectl edit`:
````bash
# Выясняем путь к желаемому редактору:
$ which vim
/usr/bin/vim

# Устанавливаем переменную окружения KUBE_EDITOR:
$ export KUBE_EDITOR=/usr/bin/vim
````

Изменение параметров компонента Kubernetes:
````bash
$ kubectl get deploy/frontend 
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
frontend   2/2     2            2           14h

$ kubectl edit deploy/frontend -o yaml # Возможны другие форматы.
# (редактируем: replicas: 3)
deployment.apps/frontend edited

$ kubectl get deploy/frontend  
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
frontend   3/3     3            3           14h
````

Масштабирование:
````bash
$ kubectl scale --replicas=2 deploy/frontend 
deployment.apps/frontend scaled

$ kubectl get deploy/frontend               
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
frontend   2/2     2            2           14h
````

Получаем описание компонента Kubernetes в файл (будет получен файл, аналогичный используемому при развёртывании,
но могут присутствовать лишние поля):
````bash
$ kubectl get ep/db -o yaml > db.yaml
````

Т.о. существует два варианта редактирования:
1. Получить файл описания -> Отредактировать его -> Применить его (`kubectl apply -f`) -> Возможно получить предупреждение "resource ... is missing in the kubectl.kubernetes.io/last-applied-configuration..."; 
2. Использовать `kubectl edit` 

> Внимание! При использовании `kubectl edit` существует опасность возникновения ситуации, когда код, на основе
> которого собиралась инфраструктура и хранящийся в VCS (# в Git), разойдётся с фактическим состоянием инфраструктуры,
> отредактированной через `kubectl edit`!


Добавление метки:
````bash
$ kubectl label deploy/frontend myKey=myVal
deployment.apps/frontend labeled

$ kubectl get all -l myKey=myVal      
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/frontend   2/2     2            2           14h
````

Удаление метки:
````bash
$ kubectl label deploy/frontend myKey-
deployment.apps/frontend unlabeled

$ kubectl get all -l myKey=myVal                                
No resources found in default namespace.
````

Получить список меток ноды:
````bash
$ kubectl get node/node1 -o jsonpath='{.metadata.labels}'
{"beta.kubernetes.io/arch":"amd64","beta.kubernetes.io/os":"linux","kubernetes.io/arch":"amd64","kubernetes.io/hostname":"node1","kubernetes.io/os":"linux"}        
````

Служебные метки применяются самим Kubernetes для отслеживания компонентов и удалив, например, метку, можно побудить
Kubernetes к созданию нового экземпляра компонента.

Аннотации используются для присоединения произвольных **неидентифицирующих** метаданных к объекту. Различные
инструменты и библиотеки могут получать такие метаданные и использовать их в своей работе.
И хотя для присоединения метаданных к объектам могут использоваться как метки, так и аннотации, но метки в основном
используются для идентификации объектов, а аннотации - именно для метаданных.

[Пример аннотаций для Nginx](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/).

Создаём [ingress](./infrastructure/playbooks/templates/back-and-front/ingress.yaml):
````bash
$ kubectl apply -f ./infrastructure/playbooks/templates/back-and-front/ingress.yaml 
ingress.networking.k8s.io/demo created

$ kubectl describe ingress/demo 
Name:             demo
Labels:           app=web-news
                  component=frontend
Namespace:        default
Address:          
Ingress Class:    nginx-example
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /   frontend-nodeport-svc:30000 ()
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
Events:       <none>
````

Создаём `whitelist` для доступа к ingress:
````bash
$ kubectl annotate ingress demo nginx.ingress.kubernetes.io/whitelist-source-range=10.0.10.0/24
ingress.networking.k8s.io/demo annotated

$ kubectl describe ingress/demo
Name:             demo
Labels:           app=web-news
                  component=frontend
Namespace:        default
Address:          
Ingress Class:    nginx-example
Default backend:  <default>
Rules:
  Host        Path  Backends
  ----        ----  --------
  *           
              /   frontend-nodeport-svc:30000 ()
Annotations:  nginx.ingress.kubernetes.io/rewrite-target: /
              nginx.ingress.kubernetes.io/whitelist-source-range: 10.0.10.0/24
Events:       <none>
````

Перенаправление **локального** порта на под:
````bash
$ kubectl get po             
NAME                        READY   STATUS    RESTARTS       AGE
frontend-757fc9f598-6ghkc   1/1     Running   2 (163m ago)   16h
...

$ kubectl port-forward pods/frontend-757fc9f598-6ghkc 8081:80
Forwarding from 127.0.0.1:8081 -> 80
Forwarding from [::1]:8081 -> 80
Handling connection for 8081
````

После этого к поду можно обращаться из `localhost`:

![](for_lecture/images/port-forward-8081-pod.png)

Перенаправление **локального** порта на деплоймент:
````bash
$ kubectl get deploy                                         
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
frontend   2/2     2            2           16h
...

$ kubectl port-forward deploy/frontend 8082:80
Forwarding from 127.0.0.1:8082 -> 80
Forwarding from [::1]:8082 -> 80
````

После этого к деплойменту можно обращаться из `localhost`:

![](for_lecture/images/port-forward-8082-deployment.png)

Перенаправление **локального** порта на сервис:
````bash
$ kubectl get svc                              
NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
frontend-nodeport-svc   NodePort    10.32.48.86    <none>        80:30000/TCP     16h
...

$ kubectl port-forward svc/frontend-nodeport-svc 8083:80
Forwarding from 127.0.0.1:8083 -> 80
Forwarding from [::1]:8083 -> 80
````

После этого к сервису можно обращаться из `localhost`:

![](for_lecture/images/port-forward-8083-service.png)

Документация по ресурсам и их полям (полезна при отсутствии доступа в инет):
````bash
kubectl explain pod
kubectl explain ingress.spec
kubectl explain pod.spec.containers
````

Вывод разницы между описаниями контейнеров в поде и деплойменте:
````bash
$ diff <(kubectl explain deploy.spec.template.spec.containers) <(kubectl explain pod.spec.containers)
1,2c1,2
< KIND:     Deployment
< VERSION:  apps/v1
---
> KIND:     Pod
> VERSION:  v1
````

Удалить под (будет создан новый под вместо удалённого):
````bash
$ kubectl delete pod/frontend-757fc9f598-6ghkc --grace-period=0 --force
warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "frontend-757fc9f598-6ghkc" force deleted
````

Пример скрипта для удаления подов, принадлежащих пространству имён `default` и находящихся в статусе `Terminating`:
````bash
$ NAMESPACE=default;for p in $(kubectl get pods -n $NAMESPACE| grep Terminating | awk '{print $1}'); do kubectl delete pod $p --grace-period=0 --force -n $NAMESPACE;done
````

Пример применения команды `patch` для немедленного удаления объектов с игнорированием финализаторов:
````bash
# kubectl patch pvc $PVC_NAME -p '{"metadata":{"finalizers": []}}' --type=merge
# kubectl patch pvc db-pv-claim -p '{"metadata":{"finalizers":null}}'
# kubectl patch pod db-74755f6698-8td72 -p '{"metadata":{"finalizers":null}}'
# kubectl get pv | tail -n+2 | awk '{print $1}' | xargs -I{} kubectl patch pv {} -p '{"metadata":{"finalizers": null}}'
````

k9s - утилита для управления кластером:

![](for_lecture/images/k9s.png)

Lens - аналог Kubernetes Dashboard.

</details>

---
