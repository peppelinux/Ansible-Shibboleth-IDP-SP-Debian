Changelog
---------


#### 14 Gen 2020

- adeguamenti secondo gli aggiornamnti di idem-tutorials
- riorganizzazione attributes filters, resolver e metadata providers in services.xml
- attributi: singoli file per singoli scopi, migliorata semantica dei nomi
- aacli e restart-services adesso non necessitano della specificazione di `-u url`
- avanzamento jetty


#### 4 Aprile 2019

Cosa è cambiato rispetto a Debian9:

- mysql rimosso, mariadb come default
- libmariadb-java (libmariadb-java) ha sostituito libmysql-java (libmysql-java)
- folder cert in root dir e non in rols/common/files
- libshibsp8 ha sostituito libshibsp7
- shibboleth sp avanzato a versione 3.0.3
- aggiunto libxslt1.1 tra apt packages (solo per nginx setup)
- aggiornata configurazione SP
