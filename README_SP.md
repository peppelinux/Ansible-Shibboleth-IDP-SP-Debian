Service Provider's

The main files you’ll have to deal with are the following XML files:

- attribute-map.xml
This tells Shibboleth which attributes (bits of information) it can expect to receive from IdP, and what each bit of information is called. This should be provided to you by your administrator, and you should overwrite Shibboleth’s version with yours.

- attribute-policy.xml
This maps certain data points to user groups. Again, your administrator should provide this to you and you should overwrite Shibboleth’s version with your own. We actually use the default version of this file at UCL, so it might be that your administrator will suggest that you do this too.

- idp-ucl-metadata.xml (or similar)
In our setup, we have been provided with information by UCL on which certificates our Shibboleth SP should expect to receive data signed with. It lists our the Development, UAT (User Acceptance Testing) and Production IdPs, along with their relevant IDs. You should receive a similar XML file from your administrator that you can drop into this folder (and reference later).

- protocols.xml
This sets up which authentication protocols (such as SAML versions) your servers should use. We use the out-of-box version of this file, and you should be able to as well, unless your administrator provides you with an alternative.

- security-policy.xml
Like protocols.xml, the defaults are okay unless your admin says so.
shibboleth2.xml

This is the main XML file that I will go into a lot more detail on (as we’ll need to match some values up between here and the Nginx configuration).


# trova versione nginx
dpkg-query -l nginx | grep nginx | awk -F' ' {'print $3'}| awk -F'-' {'print $1'}


#### Resources
- https://www.nginx.com/blog/compiling-dynamic-modules-nginx-plus/
- https://medium.com/ucl-api/adventures-in-shibboleth-and-nginx-part-2-of-2-6455a7f1d026
