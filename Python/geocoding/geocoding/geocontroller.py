from geocoding.geocoder import BaseGeocoder
import geocoding.common as cmn
import geocoding.dal as dal
import sys

class GeoController(object):
	def __init__(self,datareader,geocoder,datawriter):
		#for param in [(datareader,dal.BaseDataReader,"datareader","BaseDataReader"),(geocoder,BaseGeoCoder,"geocoder","BaseGeoCoder"),(datawriter,dal.BaseDataWriter,"datawriter","BaseDataWriter")]:
		for param in [(datareader,dal.BaseDataReader,"datareader"),(geocoder,BaseGeocoder,"geocoder"),(datawriter,dal.BaseDataWriter,"datawriter")]:
			cmn.util.checkisvalidinstances(param[0],param[1],param[2])

		self.dtrdr = datareader
		self.gcdr = geocoder
		self.dtwtr = datawriter

	def process(self):
		results = {}
		exceptions = {}
		batchsize = int(cmn.configmanager.ConfigManager.getconfigvalue('Geocode.batchsize',100))
		iterator = 0
		for store in self.dtrdr.getstores():  #tblstores.rows
			try:
				#call geocoding api 
				cmn.Logger.debug("Processing Store:{0}".format(store.Storekey))
				response = self.gcdr.geocode(store.Fulladdress)  #store.Storekey
				#parse the result
				results[store.Storekey] = self.gcdr.deserialize(response)
				iterator += 1
				if  iterator == batchsize:
					self.dtwtr.updatestores(results)
					cmn.Logger.info("Completed updating batch")
					results.clear()
					iterator = 0
			except cmn.ApiException as e:
				if e.reason == "OVER_QUERY_LIMIT": 
					cmn.Logger.info("Exceeded Query Limit")
					break
				exceptions[store.Storekey] = str(e)
			except cmn.GeocodingException as e:
				exceptions[store.Storekey] = str(e)
			except:
				exceptions[store.Storekey] = sys.exc_info()[1]
		
		#Update last batch in case exists
		if len(results): self.dtwtr.updatestores(results) 
		if len(exceptions): raise cmn.GeocodingException("\n".join(["StoreKey:{}-{}".format(s,r) for s,r in exceptions.items()]))