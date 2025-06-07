#!/bin/sh

echo "Available environment variables:"
env

# Gán PORT mặc định nếu chưa có
if [ -z "$PORT" ]; then
  PORT=8000
  echo "PORT not set. Using default: $PORT"
else
  echo "Using PORT=$PORT"
fi

# Tránh lỗi port không hợp lệ
if ! echo "$PORT" | grep -Eq '^[0-9]+$'; then
  echo "Invalid PORT: $PORT"
  exit 1
fi

if [ "$SERVICE" = "api" ]; then
    echo "Starting FastAPI on port $PORT"
    exec sh -c "uvicorn main3:app --host 0.0.0.0 --port $PORT"
elif [ "$SERVICE" = "celery" ]; then
    echo "Starting Celery worker"
    exec celery -A celery_config worker --pool=solo --concurrency=1 --loglevel=info
else
    echo "Unknown SERVICE value: $SERVICE"
    exit 1
fi
