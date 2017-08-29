#!/bin/sh

set -e -u -x

ip_address=$1
hostname=$2
exitcode=$3

#sudo su
#echo "$1 $2" | tee --append /etc/hosts
#exit

#echo "Updating /etc/hosts file"
#cat /etc/hosts

#/home/seluser/vendor/bin/phpunit webapp/tests/guestbookTests.php

if [ $3 -ne 0 ]; then
    echo "Failed tests!"
fi

exit $3
