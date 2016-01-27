#!/bin/bash
workdir=/tmp/geoip/
kml=./denyhosts_map.kml
rm -r $workdir* || mkdir $workdir
ipnums=`grep -v "#" /etc/hosts.deny | tr -d " sshd:" | sort | uniq | wc -l`
ips=`grep -v "#" /etc/hosts.deny | tr -d " sshd:" | sort | uniq`
COUNTER=0
echo "Number of Denied IPs: $ipnums"
for i in $ips; 
let COUNTER++
do wget --quiet -O - http://freegeoip.net/xml/$i >> $workdir/$i; 
echo "$i completed ($COUNTER)"
done
printf '<?xml version="1.0" encoding="UTF-8"?> \n <kml xmlns="http://www.opengis.net/kml/2.2">\n <Folder> \n  <name>Blocked SSH hosts</name>\n   <open>1</open>\n  <Document>' >> $kml
for FILE in $workdir/*; do la=`egrep Latitude $FILE | tr -d "[A-z/<> "` && lo=`egrep Longitude $FILE | tr -d "[A-z/<> "` && loc=`egrep CountryName $FILE | tr -d "<.*>/ " | sed s/CountryName//g` && ip=`echo $FILE | tr -d "[A-z]/"` && printf " <Placemark>\n  <name>$ip</name>\n  <Point>\n   <coordinates>$lo,$la,0</coordinates>\n   <description>see $FILE</description>\n  </Point>\n </Placemark>\n" >> $kml; done
printf " </Document> \n </Folder> \n </kml>\n" >> $kml
rm -r $workdir*
echo 'KML generated, import the KML file into Google Earth or http://maps.google.com'
echo 'For help, see https://support.google.com/mymaps/answer/3024836'
