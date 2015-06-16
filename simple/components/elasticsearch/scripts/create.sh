#!/bin/bash -e

. $(ctx download-resource "components/utils")
. $(ctx download-resource "components/elasticsearch/scripts/configure_es")


export ELASTICSEARCH_HOME="/opt/elasticsearch"
export ELASTICSEARCH_LOG_PATH="/var/log/cloudify/elasticsearch"
export ES_JAVA_OPRT=$(ctx node properties es_java_opts)  # (e.g. "-Xmx1024m -Xms1024m")
export ELASTICSEARCH_PORT=$(ctx node properties port)  # (e.g. "9200")
export ELASTICSEARCH_DISCOVERY_PORT=$(ctx node properties discovery_port)  # (e.g. "54329")
export ELASTICHSEARCH_SOURCE_URL=$(ctx node properties elasticsearch_tar_source_url)  # (e.g. "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.4.3.tar.gz")


ctx logger info "Installing Elasticsearch..."

copy_notice "elasticsearch"
create_dir ${ELASTICSEARCH_HOME}
create_dir ${ELASTICSEARCH_HOME}/scripts
create_dir ${ELASTICSEARCH_LOG_PATH}

es_tar=$(download_file ${ELASTICHSEARCH_SOURCE_URL})
ctx logger info "Extracting Elasticsearch from ${es_tar}..."
sudo tar -xzvf ${es_tar} --strip-components=1 -C ${ELASTICSEARCH_HOME}/
clean_tmp

blueprint_es_conf_path="components/elasticsearch/config/elasticsearch.yml"
destination_es_conf_path="${ELASTICSEARCH_HOME}/config/elasticsearch.yml"
ctx logger info "Deploying Elasticsearch Config file ${blueprint_es_conf_path} to ${destination_es_conf_path}..."
tmp_es_conf_path=$(ctx download-resource ${blueprint_es_conf_path})
sudo mv ${tmp_es_conf_path} ${destination_es_conf_path}

ctx logger info "Starting Elasticsearch for configuration purposes..."
sudo ${ELASTICSEARCH_HOME}/bin/elasticsearch -d

ctx logger info "Waiting for Elasticsearch to become available..."
wait_for_port "${ELASTICSEARCH_PORT}"

ctx logger info "Configuring Elasticsearch Indices, Mappings, etc..."
# per a function in configure_es
configure_elasticsearch

ctx logger info "Killing Elasticsearch..."
sudo pkill -f elasticsearch