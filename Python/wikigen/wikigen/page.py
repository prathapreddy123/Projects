########### Import Application Modules  ###############
from wikigen.core import ( Constants,PlaceHolderTypes,Logger
				  ,PageException
				 )
import wikigen.placeholders as ph


class PageData(object):
	""" Represents all the information required for creation of confluence page"""
	def __init__(self,pagedetails):
		self.type = pagedetails["type"]
		self.title = pagedetails["title"]
		self.space = {"key": pagedetails["space.key"]}
		self.body = {"storage": {"representation":"storage","value":pagedetails["body"]} }
		self.version = {"number": 1 }
		if pagedetails["parent.title"] != "":
			self.ancestors = [{ "id": -1,"title": pagedetails["parent.title"]}]

	"""
		def tojson(self):
			print("called tojson")
			return self.__dict__
    """

class Page(object):

	def __init__(self,configurations):
		self.requiredfields =  set(configurations.getconfigvalue("datapage.requiredfields"))
		self.requiredplaceholdertypes =  set(configurations.getconfigvalue("datapage.requiredplaceholdertypes"))

	def parse_validate(self,pagedetails):
		try:
			exceptionmessages=[]
			Logger.info("Checks whether requiredfields are present in data file")
			if not self.requiredfields.issubset(pagedetails.keys()):
				exceptionmessages.append("Page data file is missing one or more fields. Required fields are: {}".format(",".join(self.requiredfields)))
			
				
			Logger.info("Checks whether valid placeholder types are provided in data file")
			invalidplaceholdertypes = [placeholdertype for placeholdertype in self.requiredplaceholdertypes  \
								  if placeholdertype not in PlaceHolderTypes.getvalues()]
			if len(invalidplaceholdertypes):
				exceptionmessages.append("Invalid placeholder type(s) {}. Supported placeholder types are: {}" \
									 .format(",".join(invalidplaceholdertypes), ",".join(PlaceHolderTypes.getvalues())))
			
			Logger.info("Checks whether required placeholder types are provided in data file")	
			missingplaceholdertypes = [placeholdertype for placeholdertype in self.requiredplaceholdertypes \
								  if placeholdertype not in pagedetails[Constants.PLACEHOLDERKEY].keys()]
			if len(missingplaceholdertypes):
				exceptionmessages.append("Page data file is missing {} placeholder type(s)." \
									.format(",".join(missingplaceholdertypes)))

			if len(exceptionmessages):
				raise PageException("\n".join(exceptionmessages))

			#Validtae schema of each placeholder	
			for  placehodertype in pagedetails[Constants.PLACEHOLDERKEY].keys():
					placeholder = ph.get_instance(placehodertype)
					Logger.info("Validating schema of placeholder type: %s", placehodertype)	
					placeholder.checkschema(pagedetails[Constants.PLACEHOLDERKEY][placehodertype])
		except:
			raise

	
	def merge(self,template,pageplaceholders):
		"""	
		 For each placeholder type:
		  Create Instance of Placeholder type
		  Merge the template with corresponding placeholder values
		 return page
		"""
		currentpage = template
		
		for  placehodertype in pageplaceholders.keys():
				placeholder = ph.get_instance(placehodertype)
				Logger.info("Merging %s data with currentpage", placehodertype)	
				currentpage = placeholder.merge(currentpage,pageplaceholders[placehodertype])

		return currentpage

	def create_pagedata_instance(self,pagedetails):
		""" creates an instance of pagedata and returns object """
		return PageData(pagedetails)
