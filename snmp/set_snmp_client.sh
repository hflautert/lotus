#!/bin/bash

echo -n "Type costumer name (Ex: Mars S.A ):"
read costumer_name

echo -n "Type I.T Manager name and email (Ex: I.T Manager <it@costumer.com> ):"
read it_manager

echo -n "Type snmp comunity password:"
read snmp_password

yum install net-snmp net-snmp-utils -y
chkconfig snmpd on

server_ip="200.133.33.11/32"

cat > /etc/snmp/snmpd.conf << FIM
###############################################################################
# snmpd.conf:
###############################################################################
# Access Control
###############################################################################
# Communities
#       sec.name  source          community
com2sec local     localhost             $snmp_password
com2sec mbsec     $server_ip      $snmp_password

# Groups
#       groupName      securityModel securityName
group GrupoLocal        v1         local
group GrupoLocal        v2c        local
group GrupoLocal        usm        local
group GrupoMBSEC        v1         mbsec
group GrupoMBSEC        v2c        mbsec
group GrupoMBSEC        usm        mbsec

# Views
#       name           incl/excl     subtree         mask(optional)
view all    included  .1                               80

# Permissions
#       group          context sec.model sec.level prefix read   write  notif
access GrupoLocal ""      any       noauth    exact  all    all   none
access GrupoInt   ""      any       noauth    exact  all    none  none
access GrupoMBSEC ""      any       noauth    exact  all    none  none


###############################################################################
# System contact information
#
syslocation $costumer_name
syscontact $it_manager
system.sysContact.0 = "$it_manager"
system.sysLocation.0 = "$costumer_name"

###############################################################################
# Logging
#
dontLogTCPWrappersConnects yes

###############################################################################
# Process checks.
#
#  Make sure mountd is running
proc mountd

#  Make sure there are no more than 4 ntalkds running, but 0 is ok too.
proc ntalkd 4

#  Make sure at least one sendmail, but less than or equal to 10 are running.
proc sendmail 10 1


###############################################################################
# Executables/scripts
#
# a simple hello world
exec echotest /bin/echo hello world

###############################################################################
# disk checks
#
# Check the / partition and make sure it contains at least 10 megs.
disk / 10000

###############################################################################
# load average checks
#
# load [1MAX=12.0] [5MAX=12.0] [15MAX=12.0]
#
# 1MAX:   If the 1 minute load average is above this limit at query
#         time, the errorFlag will be set.
# 5MAX:   Similar, but for 5 min average.
# 15MAX:  Similar, but for 15 min average.

# Check for loads:
load 12 14 14"
FIM

service snmpd restart
