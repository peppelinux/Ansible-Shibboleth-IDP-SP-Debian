#!/bin/bash
export PEM_PATH="keys/pem"
export CERT_PATH=`pwd`"/roles/common/files/certs"
export IDP_FQDN="idp.testunical.it"
export SP_FQDN="sp.testunical.it"

apt install easy-rsa -y
rm -f easy-rsa
cp -Rp /usr/share/easy-rsa/ .
cd easy-rsa

# link easy-rsa ssl config defaults
# You can also edit it to change some informations about issuer and remove EASY-Rsa messages
ln -s openssl-1.0.0.cnf openssl.cnf # won't works with CommonName

# using original openssl file (needs more customizations)
# cp /etc/ssl/openssl.cnf openssl.cnf
# sed -i '1s/^/# For use with easy-rsa version 2.0 and OpenSSL 1.0.0*\n/' openssl.cnf

# customize informations in vars file (or override them later with env VAR)
# remember to configure "Common Name (your server's hostname)" in your certs 
# to let your client avoids "does not match common name in certificate"
# nano vars

# then source it
. ./vars

# override for speedup
export KEY_ALTNAMES=$IDP_FQDN
export KEY_OU=$IDP_FQDN
export KEY_NAME=$IDP_FQDN
export KEY_CN=$SERVER_FQDN

export KEY_COUNTRY="IT"
export KEY_PROVINCE="CS"
export KEY_CITY="Cosenza"
export KEY_ORG="testunical.it"
export KEY_EMAIL="me@testunical.it"

./clean-all

./build-ca
./build-dh
./build-key $IDP_FQDN

mkdir -p $PEM_PATH

openssl x509 -inform PEM -in keys/ca.crt > $PEM_PATH/$KEY_ORG-cacert.pem

# IDP certs
openssl x509 -inform PEM -in keys/$IDP_FQDN.crt > $PEM_PATH/$IDP_FQDN-cert.pem
openssl rsa -in keys/$IDP_FQDN.key -text > $PEM_PATH/$IDP_FQDN-key.pem

# SP certs
export KEY_ALTNAMES=$SP_FQDN
export KEY_OU=$SP_FQDN
export KEY_NAME=$SP_FQDN
./build-key $SP_FQDN
openssl x509 -inform PEM -in keys/$SP_FQDN.crt > $PEM_PATH/$SP_FQDN-cert.pem
openssl rsa -in keys/$SP_FQDN.key -text > $PEM_PATH/$SP_FQDN-key.pem

mkdir -p $CERT_PATH
cp $PEM_PATH/$KEY_ORG-cacert.pem $CERT_PATH/
cp $PEM_PATH/$IDP_FQDN-*.pem $CERT_PATH/
cp $PEM_PATH/$SP_FQDN-*.pem $CERT_PATH/
