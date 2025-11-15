#!/bin/bash
set -e

### конфигурация
BUCKET_NAME="itmo-trigger-bucket"
FUNCTION_NAME="itmo-function"
SERVICE_ACCOUNT_NAME="itmo-function-sa"
TRIGGER_NAME="itmo-trigger"

### получаем folder ID
FOLDER_ID=$(yc config get folder-id)
echo "FOLDER_ID = $FOLDER_ID"

### проверяем: существует ли bucket
if yc storage bucket get "$BUCKET_NAME" &>/dev/null; then
  echo "✔ Bucket уже существует: $BUCKET_NAME"
else
  echo "Создаём bucket: $BUCKET_NAME"
  yc storage bucket create --name "$BUCKET_NAME"
fi

### получаем service-account-id
SERVICE_ACCOUNT_ID=$(yc iam service-account get "$SERVICE_ACCOUNT_NAME" --format json | jq -r '.id')
echo "SERVICE_ACCOUNT_ID = $SERVICE_ACCOUNT_ID"

### назначаем роль storage.editor
echo "Назначаем storage.editor для $SERVICE_ACCOUNT_NAME"
yc resource-manager folder add-access-binding "$FOLDER_ID" \
  --role storage.editor \
  --subject serviceAccount:"$SERVICE_ACCOUNT_ID"

### проверяем: существует ли триггер
if yc serverless trigger get "$TRIGGER_NAME" &>/dev/null; then
  echo "✔ Триггер уже существует: $TRIGGER_NAME"
else
  echo "Создаём триггер $TRIGGER_NAME"
  yc serverless trigger create object-storage \
    --name "$TRIGGER_NAME" \
    --bucket-id "$BUCKET_NAME" \
    --events 'create-object' \
    --prefix 'input/' \
    --invoke-function-name "$FUNCTION_NAME" \
    --invoke-function-service-account-id "$SERVICE_ACCOUNT_ID"
fi

echo
printf "✓ Триггер готов. Загружай файлы в bucket '%s/input/' — функция вызовется.\n" "$BUCKET_NAME"
