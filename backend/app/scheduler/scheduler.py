import logging

from apscheduler.schedulers.background import BackgroundScheduler

from app.scheduler.price_monitor import run_price_monitor

logger = logging.getLogger(__name__)

scheduler = BackgroundScheduler()


def start_scheduler():
    scheduler.add_job(
        run_price_monitor,
        trigger="interval",
        hours=6,
        id="price_monitor",
        replace_existing=True,
    )
    scheduler.start()
    logger.info("Scheduler started (interval: 6h)")


def stop_scheduler():
    scheduler.shutdown()
    logger.info("Scheduler stopped")
