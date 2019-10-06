
class ApplicationException(Exception):

  def __init__(self,msg):
    self.msg = msg

  def __str__(self):
    return "Exception:Type-{0};Message-{1}".format(self.__class__.__name__,self.msg)


class UnsupportedObjectCreation(ApplicationException):

	def __init__(self, typename):
		super().__init__("Cannot create instance." + typename + "class supports only class/static methods")


class PageException(ApplicationException):
	def __init__(self, msg):
		super().__init__(msg)

class ApiException(ApplicationException):
	def __init__(self,httperror):
		#response = httperror.response.json()
		#self.statuscode = response["statusCode"]
		#self.message = response["message"]
		self.statuscode = httperror.response.status_code
		self.message = str(httperror).replace(str(self.statuscode),"")
	
	def __str__(self):
   		return "statuscode-{0};message-{1}".format(self.statuscode,self.message)
