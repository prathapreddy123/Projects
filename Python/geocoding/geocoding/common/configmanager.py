from geocoding.common import UnsupportedObjectCreation
from geocoding.dal import BaseDataReader
from geocoding.common import util

class ConfigManager(object):
    __configurations = None

    def __init__(self):
        raise UnsupportedObjectCreation('ConfigManager')

    @classmethod
    def loadconfigurations(cls,configreader):
        if cls.__configurations == None:
            util.checkisvalidinstances(configreader,BaseDataReader,"configreader")
            cls.__configurations = configreader.getconfigurations()
        
    
    @classmethod
    def getconfigurations(cls):
        return cls.__configurations

    @classmethod
    def getconfigvalue(cls,configname,defaultvalue=None):
        try:
            return cls.__configurations[configname]
        except KeyError:
            return defaultvalue      
        except:
            raise