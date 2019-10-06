import argparse
from wikigen import __version__,__program__
import keyring
import getpass

def parseargs():
  """
    Creates or updates confluence web page
    
    usage: wikigen [-h] [-t {create,update}] [-p PASSWORD] -d
                            DATAFILE [-v]

    optional arguments:
    -h, --help            show this help message and exit
    -t {create,update}, --task {create,update}
                          specifies whether new confluence page needs to be
                          created or an existing page to be updated
    -p PASSWORD, --pwd PASSWORD
                          LDAP Password to access confluence web
    -d DATAFILE, --datafile DATAFILE
                          json file containing page details
    -v, --version         Version info

"""
  parser = argparse.ArgumentParser(prog=__program__)  #takes sys.argv as default program
  
  #parser.add_argument('-h', '--help', help="usage info")
  
  parser.add_argument('-t', '--task', dest='task', type = str, action='store', 
                       default = 'create', required=False, choices=['create', 'update','delete'],
                       help=(" specifies whether new confluence page needs to be created "
                             "or an existing page to be updated")
                     )

  parser.add_argument('-u', '--user', dest='user', type = str, action='store',
                      required=False, default =  getpass.getuser(), help = "LDAP user to access confluence web" )

  parser.add_argument('-p', '--pwd', dest='password', type = str, action='store',
                      required=False, help = "LDAP Password to access confluence web" )


  parser.add_argument("-d", "--datafile",  type = str, action='store', required = True 
                       ,help="json file containing page details", default="page1.json")
                      

  parser.add_argument("-v", "--version", action='version', help="Version info"
                      ,version='%(prog)s {version}'.format(version = __version__)
                     )
                      
                     
  try:
    args = parser.parse_args()
    #keyring.delete_password(__program__,getpass.getuser())
    #return
    """
      User can either supply password or system can use the initial password
      provided by the user during the first run from key ring.
      if none of the password exists then prompt for password.


      The Python keyring lib provides an easy way to access the system keyring service from python. 
      It can be used in any application that needs safe password storage
      Refer https://pypi.python.org/pypi/keyring 
    """
    if args.password is None:
      if keyring.get_password(__program__,getpass.getuser()) is not None:
          args.password =   keyring.get_password(__program__,getpass.getuser())
      else:
          args.password = getpass.getpass(prompt='Enter your ldap password:')
          keyring.set_password(__program__,getpass.getuser(), args.password)
    else:
          keyring.set_password(__program__,getpass.getuser(), args.password)
    
    return args
  
  except:
    raise


