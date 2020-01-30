#!/bin/bash
export CERT_PATH=`pwd`"/certs"
export DOMAIN="testunical.it"
export IDP_FQDN="idp.$DOMAIN"
export SP_FQDN="sp.$DOMAIN"

apt install easy-rsa -y
rm -fR easy-rsa
cp -Rp /usr/share/easy-rsa/ .
cd easy-rsa

# override for speedup
export EASYRSA_CMD="./easyrsa --batch"
export EASYRSA_REQ_OU=$DOMAIN
export EASYRSA_REQ_NAME=$DOMAIN
export EASYRSA_REQ_CN=$DOMAIN
export EASYRSA_REQ_ALTNAMES="*.$DOMAIN"

export EASYRSA_REQ_COUNTRY="IT"
export EASYRSA_REQ_PROVINCE="CS"
export EASYRSA_REQ_CITY="Cosenza"
export EASYRSA_REQ_ORG="$DOMAIN"
export EASYRSA_REQ_EMAIL="me@$DOMAIN"

# fixes validation error: “unsupported purpose”
export EASYRSA_NS_SUPPORT="yes"
export EASYRSA_NS_COMMENT="Private CA Generated Certificate"

$EASYRSA_CMD init-pki
$EASYRSA_CMD build-ca nopass --req-cn=$EASYRSA_REQ_CN \
                             --req-c=$EASYRSA_REQ_COUNTRY \
                             --req-st=$EASYRSA_REQ_NAME \
                             --req-city=$EASYRSA_REQ_CITY \
                             --req-org=$EASYRSA_REQ_ORG \
                             --req-email=$EASYRSA_REQ_EMAIL \
                             --req-ou=$EASYRSA_REQ_NAME \
                             --subject-alt-name=$EASYRSA_REQ_ALTNAMES \
                             --copy-ext
# read output
openssl x509 -in pki/ca.crt -text -noout

# $EASYRSA_CMD gen-dh

export EASYRSA_REQ_NAME=$IDP_FQDN
export EASYRSA_REQ_CN=$IDP_FQDN
export EASYRSA_REQ_ALTNAMES="*.$DOMAIN"
$EASYRSA_CMD build-server-full $IDP_FQDN nopass
openssl x509 -in pki/issued/$EASYRSA_REQ_NAME.crt -text -noout

mkdir -p $CERT_PATH
openssl x509 -inform PEM -in pki/ca.crt > $CERT_PATH/$EASYRSA_REQ_ORG-cacert.pem

# IDP certs
openssl x509 -inform PEM -in pki/issued/$IDP_FQDN.crt > $CERT_PATH/$IDP_FQDN-cert.pem
openssl rsa -in pki/private/$IDP_FQDN.key -text > $CERT_PATH/$IDP_FQDN-key.pem

# SP certs
export EASYRSA_REQ_CN=$SP_FQDN
export EASYRSA_REQ_ALTNAMES=$SP_FQDN
export EASYRSA_REQ_NAME=$SP_FQDN
$EASYRSA_CMD build-server-full $SP_FQDN nopass

openssl x509 -inform PEM -in pki/issued/$SP_FQDN.crt > $CERT_PATH/$SP_FQDN-cert.pem
openssl rsa -in pki/private/$SP_FQDN.key -text > $CERT_PATH/$SP_FQDN-key.pem
