#!/bin/bash
# Instalação automatizada do Sarg (Relatórios de acesso a internet)
# hflautert@gmail.com
# 15 de Janeiro de 2015

cd ~

# Instalar dependencias
yum install gcc make gd gd-devel pcre pcre-devel httpd
# Instar sarg
wget http://downloads.sourceforge.net/project/sarg/sarg/sarg-2.3.9/sarg-2.3.9.tar.gz
tar -xvzf sarg-2.3.9.tar.gz
cd sarg-2.3.9
./configure --sysconfdir=/etc/sarg
make
make install

# Configuração
cat << 'FIM' > /etc/cron.daily/sarg
#!/bin/bash

# Get yesterday's date
YESTERDAY=$(date --date "1 day ago" +%d/%m/%Y)

exec /usr/local/bin/sarg \
   -o /var/www/sarg/daily \
   -d $YESTERDAY &>/dev/null
exit 0
FIM

cat << 'FIM' > /etc/cron.weekly/sarg
#!/bin/bash
LOG_FILES=
for FILE in /var/log/squid/access.log*; do
    LOG_FILES="$LOG_FILES -l $FILE"
done

# Get yesterday's date
YESTERDAY=$(date --date "1 day ago" +%d/%m/%Y)

# Get one week ago date
WEEKAGO=$(date --date "7 days ago" +%d/%m/%Y)

exec /usr/local/bin/sarg \
    $LOG_FILES \
    -o /var/www/sarg/weekly \
    -d $WEEKAGO-$YESTERDAY &>/dev/null
exit 0
FIM

cat << 'FIM' > /etc/cron.monthly/sarg
#!/bin/bash
LOG_FILES=
for FILE in /var/log/squid/access.log*; do
    LOG_FILES="$LOG_FILES -l $FILE"
done

# Get yesterday's date
YESTERDAY=$(date --date "1 day ago" +%d/%m/%Y)

# Get 1 month ago date
MONTHAGO=$(date --date "1 month ago" +%d/%m/%Y)

exec /usr/local/bin/sarg \
    $LOG_FILES \
    -o /var/www/sarg/monthly \
    -d $MONTHAGO-$YESTERDAY &>/dev/null
exit 0
FIM

chmod +x /etc/cron.*/sarg

cat << 'FIM' > /etc/sarg/sarg.conf
access_log /var/log/squid/access.log
graphs yes
graph_days_bytes_bar_color orange
#graph_font /etc/sarg/fonts/DejaVuSans.ttf
graph_font /usr/local/share/sarg/fonts/DejaVuSans.ttf
title "Relatorio de Acessos"
font_face Tahoma,Verdana,Arial
header_color darkblue
header_bgcolor blanchedalmond
font_size 9px
header_font_size 9px
title_font_size 11px
output_dir /var/www/sarg/ONE-SHOT
resolve_ip yes
date_format e
lastlog 30
remove_temp_files yes
index yes
overwrite_report yes
mail_utility mail
topsites_num 100
topsites_sort_order CONNECT D
charset Latin1
show_successful_message no
show_sarg_info no
show_sarg_logo no
download_suffix "zip,arj,bzip,gz,ace,doc,iso,adt,bin,cab,com,dot,drv$,lha,lzh,mdb,mso,ppt,rtf,src,shs,sys,exe,dll,mp3,avi,mpg,mpeg"
FIM

cat << 'FIM' > /etc/httpd/conf.d/sarg.conf
Alias /sarg /var/www/sarg

<Directory /var/www/sarg>
    DirectoryIndex index.html
    Order deny,allow
    Deny from all
    Allow from all
    Allow from ::1
    Options Indexes MultiViews FollowSymLinks
    AllowOverride AuthConfig
    # Allow from your-workstation.com
</Directory>
FIM

mkdir /var/www/sarg
cat << 'FIM' > /var/www/sarg/.htaccess
AuthName "Acesso Restrito"
AuthType Basic
AuthUserFile /var/www/sarg/passwd_sarg
require valid-user
FIM


cat << 'FIM' > /var/www/sarg/index.html
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html PUBLIC "XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
   <title>Relatorios de Acessos</title>
<style type="text/css">
.logo {font-family:Verdana,Tahoma,Arial;font-size:11px;color:#006699;text-align:center;vertical-align:middle;border:none;padding:0px;margin-bottom:5px;}
.logo th {padding:0px;}
.logo img {vertical-align:middle;padding:0px;border:0px none;}
.body {font-family:Tahoma,Verdana,Arial;font-size:11px;color:#000000;background-color:#ffffff;background-image:url();}
.info {font-family:Tahoma,Verdana,Arial;font-size:10px;text-align:center;margin-top:1em;margin-bottom:1em;}
.info a:link,a:visited {font-family:Tahoma,Verdana,Arial;color:#0000FF;font-size:10px;text-decoration:none;}
.title {width:100%;text-align:center;margin-bottom:1em;}
div.title > table {margin:auto;}
.title_c {font-family:Tahoma,Verdana,Arial;font-size:11px;color:darkblue;background-color:#ffffff;text-align:center;}
.title_l {font-family:Tahoma,Verdana,Arial;font-size:11px;color:darkblue;background-color:#ffffff;text-align:left;}
.title_r {font-family:Tahoma,Verdana,Arial;font-size:11px;color:darkblue;background-color:#ffffff;text-align:right;}
.index {width:100%;text-align:center;}
div.index > table {margin:auto;}
.report {width:100%;text-align:center;}
div.report > table {margin:auto;}
.header_l {font-family:Tahoma,Verdana,Arial;font-size:9px;color:darkblue;background-color:blanchedalmond;text-align:left;border-right:1px solid #666666;border-bottom:1px solid #666666;}
.header_r {font-family:Tahoma,Verdana,Arial;font-size:9px;color:darkblue;background-color:blanchedalmond;text-align:right;border-right:1px solid #666666;border-bottom:1px solid #666666;}
.header_c {font-family:Tahoma,Verdana,Arial;font-size:9px;color:darkblue;background-color:blanchedalmond;text-align:center;border-right:1px solid #666666;border-bottom:1px solid #666666;}
.data {font-family:Tahoma,Verdana,Arial;color:#000000;font-size:9px;background-color:lavender;text-align:right;border-right:1px solid #6A5ACD;border-bottom:1px solid #6A5ACD;}
.data a:link,a:visited {font-family:Tahoma,Verdana,Arial;color:#0000FF;font-size:9px;background-color:lavender;text-align:right;text-decoration:none;}
.data2 {font-family:Tahoma,Verdana,Arial;color:#000000;font-size:9px;background-color:lavender;text-align:left;border-right:1px solid #6A5ACD;border-bottom:1px solid #6A5ACD;}
.data2 a:link,a:visited {font-family:Tahoma,Verdana,Arial;color:#0000FF;font-size:9px;text-align:left;background-color:lavender;text-decoration:none;}
.data3 {font-family:Tahoma,Verdana,Arial;color:#000000;font-size:9px;background-color:lavender;text-align:center;border-right:1px solid #6A5ACD;border-bottom:1px solid #6A5ACD;}
.data3 a:link,a:visited {font-family:Tahoma,Verdana,Arial;color:#0000FF;font-size:9px;text-align:center;background-color:lavender;text-decoration:none;}
.text {font-family:Tahoma,Verdana,Arial;color:#000000;font-size:9px;background-color:lavender;text-align:right;}
.link {font-family:Tahoma,Verdana,Arial;font-size:9px;color:#0000FF;}
.link a:link,a:visited {font-family:Tahoma,Verdana,Arial;font-size:9px;color:#0000FF;text-decoration:none;}
a > img {border:none;}
</style>
</head>
<body>

<div class="title">
  <table cellpadding="0" cellspacing="0">
    <tr><th class="title_c">Relatorio de Acessos</th></tr>
  </table>
</div>
<div class="index"><table cellpadding="1" cellspacing="2">
<tr><td></td><td></td></tr>
<tr>
  <th class="header_c">CATEGORIA</th>
  <th class="header_c">DESCRICAO</th>
</tr>
<tr><td class="data2"><a href="ONE-SHOT/index.html">Manuais</a></td><td class="data2">Relatorios Manuais</td></tr>
<tr><td class="data2"><a href="daily/index.html">Diarios</a></td><td class="data2">Relatorios Diarios</td></tr>
<tr><td class="data2"><a href="weekly/index.html">Semanais</a></td><td class="data2">Relatorios Semanais</td></tr>
<tr><td class="data2"><a href="monthly/index.html">Mensais</a></td><td class="data2">Relatorios Mensais</td></tr>
</table></div>

</body>
</html>
FIM 

echo -e "\nSera gerado um usuario relatorio, com a senha definida a seguir.\n"

htpasswd -c /var/www/sarg/passwd_sarg relatorio

service httpd restart
chkconfig httpd on

echo -e "\nConfiguracao finalizada, o servico httpd foi reiniciado e ativado no boot.\n"
echo -e "\nOs relatorios estao acessiveis em http://$(hostname)/sarg. Protegido por senha.\n"

