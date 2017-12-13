#!/bin/bash

#
# This is just a sample. If you want to remove everything that was touched by 
# these scripts then this shows all the areas that you will need to undo.
#

rm -r /Users/regproctor/Jobs/asu-biokic-dev/{asu-biokic,sql}
rm -r /var/log/apache2/asu-biokic-dev.local*
rm "/usr/local/etc/apache2/2.4/certs/asu-biokic-dev.local"*
rm /usr/local/var/www/htdocs/asu-biokic-dev.local

mysql_config_editor remove --login-path=asubiokicwsasuedudev
mysql --login-path=local -e "DROP DATABASE asu_biokic_dev;"
mysql --login-path=local -e "DROP USER 'asu_biokic_dev'@'localhost'";

emacs /etc/hosts
emacs /usr/local/etc/apache2/2.4/extra/httpd-vhosts.conf
emacs /usr/local/etc/apache2/2.4/extra/httpd-ssl.conf

echo
echo
echo '--------------------------------------------------------------'
ls -al /Users/regproctor/Jobs/;
echo '--------------------------------------------------------------'
ls -al /private/var/log/apache2/;
echo '--------------------------------------------------------------'
ls -al /usr/local/etc/apache2/2.4/certs/;
echo '--------------------------------------------------------------'
ls -al /usr/local/var/www/htdocs/;
echo '--------------------------------------------------------------'
cat /etc/hosts;
echo '--------------------------------------------------------------'
tail /usr/local/etc/apache2/2.4/extra/httpd-vhosts.conf; 
echo '--------------------------------------------------------------'
tail -n 31 /usr/local/etc/apache2/2.4/extra/httpd-ssl.conf;
echo '--------------------------------------------------------------'
echo
echo
