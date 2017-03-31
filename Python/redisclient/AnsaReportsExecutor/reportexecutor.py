'''
        Date :  01/20/2016
       Author:  prathap.reddy
  Description:  Reads messages from redis and invokes the powershell reports
'''

############################################################################ Import modules ############################################################################
import logging, logging.config
import os,sys,json,time
import threading, queue
import redis
import subprocess as sp
import datetime as dt
from collections import defaultdict
#sys.path.append(os.path.join(os.path.abspath(os.path.dirname(__file__)),".."))#sys.path.append("..")
import configurations as cfg


############################################################################ Logging and configuration ############################################################################
def setuplogging(filepath):
    with open(filepath) as logconfig:
            logging.config.dictConfig(json.load(logconfig))

def loadconfigurations(configfilepath):
    Applogger.info("Loading Configurations")
    cfg.Configurations.loadconfigurations(configfilepath)
    #Applogger.info("Printing Configurations")
    #cfg.Configurations.printconfigurations()

############################################################################ Redis ############################################################################
def getconnection(host,port,db):
    """
    Creates the redis connection
    Monitors the redis for items and adds to queue
    :return: redis connection
    """
    return redis.StrictRedis(host=host, port=port, db=db)

def addpendingitemsbacktoredis(connection,listname):
    """
      In case of shut down of the process if there are any pending items that needs to be processed those items will be added back to redis to ensure tthey were not lost
    :return:
    """
    with queuelock:
        Applogger.debug("Adding pending items back to redis")
        while not pendingitems.empty():
            try:
                item = pendingitems.get()
                if item is None:
                    break
                connection.rpush(listname,item)
            except queue.Empty:
                break

def redismonitor():
    try:
        #Global variables
        global shutdownprocess

        #Assign Local Variables from configuration
        listname = cfg.Configurations.getconfigvalue("Redis.Listname",60,"Redis")
        listtimeout = cfg.Configurations.getconfigvalue("Redis.ListTimeoutSec",60,"Redis")
        errorretrycount = int(cfg.Configurations.getconfigvalue("ErrorRetryCount",3))
        errorretryintervalsec = float(cfg.Configurations.getconfigvalue("ErrorRetryintervalSec",5.00))

        #Initialize Local Variables
        errorcount=0

        #Create redis connection and add the subprocess to running list
        connection = getconnection(cfg.Configurations.getconfigvalue("Redis.host",sectionname="Redis"),cfg.Configurations.getconfigvalue("Redis.port",6379,"Redis"),cfg.Configurations.getconfigvalue("Redis.db",0,"Redis"))
        addsubprocess(threading.current_thread().getName())

        #Start monitoring redis
        while True:
            try:
                if shutdownprocess is True: #or counter == 5
                    Applogger.debug("Shutting down redis monitor process")
                    if not pendingitems.empty():
                        addpendingitemsbacktoredis(connection,listname)
                    connection.connection_pool.disconnect()
                    removesubprocess(threading.current_thread().getName())
                    break
                iteminfo = connection.blpop(listname,listtimeout)
                if iteminfo is not None:
                    item = iteminfo[1].decode("utf-8")
                    Applogger.debug("Adding item " + item)
                    #queuelock.acquire()
                    with queuelock:
                        pendingitems.put(item)
                    #queuelock.release()
            except:
                Applogger.error("Error in monitoring redis: {0}".format(sys.exc_info()[1]))
                errorcount = errorcount + 1
                time.sleep(errorretryintervalsec)
                if errorcount >= errorretrycount:
                    shutdownprocess = True
    except:
        Applogger.error("Error in setting up redis monitoring: {0}".format(sys.exc_info()[1]))

############################################################################ Report Invoker & Executor ############################################################################
def getpendingitems():
    itemslist =[]
    while not pendingitems.empty():
        try:
            item = pendingitems.get()
            if item is None:
                break
            itemslist.append(item)
        except queue.Empty:
            break
    return itemslist

def reportexecutor(reportexecutable,filepath,campaigns=None):
    """
    :param reportexecutable: Executable program that runs reports (i.e Powershell.exe, Python.exe)
    :param filepath: Report file path
    :param campaigns: List of campaigns seperated by ,
    :return: none

    Executes the report
    """
    try:
        if campaigns is not None:
            result = sp.check_output([reportexecutable,filepath]) #campaigns
        else:
            result = sp.check_output([reportexecutable,filepath])

        if result is not None:
            Applogger.info("Report: {0} returned {1} ".format(filepath,result.decode("utf-8").replace("\r\n","").strip()))
        #print("Result:" + result)
    except sp.CalledProcessError as ex:
          errormessage = ex.output.decode("utf-8").replace("\r\n","").strip()
          Applogger.error("Error {0} while executing report: {1} ".format(errormessage,filepath))
          #print("Errocode:{0} - Output:{1}".format(ex.returncode,errormessage))

#def executebycampaign(name,campaigns):
 #    print("executebycampaign: {0} - {1} - {2}".format(dt.datetime.today(),name,campaigns))

def reportinvoker():
    """
      Sleep for x sec and check if pendingqueue is not empty and beyond the configured reportinvokerinterval delay
      if yes, move all the pending items to appropriate report lists
      Call the ansa report scheduler
      Call those ansa reports on seperate threads
      wait for the threads to join
   :return:
   """
    try:
        #Global variables
        global shutdownprocess

        #Assign Local Variables from configuration
        reportexecutable = cfg.Configurations.getconfigvalue("ReportExecutable",'powershell.exe')
        reportinvokersleepintervalsec = float(cfg.Configurations.getconfigvalue("ReportInvokerSleepintervalSec",30))
        reportexecutorintervalsec = float(cfg.Configurations.getconfigvalue("ReportExecutorintervalSec",60))
        errorretrycount = int(cfg.Configurations.getconfigvalue("ErrorRetryCount",3))
        errorretryintervalsec = float(cfg.Configurations.getconfigvalue("ErrorRetryintervalSec",5.00))
        reportcodeprogrammap = {}
        reporrtfilepaths = cfg.Configurations.getconfigsection("ReportFilePaths")
        for reportcode in reporrtfilepaths:
            reportcodeprogrammap[str(reportcode).upper()] = reporrtfilepaths[reportcode]

        #Initialize Local Variables
        lastrun = dt.datetime.today()
        errorcount=0
        counter = 0
        inprocesslist = []

        #Add the subprocess to running list
        addsubprocess(threading.current_thread().getName())

        while True:  #counter < 8
            try:
                if shutdownprocess is True: #or counter == 5
                    Applogger.debug("Shutting down report invoker process")
                    removesubprocess(threading.current_thread().getName())
                    break

                if (not pendingitems.empty()) and ((dt.datetime.today() - lastrun).seconds > reportexecutorintervalsec):
                    lastrun = dt.datetime.today()
                    inprocesslist.clear()
                    Applogger.debug("Moving pending items from queue to list")
                    with queuelock:
                        processlist = getpendingitems()
                    #printlist(processlist)

                    #Collect all the campaigns by report
                    reportcodes = defaultdict(list)
                    Applogger.debug("Segregating the items by campaign")
                    for item in processlist:
                        campaignkey,reportcode = str(item).split(sep=".")
                        reportcodes[reportcode].append(campaignkey)

                    #Call the reportscheduler here
                    Applogger.debug("Invoking the report scheduler")
                    reportexecutor(reportexecutable,reportcodeprogrammap["SCH"],"")

                    #Now call the report execuctors in each thread
                    reportthreads = []
                    for reportcode in reportcodes:
                        Applogger.debug("Invoking the report: {0}".format(reportcode))
                        reportthreads.append(threading.Thread(target=reportexecutor,args=(reportexecutable,reportcodeprogrammap[reportcode],",".join(reportcodes[reportcode]))))
                        '''
                        if(reportcode == "ID"):
                         reportthreads.append(threading.Thread(target=bulkexecutor,args=(reportcodeprogrammap[reportcode],",".join(reportcodes[reportcode]))))
                        else:
                         reportthreads.append(threading.Thread(target=executebycampaign,args=("CampaignSetup",",".join(reportcodes[reportcode]))))    #executebycampaign("CampaignSetup",",".join(reportcodes[reportcode]))
                       '''

                    # Start all the threads
                    for t in reportthreads:
                        t.start()

                    # Wait for all threads to complete
                    for t in reportthreads:
                        t.join()
                else:
                    time.sleep(reportinvokersleepintervalsec)  #Wait for some time before next run
            except:
                print(sys.exc_info())
                Applogger.error("Error in invoking reports: {0}".format(sys.exc_info()[1]))
                errorcount = errorcount + 1
                time.sleep(errorretryintervalsec)
                if errorcount >= errorretrycount:
                     shutdownprocess = True
    except:
        Applogger.error("Error in setting up report invoker: {0}".format(sys.exc_info()[1]))

############################################################################ Process management ############################################################################
def shutdownprocesses(source):
    Applogger.info("Initiated Shutdown process %s" %(source))
    global shutdownprocess
    shutdownprocess = True
    shutdownstart = dt.datetime.today()
    shutdowndelayintervalsec = float(cfg.Configurations.getconfigvalue("ShutdowndelayintervalSec",15))
    while len(runningsubprocesses) and ((dt.datetime.today() - shutdownstart).seconds < shutdowndelayintervalsec):
        time.sleep(2)

def addsubprocess(threadname):
    #global runningsubprocesses
    if threadname not in runningsubprocesses:
        runningsubprocesses.append(threadname)
        Applogger.debug("Added subprocess {0} from list of running subprocesses".format(threadname))

def removesubprocess(threadname):
    #global runningsubprocesses
    if threadname in runningsubprocesses:
        runningsubprocesses.remove(threadname)
        Applogger.debug("Removed subprocess {0} from list of running subprocesses".format(threadname))

def createsubprocesses():
    '''
      Creates sub processes
    :return:
    '''
    try:
        #Define global variables
        global runningsubprocesses
        global shutdownprocess
        global queuelock
        global pendingitems

        #Initialize
        runningsubprocesses = []
        queuelock = threading.Lock()
        pendingitems = queue.Queue()
        shutdownprocess = False
        shutdownfilenotifier = cfg.Configurations.getconfigvalue("ShutdownfilePath")
        mainprocesssleepintervalsec = float(cfg.Configurations.getconfigvalue("MainProcessSleepintervalSec",30))

        #Create threads
        redismonitorprocess = threading.Thread(target=redismonitor,name="redismonitor",)
        reportinvokerprocess = threading.Thread(target=reportinvoker,name="reportinvoker",)

        #Start threads
        redismonitorprocess.start()
        time.sleep(0.1)
        reportinvokerprocess.start()

        #Wait to ensure all subprocesses started
        Applogger.info("main thread waiting...")
        time.sleep(2)

        #Wait for termination signal
        while True:
            if os.path.exists(shutdownfilenotifier):
                shutdownprocesses("manually via file")
                os.remove(shutdownfilenotifier)
                break
            else:
                time.sleep(mainprocesssleepintervalsec)
    except KeyboardInterrupt:
        #print('interrupted main thread!')
        shutdownprocesses("manually via keyboard interrupt")
    except:
        Applogger.error("Error while creating subprocesses: {0}".format(sys.exc_info()[1]))

############################################################################ windows service methods ############################################################################
def log(message):
    Applogger.info(message)

def getserviceconfigvalue(configname):
    return cfg.Configurations.getconfigvalue(configname,None,"WindowsService")

############################################################################ main ############################################################################
def bootstrap():
    try:
        configdirectory = os.path.join(os.path.abspath(os.path.dirname(__file__)),"./../Configurations")
        logconfigfilepath = os.path.join(configdirectory,"logconfig.json")
        configfilepath = os.path.join(configdirectory,"configurations.ini")
        setuplogging(logconfigfilepath)
        global Applogger
        Applogger = logging.getLogger("reportexecutor")
        loadconfigurations(configfilepath)
    except:
        print(sys.exc_info()[1])


def main():
    try:
        Applogger.info("Creating Subprocesses")
        createsubprocesses()
    except SystemExit as e:
        pass
    except:
        Applogger.error("Error in main: {0}".format(sys.exc_info()[1]))

if __name__ == "__main__":
    bootstrap()
    main()

'''
def handler(signum, frame):
    print 'I just clicked on CTRL-C '
signal.signal(signal.SIGINT, handler)
'''