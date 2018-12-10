MYROUTE=`oc get route customer -o jsonpath='{.spec.host}':; ./show_node_port.sh`

#MYAPP=`oc get route -n tutorial  | grep ^customer|awk '{print $2}'`
#for i in `seq 1 10`; do curl $MYAPP; done

#echo curl $MYROUTE
while true
do
	curl $MYROUTE
	sleep 0.1
done
