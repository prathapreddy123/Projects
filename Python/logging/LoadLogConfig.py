__author__ = 'prathap.reddy'

'''
Code in this module demonstrates how to perform logging using python standard logging module called logging.It demonstrates various techniques:
a) No external config -> can be used simple one time script
b)External ini config file
c)External json config file -  dictionary approach
d)External yaml config file - dictionary approach

References:
https://docs.python.org/2/howto/logging.html#configuring-logging-for-a-library
http://victorlin.me/posts/2012/08/26/good-logging-practice-in-python

https://docs.python.org/3.3/library/logging.html?highlight=logging#module-logging
https://docs.python.org/3.3/library/logging.config.html#module-logging.config
'''
import logging
import logging.config
import json
import os
import yaml

#inside code (without any external configurations)
def logdemo_noexternal_configfile():
    # create logger
    #logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)

    # create console handler and set level to debug
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)

    # create formatter and add formatter to handler
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)

    # add ch to logger
    logger.addHandler(ch)

    # 'application' code
    logger.debug('debug message')
    logger.info('info message')
    logger.warn('warn message')
    logger.error('error message')
    logger.critical('critical message')

#from .ini file
def logdemo_external_iniconfigfile():
    logging.config.fileConfig('logconfig.ini')
    # create logger
    logger = logging.getLogger('iniconfig')

    # 'application' code
    logger.debug('debug message')
    logger.info('info message')
    logger.warn('warn message')
    logger.error('error message')
    logger.critical('critical message')

#from .json file
def logdemo_external_jsonconfigfile(default_configfilepath='logconfig.json',default_level=logging.INFO,env_key='LOG_CFG'):
    """Setup logging configuration"""
    path = default_path
    value = os.getenv(env_key, None) #longconfig file path can be read from an environment variable
    if value:
        path = value
    if os.path.exists(path):
        with open(path, 'rt') as f:
            config = json.load(f)
        logging.config.dictConfig(config)
    else:
        logging.basicConfig(level=default_level)

#from .yaml file
def logdemo_external_yamlconfigfile(default_configfilepath='logconfig.yaml',default_level=logging.INFO,env_key='LOG_CFG'):
    """Setup logging configuration"""
    path = default_path
    value = os.getenv(env_key, None) #longconfig file path can be read from an environment variable
    if value:
        path = value
    if os.path.exists(path):
        with open(path, 'rt') as f:
            config = yaml.load(f)
        logging.config.dictConfig(config)
    else:
        logging.basicConfig(level=default_level)