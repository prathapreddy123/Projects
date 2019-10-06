from __future__ import absolute_import

########### Import Python Modules  ###############
import sys
import os
import datetime
import time
import re
import string

#Include project directory in search path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__),os.path.pardir)))

########## Import Application Modules  ###############


from wikigen.core import ( Constants,SerializationTypes, PlaceHolderTypes, ApplicationException
				  ,Logger,ConfigManager, util
				  ,deserialize_fromfile,serialize
			      )
from wikigen import __program__,bootstrap
from wikigen.cli import parseargs
from wikigen.page import Page
from wikigen.confluenceapi import ConfluenceApi


########## Module Classes  ###############
class HyperlinkTemplate(string.Template):
  """Subclass of Template to match custom pattern
      Refer: https://pymotw.com/2/string/
  """
  delimiter = '%'
  pattern = r'''
    \%(?:
    (?P<escaped>\%)|
    (?P<named>[\w\.\-\s]+->[\S]+)\%|
    (?P<braced>[\w\.\-\s]+->[\S]+)\%|
    (?P<invalid>)
    )
    '''

########## Module functions  ###############

def load_templatefile():
	""" Loads HTML template  file"""
	try:
		filepath = util.joinpath(ConfigManager.getconfigvalue("templates.directory").replace("~",Constants.ROOTPATH), \
								 ConfigManager.getconfigvalue("templatefile"))
		Logger.info("Template file path: {}".format(filepath))
		return util.read_file(filepath)
	except ApplicationException as e:
		raise ApplicationException("Error while loading template file: {}".format(e.msg))

def validate_template(template):
	""" TODO: Validate against HTMP parser """
	pass

def load_datafile(datafilename):
	""" Loads data file containing data to create/update confluence page"""
	try:
		filepath = util.joinpath(ConfigManager.getconfigvalue("pages.directory").replace("~",Constants.ROOTPATH), \
								 datafilename)
		Logger.info("Data file path: {}".format(filepath))
		return deserialize_fromfile(filepath)
	except ApplicationException as e:
		raise ApplicationException("Error while loading data file: {}".format(e.msg))


def extractlinks(pagebody,regexpattern,startdelimiter="%",enddelimiter="%"):
	hyperlinks ={}
	for linkgroup in re.findall(regexpattern, pagebody):
		actualtext = linkgroup.replace(startdelimiter,"").replace(enddelimiter,"")
		text,link = actualtext.split("->")
		hyperlinks[actualtext] = "<a href=\"{link}\">{text}</a>".format(link=link,text=text)
	return hyperlinks

def publish(pagedata,userargs):
	"""
		Create HttpRequest Object
		Call's Confluence Rest api to publish the page
	"""
	try:
		baseurl = ConfigManager.getconfigvalue("baseurl")
		htpprequest = ConfluenceApi.createrequest(url = baseurl)
		htpprequest.certificate = ConfigManager.getconfigvalue("sslcertificate")
		htpprequest.addheaders(headers = ConfigManager.getconfigvalue("httprequest.headers"))
		htpprequest.addbasicauthentication(userargs.user,userargs.password)

		confluenceapi = ConfluenceApi(htpprequest)
		doaction = {
					 'create': getattr(confluenceapi,"createpage")
					,'update' : getattr(confluenceapi,"updatepage")
					,'delete' : getattr(confluenceapi,"deletepage")
				   }.get(userargs.task)
		doaction(pagedata)
		displayurl = confluenceapi.getdisplayurl(baseurl,pagedata.space["key"],pagedata.title)
		print("Successfully {task}d wiki page.Refer url:{url}".format(task = userargs.task,url=displayurl))
	except:
		raise


def main():
	"""
		Driver program performing end to end operations
	"""
	cliargs = parseargs()

	try:

		bootstrap.start(__program__)

		Logger.info("Loading Template file")

		template = load_templatefile()

		Logger.info("Validate template file syntax")
		validate_template(template)

		Logger.info("Loading data file")
		pagedetails = load_datafile(cliargs.datafile)

		Logger.info("Validate data file against set of specifications")
		page = Page(ConfigManager.getconfigurations())
		page.parse_validate(pagedetails)

		Logger.info("Merge template with page data")
		pagebody = page.merge(template,pagedetails[Constants.PLACEHOLDERKEY])

		Logger.debug("pagebody:\n %s", pagebody)
		Logger.info("Extracting hyperlinks")
		hyperlinks = extractlinks(pagebody,ConfigManager.getconfigvalue("hyperlink.regexpattern"))
		if hyperlinks:
			Logger.info("Substituing hyperlinks:%s", hyperlinks)
			pagebody = HyperlinkTemplate(pagebody).safe_substitute(hyperlinks)
			Logger.debug("pagebody:\n %s", pagebody)

		pagedetails["body"] = pagebody

		Logger.info("Create page data instance")
		pagedata = page.create_pagedata_instance(pagedetails)

		Logger.info("Publish page to  wiki")
		publish(pagedata,cliargs)


	except Exception as e:
		Logger.error(sys.exc_info()[1])
		print(sys.exc_info()[1])
		sys.exit(1)


if __name__ == "__main__":
	main()