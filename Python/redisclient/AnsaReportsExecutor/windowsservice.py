'''
        Date :  01/20/2016
       Author:  prathap.reddy
  Description:  Windows service hosting ansareportsexecutor
'''

############################################################################ Import modules ############################################################################
import win32serviceutil
import win32service
import win32event
import servicemanager
#import socket
#import sys
import reportexecutor as rptexc

class anasreportsservice(win32serviceutil.ServiceFramework):
    """
      Calls the bootstrap tos et up logging and loading configurations
      Sets the service name,display name and description
      Starts the service calling main
      On Stop of the service calls the shutdown process
    """
    rptexc.bootstrap()
    rptexc.log("Reading windows service configurations")
    _svc_name_ = rptexc.getserviceconfigvalue("servicename")
    _svc_display_name_ = rptexc.getserviceconfigvalue("servicedisplayname")
    _svc_description_ = rptexc.getserviceconfigvalue("servicedescription")

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        # create an event that SvcDoRun can wait on and SvcStop can set.
        self.stop_event = win32event.CreateEvent(None, 0, 0, None)

    def SvcDoRun(self):
        servicemanager.LogMsg(servicemanager.EVENTLOG_INFORMATION_TYPE,servicemanager.PYS_SERVICE_STARTED,(self._svc_name_,''))
        rptexc.main()

    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        #win32event.SetEvent(self.stop_event)
        rptexc.shutdownprocesses("Windows Service")
        self.ReportServiceStatus(win32service.SERVICE_STOPPED)
        #sys.exit()

if __name__ == '__main__':
    win32serviceutil.HandleCommandLine(anasreportsservice)

'''
python anasreportsservice.py install
python anasreportsservice.py start
python anasreportsservice.py stop
python anasreportsservice.py remove
'''