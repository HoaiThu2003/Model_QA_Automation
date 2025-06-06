import os
from dotenv import load_dotenv
import sys
import logging
import asyncio
import aiomysql
import redis
from celery_config import app
from utils import db_config, get_app_state, fine_tune_phobert, update_embeddings_after_finetune
from sentence_transformers import SentenceTransformer

# Tải tệp .env
load_dotenv()

# Thêm thư mục dự án vào sys.path
# project_dir = r"C:\Users\admin\TL\Model\QA_Automation"
project_dir = os.path.dirname(os.path.abspath(__file__))
if project_dir not in sys.path:
    sys.path.insert(0, project_dir)

# Cấu hình logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

async def init_worker_pool():
    try:
        pool = await aiomysql.create_pool(**db_config)
        logger.info("Celery worker MySQL pool initialized")
        return pool
    except Exception as e:
        logger.error(f"Error creating worker MySQL pool: {e}")
        raise

async def close_worker_pool(pool):
    if pool:
        try:
            pool.close()
            await pool.wait_closed()
            logger.info("Celery worker MySQL pool closed")
        except Exception as e:
            logger.error(f"Error closing worker MySQL pool: {e}")

@app.task(bind=True, max_retries=3, retry_backoff=True)
def fine_tune_task(self):
    loop = None
    state = get_app_state()
    try:
        logger.info("Starting fine_tune_task")
        if state.redis_client is None:
            logger.info("Initializing redis_client for worker")
            redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
            state.redis_client = redis.from_url(redis_url)
            state.redis_client.ping()
            logger.info("Redis client initialized successfully")

        if state.db_pool is None:
            logger.info("Initializing db_pool for worker")
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            state.db_pool = loop.run_until_complete(init_worker_pool())
            logger.info("Database pool initialized successfully")

        checkpoint_path = os.path.join(os.path.dirname(__file__), "phobert_finetuned") if os.getenv("RENDER_ENV") != "production" else "/var/cache/models/phobert_finetuned"
        model_path = os.path.join(os.path.dirname(__file__), "phobert_base") if os.getenv("RENDER_ENV") != "production" else "/var/cache/models/phobert_base"
        model_path = os.getenv("CHECKPOINT_PATH", checkpoint_path) if os.path.exists(os.getenv("CHECKPOINT_PATH", checkpoint_path)) else os.getenv("MODEL_PATH", model_path)
        if not os.path.exists(model_path):
            logger.error(f"Model path {model_path} does not exist")
            raise FileNotFoundError(f"Model path {model_path} does not exist")
        logger.info(f"Loading SentenceTransformer from {model_path}")
        state.model = SentenceTransformer(model_path)

        if not fine_tune_phobert(state, loop=loop):
            logger.error("fine_tune_phobert failed")
            raise Exception("Fine-tuning failed")
        logger.info("fine_tune_task completed successfully")
        update_embeddings_task.delay()

    except Exception as e:
        logger.error(f"Fine-tune task failed: {e}", exc_info=True)
        raise self.retry(exc=e, countdown=180)

    finally:
        if state.db_pool and loop:
            try:
                loop.run_until_complete(close_worker_pool(state.db_pool))
                logger.info("Closed db_pool in fine_tune_task")
            except Exception as e:
                logger.error(f"Error closing db_pool: {e}")
            finally:
                state.db_pool = None
                if not loop.is_closed():
                    loop.close()
                    logger.info("Closed event loop in fine_tune_task")
        elif state.db_pool:
            logger.warning("db_pool exists but no loop, skipping close")

@app.task(bind=True, max_retries=3, retry_backoff=True)
def update_embeddings_task(self):
    loop = None
    state = get_app_state()
    try:
        logger.info("Starting update_embeddings_task")
        if state.redis_client is None:
            logger.info("Initializing redis_client for worker")
            redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")
            state.redis_client = redis.from_url(redis_url)
            state.redis_client.ping()
            logger.info("Redis client initialized successfully")

        if state.db_pool is None:
            logger.info("Initializing db_pool for worker")
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            state.db_pool = loop.run_until_complete(init_worker_pool())
            logger.info("Database pool initialized successfully")

        checkpoint_path = os.path.join(os.path.dirname(__file__), "phobert_finetuned") if os.getenv("RENDER_ENV") != "production" else "/var/cache/models/phobert_finetuned"
        model_path = os.path.join(os.path.dirname(__file__), "phobert_base") if os.getenv("RENDER_ENV") != "production" else "/var/cache/models/phobert_base"
        model_path = os.getenv("CHECKPOINT_PATH", checkpoint_path) if os.path.exists(os.getenv("CHECKPOINT_PATH", checkpoint_path)) else os.getenv("MODEL_PATH", model_path)
        if not os.path.exists(model_path):
            logger.error(f"Model path {model_path} does not exist")
            raise FileNotFoundError(f"Model path {model_path} does not exist")
        logger.info(f"Loading SentenceTransformer from {model_path}")
        state.model = SentenceTransformer(model_path)

        loop = loop or asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        loop.run_until_complete(update_embeddings_after_finetune(state))
        logger.info("update_embeddings_task completed successfully")

    except Exception as e:
        logger.error(f"Update embeddings task failed: {e}", exc_info=True)
        raise self.retry(exc=e, countdown=180)

    finally:
        if state.db_pool and loop:
            try:
                loop.run_until_complete(close_worker_pool(state.db_pool))
                logger.info("Closed db_pool in update_embeddings_task")
            except Exception as e:
                logger.error(f"Error closing db_pool: {e}")
            finally:
                state.db_pool = None
                if not loop.is_closed():
                    loop.close()
                    logger.info("Closed event loop in update_embeddings_task")
        elif state.db_pool:
            logger.warning("db_pool exists but no loop, skipping close")