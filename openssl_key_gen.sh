#!/bin/bash

#Required
domain=$1
commonname=$domain

#Change to your company details
country="FR"
state="Everywhere"
locality="Nowhere"
organization="The internet"
organizationalunit="ITea"
email="cizeur@website.com"

echo "Generating KEY & CRT"

openssl req -x509 -sha256 -nodes -newkey rsa:2048 -days 365 -keyout $domain.key -out $domain.crt\
    -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"

echo "Your CERTIFICATE"
cat $domain.crt

echo "Your KEY"
cat $domain.key
