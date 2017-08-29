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

echo "Running Validation Tests..."
if [ $3 -ne 0 ]; then
    echo "Tests Failed!"
    exit 1
fi

echo "Tests Passed!"
exit 1
