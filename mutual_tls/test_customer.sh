NODE_PORT=`oc -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'`
MY_URL=http://`hostname -I | awk '{print $1}'`:$NODE_PORT

if [ "$1" = "-f" ]
then
	echo curl $MY_URL
	while true
	do
		curl $MY_URL
		sleep 0.5
	done
else
	curl $MY_URL
fi
