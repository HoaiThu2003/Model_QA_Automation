# Stage 1: Build dependencies
FROM python:3.10-slim AS builder

WORKDIR /app

# Cài đặt phụ thuộc hệ thống
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt -f https://download.pytorch.org/whl/cpu/torch_stable.html

# Stage 2: Final image
FROM python:3.10-slim

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . .

# Remove any cached models or large files
RUN find . -name "*.pkl" -type f -delete
RUN find . -name "*.faiss" -type f -delete

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PATH="/usr/local/bin:$PATH"

# Run with shell command to handle PORT
CMD ["/bin/sh", "-c", "echo 'Starting with PORT: $PORT'; if [ -z \"$PORT\" ]; then PORT=8000; echo 'PORT not set, using default: $PORT'; fi; if [ \"$SERVICE\" = \"api\" ]; then uvicorn main3:app --host 0.0.0.0 --port $PORT; elif [ \"$SERVICE\" = \"celery\" ]; then celery -A celery_config worker --pool=solo --concurrency=1 --loglevel=info; else echo 'Unknown SERVICE value: $SERVICE'; exit 1; fi"]