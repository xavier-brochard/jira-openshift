oc delete Service jira-run
oc delete DeploymentConfig jira-run
oc delete Service jira-database
oc delete DeploymentConfig jira-database
oc delete Route jira
oc delete Secret jira
oc delete ConfigMap jira-environment
oc delete ConfigMap jira-clusterproperties
oc delete ConfigMap jira-dbconfigxml
oc delete pvc/jira-database
oc delete pvc/jira-sharedhome
