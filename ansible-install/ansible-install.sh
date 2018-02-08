yum groupinstall "Development tools" -y
yum install python-setuptools python-devel
tar xzvf pip-9.0.1.tar.gz
cd pip-9.0.1
python setup.py install
cd ..
pip install --no-index --find-links . ansible==2.2.0.0

