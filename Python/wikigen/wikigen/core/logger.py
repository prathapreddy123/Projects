import logging
import logging.config

from   .exceptions import ApplicationException,UnsupportedObjectCreation 

class Logger(object):
	__Applogger = None

	def __init__(self):
		raise UnsupportedObjectCreation(self.__class__.__name__)

	@classmethod
	def intialize(cls,logcofig,loggername):
		if not cls.__Applogger:
			logging.config.dictConfig(logcofig)
			cls.__Applogger = logging.getLogger(loggername)
		else:
			raise ApplicationException("Logger is already initialized.")

	#This method is mainly used by the test code to inject mock logger
	@classmethod			
	def setlogger(cls,loggerinstance):
		if not cls.__Applogger:
			cls.__Applogger = loggerinstance
		else:
			raise ApplicationException("Logger is already initialized.")

	@classmethod
	def info(cls,msg,*args,**kwargs):
		cls.__Applogger.info(msg,*args,**kwargs)


	@classmethod
	def debug(cls,msg,*args,**kwargs):
		cls.__Applogger.debug(msg,*args,**kwargs)

	@classmethod
	def error(cls,msg,*args,**kwargs):
		cls.__Applogger.error(msg,*args,**kwargs)