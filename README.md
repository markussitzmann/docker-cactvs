Docker Cactvs
=============

Exploratory project for packaging [CACTVS](https://xemistry.com) into a Docker container

Requirements
------------

Please have at least [Docker CE 20.10](<https://docs.docker.com/engine/installation/>) and [Docker Compose 1.29](<https://docs.docker.com/compose/install/>) installed on your system.

Installation
------------

Clone the repository::

    git clone https://github.com/markussitzmann/docker-cactvs

Download the latest CACTVS Linux3.1-SuSE12.1-64 toolkit tar archive package from the 
[Xemistry academic download website](<https://xemistry.com/academic/>) (please, pay attention to the licensing of the CACTVS 
software package) and move it into directory::

    mv {cactvs-package} ./docker-cactvs/context/build/base/

Then, change into repository directory:: 

     cd docker-cactvs

and update variables `CACTVS_VERSION` AND `CACTVS_PACKAGE` in file `settings.env` accordingly to the just downloaded 
CACTVS package::

    CACTVS_VERSION=cactvs3.4.8.20
    CACTVS_PACKAGE=cactvstools-Linux3.1-SuSE12.1-64-3.4.8.20.tar.gz

Then, start a local build of all necessary Docker images with 

    ./build

If the build of all containers has been finished, also a set of runtime environments have been initialized which will be
described in the following. All of them can be found as subdirectories of the directory `~/prickly`. If you want to 
change the name or location of this directory, adapt variable `CACTVS_HOME` in file `cactvs.env` before the build 
accordingly.

If you change the directory to `~/prickly` and list its content

    cd ~/prickly
    ls

three dockerized application contexts (apps) based on CACTVS can be found. Two of these, the version in `./pycactvs` 
and in`~/pycactvs-conda`, provide CACTVS-extended Python interpreter installations. The first one is based on the 
integrated PyCactvs interpreter version available from the original CACTVS package, while the second one uses a vanilla 
Python interpreter which is loading CACTVS as an external module and also includes a Conda package environment.  

Both version can be used in the same way, either go into directory

    cd pycactvs  ~or~   cd pycactvs-conda

and start the Python interpreter interactively inside a Docker container by using 

    ./cspy  
    pycactvs> import pycactvs

or run a script like the provided `script.py` by using 

    ./run script.py

The third app at `./cactvs-app-server` provides a Django installation with the Conda version of PyCactvs available. 
It is preconfigured with a nginx webserver and a Postgres database. Go (back) into directory

    cd ~/prickly

and from there do the following to start the app:

    cd ./actvs-app-server
    ./up
    ./django-init

which starts the app server, initializes Django (answer the questions for an admin user name and set a password for 
this user) and the Postgres databse. If you go to 

    http://localhost:8000

some Django page should appear. 



Markus Sitzmann
2022-02-07

