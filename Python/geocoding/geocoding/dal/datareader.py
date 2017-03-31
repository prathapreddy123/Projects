from abc import ABCMeta,abstractmethod
from geocoding.dal import DBManager,DataTable


class BaseDataReader(metaclass = ABCMeta):

	@abstractmethod
	def getstores(self):
		pass


class DBDataReader(BaseDataReader):

	def getconfigurations(self):
		return DBManager.ansadb().fetchtomap("""SELECT configname,configvalue
							   							 FROM dsd.Configurations 
							   							 WHERE configname IN ('Geocode.url','Geocode.apikey','Geocode.batchsize')""")

	def getstores(self):
		storestbl = DataTable( "Stores", "Storekey,Fulladdress" ) #takes name of the class and column names 	
		DBManager.ansadb().fetchtotable(storestbl,"""SELECT TOP (2400) G.DigStoreKey, 
										(Street + ' ,  ' + ISNULL(CITY,'') + '  , ' + ISNULL(State,'') + '  '  +
 										CASE When ZIP  IS NULL OR ZIP ='00000' OR ZIP ='99999' THEN '' WHEN LEN(ZIP) < 5 THEN REPLICATE('0', 5 - LEN(ZIP)) + ZIP
 										ELSE ZIP END
										) AS FULL_ADDRESS
										FROM DSD.StoreGeocode G
										JOIN DSD.DimStore S On G.DigStoreKey = S.DigStoreKey
										JOIN DSD.DimRetailer R On S.DigRetailerKey = R.DigRetailerkey
										WHERE latitude IS NULL AND Street IS NOT NULL AND UpdatedBy <> 'MAN'  AND R.DigRetailerName <> 'TESCO'
										""")
		return storestbl