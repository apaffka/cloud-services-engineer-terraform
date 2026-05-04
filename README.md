# Kittygram Final — инфраструктура и деплой в Yandex Cloud

Проект разворачивает приложение Kittygram на виртуальной машине в Yandex Cloud.  
Инфраструктура создаётся через Terraform, а деплой приложения выполняется через GitHub Actions и Docker Compose.

## Что разворачивается
Terraform создаёт:
- VPC-сеть и подсеть;
- security group с доступом по SSH и HTTP-порту приложения;
- виртуальную машину Ubuntu;
- пользователя для подключения по SSH;
- подготовку сервера через cloud-init: установка Docker и Docker Compose.

Приложение запускается на VM через `docker-compose.production.yml` и состоит из:

- `backend` — Django API;
- `frontend` — React-приложение;
- `gateway` — Nginx;
- `postgres` — база данных PostgreSQL;
- volumes для статики, медиа и данных PostgreSQL.

## Быстрый запуск

1. Создать bucket для Terraform state в Yandex Object Storage.
2. Создать service account и ключи доступа.
3. Добавить Terraform secrets в GitHub.
4. Запустить Terraform workflow с действием `plan`.
5. Если план корректный, запустить Terraform workflow с действием `apply`.
6. Получить публичный IP VM и добавить его в GitHub Secret `HOST`.
7. Обновить `tests.yml`.
8. Запустить workflow `Kittygram Deploy`.
9. Проверить приложение по адресу:

```text
http://<VM_PUBLIC_IP>:8080
```

10. После проверки удалить инфраструктуру через Terraform workflow с действием `destroy`.

## Настройка GitHub Secrets

Все чувствительные данные хранятся в GitHub Secrets.

Секреты разделены на две группы:

1. secrets для Terraform и Yandex Cloud;
2. secrets для деплоя приложения.

## Secrets для Terraform

Эти secrets используются workflow:

```text
.github/workflows/terraform.yml
```

| Secret | Описание | Где взять |
|---|---|---|
| `YC_CLOUD_ID` | ID облака Yandex Cloud | `yc config get cloud-id` |
| `YC_FOLDER_ID` | ID каталога Yandex Cloud | `yc config get folder-id` |
| `YC_KEY_JSON` | service account authorized key в формате base64 | создаётся через `yc iam key create` |
| `TF_STATE_BUCKET` | имя Object Storage bucket для Terraform state | имя заранее созданного бакета |
| `TF_STATE_ACCESS_KEY` | static access key для Object Storage | создаётся для service account |
| `TF_STATE_SECRET_KEY` | static secret key для Object Storage | создаётся вместе с access key |
| `VM_SSH_PUBLIC_KEY` | публичный SSH-ключ для подключения к VM | содержимое файла `*.pub` |

Получить `cloud_id` и `folder_id`:

```bash
yc config get cloud-id
yc config get folder-id
```

Создать authorized key для service account:

```bash
yc iam key create \
  --service-account-name <SERVICE_ACCOUNT_NAME> \
  --output authorized_key.json
```

Закодировать `authorized_key.json` в base64 для GitHub Secret `YC_KEY_JSON`:

```bash
base64 < authorized_key.json | tr -d '\n'
```

На macOS можно сразу скопировать результат в буфер:

```bash
base64 < authorized_key.json | tr -d '\n' | pbcopy
```

Создать static access key для Object Storage:

```bash
yc iam access-key create --service-account-name <SERVICE_ACCOUNT_NAME>
```

В выводе команды будут два значения:

```text
key_id:  <это TF_STATE_ACCESS_KEY>
secret:  <это TF_STATE_SECRET_KEY>
```

Публичный SSH-ключ для VM:

```bash
cat ~/.ssh/id_rsa.pub
```

или, если используется отдельный ключ для проекта:

```bash
cat ~/.ssh/kittygram_github_actions.pub
```

## Secrets для деплоя приложения

Эти secrets используются workflow:

```text
.github/workflows/deploy.yml
```

| Secret | Описание |
|---|---|
| `HOST` | публичный IP виртуальной машины в Yandex Cloud |
| `USER` | SSH-пользователь на VM, обычно `user` |
| `SSH_KEY` | приватный SSH-ключ для подключения к VM |
| `VM_SSH_PASSPHRASE` | passphrase от приватного SSH-ключа, если ключ защищён |
| `DOCKER_USERNAME` | логин Docker Hub |
| `DOCKER_PASSWORD` | пароль или access token Docker Hub |
| `DJANGO_SECRET_KEY` | секретный ключ Django |
| `POSTGRES_DB` | имя базы данных PostgreSQL |
| `POSTGRES_USER` | пользователь PostgreSQL |
| `POSTGRES_PASSWORD` | пароль PostgreSQL |
| `TELEGRAM_USER` | Telegram chat ID |
| `TELEGRAM_TOKEN` | token Telegram-бота |

Значение `HOST` становится известно только после успешного запуска Terraform `apply`.

Получить IP можно из Terraform output:

```bash
terraform output -raw vm_1_address
```

Если Terraform запускается через GitHub Actions, IP будет показан в логах workflow или в outputs Terraform.

Приватный SSH-ключ:

```bash
cat ~/.ssh/id_rsa
```

или, если используется отдельный ключ:

```bash
cat ~/.ssh/kittygram_github_actions
```

Если приватный ключ защищён passphrase, этот пароль нужно добавить в secret:

```text
VM_SSH_PASSPHRASE
```

Если используется ключ без passphrase, этот secret можно не создавать.

Сгенерировать Django secret key:

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

## Порядок запуска проекта

### 1. Подготовить Yandex Cloud

Перед запуском workflow нужно:

1. создать service account;
2. выдать service account необходимые права;
3. создать Object Storage bucket для Terraform state;
4. создать static access key для доступа к bucket;
5. создать authorized key для Terraform provider;
6. добавить все Terraform secrets в GitHub.

Bucket для Terraform state создаётся заранее вручную.

### 2. Запустить Terraform plan

В GitHub Actions открыть:

```text
Actions → Terraform → Run workflow
```

Выбрать действие:

```text
plan
```

`plan` покажет, какие ресурсы Terraform собирается создать в Yandex Cloud.

На этом этапе ресурсы ещё не создаются.

### 3. Создать инфраструктуру через Terraform apply

После успешного `plan` снова запустить workflow:

```text
Actions → Terraform → Run workflow
```

Выбрать действие:

```text
apply
```

Terraform создаст:

- VPC network;
- subnet;
- security group;
- virtual machine;
- пользователя для SSH;
- Docker и Docker Compose через cloud-init.

После завершения `apply` нужно получить публичный IP виртуальной машины и добавить его в GitHub Secret:

```text
HOST
```

### 4. Обновить `tests.yml`

После создания VM нужно указать адрес приложения в `tests.yml`:

```yaml
repo_owner: <your_github_username>
kittygram_domain: http://<VM_PUBLIC_IP>:8080
dockerhub_username: <your_dockerhub_username>
```

### 5. Запустить деплой приложения

После того как инфраструктура создана, а `HOST` добавлен в GitHub Secrets, нужно запустить deploy workflow вручную:

```text
Actions → Kittygram Deploy → Run workflow
```

Workflow выполняет следующие действия:

1. запускает backend tests;
2. запускает frontend tests;
3. собирает Docker images;
4. публикует images в Docker Hub;
5. копирует `docker-compose.production.yml` на VM;
6. создаёт `.env` на сервере;
7. запускает контейнеры через Docker Compose;
8. запускает автотесты;
9. отправляет Telegram-уведомление об успешном деплое.

После успешного деплоя приложение будет доступно по адресу:

```text
http://<VM_PUBLIC_IP>:8080
```

### 6. Проверить сервер вручную

Подключиться к VM:

```bash
ssh user@<VM_PUBLIC_IP>
```

Перейти в папку проекта:

```bash
cd /home/user/kittygram
```

Проверить контейнеры:

```bash
sudo docker compose -f docker-compose.production.yml ps
```

Посмотреть логи:

```bash
sudo docker compose -f docker-compose.production.yml logs
```

### 7. Удалить инфраструктуру после завершения работы

Чтобы не расходовать ресурсы Yandex Cloud, после проверки проекта нужно удалить инфраструктуру:

```text
Actions → Terraform → Run workflow → destroy
```

Terraform удалит созданную VM, сеть, подсеть и связанные ресурсы.
