#!/bin/bash

function generate_ssl_cert() {
    local loc="$WEB_SERVER_CERTS/$LOCAL_DOMAIN"
    local key="$loc.key"
    local csr="$loc.csr"
    local crt="$loc.crt"
    local subj="/CN=${LOCAL_DOMAIN}/emailAddress=${USER_MAIL},O=ASU,OU=UTO,C=US,ST=AZ,L=Tempe"

    if [ -f "$crt" ]; then
        echo "  Cert already exists. Please remove to regenerate with:"
        echo "    rm \"$loc\"*"
        return 1;
    else
        echo "  Generating SSL cert at: $loc"
    fi

    openssl genrsa -out "$key" 4096
    chmod 600 "$key"

    openssl req -new -key  "$key" -subj "$subj" -out  "$csr"
    openssl x509 -req -days 365 -in "$csr" -signkey "$key" -out "$crt"

    chown $USER_USER "$loc"*

    return 1
}
