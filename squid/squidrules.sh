#!/bin/bash
# Script to sort squid rules, keep maintance simple
# hflautert@gmail.com
 
# Rules Path
dir=/etc/squid/regras

# Backup Rules
cp -a $dir /etc/squid/regras.bkp

cd $dir

# Create list with files
find . -type f > /tmp/tempsquidlist

# Goes on list and generate new files
for i in $(cat /tmp/tempsquidlist)
do
cat "$i" | sort > "$i"sorted
done

# Remove old files and rename sorted files
for i in $(cat /tmp/tempsquidlist)
do
rm -Rf "$i"
mv "$i"sorted "$i"
done