# Ansible Shibboleth IdP and SP Debian 10 (buster)

Ansible playbook is an automated procedure for setting up complex systems.
This playbook has been designed to automate installation and configuration
of a Shibboleth Identity Provider and one of the Shibboleth Service Provider, as documented in the [official guide
of the IDEM Federation] (https://github.com/ConsortiumGARR/idem-tutorials).

This procedure is aimed at all those who:
- wish to learn how to install and configure Shibboleth IdP and SP
- already manage a SAML2 service but need an immediate and reproducible prototyping procedure
- wish to clone configurations and advance versions of systems already in production.

This procedure will produce a local setup of Shibboleth IdP v3.x and Shibboleth SP 3.0.3 with the following applications:
- Servlet Container for IDP (tomcat8 or jetty9, default: jetty)
- Web server (Apache or NginX as HTTPS frontend)
- mod_shib2 / FastCGI (Application module for shibboleth SP if Apache or NginX)
- Shibboleth (Identity provider and Test Service Provider)
- mariaDB
- Java (OpenJDK 11 or Amazon Correct 8)


Content index
-----------------

<!--ts-->
   * [Requirements](#requirements)
   * [Useful parameters](#useful-paramenters)
   * #### Installation
      * [LDAP](#ldap)
      * [LDAP configuration](#configurazione-di-ldap)
      * [Installation](#installation)
      * [Final Result](#final-result)
      * [LXC image](#lxc)
   * #### Troubleshooting
       * [Systems checks](#systems-checks)
       * [LDAP Troubleshooting](#ldap-troubleshooting)
       * [Shibboleth Troubleshooting](#shibboleth-troubleshooting)
           * [Injected service was null or not an AttributeResolver](#injected-service-was-null-or-not-an-attributeresolver)
           * [opensaml::FatalProfileException](#fatalprofileexception)
           * [The handshake operation timed out](#the-handshake-operation-timed-out)
           * [Message was signed, but signature could not be verified.](#signature-could-not-be-verified)
           * [java.lang.NoClassDefFoundError: org/apache/commons/pool/ObjectPool](#noclassdeffounderror)
           * [Cannot resolve reference to bean 'shibboleth.DefaultAuthenticationResultSerializer'](#defaultauthenticationresultserializer)
           * [AttributeResolverGaugeSet](#attributeresolvergaugeset)
           * [No metadata returned for](#samlmetadatalookuphandler)
           * [PrescopedAttributeDefinition](#prescopedattributedefinition)
   * [Produzione](#produzione)
   * [HTML Page](#html-page)
   * [Hints](#hints)
   * [Todo](#todo)
   * [Ringraziamenti](#ringraziamenti)
   * [Autori](#autori)
<!--te-->

Requirements
---------

- Pre-existing installation of OpenLDAP, as illustrated in the "User guide" section
- LDAP user enabled for searches in the UO of interest (example available in ldap / idp_user.ldif). It is recommended to test an LDAP search with the credentials to be used in `ldap.properties`.
  Example: `ldapsearch -H ldap: //ldap.testunical.it -D 'uid=idp,ou=idp,dc=testunical,dc=it' -w idpsecret -b 'ou=people,dc=testunical,dc=it'`
- LDAP ACL for IDP queries (example available in ldap / idp_acl.ldif)
- Installation of the following dependencies

If you don't have authoritative certificates, edit the make_ca.sh variables and run it to build a private test CA.
````
nano make_ca.sh
bash make_ca.sh
````

Install the following dependencies:
````
apt install -y python3-pip python-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg-dev zlib1g-dev ldap-utils
pip3 install ansible
````

Useful parameters
---------------

The configuration of our installation is contained within the `playbook.yml` file.
Parameters such as `domain1`,` domain2` and `domain` additionally determine the entityID and the certificates to be used.
The latter can reside in the `/ certs` directory or in another directory definable with the` src_cert_path` variable.
Certificates should have names similar to these:

- fqdn-cert.pem e fqdn-key.pem

Other useful parameters can be:

- shib_idp_version: 3.x.y. Indicates the version of shibboleth idp that will be installed;
- idp_attr_resolver, the name of the attribute file to be copied as IDP attribute-resolver.xml;
- idp_persistent_id_rdbms: false. Configure the storage of Persistent IDs on MariaDB;
- servlet_container: tomcat | jetty;
- idp_disable_saml1: disables SAML version 1 support;
- servlet_ram: 384m. How much ram to allocate to the servlet container;
- edugain_federation: true. Enable metadata, resolvers and typical attribute filters for an IDEM of IDEM EduGAIN federation;
- java_jdk: amazon_8. The Java JDK distribution to be used also supports openjdk-8-jre.

Installation
-------------

## LDAP
If you don't have a working installation of LDAP you can create one using [this playbook] (https://github.com/peppelinux/ansible-slapd-eduperson2016):
````
git clone https://github.com/ConsortiumGARR/ansible-slapd-eduperson2016
cd ansible-slapd-eduperson2016

# change the variables in playbook.yml to your liking before running the following:
ansible-playbook -i "localhost," -c local playbook.yml
````

### LDAP Configuration
````
# test the LDAP connection from a remote client
# Make sure that the hostname of the LDAP server is present in / etc / hosts or that this can be resolved by your DNS.
nano /etc/hosts
# 10.87.7.104 ldap.testunical.it

# make sure that TLS_CACERT has been configured with your CA's certificate in /etc/ldap/ldap.conf, example:
TLS_CACERT /etc/ssl/certs/testunical.it/slapd-cacert.pem

# add the idp user on the LDAP server
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=admin,dc=testunical,dc=it" -w slapdsecret -f ldap/idp_user.ldif

# aggiungi una ACL per consentire la connessione e la ricerca all'utente idp
ldapmodify -Y EXTERNAL -H ldapi:/// -D "cn=admin,dc=testunical,dc=it" -w slapdsecret -f ldap/idp_acl.ldif

# we test that the idp user can query the LDAP server
ldapsearch -H ldapi:// -Y EXTERNAL -D "uid=idpuser,ou=idp,dc=testunical,dc=it" -w idpsecret  -b 'ou=people,dc=testunical,dc=it'

# from the IdP Server
ldapsearch -H ldaps://ldap.testunical.it -D "uid=idpuser,ou=idp,dc=testunical,dc=it" -w idpsecret  -b 'ou=people,dc=testunical,dc=it'

````

## Installation

### SSL certificates of shibboleth IDP and SP

Remember to carefully read the contents of playbook.yml and to create server_ip.yml according to the example contained in server_ip.yml.example. This is used to configure name resolutions with self signed certificates. If you use authoritative certificates on fqdn you can omit this step.
The following example considers a local execution of the playbook:
````
git clone https://github.com/ConsortiumGARR/Ansible-Shibboleth-IDP-SP-Debian
cd Ansible-Shibboleth-IDP-SP-Debian

# change the variables in playbook.yml to your liking and create server_ip.yml before running the following:
ansible-playbook -i "localhost," -c local playbook.yml [-vvv]

# select only some roles, for example only the web part
ansible-playbook -i "localhost," -c local playbook.yml -v --tag httpd

# just uninstall and remove everything
ansible-playbook -i "localhost," -c local playbook.yml -v --tag uninstall
````

Final result
---------
![Alt text](images/1.png)
![Alt text](images/2.png)
![Alt text](images/3.png)

LXC
---

````
apt install lxc

CONTAINER_NAME=shib

lxc-create  -t download -n $CONTAINER_NAME -- -d debian -r buster -a amd64

lxc-start -n shib

# cp your modified playbook
cp -R Ansible-Shibboleth-IDP-SP-Debian /var/lib/lxc/$CONTAINER_NAME/rootfs/root/

lxc-attach $CONTAINER_NAME -- apt install python3-pip libffi-dev libssl-dev \
                               libxml2-dev libxslt1-dev libjpeg-dev \
                               zlib1g-dev apt-utils iputils-ping
lxc-attach $CONTAINER_NAME -- pip3 install ansible
lxc-attach $CONTAINER_NAME -- bash -c "cd /root/Ansible-Shibboleth-IDP-SP-Debian && \
                              bash make_ca.production.sh && \
                              ansible-playbook -i "localhost," -c local playbook.production.yml"

# give optionally a static ip to the container or set a static lease into your dnsmasq local instance
echo "lxc.network.ipv4 = 10.0.3.201/24 10.0.3.255" >> /var/lib/lxc/$CONTAINER_NAME/config
echo "lxc.network.ipv4.gateway = 10.0.3.1" >> /var/lib/lxc/$CONTAINER_NAME/config
````

#### LXC Troubleshooting

"ntp.service: Failed to set up mount namespacing: Permission denied"
Enable nesting in `/var/lib/lxc/$CONTAINER_NAME/config` as follow:


See Host Apparmor configuration.
````
lxc.include = /usr/share/lxc/config/nesting.conf
lxc.aa_profile = unconfined
````

Systems checks
--------------
````
# jetty status
service jetty check

# apache2 configuration test
apache2ctl configtest

# You can test that the IdP is properly installed and is at least running successfully in the container with the status command line utility
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
/opt/shibboleth-idp/bin/status.sh

# shibboleth sp test
shibd -t

# idp and sp https checks
openssl s_client -connect sp.testunical.it:443
openssl s_client -connect idp.testunical.it:443
````

LDAP Troubleshooting
--------------------

It is always better to test the connection to LDAP before setup.
In addition to the certificates, the ACLs of slapd must also be verified.
````
ldapsearch  -H ldaps://ldap.testunical.it:636 -D "uid=idpuser,ou=idp,dc=testunical,dc=it" -w idpsecret  -b 'uid=mario,ou=people,dc=testunical,dc=it' -d 220
````
If error returns: TLS: hostname (rt4-idp-sp.lan) does not match common name in certificate (ldap.testunical.it).
Solution: align the certificates and the commonName match with the hostname of the server.

For test purposes only, certificate validation can be circumvented with the following command, only for connectivity tests.

````
LDAPTLS_REQCERT=never ldapsearch  -H ldaps://ldap.testunical.it:636 -D "uid=idpuser,ou=idp,dc=testunical,dc=it" -w idpsecret  -b 'uid=mario,ou=people,dc=testunical,dc=it' -d 220
````

OpenSSL check
````
openssl x509  -text -noout -in /etc/ssl/certs/testunical.it/slapd-cacert.pem
openssl verify -verbose -CAfile /etc/ssl/certs/testunical.it/slapd-cacert.pem /etc/ssl/certs/testunical.it/slapd-cert.pem
````

Shibboleth Troubleshooting
---------

#### Injected service was null or not an AttributeResolver
````
net.shibboleth.utilities.java.support.component.ComponentInitializationException: Injected service was null or not an AttributeResolver
````
la connessione al datasource fallisce (ldap/mysql connection/authentication error) oppure un errore sintattico in attribute-resolver.xml (o quali abilitati in services.xml)


#### FatalProfileException (SP)
````
opensaml::FatalProfileException
Error from identity provider:
Status: urn:oasis:names:tc:SAML:2.0:status:Responder
````
The public key of the SP at the IDP is probably missing, or the keys present, locally, permissions to
incorrect reading. The IDP takes the certificate from the SP via MetaDati. If this error occurs and the certificates have been properly defined in shibboleth2.xml ... Did you remember to restart shibd? :)


#### The handshake operation timed out
````
"Request failed: <urlopen error ('_ssl.c:565: The handshake operation timed out',)>"
````
TASK [mod-shib2 : Add IdP Metadata to Shibboleth SP]
libapache2-mod-shib2 non contiene i file di configurazione in /etc/shibboleth (stranezza apparsa su jessie 8.0 aggiornata a 8.7). Verificare la presenza di questi altrimenti ripopolare la directory


#### Signature could not be verified
````
opensaml::SecurityPolicyException
Message was signed, but signature could not be verified.
````
The SP has incorrect / misaligned IDP metadata. Solution:

````
cd /etc/shibboleth/metadata
wget --no-check-certificate https://idp.testunical.it/idp/shibboleth

# verificare che siano effettivamente differenti !
diff shibboleth idp.testunical.it-metadata.xml
rm idp.testunical.it-metadata.xml
mv shibboleth idp.testunical.it-metadata.xml
# nessun riavvio è richiesto

# controllare inoltre che i certificati del sp siano leggibili da _shibd
chown _shibd /etc/shibboleth/sp.testunical.it-*

````

#### AttributeResolverGaugeSet
````
 Cannot resolve reference to bean 'shibboleth.metrics.AttributeResolverGaugeSet' while setting bean property 'arguments'
````
The exception emerges along the parse of the general-admin-system.xml file, at the bean id = "shibboleth.metrics.AttributeResolverGaugeSet".
Check ldap.properties and attribute-resolver.xml, there is most likely an error connecting to the LDAP server or configuration in attribute-resolver.xml.

#### SAMLMetadataLookupHandler
````
2018-03-05 13:38:13,259 - INFO [org.opensaml.saml.common.binding.impl.SAMLMetadataLookupHandler:128] - Message Handler:  No metadata returned for https://sp.testunical.it/shibboleth in role {urn:oasis:names:tc:SAML:2.0:metadata}SPSSODescriptor with protocol urn:oasis:names:tc:SAML:2.0:protocol
````
Copy the metadata of the SP (wget --no-check-certificate https://sp.testunical.it/Shibboleth.sso/Metadata) in / opt / shibboleth-idp / metadata.

#### PrescopedAttributeDefinition
````
2018-05-05 18:09:41,360 - ERROR [net.shibboleth.idp.attribute.resolver.ad.impl.PrescopedAttributeDefinition:134] - Attribute Definition 'eduPersonPrincipalName': Input attribute value rossi does not contain delimiter @ and can not be split
2018-05-05 18:09:41,390 - ERROR [net.shibboleth.idp.profile.impl.ResolveAttributes:299] - Profile Action ResolveAttributes: Error resolving attributes
net.shibboleth.idp.attribute.resolver.ResolutionException: Input attribute value can not be split.
        at net.shibboleth.idp.attribute.resolver.ad.impl.PrescopedAttributeDefinition.buildScopedStringAttributeValue(PrescopedAttributeDefinition.java:136)
2018-05-05 18:09:42,536 - WARN [net.shibboleth.idp.consent.flow.ar.impl.AbstractAttributeReleaseAction:155] - Profile Action PopulateAttributeReleaseContext: Unable to locate attribute context
````
An attribute configured to be split is not divisible. In the specific case eduPersonPrincipalName expects a scoped value, in the specific username @ structure. We find these specifications in the document: [Technical specifications IDEM GARR attributes] (https://www.eventi.garr.it/en/documenti/conferencing-garr-2016/riunione-idem/42-callofcomments-specifichetecnicheattributi-v3-0-20161005-en-gb)

Produzione
----------

````
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-amazon-corretto/jre

# reload single services (avoid restarting the servlet container)
# these are defined in conf/services.xml

/opt/shibboleth-idp/bin/reload-service.sh -id shibboleth.AttributeResolverService -u http://localhost:8080/idp

/opt/shibboleth-idp/bin/reload-service.sh -id shibboleth.AttributeFilterService -u http://localhost:8080/idp

/opt/shibboleth-idp/bin/reload-service.sh -id shibboleth.MetadataResolverService -u http://localhost:8080/idp
````


Hints
-----

#### idp global logout

- https://sp.testunical.it/Shibboleth.sso/Logout

#### shibboleth log path
- /opt/shibboleth-idp/logs/


#### test Attribute release

````
export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto/
/opt/shibboleth-idp/bin/aacli.sh -n luigi -r https://sp.testunical.it/shibboleth --saml2 -u http://localhost:8080/idp
````

#### Attribute filters
- https://www.garr.it/idem-conf/attribute-filter.xml
- https://www.garr.it/idem-conf/attribute-filter-v3-required.xml
- https://www.garr.it/idem-conf/attribute-filter-v3-rs.xml
- https://www.garr.it/idem-conf/attribute-filter-v3-coco.xml

HTML Page
-----------------

It is possible to customize the ShibbolethIDP web page by modifying the following files.
The changes do not require restarting the service.

- messages /, modify labels and strings global or by language (_it and any others);
- views /, modify the HTML structure of the templates (files with the .vm extension);
- edit-webapp /, edit CSS and images to which the templates point;

Todo
---------

- [SP Attribute Checker](https://wiki.geant.org/display/eduGAIN/How+to+configure+Shibboleth+SP+attribute+checker)
- Integrazione slapd overlay PPolicy con Shibboleth (gestione dei lock, interfacciamento a livello idp)

Ringraziamenti
--------------

- Comunità IDEM GARR
- Marco Malavolti (garr.it) per la documentazione di base;
- Maurizio Festi (unitrento) per la redazione di attribute-resolver-dbsql.xml in sede del corso Shibboleth 22-23 Gen 2020.

Autori
------

- Giuseppe De Marco (giuseppe.demarco@unical.it)
