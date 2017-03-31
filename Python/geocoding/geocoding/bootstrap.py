import os
import sys
import json
from geocoding.common import Logger,util
from geocoding.dal import DBManager

def start(logfilename,loggername='app'):
    '''
     Sets up logging
     Creates database instance
    '''
    try:
        configdirectory =os.path.abspath(os.path.join(os.path.dirname(__file__),"./configurations"))
        with open(os.path.join(configdirectory,"config.json")) as configfile:
            config = json.load(configfile)

        for filehandler in ["log_file_handler","error_file_handler"]:   
            config["log"]["handlers"][filehandler]["filename"] =  config["log"]["handlers"][filehandler]["filename"].format(filename=logfilename)

        Logger.intialize(config['log'],loggername)
        config['database']['password'] = util.decrypt(config['database']['password'])
        DBManager.createinstance(config['database'])
    except:
        raise