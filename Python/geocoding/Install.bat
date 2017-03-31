SET Pythonpath=D:\Digital\Python\DigitalVEnv3432\scripts
SET Installdir=D:\digital\Python\DigitalVEnv3432\Geocoding
%Pythonpath%\python setup.py install --install-purelib=%Installdir%  --install-scripts=%Installdir%  --install-data=%Installdir%/geocoding
REM %Virtualenv%\Scripts\python setup.py install --home=%Installdir%  --install-purelib=%Installdir%  --install-scripts=%Installdir%  --install-data=%Installdir%/geocoding
