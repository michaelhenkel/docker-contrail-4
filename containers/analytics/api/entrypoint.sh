#!/bin/bash

CONTROLLER_NODES=${CONTROLLER_NODES:-`hostname`}
ANALYTICS_NODES=${ANALYTICS_NODES:-${CONTROLLER_NODES}}
ANALYTICS_REDIS_NODES=${ANALYTICS_REDIS_NODES:-${CONTROLLER_NODES}}
ZOOKEEPER_NODES=${ZOOKEEPER_NODES:-${CONTROLLER_NODES}}
CONFIG_NODES=${CONFIG_NODES:-${CONTROLLER_NODES}}
CASSANDRA_NODES=${CASSANDRA_NODES:-${CONTROLLER_NODES}}
RABBITMQ_NODES=${RABBITMQ_NODES:-${CONTROLLER_NODES}}
REDIS_NODES=${REDIS_NODES:-${CONTROLLER_NODES}}

function get_listen_ip(){
  default_interface=`ip route show |grep "default via" |awk '{print $5}'`
  default_ip_address=`ip address show dev $default_interface |\
                    head -3 |tail -1 |tr "/" " " |awk '{print $2}'`
  echo ${default_ip_address}
}

function get_server_list(){
  server_typ=$1_NODES
  port=$2
  server_list=''
  IFS=',' read -ra server_list <<< "${!server_typ}"
  for server in "${server_list[@]}"; do
    server_address=`echo ${server}`
    extended_server_list+=${server_address}:${port}
  done
  extended_list="${extended_server_list::-1}"
  echo ${extended_list}
}

CASSANDRA_PORT=${ANALYTICS_cassandra_port:-9042}
ZOOKEEPER_PORT=${CONFIG_zookeeoer_port:-2181}
ANALYTICS_COLLECTOR_PORT=${ANALYTCS_COLLECTOR_analytics_port:-8086}
ANALYTICS_API_HTTP_PORT=${ANALYTCS_API_http_port:-8090}
ANALYTICS_API_REST_API_PORT=${ANALYTCS_API_rest_api_port:-8081}
RABBITMQ_PORT=${CONFIG__rabbit_port:-5672}
REDIS_PORT=${ANALYTICS_redis_port:-6379}
REDIS_QUERY_PORT=${ANALYTICS_redis_port:-6379}
CONFIG_PORT=${COLLECTOR_config_port:-8082}

read -r -d '' analytics_api_config << EOM
[DEFAULTS]
host_ip = ${ANALYTICS_API_host_ip:-`get_listen_ip`}
collectors = ${ANALYTICS_collectors:-`get_server_list ANALYTICS "$ANALYTICS_COLLECTOR_PORT "`}
cassandra_server_list=${ANALYTICS_cassandra_server_list:-`get_server_list CASSANDRA "$CASSANDRA_PORT "`}
api_server=${ANALYTICS_api_server:-`get_server_list CONFIG "$CONFIG_PORT "`}
zk_list=${ANALYTICS_zk_list:-`get_server_list ZOOKEEPER "$ZOOKEEPER_PORT "`}
http_server_port = ${ANALYTICS_API_HTTP_PORT}
rest_api_port = ${ANALYTICS_API_REST_API_PORT}
rest_api_ip = ${ANALYTICS_API_rest_api_ip:-0.0.0.0}
log_local = ${ANALYTICS_API_log_local:-1}
log_level = ${ANALYTICS_API_log_level:-SYS_NOTICE}
#log_category = 
log_file = ${ANALYTICS_API_log_file:-/var/log/contrail/contrail-analytics-api.log}
# Sandesh send rate limit can be used to throttle system logs transmitted per
# second. System logs are dropped if the sending rate is exceeded
#sandesh_send_rate_limit =
partitions=${ANALYTICS_partitions:-30}
aaa_mode=${ANALYTICS_API_aaa_mode:-no-auth}

[REDIS]
#server=${ANALYTICS_redis_server:-127.0.0.1}
#redis_server_port=${ANALYTICS_redis_server_port:-6379}
redis_query_port=${ANALYTICS_redis_query_port:-6379}
#redis_uve_list = 127.0.0.1:6379
redis_uve_list =${ANALYTICS_redis_uve_list:-`get_server_list ANALYTICS_REDIS "$REDIS_QUERY_PORT "`}

[SANDESH]
sandesh_ssl_enable=${ANALYTICS_sandesh_ssl_enable:-False}
introspect_ssl_enable=${ANALYTICS_introspect_ssl_enable:-False}
sandesh_keyfile=${ANALYTICS_sandesh_keyfile:-/etc/contrail/ssl/private/server-privkey.pem}
sandesh_certfile=${ANALYTICS_sandesh_certfile:-/etc/contrail/ssl/certs/server.pem}
sandesh_ca_cert=${ANALYTICS_sandesh_ca_cert:-/etc/contrail/ssl/certs/ca-cert.pem}
EOM

read -r -d '' contrail_keystone_auth_config << EOM
[KEYSTONE]
admin_password = PQWmBFprabzGZz7rAZyxXQXYb
admin_tenant_name = admin
admin_token = eDmvqUxPGrt7qp2YX67MtfF7T
admin_user = admin
auth_host = 192.168.24.12
auth_port = 35357
auth_protocol = http
insecure = false
memcached_servers = 127.0.0.1:12111
EOM

read -r -d '' vnc_api_lib_config << EOM
[global]
;WEB_SERVER = 127.0.0.1
;WEB_PORT = 9696  ; connection through quantum plugin

WEB_SERVER = 127.0.0.1
WEB_PORT = ${CONFIG_api_server_port:-8082}
BASE_URL = /
;BASE_URL = /tenants/infra ; common-prefix for all URLs

; Authentication settings (optional)
[auth]
;AUTHN_TYPE = keystone
;AUTHN_PROTOCOL = http
;AUTHN_SERVER = 127.0.0.1
AUTHN_SERVER = ${CONFIG_AUTHN_SERVER:-""}
;AUTHN_PORT = 35357
;AUTHN_URL = /v2.0/tokens
;AUTHN_TOKEN_URL = http://127.0.0.1:35357/v2.0/tokens
EOM

#get_kv
echo "$analytics_api_config" > /etc/contrail/contrail-analytics-api.conf
if [ $CONFIG_API_auth="keystone" ]; then
  echo "$contrail_keystone_auth_config" > /etc/contrail/contrail-keystone-auth.conf
fi
echo "$vnc_api_lib_config" > /etc/contrail/vnc_api_lib.ini
exec "$@"
