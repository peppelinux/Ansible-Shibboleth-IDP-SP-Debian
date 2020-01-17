# Ansible Shibboleth IDPv3 e SP3 Debian 10 (buster)

Ansible playbook è una procedura automatizzata per predisporre sistemi complessi.
Questo playbook è stato realizzato per automatizzare l'installazione e la configurazione
di uno Shibboleth Identity Provider e uno di Shibboleth Service Provider, secondo quanto documentato nelle [guida ufficiale
della Federazione IDEM](https://github.com/ConsortiumGARR/idem-tutorials).

Questa procedura è rivolta a tutti coloro i quali:
- vogliano imparare ad installare e configurare Shibboleth IdP ed SP
- per coloro i quali già amministrano un servizio SAML2 ma necessitano di una procedura di prototipazione immediata e riproducibile
- per coloro i quali debbano clonare configurazioni e avanzare di versione dei sistemi già in produzione.

Questa procedurà produrrà un Setup in locale di Shibboleth IdP v3.x e Shibboleth SP 3.0.3 con i seguenti applicativi:
- Servlet Container per IDP (tomcat8 o jetty9, default: jetty)
- Web server  (Apache o NginX come HTTPS frontend)
- mod_shib2/FastCGI  (Application module for shibboleth SP se Apache o NginX)
- Shibboleth (Identity provider)
- mariaDB    (IDP persistent store)
- Java (OpenJDK 11 oppure Amazon Corretto 8)


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
- Utente LDAP abilitato per le ricerche nella UO di interesse (esempio consultabile in ldap/idp_user.ldif). Si consiglia di testare una ricerca LDAP con le credenziali da utilizzare in `ldap.properties`.
  Esempio: `ldapsearch -H ldap://ldap.aai-test.garr.it -D 'uid=idp,ou=idp,dc=aai-test,dc=garr,dc=it' -w idpsecret  -b 'ou=people,dc=aai-test,dc=garr,dc=it'`
- ACL LDAP per le query dell'IDP (esempio consultabile in ldap/idp_acl.ldif)
- Installazione delle seguenti dipendenze

Se non possiedi certificati autorevoli modifica le variabili di make_ca.sh ed eseguilo per costruire una CA privata di test.
````
nano make_ca.sh
bash make_ca.sh
````

Installare le seguenti dipendenze:
````
apt install -y python3-pip python-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg-dev zlib1g-dev ldap-utils
pip3 install ansible
````

Parametri utili
---------------

La configurazione della nostra installazione è contenuta all'interno del file `playbook.yml`.
Parametri quali `domain1`, `domain2` e `domain` determinano in aggiunta l'entityID e i certificati da utilizzare.
Questi ultimi possono risiedere nella directory `/certs` o in altra directory definibile con la variabile `src_cert_path`.
I certificati dovranno avere dei nomi simili a questi:

- fqdn-cert.pem e fqdn-key.pem

Altri parametri utili possono essere:

- shib_idp_version: 3.x.y. Indica la versione di shibboleth idp che verrà installata;
- idp_attr_resolver, il nome del file di attributi da copiare come attribute-resolver.xml dell' IDP;
- idp_persistent_id_rdbms: false. Configura lo storage dei Persistent ID su MariaDB;
- servlet_container: tomcat | jetty;
- idp_disable_saml1: disabilita il supporto a SAML versione 1;
- servlet_ram: 384m. Quanta ram destinare al servlet container;
- edugain_federation: true. Abilita metadati, resolvers e filtri tipici sugli attributi per un IdP di federazione IDEM EduGAIN;
- java_jdk: amazon_8. La distribuzione Java JDK da utilizzare, supporta anche openjdk-8-jre.

Installazione
-------------

## LDAP
Se non hai una installazione funzionante di LDAP puoi crearne una utilizzando [questo playbook](https://github.com/peppelinux/ansible-slapd-eduperson2016):
````
git clone https://github.com/ConsortiumGARR/ansible-slapd-eduperson2016
cd ansible-slapd-eduperson2016

# modifica a tuo piacimento le variabili in playbook.yml prima di eseguire il seguente:
ansible-playbook -i "localhost," -c local playbook.yml
````

### Configurazione di LDAP
````
# testare la connessione LDAP da un client remoto
# accertati che l'hostname del server LDAP sia presente in /etc/hosts oppure che questo possa essere risolto dal tuo DNS.
nano /etc/hosts
# 10.87.7.104 ldap.aai-test.garr.it

# accertati che in /etc/ldap/ldap.conf sia stato configurato TLS_CACERT con il certificato del tuo CA, esempio:
TLS_CACERT /etc/ssl/certs/aai-test.garr.it/slapd-cacert.pem

# aggiungi l'utente idp sul server LDAP
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=admin,dc=aai-test,dc=garr,dc=it" -w slapdsecret -f ldap/idp_user.ldif

# aggiungi una ACL per consentire la connessione e la ricerca all'utente idp
ldapmodify -Y EXTERNAL -H ldapi:/// -D "cn=admin,dc=aai-test,dc=garr,dc=it" -w slapdsecret -f ldap/idp_acl.ldif

# testiamo che l'utente idp possa interrogare il server LDAP
# dal server locale di LDAP
ldapsearch -H ldapi:// -Y EXTERNAL -D "uid=idpuser,ou=idp,dc=aai-test,dc=garr,dc=it" -w idpsecret  -b 'ou=people,dc=aai-test,dc=garr,dc=it'

# dal server IDP
ldapsearch -H ldaps://ldap.aai-test.garr.it -D "uid=idpuser,ou=idp,dc=aai-test,dc=garr,dc=it" -w idpsecret  -b 'ou=people,dc=aai-test,dc=garr,dc=it'

````

## Installazione di Shibboleth IDPv3 e SPv3

### Certificati SSL di shibboleth IDP e SP

Ricordati di leggere attentamente il contenuto di playbook.yml e di creare server_ip.yml secondo l'esempio contenuto in server_ip.yml.example. Questo serve per configurare le risoluzioni dei nomi con certificati self signed. Se usi certificati autorevoli su fqdn puoi omettere questo passaggio.

Il seguente esempio considera una esecuzione in locale del playbook:
````
git clone https://github.com/ConsortiumGARR/Ansible-Shibboleth-IDP-SP-Debian
cd Ansible-Shibboleth-IDP-SP-Debian

# modifica a tuo piacimento le variabili in playbook.yml e crea server_ip.yml prima di eseguire il seguente:
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
openssl s_client -connect shib-sp.aai-test.garr.it:443
openssl s_client -connect shib-idp.aai-test.garr.it:443
````

LDAP Troubleshooting
---------

E' sempre meglio testare la connessione ad LDAP prima del setup.
Da verificare oltre ai certificati anche le ACL di slapd.

````
ldapsearch  -H ldaps://ldap.aai-test.garr.it:636 -D "uid=idpuser,ou=idp,dc=aai-test,dc=garr,dc=it" -w idpsecret  -b 'uid=mario,ou=people,dc=aai-test,dc=garr,dc=it' -d 220
````
Se torna errore: TLS: hostname (rt4-idp-sp.lan) does not match common name in certificate (ldap.aai-test.garr.it).
Soluzione: allineare i certificati e la corrispondenza commonName con l'hostname del server.


Esclusivamente per scopo di test è possibile eludere la validazione del certificato con il seguente comando, solo per test di connettività.
````
LDAPTLS_REQCERT=never ldapsearch  -H ldaps://ldap.aai-test.garr.it:636 -D "uid=idpuser,ou=idp,dc=aai-test,dc=garr,dc=it" -w idpsecret  -b 'uid=mario,ou=people,dc=aai-test,dc=garr,dc=it' -d 220
````

OpenSSL check
````
openssl x509  -text -noout -in /etc/ssl/certs/aai-test.garr.it/slapd-cacert.pem
openssl verify -verbose -CAfile /etc/ssl/certs/aai-test.garr.it/slapd-cacert.pem /etc/ssl/certs/aai-test.garr.it/slapd-cert.pem
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
wget --no-check-certificate https://shib-idp.aai-test.garr.it/idp/shibboleth

# verificare che siano effettivamente differenti !
diff shibboleth shib-idp.aai-test.garr.it-metadata.xml
rm shib-idp.aai-test.garr.it-metadata.xml
mv shibboleth shib-idp.aai-test.garr.it-metadata.xml
# nessun riavvio è richiesto

# controllare inoltre che i certificati del sp siano leggibili da _shibd
chown _shibd /etc/shibboleth/sp.aai-test.garr.it-*

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
2018-03-05 13:38:13,259 - INFO [org.opensaml.saml.common.binding.impl.SAMLMetadataLookupHandler:128] - Message Handler:  No metadata returned for https://sp.aai-test.garr.it/shibboleth in role {urn:oasis:names:tc:SAML:2.0:metadata}SPSSODescriptor with protocol urn:oasis:names:tc:SAML:2.0:protocol
````
Copiare i metadati dell'SP (wget --no-check-certificate https://sp.aai-test.garr.it/Shibboleth.sso/Metadata) in /opt/shibboleth-idp/metadata.


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

/opt/shibboleth-idp/bin/reload-service.sh -id shibboleth.AttributeResolverService -u http://localhost:8080/idp

/opt/shibboleth-idp/bin/reload-service.sh -id shibboleth.AttributeFilterService -u http://localhost:8080/idp

/opt/shibboleth-idp/bin/reload-service.sh -id shibboleth.MetadataResolverResources -u http://localhost:8080/idp
````


Hints
-----

#### idp global logout

- https://shib-sp.aai-test.garr.it/Shibboleth.sso/Logout

#### shibboleth log path
- /opt/shibboleth-idp/logs/


#### test Attribute release

````
/opt/shibboleth-idp/bin/aacli.sh -n luigi -r https://shib-sp.aai-test.garr.it/shibboleth --saml2 -u http://localhost:8080/idp
````

Personalizzazione
-----------------

E' possibile personalizzare la pagina web di ShibbolethIDP modificando i seguenti files.
Le modifiche non richiedono il riavvio del servizio.

- messages/, modifica labels e stringhe globali o per lingua (_it e ed eventuali altri);
- views/, modifica la struttura HTML dei template (file con estensione .vm);
- edit-webapp/, modifica CSS e immagini a cui puntano i template;


Todo
---------

- [SP Attribute Checker](https://wiki.geant.org/display/eduGAIN/How+to+configure+Shibboleth+SP+attribute+checker)
- Rimozione/disinstallazione: non più in un unico ruolo (roles/uninstall) ma contestualizzata nel ruolo di riferimento
- Integrazione slapd overlay PPolicy con Shibboleth (gestione dei lock, interfacciamento a livello idp)
- Implementare multiple sources per attributi da RDBMS differenti
- Read [this](https://tuakiri.ac.nz/confluence/display/Tuakiri/Installing+a+Shibboleth+3.x+IdP#InstallingaShibboleth3.xIdP-ConfigureLDAPAuthentication)

Ringraziamenti
--------------

- Comunità IDEM GARR
- Marco Malavolti (garr.it) per la documentazione di base;
