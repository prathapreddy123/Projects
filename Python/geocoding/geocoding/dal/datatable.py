from collections import namedtuple
import csv

'''
        Date :  05/12/2016
       Author:  prathap.reddy
       Description: Creates a table with set of columns and rows.  Capable to iterate 
'''

class DataTable(object):

	def __init__(self,tabename,columns):
		self.__table = namedtuple(tabename, columns) #takes name of the table and columns names
		self.__rows= []
		self.__columns = columns.split(",")
		self.__rowpos = 0
		
	def addrow(self,rowvalues):
		if type(rowvalues) == list:
			self.__rows.append(self.__table._make(rowvalues))
		elif type(rowvalues) == dict:
			self.__rows.append(self.__table._make([rowvalues[column] for column in self.__columns]))
		else:
			raise ValueError("Invalid row type. row type must be either list/dict")

	def __addlistrows(self,rows):
		for row in rows:
			self.__rows.append(self.__table._make(row))

	def __adddictrows(self,rows):
		for row in rows:
			self.__rows.append(self.__table._make([row[column] for column in self.__columns]))

	def __addpyodbcrows(self,rows):
		for row in rows:
			self.__rows.append(self.__table._make([colvalue for colvalue in row]))

	def addrows(self,rows):
		if len(rows) == 0: return
		rowtype = type(rows[0])
		if str(rowtype) =="<class 'pyodbc.Row'>":
			self.__addpyodbcrows(rows)
		elif rowtype == list:
			self.__addlistrows(rows)
		elif rowtype == dict:
			self.__adddictrows(rows)
		else:
			raise ValueError("Invalid row type. row type must be either list/dict/pydobc.row")

	def __iter__(self):
		"""
		Returns itself as an iterator
		"""
		return self

	def __next__(self):
		"""
		Returns the next row in the sequence or raises StopIteration
		"""
		if self.__rowpos >= len(self.__rows):
			raise StopIteration

		row = self.__rows[self.__rowpos]
		self.__rowpos += 1
		return row


	@property	
	def rows(self):
		return  self.__rows

	@property	
	def rowsasdict(self):
		return [row._asdict() for row in self.__rows]
		
	@property	
	def columns(self):
		return self.__columns
	
	def printrows(self):
		for row in self.__rows:
			dictrow = row._asdict()
			for col in dictrow.keys():			
				 print("{0}:{1}".format(col,dictrow[col]))	

	def newrow(self,filltype="name"):
		return {column:None for column in self.__columns} if  filltype == "name" else [None] * len(self.__columns)

	def __exporttodelimitedfile(self,filename,delimiter):
		with open(filename,"w",newline="") as target:
			writer= csv.DictWriter( target, self.__columns,delimiter=delimiter,  quoting=csv.QUOTE_ALL )
			writer.writeheader()
			writer.writerows(self.rowsasdict)

	def exporttocsv(self,filename):
		self.__exporttodelimitedfile(filename,",")
   
	def exporttopsv(self,filename):
		self.__exporttodelimitedfile(filename,"|")

	def exporttotsv(self,filename):
		self.__exporttodelimitedfile(filename,"\t")