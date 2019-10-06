from .exceptions import UnsupportedObjectCreation,ApplicationException

class Configurations(dict):
     def getconfigvalue(self,configname,defaultvalue=None):
        try:
            return self[configname]
        except KeyError:
            if defaultvalue is not None:
                return defaultvalue    
            else:
                raise  ApplicationException("configuration {} is missing in user configuration file".format(configname)) 
        

class ConfigManager(object):
    __configurations = Configurations()

    def __init__(self):
        raise UnsupportedObjectCreation(self.__class__.__name__)

    @classmethod
    def loadconfigurations(cls,appconfig,userconfig=None):
        #Load only once
        if len(cls.__configurations.keys()) == 0:
             cls.__configurations.update(appconfig)
             if userconfig is not None:
                cls.__configurations.update(userconfig)
        else:
            raise ApplicationException("configurations were already loaded and cannot be modified") 
    
    @classmethod
    def getconfigurations(cls):
        return cls.__configurations

    @classmethod
    def getconfigvalue(cls,configname,defaultvalue=None):
        return  cls.__configurations.getconfigvalue(configname) 