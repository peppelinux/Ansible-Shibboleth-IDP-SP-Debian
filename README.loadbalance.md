Shibboleth Load Balancer
-----------------------
In this section there's some reference about Http Websites loadbalancing with shibboleth.
An example with HAproxy should also published here.


### NginX community edition
| WARNING: Mind That if the Shibboleth servers/containers doesn't have any JSESSIONID shared storage (Memcached) the users must login again on each takeover.|
| --- |

Example
````
upstream shib_balancer {
        least_conn;
        server 10.0.3.101:8080 max_fails=1 fail_timeout=10s;
        server 10.0.3.102:8080 backup;
}

# match is not available in all releases
#match server_ok {
    # status 200;
    # body !~ "maintenance";
#    send      "GET /idp/shibboleth HTTP/1.0\r\nHost: localhost\r\n\r\n";
#    expect ~* "200 OK";
#}

# configuration of the server
server {
    listen      80;
    server_name idp.testunical.it; # substitute your machine's IP address or FQDN

    access_log /var/log/nginx/idp.testunical.it.access.log;
    error_log  /var/log/nginx/idp.testunical.it.error.log error;

    return 301 https://$host$request_uri; 
}

server {
    server_name idp.testunical.it;
    charset     utf-8;

    listen 443 ssl;
    ssl_certificate /etc/ssl/certs/shib-balancer/idp.testunical.it-cert.pem;
    ssl_certificate_key /etc/ssl/certs/shib-balancer/idp.testunical.it-key.pem;

    access_log /var/log/nginx/idp.testunical.it.access.log;
    error_log  /var/log/nginx/idp.testunical.it.error.log error;

    # max upload size
    client_max_body_size 5M;   # adjust to taste

    # test this location fetching metadatas
    # https://idp.testunical.it/idp/shibboleth
    location /idp {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_connect_timeout 300;
        port_in_redirect off;

        # these fixes SAML message intended destination endpoint did not match the recipient endpoint
        # $scheme in questo caso è https.
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        
        # HSTS
        add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; ";
        add_header X-Frame-Options "DENY"; 
        
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://shib_balancer;
        #health_check interval=5 passes=1 fails=1;
        #health_check match=server_ok;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
    root   /usr/local/nginx/html;
    }

}
````


