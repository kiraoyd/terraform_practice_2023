#!/usr/bin/env bash

#stage first
cd prod/services/webserver-cluster
echo "yes" | terraform destroy
cd ../../
cd data-stores/postgres
echo "yes" | terraform destroy


