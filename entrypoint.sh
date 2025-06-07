#!/bin/sh

# Kiểm tra biến SERVICE
if [ "$SERVICE" = "api" ]; then
    echo "Starting FastAPI on port $PORT"
    uvicorn main3:app --host 0.0.0.0 --port "$PORT"
elif [ "$SERVICE" = "celery" ]; then
    echo "Starting Celery worker"
    celery -A celery_config worker --pool=solo --concurrency=1 --loglevel=info
else
    echo "Unknown SERVICE value: $SERVICE"
    exit 1
fi