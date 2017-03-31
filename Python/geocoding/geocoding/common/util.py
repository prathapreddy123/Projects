import os
############################ File Operations ##################################
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