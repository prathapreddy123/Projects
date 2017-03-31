from abc import ABCMeta,abstractmethod
from datetime import datetime
from geocoding.dal import DBManager

class BaseDataWriter(metaclass = ABCMeta):

	@abstractmethod
	def updatestores(self,geocodedstores):
		pass


class DBDataWriter(BaseDataWriter):

	def updatestores(self,geocodedstores):
		queries = []
		for storekey,geodata in geocodedstores.items():
			queries.append("""UPDATE dsd.StoreGeocode 
		 				  SET formatted_address = '{}',street_number_short = '{}',street_number_long = '{}',route_short = '{}', route_long = '{}',locality_short = '{}',locality_long = '{}'
   						  ,adm_area1_short = '{}', adm_area1_long = '{}',adm_area2_short = '{}', adm_area2_long = '{}',adm_area3_short = '{}', adm_area3_long = '{}',country_short = '{}', country_long = '{}'
   						  , postal_code_short = '{}',postal_code_long = '{}', location_type = '{}', partial_match = '{}', latitude = '{}', longitude = '{}', [status] = '{}',UpdatedBy = '{}', UpdatedOn = '{}' 
   						  WHERE DigStoreKey = {}""".format(geodata.formatted_address,geodata.addresscomponents['street_number_short'],geodata.addresscomponents['street_number_long']
   						  ,geodata.addresscomponents['route_short'],geodata.addresscomponents['route_long'],geodata.addresscomponents['locality_short'],geodata.addresscomponents['locality_long']
   						  ,geodata.addresscomponents['administrative_area1_short'],geodata.addresscomponents['administrative_area1_long'],geodata.addresscomponents['administrative_area2_short']
   						  ,geodata.addresscomponents['administrative_area2_long'],geodata.addresscomponents['administrative_area3_short'],geodata.addresscomponents['administrative_area3_long']
   						  ,geodata.addresscomponents['country_short'],geodata.addresscomponents['country_long'],geodata.addresscomponents['postal_code_short'],geodata.addresscomponents['postal_code_long']
   						  ,geodata.location_type,geodata.partial_match,geodata.latitude,geodata.longitude,geodata.status,geodata.UpdatedBy,geodata.UpdatedOn,storekey).replace('\'None\'','null')
					  )
		DBManager.ansadb().executequery(";".join(queries))