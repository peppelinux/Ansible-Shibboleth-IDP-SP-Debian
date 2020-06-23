OIDC notes
----------

# OP tests overview
https://github.com/rohe/oidctest/blob/master/docs/OIDCtesting/OPtest/overview.rst#id1

# create a configuration through a web interface
https://github.com/rohe/oidctest/blob/master/docs/OIDCtesting/OPtest/web.rst

--------------------------------------------

# official documentation
https://oidctest.readthedocs.io/en/latest/


### Installing
````
virtualenv -ppython3 oidctest.env
source oidctest.env/bin/activate

git clone https://github.com/openid-certification/otest
pushd otest/
python3 setup.py install
popd

# seems quite useless ...
# pip install jwkest
# pip install oic

git clone https://github.com/openid-certification/oidctest
pushd oidctest
python3 setup.py install
popd
````

### Configuring

````
oidc_setup.py $PWD/oidctest oidf

cd oidf
optest.py -i "https://idp.testunical.it" -f oidf/oidc_op/flows -p 8080 config_example
````
