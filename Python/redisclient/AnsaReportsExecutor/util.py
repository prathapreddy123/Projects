'''
        Date :  06/09/2015
       Author:  prathap.reddy
  Description:  Utility methods
    References: https://docs.python.org/3.3/library/logging.html?highlight=logger
'''

#Python modules
import os
#############################################################  File Operations #######################################################################################
def checkfileexistence(filepath):
    if not os.path.exists(filepath):
        raise IOError("Invalid file Path:",filepath)

def getfilename(filepath,excludeextension=True):
     if excludeextension:
        return os.path.splitext(os.path.split(filepath)[1])[0]
     else:
        return os.path.split(filepath)[1]

def getfiledirectory(filepath):
     return os.path.split(filepath)[0]

def getfileextension(filepath):
     return os.path.splitext(os.path.split(filepath)[1])[1]

if __name__ == "__main__":
    pass