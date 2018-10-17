FILE=$1
grep istiofile $FILE |sed 's/\(.*\)istiofiles\/\(.*\).yml.*/less $HOME\/istio-tutorial\/istiofiles\/\2.yml/g'|sh
