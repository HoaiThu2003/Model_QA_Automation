#!/bin/sh

# In ra tất cả biến môi trường để debug
echo "Available environment variables:"
env

# Kiểm tra và gán PORT
if [ -z "$PORT" ]; then
  echo "PORT not set. Using default: 8000"
  PORT=8000
else
  echo "Using PORT=$PORT"
fi

# Tránh lỗi port không hợp lệ
if ! echo "$PORT" | grep -Eq '^[0-9]+$'; then
  echo "Invalid PORT: $PORT. Must be a valid integer."
  exit 1
fi

# Kiểm tra biến SERVICE
if [ "$SERVICE" = "api" ]; then
    echo "Starting FastAPI on port $PORT"
    exec uvicorn main3:app --host 0.0.0.0 --port "$PORT"
elif [ "$SERVICE" = "celery" ]; then
    echo "Starting Celery worker"
    exec celery -A celery_config worker --pool=solo --concurrency=1 --loglevel=info
else
    echo "Unknown SERVICE value: $SERVICE"
    exit 1
fi