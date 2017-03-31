'''
        Date :  05/10/2016
       Author:  prathap.reddy
       Description:  Creates connection, executes queries and closes connection
'''

#Python modules
import pyodbc

#Application modules
from geocoding.common import UnsupportedObjectCreation


class Database(object):
    '''
       This class contains all the methods required to interact with underlying dbms system
    '''
    def __init__(self,connectionparams):
        self.connectionstring = self.__getconnectionstring(connectionparams)
        self.isconnectionopen = False
        self.dbtransaction = False

    def __enter__(self):
        self.openconnection(self.dbtransaction)
        return self

    def opentransaction(self):
        self.dbtransaction = True
        return self

    def openconnection(self,dbtransaction=False):
        self.dbtransaction = dbtransaction
        #print(format("In DB openconnection method: Connectionstring - %s ; Transaction - %s " %(self.connectionstring,self.dbtransaction)))
        if(dbtransaction):
            self.connection = pyodbc.connect(self.connectionstring)
            #print("using transaction")
        else:
            self.connection = pyodbc.connect(self.connectionstring,autocommit=True)
        self.isconnectionopen = True

    #private method
    def __checkconnectionstatus(self):
        closeconnection = False
        if(self.isconnectionopen == False):
            self.openconnection()
            closeconnection = True
        return closeconnection

    def fetchrecord(self,query,paramvalues=None):
        closeconnection = self.__checkconnectionstatus()
        if paramvalues == None:
            record = self.connection.cursor().execute(query).fetchone()
        else:
            record = self.connection.cursor().execute(query,paramvalues).fetchone()
        if(closeconnection):self.closeconnection()
        return record

    def fetchrecords(self,query,paramvalues=None):
        closeconnection = self.__checkconnectionstatus()
        if paramvalues == None:
            records = self.connection.cursor().execute(query).fetchall()
        else:
            records = self.connection.cursor().execute(query,paramvalues).fetchall()
        if(closeconnection):self.closeconnection()
        return records

    def executequery(self,query,paramvalues=None):
        closeconnection = self.__checkconnectionstatus()
        if paramvalues == None:
            impactedrows = self.connection.cursor().execute(query).rowcount
        else:
            impactedrows = self.connection.cursor().execute(query,paramvalues).rowcount
        if(closeconnection):self.closeconnection()
        return impactedrows

    def executebulkchanges(self,query,data):
        if(not isinstance(data,list)):
            raise TypeError("Invalid argument. Expected type is list and supplied type is %s" %(type(data).__name__))
        closeconnection = self.__checkconnectionstatus()
        self.connection.cursor().executemany(query,data)
        if(closeconnection):self.closeconnection()

    def fetchtotable(self,datatable,query,paramvalues=None):
        datatable.addrows(self.fetchrecords(query,paramvalues))
        #return datatable

    def fetchtomap(self,query,paramvalues=None):
        records = self.fetchrecords(query,paramvalues)
        if len(records):
            if len(records[0]) !=2: raise ValueError("Query must contain only 2 columns to generate map")
            return { record[0]:record[1] for record in records }
        return {}

    def closeconnection(self):
        #print("In DB closeconnection method")
        if(self.isconnectionopen):
            self.connection.close()
            self.isconnectionopen = False

    def commit(self):
        #print("Commit connection")
        self.connection.commit()

    def rollback(self):
        #print("rollback connection")
        self.connection.rollback()

    def __exit__(self, type, value, traceback):
        #print("In DB Exit method")
        if type != None:  #In case of exception if there is a transaction roll back the transaction and close the connection
           if self.dbtransaction: self.rollback()
           self.closeconnection()
           raise ValueError(value)
        else:
           if self.dbtransaction: self.commit()
           self.closeconnection()

    @staticmethod
    def __getconnectionstring(connectionparams):
        '''
         Does not depend on state

        :param connectionparams: List of connection parameters
        :return: connectionstring
        '''
        if 'dsn' in connectionparams:
            return r'dsn={};UID={};PWD={}'.format(connectionparams["dsn"],connectionparams["userid"],connectionparams["password"])
        else:
            return r'DRIVER={};SERVER={};Database={};UID={};PWD={}'.format(connectionparams["driver"],connectionparams["server"]
                                        ,connectionparams["database"],connectionparams["userid"],connectionparams["password"])





class DBManager(object):
    __dbinstance = None

    def __init__(self):
        raise UnsupportedObjectCreation('DBManager')

    @classmethod
    def createinstance(cls,connectionparams):
        if cls.__dbinstance == None:
            cls.__dbinstance = Database(connectionparams)
        
    
    @classmethod
    def ansadb(cls,dbtransaction=False):
        cls.__dbinstance.dbtransaction = dbtransaction
        return cls.__dbinstance
