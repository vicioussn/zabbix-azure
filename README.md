# Zabbix-Azure
This solution is intended to allow to pull metrics from Azure Monitor using Azure API and push them to Zabbix Server.

## Basic flow
1. Discover Azure resources metrics and create them as Zabbix items using Zabbix LLD (low-level discovery).
2. On scheduled basis, get items representing metrics from Zabbix host, pull metrics from Azure Monitor API and push them as Zabbix items data.

## Step-by-step guide to configure
Please visit [https://b-blog.info/en/monitoring-azure-resources-with-zabbix.html](https://b-blog.info/en/monitoring-azure-resources-with-zabbix.html) for detailed instructions.