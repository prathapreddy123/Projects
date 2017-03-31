#from distutils.core import setup
from setuptools import setup, find_packages

setup(name='Geocoding',
      version='1.0',
      description='Geocoding Retailer Stores',
      author='prathap reddy',
      author_email='prathap.reddy@retailsolutions.com',
	  url='http;//www.rsi.com',
      #packages=['geocoding','geocoding.common','geocoding.dal'],
	  packages=find_packages(exclude=('tests', 'tests.*')),
	  scripts = [],
	  data_files=[('configurations', ['geocoding/configurations/config.json'])],
	  install_requires=[
		'pyodbc==3.0.10'
	  ]
     )
	 