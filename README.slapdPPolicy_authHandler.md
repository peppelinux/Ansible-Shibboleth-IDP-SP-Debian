#### Configurazione LDAP PPolicy

[LDAPAuthnConfiguration-HandlingaccountstatewithOpenLDAP](https://wiki.shibboleth.net/confluence/display/IDP30/LDAPAuthnConfiguration#LDAPAuthnConfiguration-HandlingaccountstatewithOpenLDAP)

In conf/authn/password-authn-config.xml decommentare il seguente bean
in conformità al parametro maxAttempts configurato in slapd ppolicy
````
    <bean id="shibboleth.authn.Password.AccountLockoutManager"
        parent="shibboleth.StorageBackedAccountLockoutManager"
        p:maxAttempts="8"
        p:counterInterval="PT5M"
        p:lockoutDuration="PT5M"
        p:extendLockoutDuration="false" />
````

Nel file conf/authn/ldap-authn-config.xml modificare i seguenti bean come segue
````
    <!-- Authentication handler -->
    <!-- From
    <bean id="authHandler" class="org.ldaptive.auth.PooledBindAuthenticationHandler" p:connectionFactory-ref="bindPooledConnectionFactory"  />
    -->

    <!-- To -->
    <bean id="authHandler" class="org.ldaptive.auth.PooledBindAuthenticationHandler" p:connectionFactory-ref="bindPooledConnectionFactory"
     p:authenticationControls-ref="authenticationControl"  />
````

````
    <!-- From
    <bean name="bindSearchAuthenticator" class="org.ldaptive.auth.Authenticator" p:resolveEntryOnFailure="%{idp.authn.LDAP.resolveEntryOnFailure:false}">
        <constructor-arg index="0" ref="bindSearchDnResolver" />
        <constructor-arg index="1" ref="authHandler" />
    </bean>
    -->

    <!-- To -->
    <bean name="bindSearchAuthenticator" class="org.ldaptive.auth.Authenticator" p:resolveEntryOnFailure="%{idp.authn.LDAP.resolveEntryOnFailure:false}"
     p:authenticationResponseHandlers-ref="authenticationResponseHandler">
        <constructor-arg index="0" ref="bindSearchDnResolver" />
        <constructor-arg index="1" ref="authHandler" />
    </bean>
````

Aggiungere quindi authHandler come già descritto nei commenti
````
    <!-- Want to use ppolicy? Configure support by adding <bean id="authenticationResponseHandler" class="org.ldaptive.auth.ext.PasswordPolicyAuthenticationResponseHandler" 
        /> add p:authenticationResponseHandlers-ref="authenticationResponseHandler" to the authenticator <bean id="authenticationControl" 
        class="org.ldaptive.control.PasswordPolicyControl" /> add p:authenticationControls-ref="authenticationControl" to the authHandler -->

    <bean id="authenticationControl"  class="org.ldaptive.control.PasswordPolicyControl" />

````
