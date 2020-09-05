FROM registry.access.redhat.com/ubi8/ubi

USER 0

# Install the certificates, and install the OpenJDK Headless Runtime Environment 11
RUN REPO_LIST="ubi-8-baseos,ubi-8-appstream,ubi-8-codeready-builder" && \
    # Define the packages needed
    INSTALL_PKGS="net-tools java-11-openjdk-headless.x86_64" && \
    # Install the packages
    yum install -y --setopt=tsflags=nodocs --disablerepo "*" --enablerepo $REPO_LIST $INSTALL_PKGS && \
    # Verify the packages
    rpm -V $INSTALL_PKGS && \
    # Clean all packages
    yum -y clean all && \
    # Delete all repo files
    rm /etc/yum.repos.d/*.repo && \
    # Delete the cache  
    rm -rf /var/cache/yum && \
    # Issue with .pki dir in ${HOME} dir 
    rm -rf ${HOME}/.pki

# Set environment variables needed by Jira.
# https://confluence.atlassian.com/display/JSERVERM/Important+directories+and+files
ENV JIRA_INSTALL_DIR        /opt/atlassian/jira
ENV JIRA_HOME               /var/atlassian/application-data/jira

# Expose default HTTP connector port for Jira.
EXPOSE 8080/tcp

# Peer discovery ports for Jira running in cluster mode.
EXPOSE 40001/tcp
EXPOSE 40011/tcp

ARG JIRA_VERSION
ARG ARTEFACT_NAME=atlassian-jira-software
ARG DOWNLOAD_URL=https://product-downloads.atlassian.com/software/jira/downloads/${ARTEFACT_NAME}-${JIRA_VERSION}.tar.gz

# Install Jira.
RUN mkdir -p                ${JIRA_HOME} ${JIRA_INSTALL_DIR} \
    && curl -L              ${DOWNLOAD_URL} | tar -xz --strip-components=1 -C "${JIRA_INSTALL_DIR}" \
    && chgrp -R 0           ${JIRA_HOME} ${JIRA_INSTALL_DIR} \
    && chmod -R g+rwX       ${JIRA_HOME} ${JIRA_INSTALL_DIR} \
    \
    && sed -i -e 's/^JVM_SUPPORT_RECOMMENDED_ARGS=""$/: \${JVM_SUPPORT_RECOMMENDED_ARGS:=""}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/^JVM_\(.*\)_MEMORY="\(.*\)"$/: \${JVM_\1_MEMORY:=\2}/g' ${JIRA_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/port="8080"/port="8080" secure="${catalinaConnectorSecure}" scheme="${catalinaConnectorScheme}" proxyName="${catalinaConnectorProxyName}" proxyPort="${catalinaConnectorProxyPort}"/' ${JIRA_INSTALL_DIR}/conf/server.xml \
    && sed -i -e 's/Context path=""/Context path="${catalinaContextPath}"/' ${JIRA_INSTALL_DIR}/conf/server.xml \
    && touch /etc/container_id && chmod 666 /etc/container_id

# Set volume mount points for installation and home directory. Changes to the
# home directory needs to be persisted (Jira config, attachements)
VOLUME ["${JIRA_HOME}"]

WORKDIR $JIRA_HOME

# https://github.com/krallin/tini
ADD tini /tini
RUN chmod +x /tini

COPY entrypoint.sh          /entrypoint.sh

CMD ["/entrypoint.sh", "-fg"]
ENTRYPOINT ["/tini", "--"]
