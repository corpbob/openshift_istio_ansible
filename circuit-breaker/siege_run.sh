MY_URL=`oc get route customer -n tutorial -o jsonpath='{.spec.host}'`

siege -r 2 -c 20 -v http://$MY_URL

exit 0

if [ "$1" = "-f" ]
then
	#echo curl $MY_URL
	while true
	do
		curl $MY_URL
		sleep 0.2
	done
else
	for i in `seq 1 10`; do curl $MY_URL; done
fi 
