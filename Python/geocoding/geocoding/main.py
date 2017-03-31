#Python modues
import sys,os
import time,datetime
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__),os.path.pardir)))  #Include project directory in search path

#Application modules
from geocoding.common.configmanager import ConfigManager
from geocoding.geocoder import GoogleGeocoder
from geocoding.geocontroller import GeoController 
from geocoding import bootstrap
import geocoding.common as cmn
import geocoding.dal as dal


def main():
	bootstrap.start('geocoding') #cmn.util.getfilename(__file__)
	
	try:
		reader = dal.DBDataReader()
		cmn.Logger.info("Loading Configurations")
		ConfigManager.loadconfigurations(reader)
		cmn.Logger.info("Creating GeoController instance")
		controller = GeoController(reader,GoogleGeocoder(ConfigManager.getconfigvalue('Geocode.url'),ConfigManager.getconfigvalue('Geocode.apikey')),dal.DBDataWriter()) 
		cmn.Logger.info("Processing the stores")
		controller.process()
		return
	except cmn.GeocodingException as ge:
		cmn.Logger.error(ge)
	except:
		cmn.Logger.error(sys.exc_info())
	
	print('Error occurred while processing. Refer log file for more details')
	sys.exit(1)

if __name__ == "__main__":
	main()   