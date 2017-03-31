from abc import ABCMeta,abstractmethod
import json,os
from urllib.request import urlopen
from urllib.parse import urlencode
from urllib.error import URLError
from geocoding.common import ApiException,GeocodingException
from geocoding.georesult import GeoResult

class BaseGeocoder(metaclass = ABCMeta):

	@abstractmethod
	def geocode(self,fulladdress):
		pass

	@abstractmethod
	def deserialize(self,response):
		pass



class GoogleGeocoder(BaseGeocoder):
	#Maps the api specific address types to common address types as specified by GeoResult instance
	__addresstypesmap = {
		 "street_number" :  "street_number"
		 ,"route" : "route"
		 ,"locality" : "locality"
		 ,"administrative_area_level_1" : "administrative_area1"
		 ,"administrative_area_level_2" : "administrative_area2"
		 ,"administrative_area_level_3" : "administrative_area3"
		 ,"country" : "country"
		 ,"postal_code" : "postal_code"
 	}

	def __init__(self,apiurl,apikey):
		self.url = apiurl
		self.key = apikey

	'''
	def geocodeallstores(self,stores):
		results = {}
		exceptions = {}
		for store in stores:
			try:
				 response = self.geocode(store.fulladdress)
				 results[store.Storekey] = self.gcdr.deserialize(response)
			except:
				exceptions[store.Storekey] = sys.exc_info()[1]			
	'''
	def geocode(self,fulladdress):
		params = urlencode({'address': fulladdress.replace(" ","+"), 'key': self.key})
		try:
			resp = urlopen("%s?%s" %(self.url,params))
			return json.loads(resp.read().decode('utf-8'))
		except URLError as e:
			raise GeocodingException(e.reason)	

	def deserialize(self,response):
		if response['status'] == 'OK':
			addressdetails = response['results'][0]
			addresscomponents = {}
			for addresscomponent in addressdetails["address_components"]:
				for addresstype in [addrtype for addrtype in addresscomponent['types'] if addrtype in self.__class__.__addresstypesmap]:
					addresscomponents[self.__class__.__addresstypesmap[addresstype]] = {'short':addresscomponent['short_name'].replace("'","''"),'long':addresscomponent['long_name'].replace("'","''")}
			georesult = GeoResult()	
			georesult.addresscomponentsbytype =addresscomponents
			georesult.formatted_address = addressdetails["formatted_address"].replace("'","''")
			georesult.location_type = addressdetails["geometry"]["location_type"]
			georesult.latitude = addressdetails["geometry"]["location"]["lat"]
			georesult.longitude = addressdetails["geometry"]["location"]["lng"]
			georesult.status = response['status']
			georesult.partial_match =  addressdetails['partial_match'] if 'partial_match' in addressdetails else None
			georesult.normalizeaddresscomponents()
			return georesult
		else:
			raise ApiException(response['status'],response['error_message'] if 'error_message' in response else None)
