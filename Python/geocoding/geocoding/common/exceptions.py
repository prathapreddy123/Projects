
class GeocodingException(Exception):

  def __init__(self,msg):
    self.msg = msg

  def __str__(self):
    return "Exception:Type-{0};Message-{1}".format(self.__class__.__name__,self.msg)

class UnsupportedObjectCreation(GeocodingException):

	def __init__(self, typename):
		super().__init__("Cannot create instance." + typename + " supports only class methods")

class ApiException(GeocodingException):
	def __init__(self,reason,errordetails):
		self.reason = reason
		self.errordetails = errordetails or "NA"
	
	def __str__(self):
   		return "ErrorReason-{0};ErrorDetails-{1}".format(self.reason,self.errordetails)
