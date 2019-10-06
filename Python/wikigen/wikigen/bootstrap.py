from wikigen.core import (Constants,Logger,util, 
                  ConfigManager,deserialize_fromfile
                  )

import os

def start(logfilename,loggername='app'):
    '''
     Sets up logging instance based on log configuration
     Creates configration instance based on config files 
    '''
    try:

        appconfig = deserialize_fromfile(Constants.APP_CONF_FILEPATH)
  
        #check if log file path specified in conf. If not then set relative to current root    
        if appconfig["log"]["handlers"]["log_file_handler"]["filename"].startswith("{"):
            logdir = os.path.join(Constants.ROOTPATH,"logs")
            util.createdirectory(logdir)
            
             #For all filehandlers append log directory and substitute filename as programname
            for filehandler in appconfig["log"]["loggers"][loggername]["handlers"]:   
                appconfig["log"]["handlers"][filehandler]["filename"] = \
                os.path.join(logdir,appconfig["log"]["handlers"][filehandler]["filename"].format(filename = logfilename))
        
        Logger.intialize(appconfig['log'],loggername)
        

        Logger.info("Loading user configurations")
        if  util.isfileexists(Constants.USER_CONF_FILEPATH):
            userconfig = deserialize_fromfile(Constants.USER_CONF_FILEPATH)
            ConfigManager.loadconfigurations(appconfig,userconfig)
        else:   
            ConfigManager.loadconfigurations(appconfig)
    except:
        raise