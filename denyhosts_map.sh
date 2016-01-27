#!/bin/bash

workdir=/tmp/geoip/
kmlroot=./denyhosts.map.kml
rm -f $workdir* || mkdir -p $workdir
rm ./*.kml
ips=`grep -v "#" /etc/hosts.deny | tr -d " sshd:" | sort | uniq`
ipnums=`grep -v "#" /etc/hosts.deny | tr -d " sshd:" | sort | uniq | wc -l`

#kml imports can have up to 2000 records per file
recsperfile=2000

#TEST
#ipnums=10

totfiles=$(( $ipnums / $recsperfile ))
if [ $(( $ipnums % $recsperfile )) -gt 0 ]; then
totfiles=$(( $totfiles + 1 ))
fi

ipcount=1
rcount=1
fcount=1


# output info
echo "Number of Denied IPs: $ipnums";
echo "Number of records per file: $recsperfile";
echo "Number of files to create: $totfiles";
echo

echo "Geolocating blocked IPs (may take considerable time)";

# geolocate all the blocked ips
for i in $ips; do

	wget --quiet -O - http://freegeoip.net/xml/$i >> $workdir/$i; 
	echo "$i finished ($ipcount)";

	# debug/test
	#if [ $ipcount -eq $ipnums ]; then
	#	break;
	#fi
	# end debug/test

	let ipcount++;

done

echo

# loop to create kml files
for x in $(seq "$totfiles"); do

	kml=$( echo ${kmlroot} | sed s/map/map$fcount/g );
	rcount=0;

	echo "Creating KML file $kml";

	printf '<?xml version="1.0" encoding="UTF-8"?>\n<kml xmlns="http://www.opengis.net/kml/2.2">\n' > $kml;
	printf '<Document>\n<name>Blocked SSH hosts</name>\n<description><![CDATA[Location of all Ips that have attempted access]]></description>\n<Folder>\n<name>IP Attempts</name>\n' >> $kml;

	for FILE in $workdir*; do

		# test if we have processed enough records to start a new file
		if [ $rcount -eq $recsperfile ]; then
			let fcount++;
			break;
		fi

		la=`egrep Latitude $FILE | tr -d "[A-z/<> "` && lo=`egrep Longitude $FILE | tr -d "[A-z/<> "` && loc=`egrep CountryName $FILE | tr -d "<.*>/" | sed s/CountryName//g` && reg=`egrep City $FILE | tr -d "<.*>/ " | sed s/City//g` && ip=`echo $FILE | tr -d "[A-z]/"` && printf "<Placemark>\n<name>$ip</name>\n<description><![CDATA[$reg, $loc]]></description>\n<Point>\n<coordinates>$lo,$la,0.0</coordinates>\n</Point>\n</Placemark>\n" >> $kml; 
		rm $FILE;
		let rcount++;

	done

	printf "</Folder>\n</Document>\n</kml>" >> $kml;

done

echo 'KML generated, import the KML file(s) into Google Earth or http://maps.google.com'
echo 'For help, see https://support.google.com/mymaps/answer/3024836'
