#!/bin/bash

#echo "web server is starting"
#echo "PWD: $(pwd)"

trap "rm -rf /tmp/index.html" EXIT

cat<<EOC > /tmp/index.html
$(date)
Webserver's placeholder
EOC

#exit 0

while true; do
  [ ! -f /tmp/index.html ] || [ -d /etc/nginx ] && exit 0
  {
    echo -ne "HTTP/1.0 200 OK\r\nContent-Length: $(wc -c </tmp/index.html)\r\n\r\n"
    cat /tmp/index.html
  } | nc -l -p 80 >> /dev/null
done

