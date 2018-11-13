#!/bin/bash

function initElasticSearch() {
    until curl -u elastic:changeme -s http://elasticsearch:9200/_cat/health -o /dev/null; do
        echo -e "Waiting for Elasticsearch...";
        sleep 4
    done
}

initElasticSearch
