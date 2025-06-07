#!/bin/sh

echo "Available environment variables:"
env

# Set PORT mặc định nếu không được set
PORT=${PORT:-8000}
echo "Using PORT=$PORT"

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
