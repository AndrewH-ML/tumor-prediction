# log_handlers.py

import logging


def init_logging(app, logger_name: str):
    # Ensure the logger does not propagate messages to the root logger
    app.logger.propagate = False

    # Retrieve the logger (likely 'gunicorn.error')
    gunicorn_logger = logging.getLogger(logger_name)
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)

    # Make all log formats consistent
    formatter = logging.Formatter(
        "[%(asctime)s] [%(levelname)s] [%(module)s] %(message)s",
        "%Y-%m-%d %H:%M:%S %z"
    )

    # Apply formatter to all handlers
    for handler in app.logger.handlers:
        handler.setFormatter(formatter)
