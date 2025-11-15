#!/bin/bash

set -e  # остановить скрипт при любой ошибке

### Конфигурация
FUNCTION_NAME="itmo-function"
SERVICE_ACCOUNT_NAME="itmo-function-sa"
ZIP_NAME="function.zip"
PYTHON_FILE="main.py"
RUNTIME="python37"
MEMORY="256m"
TIMEOUT="20s"

### получить folder ID из текущего профиля
FOLDER_ID=$(yc config get folder-id)
echo "FOLDER_ID = $FOLDER_ID"

### проверка, существует ли сервисный аккаунт
if yc iam service-account get "$SERVICE_ACCOUNT_NAME" &>/dev/null; then
  echo "✓ Сервисный аккаунт уже существует: $SERVICE_ACCOUNT_NAME"
else
  echo "Создаём сервисный аккаунт: $SERVICE_ACCOUNT_NAME"
  yc iam service-account create \
    --name "$SERVICE_ACCOUNT_NAME" \
    --description "Service account for Cloud Function"
fi


### получить service-account-id
SERVICE_ACCOUNT_ID=$(yc iam service-account get "$SERVICE_ACCOUNT_NAME" --format json | jq -r '.id')
echo "SERVICE_ACCOUNT_ID = $SERVICE_ACCOUNT_ID"

### выдать роль editor
yc resource-manager folder add-access-binding "$FOLDER_ID" \
  --role editor \
  --subject serviceAccount:"$SERVICE_ACCOUNT_ID"

### проверка, существует ли функция
if yc serverless function get "$FUNCTION_NAME" &>/dev/null; then
  echo "✓ Функция уже существует: $FUNCTION_NAME"
else
  echo "Создаём функцию: $FUNCTION_NAME"
  yc serverless function create --name "$FUNCTION_NAME"
fi

### упаковать функцию
if [[ -f "$ZIP_NAME" ]]; then
  echo "Архив $ZIP_NAME уже существует. Удаляем перед пересборкой."
  rm "$ZIP_NAME"
fi

echo "Упаковка $PYTHON_FILE → $ZIP_NAME"
zip -q -j "$ZIP_NAME" "$PYTHON_FILE"

### версия функции
echo "Загружаем новую версию функции"
yc serverless function version create \
  --function-name "$FUNCTION_NAME" \
  --memory "$MEMORY" \
  --execution-timeout "$TIMEOUT" \
  --runtime "$RUNTIME" \
  --entrypoint main.handler \
  --source-path "$ZIP_NAME" \
  --service-account-id "$SERVICE_ACCOUNT_ID"

### делаем функцию публичной
echo "Открываем публичный доступ"
yc serverless function allow-unauthenticated-invoke "$FUNCTION_NAME"

### финальный вывод
echo
echo "✓ Готово! Ссылка для вызова функции:"
yc serverless function get "$FUNCTION_NAME" | grep http_invoke_url
