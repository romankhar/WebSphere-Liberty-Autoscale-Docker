#!/bin/bash

#!/bin/bash
docker rm `docker ps --no-trunc -a -q`
docker images | grep '' | awk '{print $3}' | xargs docker rmi
exit 0