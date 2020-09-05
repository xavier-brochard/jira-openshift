#!/bin/bash
set -euo pipefail

# Check if the JIRA_HOME and JIRA_INSTALL variable are found in ENV.
if [ -z "${JIRA_HOME}" ] || [ -z "${JIRA_INSTALL_DIR}" ]; then
  echo "Either JIRA_HOME (${JIRA_HOME}), or JIRA_INSTALL_DIR (${JIRA_INSTALL_DIR}) is undefined."
  echo "Please ensure that it is set in Dockerfile, or passed as ENV variable."
  echo "Abnormal exit ..."
  exit 1
else
  echo "Found JIRA_HOME: ${JIRA_HOME}"
  echo "Found JIRA_INSTALL_DIR: ${JIRA_INSTALL_DIR}"
fi

# Setup Catalina Opts
: ${CATALINA_CONNECTOR_PROXYNAME:=}
: ${CATALINA_CONNECTOR_PROXYPORT:=}
: ${CATALINA_CONNECTOR_SCHEME:=http}
: ${CATALINA_CONNECTOR_SECURE:=false}
: ${CATALINA_CONTEXT_PATH:=}

: ${CATALINA_OPTS:=}

: ${JAVA_OPTS:=}

CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyName=${CATALINA_CONNECTOR_PROXYNAME}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorProxyPort=${CATALINA_CONNECTOR_PROXYPORT}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorScheme=${CATALINA_CONNECTOR_SCHEME}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaConnectorSecure=${CATALINA_CONNECTOR_SECURE}"
CATALINA_OPTS="${CATALINA_OPTS} -DcatalinaContextPath=${CATALINA_CONTEXT_PATH}"

export JAVA_OPTS="${JAVA_OPTS} ${CATALINA_OPTS}"

: ${CLUSTERED:=false}

# Set values in cluster.properties
function set_cluster_property {
    local search=$1
    local replace=$2
    local escaped_replace=$(echo ${replace} | sed -e 's/[\/&]/\\&/g')
    sed -i "s/${search}/${escaped_replace}/g" "${JIRA_HOME}/cluster.properties"
}

if [ "${CLUSTERED}" == "true" ]; then
    echo "CLUSTERED set to true."

    cp /tmp/clusterproperties/cluster.properties  ${JIRA_HOME}

    echo "Setting values in cluster.properties from passed environment variables."
    set_cluster_property "NODE_NAME"        "${NODE_NAME}"
    set_cluster_property "JIRA_SHARED_HOME" "${JIRA_SHARED_HOME}"
    set_cluster_property "NODE_IP"          "${NODE_IP}"
fi

cp /tmp/dbconfigxml/dbconfig.xml                ${JIRA_HOME}

# Start Jira
exec "$JIRA_INSTALL_DIR/bin/start-jira.sh" "$@"
