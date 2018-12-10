MY_URL=http://`hostname -I | awk '{print $1}'`:`./show_node_port.sh`

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
