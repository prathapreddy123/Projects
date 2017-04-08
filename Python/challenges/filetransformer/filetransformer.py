"""
  This script reads, parses file and checks for data integrity.

  Assumptions:
	File is available atleast with valid header row
	if number of data columns count is less than header column count skip row
	if number of data columns count is more than header column count then consider up to header column count
"""
####################  Import modules #########################
import argparse
import sys
import re
import os

####################  modules level functions#########################
regexes = {
		   "orderiddate": re.compile("^[\w]+:[0-9]+$")  #^(.+):([0-9])+$
		   ,"itemprice" : re.compile("^[0-9]+\.?[0-9]{0,}$")
		   ,"url": re.compile("^http://www.insacart.com.*$")
		  }

def isfilepathsexists(filepaths):
	"""
	summary:  checks filepaths
	:param filepaths: list of tuples - (filetype,filepath)
	:return: list of error messages
	"""
	return ["Invalid {} file path:{}".format(filetype,path) for filetype,path in filepaths if not os.path.exists(path)]

def parseargs():
	"""
	summary: parses command line arguments
	:return: command line arguments
	"""
	parser = argparse.ArgumentParser()  #takes sys.argv as default program
	parser.add_argument('-i', '--inputfilepath', dest='inputfilepath', action='store')
	parser.add_argument('-o', '--outputfilepath', dest='outputfilepath', action='store')
	args = None
	try:
		args = parser.parse_args()

		if args.inputfilepath == None:
			parser.print_help()
			args = None
		if args.outputfilepath == None:
			args.outputfilepath =  os.path.join(os.path.dirname(args.inputfilepath),"outputdata.txt")

	except:
		pass

	return args

####################  class #########################
class Constants(object):
	totalcolumns = 7
	lineseperator ="\n"
	outputheaders = ["order_id", "order_date", "user_id", "Avg_Item_price", "Start_page_url", "Error_msg"]

class FieldNames(object):
	orderiddate = 0
	userid = 1
	Itemprice1 = 2
	Itemprice2 = 3
	Itemprice3 = 4
	Itemprice4 = 5
	url = 6

class OrderDetails(object):
	def readfromfile(self,filepath):
		"""
		summary: Reads data from file
		:param filepath: filepath
		:return: (header,data)
		"""
		try:
			with open(filepath, "rt", encoding="utf8") as fp:
				header = next(fp)
				return(header,fp.readlines())
		except:
			raise

	def checkintegrity(self,headers,datavalues):
		"""
		summary: Validates if there are any violation of business rules
		:param headers: list of headers
		:param datavalues: list of data values
		:return: error values dictionary containing errortype as key and errordata as value.
				errormessages is list of all error messages
		"""
		errorvalues = {}
		errormessages = []

		#Check if any column is missing value.
		errorvalues["missingvalues"] = [headers[index] for index,datavalue in enumerate(datavalues) if len(datavalue) == 0]
		if len(errorvalues["missingvalues"]): errormessages.append("Missing columns:{}".format(",".join(errorvalues["missingvalues"])))

		# Check if the first column is in valid format provided if value is not missing
		if headers[FieldNames.orderiddate] not in errorvalues["missingvalues"] and regexes["orderiddate"].match(datavalues[FieldNames.orderiddate]) == None:   #re.match(".+:.+",fields[0]) prathap
			errorvalues["invalidorderiddate"] ="y"
			errormessages.append("Invalid orderid:orderdate value {}. Expected format is {}".format(datavalues[FieldNames.orderiddate],headers[FieldNames.orderiddate]))

		# Check if any item price columns are missing
		if len([itempriceindex for itempriceindex in range(FieldNames.Itemprice1,(FieldNames.Itemprice4 + 1)) if headers[itempriceindex] in errorvalues["missingvalues"]]):
			errorvalues["missingitemprice"] = "y"
		else:
			# Check if item prices are numeric
			Invaliditemprices = [headers[itempriceindex] for itempriceindex in range(FieldNames.Itemprice1,(FieldNames.Itemprice4 + 1)) if regexes["itemprice"].match(datavalues[itempriceindex]) == None]
			if len(Invaliditemprices):   #if few invalid
				errorvalues["invaliditemprice"] = "y"
				errormessages.append("Invalid item prices in columns {}".format(",".join(Invaliditemprices)))

		#Validate page url if value is not missing
		if headers[FieldNames.url] not in errorvalues["missingvalues"] and regexes["url"].match(datavalues[FieldNames.url]) == None:
			errorvalues["invalidurl"] = "y"
			errormessages.append("Invalid url:{}".format(datavalues[FieldNames.url]))

		return (errorvalues,errormessages)

	def generateoutputrow(self,headers,datavalues,errorvalues,errormessages):
		"""
		summary: Generates output row based on headers and input data value
		:param headers: list of header values
		:param datavalues: list of data values
		:param errorvalues: dictionary of error types and associated values
		:param errormessages: list of error messages
		:return: output row data as list
		"""
		outputrow = []

		#Orderid and orderdate. if column is available and format is correct
		if headers[FieldNames.orderiddate] not in errorvalues["missingvalues"] and "invalidorderiddate" not in errorvalues:
			outputrow.extend(datavalues[FieldNames.orderiddate].split(":"))
		else:
			outputrow.extend(["",""])

		#userid
		outputrow.append(datavalues[FieldNames.userid])

		# Avg Item price
		if "missingitemprice" not in errorvalues and "invaliditemprice" not in errorvalues:
			itemprices = list(map(lambda itemprice:float(itemprice),datavalues[FieldNames.Itemprice1:FieldNames.Itemprice4 + 1])) #change data type
			nonzeroitemprices = list(filter(lambda itemprice:itemprice > 0, itemprices)) #filter for non zero values
			avgprice = round(sum(nonzeroitemprices)/len(nonzeroitemprices),3) if nonzeroitemprices else 0 #find average price
			outputrow.append(str(avgprice))
		else:
			outputrow.append("")

		#url
		if "invalidurl" not in errorvalues:
			outputrow.append(datavalues[FieldNames.url])
		else:
			outputrow.append("")

		#errormessage
		outputrow.append(";".join(errormessages))
		return outputrow

	def parsedata(self,header,data,seperator="\t"):
		"""
		summary:  parses data row by row
		:param header: header value
		:param data: list of data rows
		:return: list of output rows
		"""
		try:
				headerfields =  header.strip(Constants.lineseperator).split(seperator)
				outputdata = []
				for row in data:
					row = row.strip(Constants.lineseperator)
					datavalues = row.split(seperator)
					if len(datavalues) < Constants.totalcolumns: continue
					errorvalues, errormessages = self.checkintegrity(headerfields,datavalues[:Constants.totalcolumns])
					outputdata.append(self.generateoutputrow(headerfields,datavalues,errorvalues, errormessages))
				return outputdata
		except:
			raise

	def writetofile(self,headers,data,filepath,seperator="\t"):
		"""
		summary: Writes data to file
		:param headers: list of headers
		:param data: list of data values
		:param filepath: filepath
		:param seperator: field seperator
		:return: None
		"""
		try:
			with open(filepath,"w",encoding="utf8") as fp:
				fp.write(seperator.join(headers) + Constants.lineseperator)
				for row in data:
					fp.write(seperator.join(row) + Constants.lineseperator)
		except:
			raise

	def transformfile(self,inputfilepath,outputfilepath):
		"""
		summary: driver function that invokes other functions
		:param inputfilepath: input file path
		:param outputfilepath: output file path
		"""
		header, datavalues = self.readfromfile(inputfilepath)
		outputdata = self.parsedata(header, datavalues)
		self.writetofile(Constants.outputheaders, outputdata,outputfilepath)
		print("File generated successfully and available in path: {} ".format(outputfilepath))

################### Script main ##############################
def main():
	try:
		arguments = parseargs()
		if arguments != None:
			errormessages = isfilepathsexists([('input',arguments.inputfilepath),('output',os.path.dirname(arguments.outputfilepath))])
			if errormessages:
				raise IOError(Constants.lineseperator.join(errormessages))
			OrderDetails().transformfile(arguments.inputfilepath,arguments.outputfilepath)
	except:
		print(sys.exc_info()[1])

if __name__ == "__main__":
	main()
