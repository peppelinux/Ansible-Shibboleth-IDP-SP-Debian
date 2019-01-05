Shibboleth SP3 from sources
---------------------------
This guide was crafted and tested for Debian 9.

#### Gettings started
````
apt update
apt upgrade
````

#### Install Dependencies
NB: some package name could be different in some distributions.
````
apt install libboost-all-dev zlib1g-dev libssl1.0-dev libcurl4-openssl-dev \
            libxmlsec1-dev libxmlsec1 xmlsec1 \
            libsystemd-dev apache2-dev \
            # the following commented out will be compiled from sources \
            # libxerces2-java libxerces-c-dev libxerces-c3.1 \
            # libxml-security-c-dev xml-security-c-utils
````

##### Install log4shib
````
wget https://shibboleth.net/downloads/log4shib/latest/log4shib-2.0.0.tar.bz2
tar xjvf log4shib-2.0.0.tar.bz2
cd log4shib-2.0.0
./configure --disable-static --disable-doxygen --prefix=/opt/shibboleth-sp
make -j 4
make install
````

##### Xerces-c
````
wget http://mirror.nohup.it/apache/xerces/c/3/sources/xerces-c-3.2.2.tar.bz2
tar xjvf xerces-c-3.2.2.tar.bz2
cd xerces-c-3.2.2
make clean
./configure --prefix=/opt/shibboleth-sp \
            --enable-xmlch-char16_t \
            --enable-xmlch-wchar_t \
            --enable-xmlch-uint16_t
make -j 4
make install
````

##### Install xml-security-c
````
apt install libxalan-c-dev

wget https://archive.apache.org/dist/santuario/c-library/xml-security-c-2.0.2.tar.bz2
tar xjvf xml-security-c-2.0.2.tar.bz2
cd xml-security-c-2.0.2

# see for example: pkg-config --cflags libcurl and pkg-config --libs libcurl
export xerces_CFLAGS=-I/opt/shibboleth-sp/include
export xerces_LIBS="-L/opt/shibboleth-sp/lib -lxerces-c"

./configure --without-xalan --disable-static --prefix=/opt/shibboleth-sp 
make -j 4

make install
````

##### Install xmltooling
````
wget http://shibboleth.net/downloads/c++-opensaml/3.0.0/xmltooling-3.0.3.tar.bz2
tar xjvf xmltooling-3.0.3.tar.bz2
cd xmltooling-3.0.3

export log4shib_CFLAGS=-I/opt/shibboleth-sp/include
export log4shib_LIBS=-llog4shib

export xml_security_CFLAGS=-I/opt/shibboleth-sp/include
export xml_security_LIBS="-L/opt/shibboleth-sp/lib -lxml-security-c"
./configure --prefix=/opt/shibboleth-sp 
make -j 4

make install
````

##### Install opensaml
````
wget https://shibboleth.net/downloads/c++-opensaml/3.0.0/opensaml-3.0.0.tar.bz2
tar xjvf opensaml-3.0.0.tar.bz2
cd opensaml-3.0.0

./configure --prefix=/opt/shibboleth-sp 
make -j 4

make install
````

#### install SP

Configuration hint: 
**--enable-apache-24** means Apache 2.4, you can also choose one ore more of the following:
````
# see ./configure -h
  --enable-apache-13      enable the Apache 1.3 module
  --enable-apache-20      enable the Apache 2.0 module
  --enable-apache-22      enable the Apache 2.2 module
  --enable-apache-24      enable the Apache 2.4 module
````
Check your installed apache version before running the configuration script.

##### Compilation
````
wget https://shibboleth.net/downloads/service-provider/latest/shibboleth-sp-3.0.3.tar.bz2
tar xjvf shibboleth-sp-3.0.3.tar.bz2
cd shibboleth-sp-3.0.3

#export PKG_CONFIG_PATH=/opt/shibboleth-sp/include
#export PKG_CONFIG_LIBDIR=/opt/shibboleth-sp/include

export xmltooling_CFLAGS=-I/opt/shibboleth-sp/include
export xmltooling_LIBS=-lxmltooling

export xmltooling_lite_CFLAGS=-I/opt/shibboleth-sp/include
export xmltooling_lite_LIBS=-lxmltooling-lite

export opensaml_CFLAGS=-I/opt/shibboleth-sp/include
export opensaml_LIBS=-lsaml

./configure --with-apxs=/usr/local/apache/bin/apxs \
            --enable-apache-24 \
            --with-apxs2=/usr/local/apache2/bin/apxs \
            --enable-systemd \
            --prefix=/opt/shibboleth-sp 
make -j 4
make install
````

#### Configuration
Some notes about running it in a production environment.

#### Appendix: Common libraries knowledge
````
# for make , compilation
export LIBRARY_PATH=$LIBRARY_PATH:/opt/shibboleth-sp/lib

# for run
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/shibboleth-sp/lib

# extra for automatic run
echo "/opt/shibboleth-sp/lib" >  /etc/ld.so.conf.d/shibboleth-sp_custom.conf 
````

Some usefull commands to debug common linking problems during compilation.
These also came usefull for testings _LIBS flags.
````
# debug
ld --verbose -L /opt/shibboleth-sp/lib -lxerces-c

# read lib's symbol table 
objdump -t /opt/shibboleth-sp/lib/libxerces-c.so | grep XMLException
````
