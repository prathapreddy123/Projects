from abc import ABCMeta,abstractmethod
import json

from .exceptions import ApplicationException 
from .util  import getfileextension,read_file
from .constants import SerializationTypes

#################### Module functions ####################   
def getinstance(serdetype):
	""" Creates are returns appropriate serialization object based on serdetype"""
	if serdetype in SerializationTypes.getvalues():
		return {
				 "json" : JsonSerDe()
				,"yaml" : YamlSerDe()
  			   }.get(serdetype)
	raise ApplicationException("Serialization is not supported for {} type".format(serdetype))


def serialize(instance,serdetype):
	try:
		serdeinstance = getinstance(serdetype)
		return serdeinstance.serialize(instance)
	except:
		raise 	


def deserialize(content,serdetype):
	try:
		serdeinstance = getinstance(serdetype)
		return serdeinstance.deserialize(content)
	except:
		raise 	


def __getserdetype_byfileextension(fileextension):
		if fileextension in ["json","avsc"]:
			return "json"
		elif fileextension == "yaml":
			return "yaml"	
		else:
			raise ApplicationException("Serialization is not supported for files of {} type".format(serdetype))

def deserialize_fromfile(filepath):
	try:
		serdetype = __getserdetype_byfileextension(getfileextension(filepath)[1:])
		data = read_file(filepath)
		return deserialize(data,serdetype)
	except:
		raise 	


#################### Module classes #################### 
class BaseSerDe(metaclass = ABCMeta):

	@abstractmethod
	def serialize(self,instance):
		pass

	@abstractmethod
	def deserialize(self,content):
		pass


class JsonSerDe(BaseSerDe):
	""" Serialzes and Deserializes JSON content """

	def serialize(self,instance):
		if isinstance(instance,dict):
			return json.dumps(instance)
		elif hasattr(instance,"tojson"):
			return json.dumps(instance.tojson())
		else: 
			return json.dumps(instance.__dict__)


	def deserialize(self,content):
		return json.loads(content)


class YamlSerDe(BaseSerDe):
	""" Serialzes and Deserializes Yaml content """

	def serialize(self,instance):
		raise ApplicationException("Yaml Serialization is currently not supported")

	def deserialize(self,content):
		raise ApplicationException("Yaml DeSerialization is currently not supported")