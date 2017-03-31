'''
        Date :  01/20/2016
       Author:  prathap.reddy
  Description:  Reads Configurations information from ini file
  References: https://docs.python.org/3.3/library/configparser.html
'''

import configparser
import os
#from AnsaReportsExecutor import util
import util
#Application modules

class Configurations():
    __configurations = None   #Private class level variable

    @classmethod
    def setconfigurations(cls,configurations):
        cls.__configurations = configurations

    @classmethod
    def loadconfigurations(cls,configfilepath):  #
        util.checkfileexistence(os.path.abspath(configfilepath))
        cls.__configurations = configparser.ConfigParser()  #returns an isntance of configparser
        cls.__configurations.read(configfilepath)

    @classmethod
    def getconfigurations(cls):
        return cls.__configurations

    @classmethod
    def getconfigvalue(cls,configname,defaultvalue="None",sectionname="Global"):
        try:
            return cls.__configurations[sectionname][configname]
        except:
            return defaultvalue

    @classmethod
    def getconfigsection(cls,sectionname):
        try:
            return cls.__configurations[sectionname]

        except:
            return defaultvalue
    @classmethod
    def printconfigurations(cls):
        if cls.__configurations is not  None:
            for section in cls.__configurations.sections():
                print("\r\nSection:%s\r\n------------------------" %(section))
                for k,v in cls.__configurations[section].items():
                    print("Name:%s - Value:%s" %(k,v))
        else:
            print("configuration data must be loaded prior to printing")

if __name__ == "__main__":
    pass