#!/bin/bash
# Instalação automatizada do Squid (integrado com Active Directory)
# hflautert@gmail.com
# 30 de Janeiro de 2015

# Instalar squid
yum install squid -y

# Criar estrutura e arquivos regras
mkdir /etc/squid/regras
mkdir /etc/squid/bin

#TODO - Inserir conteudo em redes sociais
touch /etc/squid/regras/ips_liberados
touch /etc/squid/regras/ips_dest_liberados
touch /etc/squid/regras/sites_liberados
touch /etc/squid/regras/palavras_liberadas
touch /etc/squid/regras/redes_sociais

# Configuração
cp -a /etc/squid/squid.conf /etc/squid/squid.conf.original
cat << FIM > /etc/squid/squid.conf
http_port 3128 intercept
http_port 8080
visible_hostname $(hostname)

cache_mem 512 MB
cache_swap_low 90
cache_swap_high 95

maximum_object_size 30960 KB
minimum_object_size 100 KB
maximum_object_size_in_memory 512 KB
maximum_object_size_in_memory 4 KB

ipcache_size 1000
ipcache_low 90
ipcache_high 95

# Tunning
client_db off # desabilita statisticas dos clientes
half_closed_clients off # derruba conexoes nao finalizadas de clientes

# We recommend you to use at least the following line.
hierarchy_stoplist cgi-bin ?

# Cache em disco
cache_dir ufs /var/spool/squid 6144 16 256

# Dump
coredump_dir /var/spool/squid

# Add any of your own refresh_pattern entries above these.
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320

# KERBEROS - Integracao completa com AD
#auth_param negotiate program /usr/lib64/squid/squid_kerb_auth -s HTTP/$(hostname)
#auth_param negotiate children 15 idle=2
#auth_param negotiate keep_alive on

# ACLs para buscar grupos do LDAP.
#external_acl_type InternetLiberada ttl=3600 negative_ttl=3600 %LOGIN /etc/squid/bin/squid_kerb_ldap -g InternetLiberada
#external_acl_type InternetRestrita ttl=3600 negative_ttl=3600 %LOGIN /etc/squid/bin/squid_kerb_ldap -g InternetRestrita

#acl InternetLiberada external InternetLiberada
#acl InternetRestrita external InternetRestrita

acl ips_liberados               src     "/etc/squid/regras/ips_liberados"
acl ips_dest_liberados          dst     "/etc/squid/regras/ips_dest_liberados"
acl sites_liberados             dstdomain -i    "/etc/squid/regras/sites_liberados"
acl palavras_liberadas          url_regex -i    "/etc/squid/regras/palavras_liberadas"


# ACLs
#acl auth proxy_auth REQUIRED
acl manager proto cache_object
acl localhost src 127.0.0.1/32 ::1
acl to_localhost dst 127.0.0.0/8 0.0.0.0/32 ::1

acl localnet src 10.0.0.0/8     # RFC1918 possible internal network
acl localnet src 192.168.0.0/16 # RFC1918 possible internal network
acl localnet src fc00::/7       # RFC 4193 local private network range
acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 81          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

# Regras padrao squid
http_access allow manager localhost
http_access deny manager
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports

# Regras personalizadas - TODO - Ajustar regra rede_social
http_access deny !localnet
http_access allow ips_liberados
http_access allow ips_dest_liberados
http_access allow sites_liberados
http_access allow palavras_liberadas
#http_access deny !auth
#http_access allow InternetLiberada
#http_access allow InternetRestrita
http_access allow all

http_reply_access allow all
icp_access allow all
miss_access allow all
FIM


service squid start

chkconfig squid on

echo -e "\nO squid já está instalado, sera iniciada a integração com Kerberos
Crtl-C para finalizar, y para continuar: "
read DO_KERB
# TODO - Sair do script do com mais elegancia.

yum install cvs gcc krb5-devel krb5-server-ldap openldap-devel cyrus-sasl-ldap cyrus-sasl-gssapi openldap-clients -y
cvs -z3 -d:pserver:anonymous@squidkerbauth.cvs.sourceforge.net:/cvsroot/squidkerbauth co -P squid_kerb_ldap
cd squid_kerb_ldap
./configure
make
cp squid_kerb_ldap /etc/squid/bin/

echo -e "\nAntes de prosseguir, certifique-se:
-> O servidor squid tem um nome FQDN, ex: servidorsquid.empresa.com, ex2: serverx.empresa.local
-> A resolução de nomes, inclusive reverso, está funcionando no servidor do Squid e AD 
"

echo -e "\nDigite o nome do usuario criado no AD, ex: squid.empresa: "
read AD_USER

# Arquivo e infos para integração do AD via Kerberos

DOMAIN_LOWER=$(dnsdomainname)
DOMAIN_UPPER=$(echo $DOMAIN_LOWER | tr '[a-z]' '[A-Z]')
DOMAIN=$(dnsdomainname | cut -d. -f1)
AD_SERVER=$(ping $(dnsdomainname) -c 1 | grep "bytes from" | awk {'print $4'})

# /etc/krb5.conf
cat << FIM > /etc/krb5.conf
[libdefaults]
 default_realm = $DOMAIN_UPPER
 dns_lookup_realm = no
 dns_lookup_kdc = no
 ticket_lifetime = 24h
 renew_lifetime = 7d
 forwardable = yes

; for Windows 2008 with AES
      default_tgs_enctypes = aes256-cts-hmac-sha1-96 rc4-hmac des-cbc-crc des-cbc-md5
      default_tkt_enctypes = aes256-cts-hmac-sha1-96 rc4-hmac des-cbc-crc des-cbc-md5
      permitted_enctypes = aes256-cts-hmac-sha1-96 rc4-hmac des-cbc-crc des-cbc-md5

[realms]
 $DOMAIN_UPPER = {
  kdc = $AD_SERVER:88
  admin_server = $AD_SERVER:749
  default_domain = $DOMAIN_LOWER
 }

[domain_realm]
 .$DOMAIN_LOWER = $DOMAIN_UPPER
 $DOMAIN_LOWER = $DOMAIN_UPPER

[logging]
 default = FILE:/var/log/krb5libs.log
 kdc = FILE:/var/log/krb5kdc.log
 admin_server = FILE:/var/log/kadmind.log
FIM

cat << FIM > /root/install_squid_utils.txt

#Comando para gerar o keytab no windows
ktpass -princ HTTP/$(hostname)@$DOMAIN_UPPER -mapuser $DOMAIN\\$AD_USER -crypto All -mapop set -pass senhaSENHAsenha -ptype KRB5_NT_PRINCIPAL -out $AD_USER.keytab

#Linha a ser inserida no /etc/init.d/squid
#Logo abaixo da variavel SQUID_CONF
KRB5_KTNAME=/etc/squid/$AD_USER.keytab
export KRB5_KTNAME

FIM

echo -e "\nO arquivo /root/install_squid_utils.txt, contem o que voce precisa para finalizar a conf do kerberos.\n"