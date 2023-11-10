#!/usr/bin/env bash

#stage first
cd stage/services/webserver-cluster
echo "yes" | terraform destroy
cd ../../
cd data-stores/postgres
echo "yes" | terraform destroy



