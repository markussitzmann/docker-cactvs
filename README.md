Docker Cactvs
=============

Exploratory project for packaging [CACTVS](https://xemistry.com) into a Docker container

Requirements
------------

Please have at least [Docker CE 17.09](<https://docs.docker.com/engine/installation/>) and [Docker Compose 1.17](<https://docs.docker.com/compose/install/>) installed on your system.

Requirements
------------

Clone the repository::

    git clone https://github.com/markussitzmann/docker-cactvs

Then, change into the newly created directory ::

    cd docker-cactvs

and start a local build of all necessary Docker images with 

    ./build

NOTE: The build includes the download of the CACTVS Chemoinformatics Toolkit Academic version from the
[Xemistry website](<https://xemistry.com/academic/>). Hence, please pay attention to the licensing of the CACTVS 
software package (there will be no prebuild Docker images made available from public Docker image repositories, it
has to be build locally).
 
If the build has finished, initialize the runtime environment by using

    ./init

This will create a directory named `~/prickly`. If you want to change the location of this directory, adapt variable
`CACTVS_HOME` in file `cactvs.env` accordingly.

If you change the directory to `~/prickly` and list its content

    cd ~/prickly
    ls

two versions of how to use Cactvs inside a Docker container can be found. The version in directory `~/pycactvs` provides
starts the Cactvs-extended Python interpreter as provided by the standard Cactvs package and running `cspy`. The 
second version in `~/pycactvs-conda` is a vanilla Python interpreter made available inside a conda environment
and loading CACTVS as an external Python module.

Both version can be used in the same fashion, either go into directory

    cd pycactvs  ~or~   cd pycactvs-conda

and start the Python interpreter interactively inside a Docker container by using 

    ./cspy  
    pycactvs> import pycactvs

or run a script like the provided `script.py` by using 

    ./run script.py

Note: To be improved. The Conda version is running properly yet.

Markus Sitzmann
2021-09-17

