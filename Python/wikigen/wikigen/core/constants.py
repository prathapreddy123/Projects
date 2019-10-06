
import os

from .exceptions import UnsupportedObjectCreation 

class Constants(object):
	""" Contains all constant values"""

	#Avoids creations of instance accidentally
	def __init__(self):
		raise UnsupportedObjectCreation(self.__class__.__name__) 

	PLACEHOLDERKEY = "placeholders"

	#Paths
	ROOTPATH = os.path.abspath(os.path.join(os.path.dirname(__file__),"./../.."))

	CONF_DIRECTORY= os.path.join(ROOTPATH,"conf")

	APP_CONF_FILEPATH = os.path.join(CONF_DIRECTORY,"appconf.json")

	USER_CONF_FILEPATH = os.path.join(CONF_DIRECTORY,"userconf.json")


class PlaceHolderTypes(object):

	TEXT =  "text"
	TABLE =  "table"
	AVROTABLE =  "avrotable"
	JSONFIELD =  "jsonfield"

	#Avoids creations of instance accidentally
	def __init__(self):
		raise UnsupportedObjectCreation(self.__class__.__name__) 

	@classmethod
	def getvalues(cls):
		return [cls.TEXT,cls.TABLE,cls.AVROTABLE,cls.JSONFIELD]


class SerializationTypes(object):
	
	JSON =  "json"
	YAML =  "yaml"

	#Avoids creations of instance accidentally
	def __init__(self):
		raise UnsupportedObjectCreation(self.__class__.__name__) 

	@classmethod
	def getvalues(cls):
		return [cls.JSON,cls.YAML]
