#from distutils.core import setup
from setuptools import setup, find_packages

setup(
    name='ndb',
    version='0.6',
    author='Guido',
    author_email='guido@google.com',    
    packages=['ndb', ],
    license='Apache 2.0 Licence',
    long_description=open('README').read(),
)