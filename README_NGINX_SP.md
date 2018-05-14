## How to compile nginx shib modules addons
Note that stable does not mean more reliable or more bug-free.
In fact, the mainline is generally regarded as more reliable because we port all bug fixes to it, and
not just critical fixes as for the stable branch. On the other hand, changes in the stable branch
are very unlikely to affect third-party modules. We don’t make the same commitment concerning
the mainline, where new features can affect the operation of third-party modules.
We recommend that in general you deploy the NGINX mainline branch at all times.

````
# which version do you have? (just4fun)
# export NGINX_VERSION=$(dpkg-query -l nginx | grep nginx | awk -F' ' {'print $3'}| awk -F'-' {'print $1'})
# download its sources
# apt-get source nginx

mkdir nginx_setup && pushd nginx_setup

# donwload last mainline version
git clone https://github.com/nginx/nginx.git nginx_src

# get push stream module
git clone https://github.com/wandenberg/nginx-push-stream-module.git push-stream

# get  Shibboleth Module
git clone https://github.com/nginx-shib/nginx-http-shibboleth.git http-shib

# get Clear Headers module
git clone https://github.com/openresty/headers-more-nginx-module.git headers-more

# Enter the Nginx folder
#pushd nginx-$NGINX_VERSION
cd nginx_src/src

# Configure the Nginx compilation
auto/configure --with-http_ssl_module \
            --add-module=../push-stream \
            --add-module=../http-shib \
            --add-module=../headers-more \
            --sbin-path=/usr/sbin/nginx \
            --prefix=/usr \
            --modules-path=/usr/lib/nginx/modules/ \
            --conf-path=/etc/nginx/nginx.conf \
            --pid-path=/run/nginx.pid \
            --error-log-path=/var/log/nginx/error.log \
            --http-log-path=/var/log/nginx/access.log\
            --user=www-data \
            --group=www-data
            
# Compile Nginx
make -j2
make install

# check where it have installed all the things
make -n install

# Compiled modules are in
ls ./objs/addon/src/
ls ./objs/addon/http-shib/

# copy its content in
cp ./objs/addon/src/* /usr/lib/nginx/modules/
cp ./objs/addon/http-shib/* /usr/lib/nginx/modules/

popd
````
