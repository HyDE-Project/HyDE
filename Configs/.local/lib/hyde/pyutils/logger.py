import os
import sys
import importlib

lib_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, lib_dir)

import pip_env  # noqa: E402


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

    # Dynamically import logging or loguru
    try:
        log = importlib.import_module("loguru")
        log.logger.remove()
        log.logger.add(sys.stderr, level=log_level)
        logger_type = "loguru"
    except ModuleNotFoundError:
        try:
            pip_env.v_import("loguru")
            log = importlib.import_module("loguru")
            log.logger.remove()
            log.logger.add(sys.stderr, level=log_level)
            logger_type = "loguru"
        except ImportError:
            import logging as log

            log.basicConfig(level=getattr(log, log_level))
            logger_type = "logging"

    class UnifiedLogger:
        def __init__(self, logger, logger_type):
            self.logger = logger
            self.logger_type = logger_type

        def debug(self, msg, *args, **kwargs):
            if hasattr(self.logger, "logger"):
                self.logger.logger.debug(msg, *args, **kwargs)
            else:
                self.logger.debug(msg, *args, **kwargs)

        def info(self, msg, *args, **kwargs):
            if hasattr(self.logger, "logger"):
                self.logger.logger.info(msg, *args, **kwargs)
            else:
                self.logger.info(msg, *args, **kwargs)

        def warning(self, msg, *args, **kwargs):
            if hasattr(self.logger, "logger"):
                self.logger.logger.warning(msg, *args, **kwargs)
            else:
                self.logger.warning(msg, *args, **kwargs)

        def error(self, msg, *args, **kwargs):
            if hasattr(self.logger, "logger"):
                self.logger.logger.error(msg, *args, **kwargs)
            else:
                self.logger.error(msg, *args, **kwargs)

        def critical(self, msg, *args, **kwargs):
            if hasattr(self.logger, "logger"):
                self.logger.logger.critical(msg, *args, **kwargs)
            else:
                self.logger.critical(msg, *args, **kwargs)

        def get_logger_type(self):
            return self.logger_type

    return UnifiedLogger(log, logger_type)
