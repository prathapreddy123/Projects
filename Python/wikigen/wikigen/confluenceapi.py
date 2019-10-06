import requests
from urllib.parse import urlencode

from wikigen.core import (Logger,PageException,ApiException
							  ,serialize,SerializationTypes)

class HttpRequest(object):

	def __init__(self,url):
		self.url = url
		self.authentication = None
		self.certificate = None
		self.headers = {} 

	def addheader(self,name, value):
		self.headers[name] =  value

	def addheaders(self,headers):
		self.headers.update(headers)
	
	def addbasicauthentication(self,username,password):
		self.authentication = (username,password)


class ConfluenceApi(object):

	def __init__(self,httprequest):
		self.httprequest = httprequest
	
	@staticmethod
	def createrequest(url):
		return HttpRequest(url)

	"""	
	def get_page_ancestors(self,pagedata):

    # Get basic page information plus the ancestors property

    url = '{base}/{pageid}?expand=ancestors'.format(
        base = BASE_URL,
        pageid = pageid)

    r = requests.get(url, auth = auth)

    r.raise_for_status()

    return r.json()['ancestors']
    """

	def __getpage(self,spacekey,title,expand="",type="page"):
		"""
		expand:  specifies additional information to be fetched in a single call. 
				 fields can be specified in comma seperated list. for e.g if we need
				 version , history, ancestors information in same call specift
				 expand as version,ancestors,history
		"""
		fullurl = "{baseurl}?{params}".format(baseurl = self.httprequest.url, \
				 	params =urlencode({"spaceKey": spacekey,"title": title,"expand":expand})
				    )	
		Logger.info("Fetching page %s", fullurl)
		r = requests.get(fullurl,headers = self.httprequest.headers, auth=self.httprequest.authentication, \
						 verify=self.httprequest.certificate)
		
		r.raise_for_status()
		response = r.json()
		if len(response["results"]) == 0:
				raise PageException("{type} {url} not found".format(type=type,url=self.getdisplayurl(self.httprequest.url,spacekey,title)))
		return response["results"][0]

	def getdisplayurl(self,baseurl,spacekey,title):
		return "{baseurl}/{spacekey}/{title}".format(
					  baseurl = baseurl.replace("rest/api/content/","display")
                     ,spacekey = spacekey
                     ,title = title
			    	)

	def __addancestor(self,pagedata):
		Logger.info("Fetching ancestor page")
		pageinfo = self.__getpage(pagedata.space["key"],pagedata.ancestors[0]["title"],type="Parent page")
		pagedata.ancestors[0]["id"] = pageinfo["id"]
		
	def createpage(self,pagedata):
		try:
			Logger.info("Creating wiki page %s", self.httprequest.url)
			if hasattr(pagedata,"ancestors"):
				self.__addancestor(pagedata)
			payload = serialize(pagedata,SerializationTypes.JSON)
			Logger.debug("Payload: %s", payload)
			r = requests.post(self.httprequest.url,headers = self.httprequest.headers, \
						 auth=self.httprequest.authentication, \
						 verify=self.httprequest.certificate,  data= payload)
			r.raise_for_status()
		except requests.HTTPError as httperror:
			raise ApiException(httperror)

	def updatepage(self,pagedata):
		try:
			pageinfo = self.__getpage(pagedata.space["key"],pagedata.title,expand="version,ancestors")
			'''
			ancestors = pageinfo["ancestors"][-1]
			del anc['_links']
	  	    del anc['_expandable']
	    	del anc['extensions']
			'''
			pagedata.version["number"] = int(pageinfo["version"]["number"]) + 1
			url = "{base}{pageid}".format(base= self.httprequest.url,pageid=pageinfo["id"])
			Logger.info("Updating wiki page %s with new version id: %d", url,pagedata.version["number"])
			payload = serialize(pagedata,SerializationTypes.JSON)
			Logger.debug("Payload: %s", payload)
			r = requests.put(url,headers = self.httprequest.headers, \
							 auth=self.httprequest.authentication, \
							 verify=self.httprequest.certificate,  data=payload)
			r.raise_for_status()
		except requests.HTTPError as httperror:
			raise ApiException(httperror)

	def deletepage(self,pagedata):
		try:
			pageinfo = self.__getpage(pagedata.space["key"],pagedata.title)
			url = "{base}{pageid}".format(base= self.httprequest.url,pageid=pageinfo["id"])
			Logger.info("Deleting wiki page %s", url)
			r = requests.delete(url,headers = self.httprequest.headers, \
							 auth=self.httprequest.authentication,verify=self.httprequest.certificate)
			r.raise_for_status()
		except requests.HTTPError as httperror:
			raise ApiException(httperror)
