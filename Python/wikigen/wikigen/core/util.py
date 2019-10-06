import os
import json

from .exceptions import ApplicationException
############################ File Operations ##################################

def isfullpath(path):
    """Checks whether the file path is full path or only the filename """
    return path.find("/") != -1


def isfileexists(filepath):
    """Checks whether the file exists or not """
    return os.path.exists(filepath)

def isvalidpath(filepath):
    if not os.path.exists(filepath):
        raise IOError("Invalid file Path:",filepath)

def joinpath(path1,path2):
    return os.path.join(path1,path2)

def getfilename(filepath,excludeextension=True):
     if excludeextension:
        return os.path.splitext(os.path.split(filepath)[1])[0]
     else:
        return os.path.split(filepath)[1]

def read_file(filepath,encoding="utf-8"):
    """ Read file from file system """
    try:
        if isfileexists(filepath):
            with open(filepath,"r",encoding=encoding) as fp:
                return fp.read()
        else:
            raise ApplicationException("{} does not exists".format(filepath))
    except ApplicationException as e:
        raise 
    except Exception as e:
        raise

def createdirectory(filepath):
    #check if parent path exists
    isvalidpath(os.path.dirname(filepath))
    #if directory already doesn't exists then create directory     return path.find("/") != -1:
    if not os.path.exists(filepath):
        os.mkdir(filepath)

def getfiledirectory(filepath):
     return os.path.split(filepath)[0]

def getfileextension(filepath):
     return os.path.splitext(os.path.split(filepath)[1])[1]

def pprint(data):
    #Pretty prints json data.
    print(json.dumps(
        data,
        sort_keys = True,
        indent = 4,
        separators = (', ', ' : ')))
'''
######################### Crypto Operations ##################################
from Crypto.Cipher import AES
import base64
# the character used for padding--with a block cipher such as AES, the value
# you encrypt must be a multiple of BLOCK_SIZE in length.  This character is
# used to ensure that your value is always a multiple of BLOCK_SIZE
PADDING = '{'
BLOCK_SIZE = 16

def decrypt(value):
    # generate a random secret key
    secret = '{random{random{{'
    # create a cipher object using the random secret
    cipher = AES.new(secret)
    #return cipher.decrypt(base64.b64decode(value)).decode().rstrip(PADDING) 
    return cipher.decrypt(base64.b64decode(value)).decode().rstrip(PADDING) 


######################### Class Operations ##################################
from geocoding.common.exceptions import GeocodingException
def checkisvalidinstances(instance,instancetype,instancename):
		if not isinstance(instance,instancetype):
			raise GeocodingException("Invalid instance type. {0} must be an instance of type derived from {1}".format(instancename,instancetype.__name__))     


'''