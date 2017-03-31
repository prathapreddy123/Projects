from geocoding.common.exceptions import GeocodingException,UnsupportedObjectCreation 
import logging
import logging.config


class Logger(object):
	__Applogger = None

	def __init__(self):
		raise UnsupportedObjectCreation("Logger"
        )

	@classmethod
	def intialize(cls,logcofig,loggername):
		if not cls.__Applogger:
			logging.config.dictConfig(logcofig)
			cls.__Applogger = logging.getLogger(loggername)
		else:
			raise GeocodingException("Logger is already initialized.")

	
	#This method is mainly used by the test code to inject mock logger
	@classmethod			
	def setlogger(cls,loggerinstance):
		if not cls.__Applogger:
			cls.__Applogger = loggerinstance
		else:
			raise GeocodingException("Logger is already initialized.")

	@classmethod
	def info(cls,msg):
		cls.__Applogger.info(msg)


	@classmethod
	def debug(cls,msg):
		cls.__Applogger.debug(msg)

	@classmethod
	def error(cls,msg):
		cls.__Applogger.error(msg)