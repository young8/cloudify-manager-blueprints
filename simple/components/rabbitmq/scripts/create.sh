#!/bin/bash -e

. $(ctx download-resource "components/utils")


export RABBITMQ_LOG_BASE="/var/log/cloudify/rabbitmq"
export ERLANG_SOURCE_URL=$(ctx node properties erlang_rpm_source_url)  # (e.g. "http://www.rabbitmq.com/releases/erlang/erlang-17.4-1.el6.x86_64.rpm")
export RABBITMQ_SOURCE_URL=$(ctx node properties rabbitmq_rpm_source_url)  # (e.g. "http://www.rabbitmq.com/releases/rabbitmq-server/v3.5.3/rabbitmq-server-3.5.3-1.noarch.rpm")


ctx logger info "Installing RabbitMQ..."

copy_notice "rabbitmq"
create_dir "${RABBITMQ_LOG_BASE}"

ctx logger info "Installing logrotate"
yum_install "logrotate"
yum_install ${ERLANG_SOURCE_URL}
yum_install ${RABBITMQ_SOURCE_URL}

# Dunno if required.. the key thing, that is... check please.
# curl --fail --location http://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-${RABBITMQ_VERSION}-1.noarch.rpm -o /tmp/rabbitmq.rpm
# sudo rpm --import https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
# sudo yum install /tmp/rabbitmq.rpm -y

ctx logger info "Starting RabbitMQ Server in Daemonized mode..."
sudo rabbitmq-server -detached

ctx logger info "Enabling RabbitMQ Plugins..."
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmq-plugins enable rabbitmq_tracing

# enable guest user access where cluster not on localhost
ctx logger info "Enabling RabbitMQ user access..."
echo "[{rabbit, [{loopback_users, []}]}]." | sudo tee --append /etc/rabbitmq/rabbitmq.config

ctx logger info "Chowning RabbitMQ Log Path..."
sudo chown rabbitmq:rabbitmq ${RABBITMQ_LOG_BASE}

ctx logger info "Killing RabbitMQ..."
sudo pkill -f rabbitmq