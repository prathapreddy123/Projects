########### Import Python Modules  ###############
from abc import ABCMeta,abstractmethod
import string


########### Import Application Modules  ###############
from wikigen.core import ( Logger,ConfigManager,Constants,PlaceHolderTypes
				   ,util,PageException,util,deserialize_fromfile
				  )	
from wikigen.json2html import Json2Html


########### Module Functions  ###############
def get_instance(placeholdertype):
	"""Returns appropriate placeholder instance based on placeholdertype"""
	return {
		       PlaceHolderTypes.TEXT : TextPlaceHolder(ConfigManager.getconfigurations())
			 , PlaceHolderTypes.TABLE : TablePlaceHolder(ConfigManager.getconfigurations())
             , PlaceHolderTypes.AVROTABLE : AvroTablePlaceHolder(ConfigManager.getconfigurations())
             , PlaceHolderTypes.JSONFIELD : JsonFieldPlaceHolder(ConfigManager.getconfigurations())
			}.get(placeholdertype)


class ConfluencePageTemplate(string.Template):
	"""Subclass of Template to match custom pattern
		
	    Refer: https://pymotw.com/2/string/ 	
	"""
	delimiter = '{{'
	pattern = r'''
    \{\{(?:
    (?P<escaped>\{\{)|
    (?P<named>[_a-z][_a-z0-9]*)\}\}|
    (?P<braced>[_a-z][_a-z0-9-\s]*)\}\}|
    (?P<invalid>)
    )
    '''


class HyperlinkTemplate(string.Template):
	"""Subclass of Template to match custom pattern
		
	    Refer: https://pymotw.com/2/string/ 	
	"""
	delimiter = '%'
	pattern = r'''
    \%(?:
    (?P<escaped>\%)|
    (?P<named>[_a-z][_a-z0-9]*)\%|
    (?P<braced>[_a-z][_a-z0-9-\s]*)\}\}|
    (?P<invalid>)
    )
    '''


class BasePlaceHolder(metaclass = ABCMeta):

	def __init__(self,configurations):
		self.configurations = configurations

	@abstractmethod
	def checkschema(self,placeholderinfo):
		pass

	@abstractmethod
	def merge(self,source,placeholderinfo):
		pass

	def checkifplaceholderexists(self,source,placeholder):
		if source.find(placeholder) == -1:
				raise PageException(placeholder + " not found in template file" )


class TextPlaceHolder(BasePlaceHolder):

	def checkschema(self,placeholderinfo):
		pass


	def merge(self,source,placeholderinfo):
		if bool(placeholderinfo): #data exists
			Logger.info("Substituting %s based on text fields mapping" , placeholderinfo)	
			return ConfluencePageTemplate(source).safe_substitute(placeholderinfo)

		return source


class TablePlaceHolder(BasePlaceHolder):

	def checkschema(self,placeholderinfo):
		pass


	def merge(self,source,tableplaceholders):
		"""
		For each table placeholder object 
		  1.Check if template tag exists
		  2.Construct html table 

		Substitute html tables in place of placeholder tags inside template	
		"""
		try:
			if len(tableplaceholders) == 0:
				return source

			htmltablestrings = {}
			for tableplaceholder in tableplaceholders:
				super(TablePlaceHolder,self).checkifplaceholderexists(source,"{{" + tableplaceholder["name"] + "}}")
				
				Logger.info("Generating table for %s" , tableplaceholder["name"])
				htmltable = "<table"
				if "class" in tableplaceholder:
					htmltable += " class=\"{}\"".format(tableplaceholder["class"])

				if "style" in tableplaceholder:
					htmltable += " style=\"{}\"".format(tableplaceholder["style"])
				
				htmltable += ">\n"  

				if "colgroup" in tableplaceholder:
					Logger.info("Constructing colgroup tags")
					colgroup="<colgroup>"
					for column in tableplaceholder["colgroup"]:
						colgroup += "\n<col{}/>".format(" ".join([" {}=\"{}\"".format(k,v) for k, v in column.items()]))
					htmltable +=  colgroup + "\n</colgroup>"

				htmltable += "\n<thead>\n<tr><th>" + "</th><th>".join(tableplaceholder["colheaders"]) + "</th></tr></thead>\n<tbody>"

				#Construct data rows
				htmltable += "\n".join(["<tr><td>{}</td></tr>".format("</td><td>".join(row)) for row in tableplaceholder["rows"]])
			
				htmltable += "\n</tbody></table>"
				Logger.info("%s -> %s",tableplaceholder["name"],htmltable)
				htmltablestrings[tableplaceholder["name"]] = htmltable#.replace("\n","")

			return ConfluencePageTemplate(source).safe_substitute(htmltablestrings) 
		except:
			raise


class AvroTablePlaceHolder(BasePlaceHolder):

	def checkschema(self,placeholderinfo):
		pass


	def merge(self,source,avrotableplaceholders):
		"""
		 For each avro table placeholder object 
		  1.Check if template tag exists
		  2.Construct html table 

		 Substitute html tables in place of placeholder tags inside template	
		"""
		try:
			if len(avrotableplaceholders) == 0:
				return source

			htmltablestrings = {}
			#directory = self.configurations.getconfigvalue("avrofiles.directory").replace("~",Constants.ROOTPATH)
			json2html = Json2Html()
		
			for avrotableplaceholder in avrotableplaceholders:
				tableplaceholdername = avrotableplaceholder["name"]
				super(AvroTablePlaceHolder,self).checkifplaceholderexists(source,"{{" + tableplaceholdername + "}}")

				filepath = avrotableplaceholder["filepath"]
				util.isvalidpath(filepath)
				Logger.info("Generating table for %s based on file %s" , tableplaceholdername,filepath)
				avrodetails = deserialize_fromfile(filepath)	

				#if table needs to be constucted from certain key
				if "start.key" in avrotableplaceholder and avrotableplaceholder["start.key"] in avrodetails:
					avrodetails = avrodetails[avrotableplaceholder["start.key"]]
				
				tableattributes = ""
				if "class" in avrotableplaceholder:
					tableattributes += " class=\"{}\"".format(avrotableplaceholder["class"])

				if "style" in avrotableplaceholder:
					tableattributes += " style=\"{}\"".format(avrotableplaceholder["style"])
				
				if "colgroup" in avrotableplaceholder:
					Logger.info("Constructing colgroup tags")
					colgroup="<colgroup>"
					for column in avrotableplaceholder["colgroup"]:
						colgroup += "\n<col{}/>".format(" ".join([" {}=\"{}\"".format(k,v) for k, v in column.items()]))
					colgroup =  colgroup + "\n</colgroup>"


				extrargs = {} #"equalheaders" : True

				if "customheaders" in avrotableplaceholder:
					extrargs["customheaders"]  =  avrotableplaceholder["customheaders"]

				nestedtable_layout = "vertical" if "nestedtable.layout" not in avrotableplaceholder else avrotableplaceholder["nestedtable.layout"]
				
				Logger.info("Converting file to table for %s",tableplaceholdername)
				htmltable = json2html.convert(json = avrodetails, \
											  table_attributes = tableattributes, \
											  nestedtable_layout = nestedtable_layout, \
											  optionalargs = extrargs)
				Logger.info("%s -> %s",tableplaceholdername,htmltable)
				htmltablestrings[avrotableplaceholder["name"]] = htmltable#.replace("\n","")

			return ConfluencePageTemplate(source).safe_substitute(htmltablestrings) 
		except:
			raise


class JsonFieldPlaceHolder(BasePlaceHolder):

	def checkschema(self,placeholderinfo):
		pass


	def merge(self,source,jsonfieldplaceholders):
		"""
		 For each json field placeholder object 
		  1.Check if template tag exists
		  2.Substitute the placeholder with text in the corresponding json field
		"""
		try:
			if len(jsonfieldplaceholders) == 0:
				return source

			jsonfieldvalues = {}
			#directory = self.configurations.getconfigvalue("avrofiles.directory").replace("~",Constants.ROOTPATH)
			for jsonfieldplaceholder in jsonfieldplaceholders:
				#filepath = util.joinpath(directory,jsonfieldplaceholder["filename"])
				filepath = jsonfieldplaceholder["filepath"]
				util.isvalidpath(filepath)
				jsondata = deserialize_fromfile(filepath)
				
				#Iterate through mapping (dict) provided. Each item has template Placeholder name as key and json property name as value 
				for placeholdername in jsonfieldplaceholder["fieldmap"].keys():
					super(JsonFieldPlaceHolder,self).checkifplaceholderexists(source,"{{" + placeholdername + "}}")
					jsonpropertyname = jsonfieldplaceholder["fieldmap"][placeholdername]
					if not jsonpropertyname in jsondata:
						raise PageException("{} is not a valid propertyname in {} file".format(jsonpropertyname,filepath))
					if not isinstance(jsondata[jsonpropertyname],str):
						raise PageException("value of {} property should be text type. Lists, objects and other types are not supported".format(jsonpropertyname))
					Logger.debug("Substituting %s based on %s field in file %s" , placeholdername,jsonpropertyname,filepath)
					jsonfieldvalues[placeholdername] = jsondata[jsonpropertyname]

			if bool(jsonfieldvalues):  #data exists
				Logger.info("Substituting %s based on json fields" , jsonfieldvalues)
				return ConfluencePageTemplate(source).safe_substitute(jsonfieldvalues) 
			
			return source
		except:
			raise
