# Stage 1: Build dependencies
FROM python:3.11-slim AS builder

WORKDIR /app

# 1. Cài gói hệ thống cần thiết
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy requirements
COPY requirements.txt .

# 3. Tách cài torch trước (có thể cache riêng và giảm thời gian timeout)
RUN pip install --upgrade pip && \
    pip install torch==2.2.2+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html

# 4. Cài các thư viện còn lại
RUN grep -v "^torch" requirements.txt > other.txt && \
    pip install --no-cache-dir -r other.txt

# Stage 2: Final image
FROM python:3.11-slim

WORKDIR /app

# Copy từ builder stage
COPY --from=builder /usr/local /usr/local
COPY . .

# Xóa file lớn không cần
RUN find . -name "*.pkl" -delete || true
RUN find . -name "*.faiss" -delete || true

# Cấu hình môi trường
ENV PYTHONUNBUFFERED=1
ENV PATH="/usr/local/bin:$PATH"

# Run app
CMD ["sh", "-c", "uvicorn main3:app --host 0.0.0.0 --port ${PORT:-8000}"]
