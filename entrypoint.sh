#!/bin/sh

# Debug: In ra toàn bộ biến môi trường để kiểm tra nếu cần
echo "Environment variables:"
env

# In ra giá trị của PORT
echo "PORT value: $PORT"

# Gán PORT mặc định nếu chưa có
if [ -z "$PORT" ]; then
    echo "PORT is not set, using default 8000"
    PORT=8000
fi

# Kiểm tra biến SERVICE
if [ "$SERVICE" = "api" ]; then
    echo "Starting FastAPI on port $PORT"
    exec uvicorn main3:app --host 0.0.0.0 --port $PORT
elif [ "$SERVICE" = "celery" ]; then
    echo "Starting Celery worker"
    exec celery -A celery_config worker --pool=solo --concurrency=1 --loglevel=info
else
    echo "Unknown SERVICE value: $SERVICE"
    exit 1
fi
