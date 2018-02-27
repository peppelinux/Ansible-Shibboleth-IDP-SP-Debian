[NotUsableYET][Ansible playbook] Shibboleth Debian 9 
======================================

Setup in locale di ShibbolethIdP 3 e Shibboleth SP 2.
Richiede una installazione preesistente di OpenLDAP, come esemplificata nel seguente playbook:

````
git clone https://github.com/peppelinux/ansible-slapd-eduperson2016
````

I servizi configurati nel presente playbook sono:

- jetty9     (Servlet Container for shibboleth idp)
- apache2    (HTTPS frontend)
- mod_shib2  (Application module for shibboleth sp)
- shibboleth (Identity provider)
- mariaDB    (IDP persistent store)

La versione di Java con la quale viene fatto il presente setup è OpenJDK 8.

Requisiti
---------

- Una installazione preesistente di OpenLDAP
- Creare o dedicare un utente e una ACL per consentire le query dell'IDP sulle definizioni LDAP in sola lettura
- Due interfacce di rete, rispettivamente per IDP e SP
- Installare le seguenti dipendenze per l'esecuzione in locale di ansible

````    
aptitude install python3-pip python-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev libjpeg-dev zlib1g-dev
pip3 install ansible
````

Comandi di deployment e cleanup
===============================

Puoi creare delle chiavi firmate di esempio con make_ca.sh.
Edita le variabili nel playbook e il file hosts prima di fare l'esecuzione.
Il seguente esempio considera una esecuzione in locale.

````
ansible-playbook -i "localhost," -c local playbook.yml [-vvv]
````

Risultato
========================

![Alt text](images/1.png)
![Alt text](images/2.png)
![Alt text](images/3.png)

Note
========================

Crea nel tuo DNS o in /etc/hosts gli hostname idp ed sp se sei in testunical

    10.0.3.22  idp.testunical.it
    10.0.4.22  sp.testunical.it
	

Troubleshooting
========================

net.shibboleth.utilities.java.support.component.ComponentInitializationException: Injected service was null or not an AttributeResolver
    In tomcat8 localhost.YYYY-mm-dd.log
    La connessione al datasource fallisce (ldap/mysql connection/authentication error).

opensaml::FatalProfileException
    Error from identity provider: 
    Status: urn:oasis:names:tc:SAML:2.0:status:Responder
    probabilmente manca la chiave pubblica dell'SP presso l'IDP, oppure le chiavi presentano, localmente, permessi di 
    lettura errati. L'IDP preleva il certificato dall'SP tramite MetaDati. Se questo errore si presenta e i certificati sono     stati adeguatamente definiti in shibboleth2.xml... Hai ricordato di riavviare shibd? :)

"Request failed: <urlopen error ('_ssl.c:565: The handshake operation timed out',)>"

    TASK [mod-shib2 : Add IdP Metadata to Shibboleth SP]
    libapache2-mod-shib2 non contiene i file di configurazione in /etc/shibboleth (stranezza apparsa su una jessie 8.0 aggiornata a 8.7). 
    Verificare la presenza di questi altrimenti ripopolare la directory

Test confgurazioni singoli servizi/demoni

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

````

opensaml::SecurityPolicyException
Message was signed, but signature could not be verified.
L'SP ha i metadati dell'IDP errati/disallineati.

````
cd /etc/shibboleth/metadata
wget --no-check-certificate https://idp.testunical.it/idp/shibboleth

# verificare che siano effettivamente differenti !
diff shibboleth idp.testunical.it-metadata.xml 
rm idp.testunical.it-metadata.xml 
mv shibboleth idp.testunical.it-metadata.xml 

# nessun riavvio è richiesto
````

Todo
====

- Implementare multiple sources per attributi da RDBMS differenti
- ruolo per SP con nginx

Ringraziamenti
========================

Inspirato da Garr Netvolution 2017 (http://eventi.garr.it/it/ws17) e basato sul playbook di Davide Vaghetti https://github.com/daserzw/IdP3-ansible.
Un ringraziamento speciale a Marco Malavolti per la redazione delle guide di installazione ufficiali e per le repository (https://github.com/malavolti).
Un ringraziamento speciale a Francesco Sansone per l'integrazione del Service Provider mediante frontend PHP.
