<<<<<<< HEAD
#### [Ansible playbook]
Shibboleth IDPv3 SP2 Debian 9
=======
#### [Ansible playbook] 
Shibboleth IDPv3 e SP3 su Debian 10 (buster)
>>>>>>> Debian10
=============================

Setup in locale di ShibbolethIdP 3 e Shibboleth SP 3.0.3 con i seguenti servizi:

- Servlet Container per IDP (tomcat8 o jetty9, default: jetty)
- Web server  (Apache o NginX come HTTPS frontend)
- mod_shib2/FastCGI  (Application module for shibboleth SP se Apache o NginX)
- Shibboleth (Identity provider)
- mariaDB    (IDP persistent store)
<<<<<<< HEAD
- Java (OpenJDK 9 oppure Amazon Corretto 8)
=======

La versione di Java utilizzata è OpenJDK 11.
>>>>>>> Debian10

#### Documentazione di riferimento
Il contenuto di questo playbook è stato perlopiù ricavato dalla seguente documentazione:
- https://github.com/ConsortiumGARR/idem-tutorials

Indice dei contenuti
-----------------

<!--ts-->
   * [Requisiti](#requisiti)
   * [Parametri utili](#parametri-utili)
   * #### Installazione
      * [LDAP](#ldap)
      * [Configurazione di LDAP](#configurazione-di-ldap)
      * [Installazione di Shibboleth IDPv3 e SPv3](#installazione-di-shibboleth-idpv3-e-spv3)
      * [Risultato](#risultato)
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
   * [Personalizzazione](#personalizzazione)
   * [Hints](#hints)
   * [Todo](#todo)
   * [Ringraziamenti](#ringraziamenti)
<!--te-->

Requisiti
---------

- Installazione preesistente di OpenLDAP, come illustrato nella sezione "Guida all'uso"
<<<<<<< HEAD
- Utente LDAP abilitato per le ricerche nella UO di interesse (esempio consultabile in ldap/idp_user.ldiff)
- ACL LDAP per le query dell'IDP (esempio consultabile in ldap/idp_acl.ldiff)
=======
- Utente LDAP abilitato per le ricerche nella UO di interesse (esempio consultabile in ldap/idp_user.ldif)
- ACL LDAP per le query dell'IDP (esempio consultabile in ldap/idp_acl.ldif)
>>>>>>> Debian10
- Installazione delle seguenti dipendenze

````
apt install -y python3-pip python-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg-dev zlib1g-dev ldap-utils
pip3 install ansible
````

Parametri utili
---------------

<<<<<<< HEAD
- shib_idp_version: 3.x.y. Indica la versione di shibboleth idp che verrà installata;
- idp_attr_resolver, il nome del file di attributi da copiare come attribute-resolver.xml dell' IDP;
- idp_persistent_id_rdbms: false. Configura lo storage dei Persistent ID su MariaDB;
- servlet_container: tomcat | jetty;
- idp_disable_saml1: disabilita il supporto a SAML versione 1;
- servlet_ram: 384m. Quanta ram destinare al servlet container;
- edugain_federation: true. Abilita metadati, resolvers e filtri tipici sugli attributi per un IdP di federazione IDEM EduGAIN;
- java_jdk: amazon_8. Che distribuzione Java JDK da utilizzare, supporta anche openjdk-8-jre.
=======
- shib_idp_version: 3.x.y. Indica la versione di shibboleth idp che verrà installata
- idp_attr_resolver, il nome del file di attributi da copiare come attribute-resolver.xml dell' IDP
- idp_persistent_id_rdbms: true. Configura lo storage dei Persistent ID su MariaDB e ottine REMOTE_USER nella diagnostica della pagina SP
- servlet_container: tomcat | jetty.
- idp_disable_saml1: disabilita il supporto a SAML versione 1
- servlet_ram: 384m. Quanta ram destinare al servlet container
>>>>>>> Debian10

Installazione
-------------

## LDAP
Se non hai una installazione funzionante di LDAP puoi crearne una utilizzando questo playbook:
````
git clone https://github.com/peppelinux/ansible-slapd-eduperson2016
cd ansible-slapd-eduperson2016

# modifica a tuo piacimento le variabili in playbook.yml prima di eseguire il seguente:
ansible-playbook -i "localhost," -c local playbook.yml
````

### Configurazione di LDAP
se non possiedi certificati autorevoli modifica le variabili di make_ca.sh prima di creare le chiavi, specialmente l'hostname del server ldap altrimenti le connessioni SSL falliranno!
````
nano make_ca.sh
bash make_ca.sh

# testare la connessione LDAP da un client remoto
# accertati che l'hostname del server LDAP sia presente in /etc/hosts oppure che questo possa essere risolto dal tuo DNS.
nano /etc/hosts
# 10.87.7.104 ldap.testunical.it

# accertati che in /etc/ldap/ldap.conf sia stato configurato TLS_CACERT con il certificato del tuo CA, esempio:
TLS_CACERT /etc/ssl/certs/testunical.it/slapd-cacert.pem

# aggiungi l'utente idp sul server LDAP
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=admin,dc=testunical,dc=it" -w slapdsecret -f ldap/idp_user.ldif

# aggiungi una ACL per consentire la connessione e la ricerca all'utente idp
ldapmodify -Y EXTERNAL -H ldapi:/// -D "cn=admin,dc=testunical,dc=it" -w slapdsecret -f ldap/idp_acl.ldif

# testiamo che l'utente idp possa interrogare il server LDAP
# dal server locale di LDAP
ldapsearch -H ldapi:// -Y EXTERNAL -D "uid=idp,ou=applications,dc=testunical,dc=it" -w idpsecret  -b 'ou=people,dc=testunical,dc=it'

# dal server IDP
ldapsearch -H ldaps://ldap.testunical.it -D "uid=idp,ou=applications,dc=testunical,dc=it" -w idpsecret  -b 'ou=people,dc=testunical,dc=it'

````

## Installazione di Shibboleth IDPv3 e SPv3

### Certificati SSL di shibboleth IDP e SP
Puoi creare delle chiavi firmate di esempio con make_ca.sh, basta editare le variabili all'interno del file secondo le tue preferenze.
````
nano make_ca.sh
bash make_ca.sh
````

<<<<<<< HEAD
**Ricordati** di leggere attentamente il contenuto di playbook.yml e di creare server_ip.yml secondo l'esempio contenuto in server_ip.yml.example. Questo serve per configurare le risoluzioni dei nomi con certificati self signed. Se usi certificati autorevoli su fqdn puoi omettere questo passaggio.
=======
Ricordati di leggere attentamente il contenuto di playbook.yml e di creare server_ip.yml secondo l'esempio contenuto in server_ip.yml.example. Questo serve per configurare le risoluzioni dei nomi con certificati self signed. Se usi certificati autorevoli su fqdn puoi omettere questo passaggio.
>>>>>>> Debian10

Il seguente esempio considera una esecuzione in locale del playbook:
````
ansible-playbook -i "localhost," -c local playbook.yml [-vvv]

# seleziona esclusivamente alcuni ruoli, esempio soltanto la parte web
ansible-playbook -i "localhost," -c local playbook.yml -v --tag httpd

# soltanto disinstallare e rimuovere tutto
ansible-playbook -i "localhost," -c local playbook.yml -v --tag uninstall
````

Risultato
---------
![Alt text](images/1.png)
![Alt text](images/2.png)
![Alt text](images/3.png)

Systems checks
---------
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
---------

E' sempre meglio testare la connessione ad LDAP prima del setup.
Da verificare oltre ai certificati anche le ACL di slapd.

````
ldapsearch  -H ldaps://ldap.testunical.it:636 -D "uid=idp,ou=applications,dc=testunical,dc=it" -w idpsecret  -b 'uid=mario,ou=people,dc=testunical,dc=it' -d 220
````
Se torna errore: TLS: hostname (rt4-idp-sp.lan) does not match common name in certificate (ldap.testunical.it).
Soluzione: allineare i certificati e la corrispondenza commonName con l'hostname del server.


Esclusivamente per scopo di test è possibile eludere la validazione del certificato con il seguente comando, solo per test di connettività.
````
LDAPTLS_REQCERT=never ldapsearch  -H ldaps://ldap.testunical.it:636 -D "uid=idp,ou=applications,dc=testunical,dc=it" -w idpsecret  -b 'uid=mario,ou=people,dc=testunical,dc=it' -d 220
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
In tomcat8/jetty logs: la connessione al datasource fallisce (ldap/mysql connection/authentication error) oppure un errore sintattico in attribute-resolver.xml (o quali abilitati in services.xml)


#### FatalProfileException
````
opensaml::FatalProfileException
Error from identity provider:
Status: urn:oasis:names:tc:SAML:2.0:status:Responder
````
Probabilmente manca la chiave pubblica dell'SP presso l'IDP, oppure le chiavi presentano, localmente, permessi di
lettura errati. L'IDP preleva il certificato dall'SP tramite MetaDati. Se questo errore si presenta e i certificati sono stati adeguatamente definiti in shibboleth2.xml... Hai ricordato di riavviare shibd? :)


#### The handshake operation timed out
````
"Request failed: <urlopen error ('_ssl.c:565: The handshake operation timed out',)>"
````
TASK [mod-shib2 : Add IdP Metadata to Shibboleth SP]
libapache2-mod-shib2 non contiene i file di configurazione in /etc/shibboleth (stranezza apparsa su jessie 8.0 aggiornata a 8.7).
Verificare la presenza di questi altrimenti ripopolare la directory


#### Signature could not be verified
````
opensaml::SecurityPolicyException
Message was signed, but signature could not be verified.
````
L'SP ha i metadati dell'IDP errati/disallineati. Soluzione:

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


#### NoClassDefFoundError

````
java.lang.NoClassDefFoundError: org/apache/commons/pool/ObjectPool
...
Cannot resolve reference to bean 'MyDataSource' while setting bean property 'dataSource'
...
Failed to instantiate [org.apache.commons.dbcp.BasicDataSource]: No default constructor found
````
manca commons-pool.jar in /opt/jetty/lib/ext oppure al posto di commons-pool.jar hai installato commons-pool2.jar

#### DefaultAuthenticationResultSerializer
````
Caused by: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'authn/IPAddress' defined in file [/opt/shibboleth-idp/system/conf/../../conf/authn/general-authn.xml]:
....
Cannot resolve reference to bean 'shibboleth.DefaultAuthenticationResultSerializer' while setting bean property 'resultSerializer'; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'shibboleth.DefaultAuthenticationResultSerializer' defined in file [/opt/shibboleth-idp/system/conf/general-authn-system.xml]:
....
Instantiation of bean failed; nested exception is org.springframework.beans.BeanInstantiationException: Failed to instantiate [net.shibboleth.idp.authn.impl.DefaultAuthenticationResultSerializer]: Constructor threw exception; nested exception is javax.json.JsonException: Provider org.glassfish.json.JsonProviderImpl not found
````
manca javax.json-api-1.0.jar in /opt/jetty/lib/ext
Test confgurazioni singoli servizi/demoni


#### AttributeResolverGaugeSet
````
 Cannot resolve reference to bean 'shibboleth.metrics.AttributeResolverGaugeSet' while setting bean property 'arguments'
````
L'eccezione emerge lungo il parse del file general-admin-system.xml, al bean id="shibboleth.metrics.AttributeResolverGaugeSet".
Riferimento ML shibboleth-users: http://shibboleth.1660669.n2.nabble.com/Update-IdP3-3-0-error-td7629585.html
Controllare ldap.properties e attribute-resolver.xml, con molta probabilità c'è un errore di connessione al server LDAP.

#### SAMLMetadataLookupHandler
````
2018-03-05 13:38:13,259 - INFO [org.opensaml.saml.common.binding.impl.SAMLMetadataLookupHandler:128] - Message Handler:  No metadata returned for https://sp.testunical.it/shibboleth in role {urn:oasis:names:tc:SAML:2.0:metadata}SPSSODescriptor with protocol urn:oasis:names:tc:SAML:2.0:protocol
````
Copiare i metadati dell'SP (wget --no-check-certificate https://sp.testunical.it/Shibboleth.sso/Metadata) in /opt/shibboleth-idp/metadata.


#### PrescopedAttributeDefinition
````
2018-05-05 18:09:41,360 - ERROR [net.shibboleth.idp.attribute.resolver.ad.impl.PrescopedAttributeDefinition:134] - Attribute Definition 'eduPersonPrincipalName': Input attribute value rossi does not contain delimiter @ and can not be split
2018-05-05 18:09:41,390 - ERROR [net.shibboleth.idp.profile.impl.ResolveAttributes:299] - Profile Action ResolveAttributes: Error resolving attributes
net.shibboleth.idp.attribute.resolver.ResolutionException: Input attribute value can not be split.
        at net.shibboleth.idp.attribute.resolver.ad.impl.PrescopedAttributeDefinition.buildScopedStringAttributeValue(PrescopedAttributeDefinition.java:136)
2018-05-05 18:09:42,536 - WARN [net.shibboleth.idp.consent.flow.ar.impl.AbstractAttributeReleaseAction:155] - Profile Action PopulateAttributeReleaseContext: Unable to locate attribute context
````
Un attributo configurato per essere diviso (split) non risulta essere divisibile. Nel caso specifico eduPersonPrincipalName si aspetta un valore scoped, nello specifico nomeutente@struttura. Queste specificazioni le troviamo nel documento: [Specifiche tecniche Attributi IDEM GARR](https://www.eventi.garr.it/en/documenti/conferenza-garr-2016/riunione-idem/42-callofcomments-specifichetecnicheattributi-v3-0-20161005-it-it)


Produzione
----------

````
# ricaricare servizi singoli (eviti di riavviare il servlet container)
# questi sono definiti in conf/services.xml

/opt/shibboleth-idp/bin/reload-service.sh -id shibboleth.AttributeResolverService

/opt/shibboleth-idp/bin/reload-service.sh -id shibboleth.AttributeFilterService

/opt/shibboleth-idp/bin/reload-service.sh -id shibboleth.MetadataResolverResources
````

Hints
-----

#### idp logout standard url
<<<<<<< HEAD
https://sp.testunical.it/Shibboleth.sso/Logout
=======
- https://sp.testunical.it/Shibboleth.sso/Logout
>>>>>>> Debian10

#### shibboleth log path
- /opt/shibboleth-idp/logs/

Personalizzazione
-----------------

E' possibile personalizzare la pagina web di ShibbolethIDP modificando i seguenti files.
Le modifiche non richiedono il riavvio del servizio.

- messages/, modifica labels e stringhe globali o per lingua (_it e ed eventuali altri);
- views/, modifica la struttura HTML dei template (file con estensione .vm);
- edit-webapp/, modifica CSS e immagini a cui puntano i template;


Todo
---------

- [SP] Riqualifica codice PHP di esempio per NginX FastCGI e Apache2 secondo:
  https://wiki.geant.org/display/eduGAIN/How+to+configure+Shibboleth+SP+attribute+checker
- Rimozione/disinstallazione: non più in un unico ruolo (roles/uninstall) ma contestualizzata nel ruolo di riferimento
- Integrazione slapd overlay PPolicy con Shibboleth (gestione dei lock, interfacciamento a livello idp)
- Implementare multiple sources per attributi da RDBMS differenti
- NginX/Apache2/Tomcat2 hardening
- implementare ruolo/opzioni per setup Attribute Authority, con e senza autenticazione
- JRE selezionabile: openJDK, Oracle
- Read [this](https://tuakiri.ac.nz/confluence/display/Tuakiri/Installing+a+Shibboleth+3.x+IdP#InstallingaShibboleth3.xIdP-ConfigureLDAPAuthentication)

Ringraziamenti
--------------

- Comunità IDEM GARR
- Marco Malavolti (garr.it) per la documentazione di base;
- Marco Cappellacci (uniurb) per la documentazione NginX di base;
- Daniele Albrizio (unitrieste) per consigli, confronti e tecnicismi;
