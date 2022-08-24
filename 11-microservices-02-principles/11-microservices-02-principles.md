
# Домашнее задание к занятию "11.02 Микросервисы: принципы"

Вы работаете в крупной компанию, которая строит систему на основе микросервисной архитектуры.
Вам как DevOps специалисту необходимо выдвинуть предложение по организации инфраструктуры, для разработки и эксплуатации.

## Задача 1: API Gateway 

Предложите решение для обеспечения реализации API Gateway. Составьте сравнительную таблицу возможностей различных программных решений. На основе таблицы сделайте выбор решения.

Решение должно соответствовать следующим требованиям:
- Маршрутизация запросов к нужному сервису на основе конфигурации
- Возможность проверки аутентификационной информации в запросах
- Обеспечение терминации HTTPS

Обоснуйте свой выбор.

---

### Ответ

Все виды решений API Gateway условно можно разделить на 3 класса:
- **облачные:**
  - Azure API Management;
  - Alibaba Cloud API Gateway;
  - AWS API Gateway;
  - IBM API Connect;
  - Microsoft Azure;
  - Oracle API Gateway;
  - Google Endpoints;
  - Google API Gateway;
  - SberCloud API Gateway;
  - Yandex API Gateway;
  - и др.
- **локальные от стороннего производителя:**
  - Kong Gateway;
  - Tyk;
  - KrakenD;
  - Gravitee.io;
  - Gloo Edge;
  - Goky API Gateway;
  - WSO2 API Microgateway;
  - Fusio;
  - Apiman;
  - API Umbrella;
  - Apigee;
  - MuleSoft;
  - Axway;
  - Young App;
  - SnapLogic;
  - Akana API Platform;
  - Oracle API Platform;
  - TIBCO Cloud-Mashery;
  - 3Scale;
  - и др.
- **собственное решение** (включая ч/з конфигурирование Nginx).

Во всем своём разнообразии **все эти решения потенциально способны предоставить требуемый
функционал**: 

| Решение             | Маппинг ч/з конфигурацию | Проверка подлинности | Терминация HTTPS |
|:--------------------|:------------------------:|:--------------------:|:----------------:|
| Облачные решения    |            Да            |          Да          |        Да        |
| Локальные решения   |            Да            |          Да          |        Да        |
| Собственные решения |            Да            |          Да          |        Да        |
| Конфигурация Nginx  |            Да            |     Ограниченно      |        Да        |


**Облачные решения** обладают широкими возможностями и избавляют от проблем с обслуживанием
оборудования, но в определенных условиях м.б. невыгодны экономически.

**Локальные решения** также обладают широчайшими возможностями конфигурирования, но выбор следует
делать осторожно - только после ряда экспериментов возможно выяснить, подходит ли конкретное
решение под требования конкретного бизнеса и только тогда сделать выбор.

**Собственные решения** предоставляют наибольшую свободу, и позволяет решить проблему,если: 
- требуются функции, отсутствующие в готовых решениях.
- нужно изменять внешний протокол (#HTTP, удобен клиентам) на какой-либо внутренний
(JRPC, событийная модель и т.п. удобный внутри).
- другие особые случаи.

Но в этом случае все затраты (в т.ч. временнЫе) и риски разработки и эксплуатации ложатся на бизнес.

**Конфигурирование [Nginx](https://ru.wikipedia.org/wiki/Nginx)**, позволяют реализовать
требуемый функционал не в полной мере, т.к. аутентификация ограничена базовой.

> Плюсом будет то, что Nginx может играть роль ревесного прокси, балансировщика нагрузки
> и веб-сервера для разнообразного HTTP-трафика.

К сожалению, **исходные данные задачи не сообщают о конкретных требованиях** - сроках, бюджетах,
различных объективных ограничениях, в которых функционирует бизнес - **что не позволяет выработать
компетентную рекомендацию, но наиболее дешевым является вариант с Nginx**.

---


## Задача 2: Брокер сообщений

Составьте таблицу возможностей различных брокеров сообщений. На основе таблицы сделайте обоснованный выбор решения.

Решение должно соответствовать следующим требованиям:
- Поддержка кластеризации для обеспечения надежности
- Хранение сообщений на диске в процессе доставки
- Высокая скорость работы
- Поддержка различных форматов сообщений
- Разделение прав доступа к различным потокам сообщений
- Протота эксплуатации

Обоснуйте свой выбор.

---

### Ответ

Брокер сообщений позволяет сервисам обмениваться сообщениями друг с другом, реализуя тем самым
событийную модель взаимодействия. Существует довольно широкий выбор решений:

- AWS Amazon SQS;
- AWS Kinesis;
- Apache ActiveMQ;
- Apache Artemis;
- Apache Kafka;
- Apache Qpid;
- Apache Pulsar;
- Cloverleaf;
- Comverse Message Broker;
- Datareon MQ;
- Eclipse Mosquitto MQTT Broker;
- Enduro/X Transactional Message Queue;
- Financial Fusion Message Broker;
- Fuse Message Broker;
- Gearman;
- Google Cloud Pub/Sub;
- HiveMQ HiveMQ MQTT Broker;
- EMQX Broker;
- HornetQ;
- IBM App Connect;
- IBM MQ;
- JBoss Messaging;
- JORAM;
- Microsoft Azure Service Bus;
- Microsoft BizTalk Server;
- MigratoryData;
- NATS;
- Open Message Queue;
- Oracle Message Broker;
- RabbitMQ;
- Redis;
- Red Hat AMQ;
- SAP PI;
- Solace PubSub;
- Spread Toolkit;
- Tarantool;
- TIBCO Enterprise Message Service;
- WSO2 Message Broker;
- и др.

Мы не будем анализировать их все, особенно с учетом того, что между многими из них особых различий
нет, рассмотрим лишь пятерку одних из самых популярных:

| Брокер               | Кластеризация | Хранение сообщений |   Скорость    |       Форматы сообщений       | Разделение прав | Сложность |
|:---------------------|:-------------:|:------------------:|:-------------:|:-----------------------------:|:---------------:|:---------:|
| Apache Kafka         |      Да       |         Да         | Очень высокая |              TCP              |       Да        |  Низкая   |
| RabbitMQ             |      Да       |        Нет         |    Высокая    | WebSockets, AMQP, MQTT, STOMP |       Нет       |  Низкая   |
| IBM MQ               |      Да       |         Да         | Очень высокая |           SSL, TLS            |       Да        |  Высокая  |
| Amazon SQS           |      Да       |         Да         |    Высокая    | WebSockets, AMQP, MQTT, STOMP |       Да        |  Средняя  |
| Redis                |      Да       |        Нет         | Очень высокая |             RESP              |       Да        |  Низкая   |



На основе данного анализа **сделаем свой выбор в пользу Apache Kafka** из-за его скорости, богатого функционала и доступности.

---


## Задача 3: API Gateway * (необязательная)

### Есть три сервиса:

**minio**
- Хранит загруженные файлы в бакете images
- S3 протокол

**uploader**
- Принимает файл, если он картинка сжимает и загружает его в minio
- POST /v1/upload

**security**
- Регистрация пользователя POST /v1/user
- Получение информации о пользователе GET /v1/user
- Логин пользователя POST /v1/token
- Проверка токена GET /v1/token/validation

### Необходимо воспользоваться любым балансировщиком и сделать API Gateway:

**POST /v1/register**
- Анонимный доступ.
- Запрос направляется в сервис security POST /v1/user

**POST /v1/token**
- Анонимный доступ.
- Запрос направляется в сервис security POST /v1/token

**GET /v1/user**
- Проверка токена. Токен ожидается в заголовке Authorization. Токен проверяется через вызов сервиса security GET /v1/token/validation/
- Запрос направляется в сервис security GET /v1/user

**POST /v1/upload**
- Проверка токена. Токен ожидается в заголовке Authorization. Токен проверяется через вызов сервиса security GET /v1/token/validation/
- Запрос направляется в сервис uploader POST /v1/upload

**GET /v1/user/{image}**
- Проверка токена. Токен ожидается в заголовке Authorization. Токен проверяется через вызов сервиса security GET /v1/token/validation/
- Запрос направляется в сервис minio  GET /images/{image}

### Ожидаемый результат

Результатом выполнения задачи должен быть docker compose файл запустив который можно локально выполнить следующие команды с успешным результатом.
Предполагается что для реализации API Gateway будет написан конфиг для NGinx или другого балансировщика нагрузки который будет запущен как сервис через docker-compose и будет обеспечивать балансировку и проверку аутентификации входящих запросов.
Авторизация
curl -X POST -H 'Content-Type: application/json' -d '{"login":"bob", "password":"qwe123"}' http://localhost/token

**Загрузка файла**

curl -X POST -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I' -H 'Content-Type: octet/stream' --data-binary @yourfilename.jpg http://localhost/upload

**Получение файла**
curl -X GET http://localhost/images/4e6df220-295e-4231-82bc-45e4b1484430.jpg

---

#### [Дополнительные материалы: как запускать, как тестировать, как проверить]().

---


### Решение

Создадим сертификат и ключ - они позволят нам защитить соединение с нашим [API Gateway](./gateway/api_gateway.conf):
````bash
$ openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out ./gateway/ssl/certs/my_cert.crt -keyout ./gateway/ssl/private/my_cert.key
Generating a RSA private key
...++++
..........................................................................................................++++
writing new private key to './gateway/ssl/private/my_cert.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:
State or Province Name (full name) [Some-State]:
Locality Name (eg, city) []:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:
Email Address []:
````

Сохраним полученный сертификат и ключ назначенных папках, после чего запустим нашу конфигурацию
через  [docker-compose](docker-compose.yaml). Список контейнеров после запуска будет следующим:

![](images/docker_ps.png)

> Здесь следует обратить внимание на маппинг порта `443` контейнера "gateway", что позволяет
> обращаться к нему через `localhost` с использованием протокола `https`.

> Контейнер "docker-hoster" здесь отвечает за сопоставление имен контейнеров с присвоенными
> им IP-адресами путём заполнения файла `/etc/hosts` и к текущему заданию не относится.

#### Сначала проверим готовность инфраструктуры без использования API Gateway.

Проверим статус служб `security` и `uploader`:
````bash
$ curl http://security:3000/status
{"status":"OK"}

$ curl http://uploader:3000/status
{"status":"OK"}%   
````

Получим токен:
````bash
$ curl -X POST -H 'Content-Type: application/json' -d '{"login":"bob", "password":"qwe123"}' http://security:3000/v1/token
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I
````

Проверим валидность токена (знак `%` на конце токена, если он есть, нужно убрать!):
````bash
$ curl -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I' http://security:3000/v1/token/validation
{"sub":"bob"}
````

Загрузим файл в хранилище, применяя полученный токен:
````bash
$ curl -X POST -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I' -H 'Content-Type: octet/stream' --data-binary @/home/oleg/devkub-homeworks/11-microservices-02-principles/images/cat.jpg http://uploader:3000/v1/upload
{"filename":"ffe54603-58a8-408b-99ed-27b2dd0c7891.jpg"}
````

> При желании можно открыть веб-интерфейс "MinIO" ([login/pass: storage/qwerty123456](.env)):
>
> ![](images/minio_login.png)
>
> И нажав кнопку "Browse":
>
> ![](images/minio_browse_data.png)
>
> Увидеть загруженный нами файл:
>
> ![](images/minio_uploaded_file.png)
>
> И даже увидеть само изображение, нажав кнопку "Preview:
>
> ![](images/minio_uploaded_image.png)

Файл из хранилища можно загрузить и с помощью `curl`:
````bash
$ curl http://storage:9000/data/ffe54603-58a8-408b-99ed-27b2dd0c7891.jpg > ~/devkub-homeworks/11-microservices-02-principles/images/cat_downloaded_directly.jpg
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 17490  100 17490    0     0  1593k      0 --:--:-- --:--:-- --:--:-- 1708k
````

Картинка успешно сохранена в локальном каталоге под именем
[cat_downloaded_directly.jpg](./images/cat_downloaded_directly.jpg):

![](./images/cat_downloaded_directly.jpg)


#### Теперь проверим работу созданной инфраструктуры, получая к ней доступ через API Gateway.

Сконфигурированный нами [API Gateway](./gateway/api_conf.d/gateway_api.conf) реализует следующее сопоставление точек доступа
через `localhost`:

| Точка доступа             | Проверка безопасности              | Точка назначения         | Действие                      |
|:--------------------------|:-----------------------------------|:-------------------------|:------------------------------|
| _POST /v1/register_       | Anonymous                          | _security POST /v1/user_ | Регистрация пользователя*     |
| POST /v1/token            | Anonymous                          | security POST /v1/token  | Получение токена пользователя |
| POST /v1/upload           | security GET /v1/token/validation/ | uploader POST /v1/upload | Загрузка файла                |
| _GET /v1/user_            | security GET /v1/token/validation/ | _security GET /v1/user_  | Информация о пользователе*    |
| GET /v1/user/{image}      | security GET /v1/token/validation/ | minio GET /data/{image}  | Скачивание файла              |

> ***ПРИМЕЧАНИЕ:** Точки доступа `security POST /v1/user` и `GET /v1/user` в коде предоставленных
> сервисов не реализованы, поэтому доступ к ним через API Gateway сконфигурирован на возвращение
> ошибки "**501 Not Implemented**"!

Балансировка нагрузки между серверами задана в файле [api_backends.conf](./gateway/api_backends.conf)
через указание имен контейнеров, сопоставление которых с реальными IP-адресами задано
в файле `/etc/hosts` самого хоста.

Получим токен пользователя:
````bash
$ curl -X POST -H 'Content-Type: application/json' -d '{"login":"bob", "password":"qwe123"}' --insecure https://localhost/v1/token
eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I    
````

> Данный маршут был [переопределен](./gateway/api_conf.d/gateway_api.conf) следующим образом:
>````bash
>location /v1/ {
>...
>  location ~ ^/v1/token$ {
>    proxy_pass http://security_server$uri;
>  }
>...
>````

Провалидируем токен:
````bash
$ curl -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I' --insecure https://localhost/v1/token/validation
{"sub":"bob"}
````

> Данный маршут был [переопределен](./gateway/api_conf.d/gateway_api.conf) следующим образом:
>````bash
>location /v1/ {
>...
>  location ~ ^/v1/token/validation$ {
>    proxy_pass http://security_server$uri;
>  }
>...
>````

Загрузим файл в хранилище:
````bash
$ curl -X POST -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJib2IifQ.hiMVLmssoTsy1MqbmIoviDeFPvo-nCd92d4UFiN2O2I' -H 'Content-Type: octet/stream' --data-binary @/home/oleg/devkub-homeworks/11-microservices-02-principles/images/cat.jpg --insecure https://localhost/v1/upload
{"filename":"f2a2962a-cfa7-4314-b972-8878ced5f566.jpg"}
````

> Данный маршут был [переопределен](./gateway/api_conf.d/gateway_api.conf) следующим образом:
>````bash
>location /v1/ {
>...
>  location ~ ^/v1/upload$ {
>    proxy_pass http://uploader_server$uri;
>  }
>...
>````

Теперь у нас в хранилище два файла:

![](./images/minio_uploaded_file_2.png)

Скачаем файл, пользуясь API Gateway:
````bash
$ curl --insecure https://localhost/v1/user/ffe54603-58a8-408b-99ed-27b2dd0c7891.jpg > ~/devkub-homeworks/11-microservices-02-principles/images/cat_downloaded_gateway.jpg
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 17490  100 17490    0     0   589k      0 --:--:-- --:--:-- --:--:--  610k
````

> Данный маршут был [переопределен](./gateway/api_conf.d/gateway_api.conf) следующим образом:
>````bash
>location /v1/ {
>...
>  location ~ \/v1\/user\/(.+\..+)$ {
>    proxy_pass http://storage_server/data/$1;
>  }
>...
>````
> Здесь, благодаря использованию такого механизма регулярных выражений, как группировка, мы можем
> получить имя запрашиваемого файла по номеру группы, в которую он попал (`$1`). 

Как результат, картинка успешно сохранена в локальном каталоге под именем
[cat_downloaded_gateway.jpg](./images/cat_downloaded_gateway.jpg):

![](./images/cat_downloaded_gateway.jpg)

Как видим, результат доступа к сервисам через точку доступа API Gateway полностью идентичен тому,
который мы получили ранее, обращаясь к сервисам непосредственно.

---
