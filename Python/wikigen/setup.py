#from distutils.core import setup
from setuptools import setup, find_packages

#from distgradle import GradleDistribution

setup(name='wikigen',
      version='0.1',
      description='Automation of Confluence Wiki Generation',
      author='prathap reddy',
      author_email='',
      url='https://github.com/prathapreddy123/Projects',
      #packages=['package1','package1.subpackage'],
      packages=find_packages(exclude=('test', 'test.*')),
      include_package_data=True,
      data_files=[('conf', ['conf/appconf.json', 'conf/userconf.json']),
                  ('resources/templates', ['resources/templates/dataservices.html']),
                  ('resources/pages', ['resources/pages/dim_os_agent_demo.json']),
                  ('resources/avro', ['resources/avro/dim_os_agent_demo.avsc'])
                ],
      scripts = [],
      entry_points={
        'console_scripts': ['wikigen=wikigen.main:main']
      },
      python_requires='>=3.3',
      install_requires=[
      'keyring==11.0.0',
      'urllib3==1.25',
      'requests==2.20.0'
      ],
      classifiers=[
          "Development Status :: Alpha",
          "Intended Audience :: Developers",
          "License :: Apache License",
          "Programming Language :: Python :: >=3.3",
      ]
  )

'''
setuptools.setup(
    distclass=GradleDistribution,
    package_dir={'': 'src'},
    packages=setuptools.find_packages('src'),
    include_package_data=True,
    entry_points={
        'console_scripts': [
            'wikigen = wikigen.main:main',
        ],
    },
)
'''