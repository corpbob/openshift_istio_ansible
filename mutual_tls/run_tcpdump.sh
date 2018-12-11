echo Waiting for customer pod to start ...

while ! CUSTOMER_POD=$(oc get po | grep customer.*2/2.*Running | awk '{print $1}')
do
	sleep 1
done

POD_IP=`oc rsh -c istio-proxy $CUSTOMER_POD hostname -I`

echo Starting tcpdump in the istio proxy container in pod $CUSTOMER_POD for IP $POD_IP

oc rsh -c istio-proxy $(oc get po | grep customer.*2/2.*Running | awk '{print $1}') sudo tcpdump -vvv -A -i eth0 "((dst port 8080) and (net $POD_IP))"


