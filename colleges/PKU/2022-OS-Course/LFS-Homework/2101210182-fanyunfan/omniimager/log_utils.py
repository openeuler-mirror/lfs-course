import logging
import logging.handlers
import os
import time

LOG_LEVEL_DICT = {
    'CRITICAL': logging.CRITICAL,
    'FATAL': logging.FATAL,
    'ERROR': logging.ERROR,
    'WARNING': logging.WARNING,
    'WARN': logging.WARN,
    'INFO': logging.INFO,
    'DEBUG': logging.DEBUG
}
DEFAULT_LOG_DIR = '/var/log/omni-imager'
DEFAULT_LOG_LEVEL = 'DEBUG'


class LogUtils(logging.Logger):

    def __init__(self, name, config_options):
        super().__init__(name)
        log_level = config_options.get('log_level', DEFAULT_LOG_LEVEL)
        if log_level in LOG_LEVEL_DICT.keys():
            log_level = LOG_LEVEL_DICT.get(log_level)
        else:
            log_level = LOG_LEVEL_DICT.get(DEFAULT_LOG_LEVEL)
        log_dir = config_options.get('log_dir', DEFAULT_LOG_DIR)
        if not (os.path.exists(log_dir) and os.path.isdir(log_dir)):
            os.makedirs(log_dir)

        date = time.strftime("%Y-%m-%d", time.localtime())
        logfile_name = f'{date}.log'
        logfile_path = os.path.join(log_dir, logfile_name)
        rotating_file_handler = logging.handlers.RotatingFileHandler(filename=logfile_path,
                                                                     maxBytes=1024 * 1024 * 50,
                                                                     backupCount=5)
        formatter = logging.Formatter('[%(asctime)s][%(levelname)s][%(filename)s:%(lineno)s]%(message)s',
                                      '%Y-%m-%d %H:%M:%S')
        rotating_file_handler.setFormatter(formatter)

        console = logging.StreamHandler()
        console.setLevel(log_level)
        console.setFormatter(formatter)
        self.addHandler(rotating_file_handler)
        self.addHandler(console)
        self.setLevel(log_level)
