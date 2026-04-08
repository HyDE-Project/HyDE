import logging
import os
import sys


_VALID_LEVELS = {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}


def get_logger():
    """Get a unified logger instance based on the environment variable LOG_LEVEL."""
    log_level = os.getenv("LOG_LEVEL")
    if not log_level:

        class NoOpLogger:
            def __getattr__(self, name):
                def no_op(*args, **kwargs):
                    pass

                return no_op

            def get_logger_type(self):
                return "NoOpLogger"

        return NoOpLogger()

    log_level = log_level.upper()
    if log_level not in _VALID_LEVELS:
        log_level = "INFO"

    # Prefer loguru when available; otherwise fall back to stdlib logging.
    try:
        from loguru import logger as loguru_logger

        loguru_logger.remove()
        loguru_logger.add(sys.stderr, level=log_level)
        log = loguru_logger
        logger_type = "loguru"
    except ImportError:
        logging.basicConfig(level=getattr(logging, log_level))
        log = logging.getLogger("hyde")
        logger_type = "logging"

    class UnifiedLogger:
        def __init__(self, logger, logger_type):
            self.logger = logger
            self.logger_type = logger_type
            self.use_loguru = logger_type == "loguru"

        def _log(self, level: str, msg, *args, **kwargs):
            method = getattr(self.logger, level)
            if self.use_loguru:
                # Keep loguru behavior stable by emitting a pre-formatted message.
                if args or kwargs:
                    msg = msg.format(*args, **kwargs)
                method(msg)
                return
            method(msg, *args, **kwargs)

        def debug(self, msg, *args, **kwargs):
            self._log("debug", msg, *args, **kwargs)

        def info(self, msg, *args, **kwargs):
            self._log("info", msg, *args, **kwargs)

        def warning(self, msg, *args, **kwargs):
            self._log("warning", msg, *args, **kwargs)

        def error(self, msg, *args, **kwargs):
            self._log("error", msg, *args, **kwargs)

        def critical(self, msg, *args, **kwargs):
            self._log("critical", msg, *args, **kwargs)

        def get_logger_type(self):
            return self.logger_type

    return UnifiedLogger(log, logger_type)
