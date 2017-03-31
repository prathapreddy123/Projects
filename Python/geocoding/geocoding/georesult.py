from datetime import datetime

class GeoResult(object):
	__validaddresstypes = ['street_number','route','locality','administrative_area1','administrative_area2','administrative_area3','country','postal_code']

	def __init__(self):
		self.formatted_address = None
		self.latitude = None
		self.longitude = None
		self.addresscomponentsbytype={}
		self.addresscomponents={}
		self.location_type = None
		self.status = None
		self.partial_match = None
		self.UpdatedBy = 'sys'
		self.UpdatedOn = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

	@classmethod
	def getvalidaddresstypes(cls):
		return cls.__validaddresstypes

	def normalizeaddresscomponents(self):
		for addresstype in GeoResult.__validaddresstypes:
			if addresstype in self.addresscomponentsbytype:
				self.addresscomponents[addresstype + "_short"] = self.addresscomponentsbytype[addresstype]['short']
				self.addresscomponents[addresstype + "_long"] = self.addresscomponentsbytype[addresstype]['long']
			else:
				self.addresscomponents[addresstype + "_short"] = None
				self.addresscomponents[addresstype + "_long"] = None
