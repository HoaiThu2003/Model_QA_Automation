# QA Automation Project with PhoBERT and Sentence Transformers

This project implements a Question Answering (QA) system using PhoBERT combined with Sentence Transformers for Vietnamese text processing. It includes a FastAPI server for API endpoints and Celery for background tasks (e.g., fine-tuning and updating embeddings). The system uses Redis for task queuing and MySQL for data storage.

## Prerequisites

### Software Requirements
- **Python 3.10** or higher
- **Redis Server** (for task queuing)
- **MySQL Server** (for data storage)
- **Git** (optional, for version control)

### System Requirements
- Minimum 4GB RAM and a multi-core CPU (recommended: 8GB RAM for smooth fine-tuning)
- Stable internet connection (for downloading PhoBERT model initially)

## Installation
trong terminal:
## Set Up Virtual Environment
python -m venv .venv
# Windows
.\.venv\Scripts\activate
# Linux/Mac
source .venv/bin/activate

## Install Dependencies
pip install -r requirements.txt

## Configure Environment Variables
cp .env.example .env

## Create database
CREATE DATABASE qa_db;

## Running
- mở terminal chạy lệnh:
cd redis
.\redis-server.exe

- mở 1 tab terminal khác, chạy lệnh:
celery -A celery_config worker --pool=solo --concurrency=1 --loglevel=info

- mở 1 tab terminal khác, chạy lệnh:
uvicorn main3:app --reload --port 8000

## Test 
chạy thử với các api sau:
- api: /upload-excel
    chạy code với cURL sau: 
    curl --location 'http://localhost:8000/upload-excel' \
    --form 'file=@"/C:/duong_dan_den_file_excel/QA_Automation/qa_data1.xlsx"'

- api: /search
    chạy code với cURL sau:
    curl --location 'http://localhost:8000/search' \
    --header 'Content-Type: application/json' \
    --data '{"question": "chuẩn đầu ra anh văn"}'

- api: /update      (chức năng update câu hỏi và câu trả lời mới và tập dữ liệu)
    chạy code với cURL sau:
    curl --location 'http://localhost:8000/update' \
    --header 'Content-Type: application/json' \
    --data '{
        "question": "câu hỏi test",
        "answer": "Test"
    }'

- api: /fine-tune
    chạy code với cURL sau:
    curl --location --request POST 'http://localhost:8000/fine-tune'

- api: /enable-auto-fine-tune
    chạy code với cURL sau:
    curl --location --request POST 'http://localhost:8000/enable-auto-fine-tune'

- api: /disable-auto-fine-tune
    chạy code với cURL sau:
    curl --location --request POST 'http://localhost:8000/disable-auto-fine-tune'

- api: /get-auto-fine-tune-status
    chạy code với cURL sau:
    curl --location 'http://localhost:8000/get-auto-fine-tune-status'