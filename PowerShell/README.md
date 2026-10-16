***Automated Confluence Cloud Backup (PowerShell)***

This repository contains a PowerShell script to automate Confluence Cloud backups.

The script creates a Confluence Cloud backup, waits for completion and downloads the generated backup file automatically.
Why?

**Atlassian's original scripts such as:**

    atlassianlabs/automatic-cloud-backup
    backup-confluence-api-token.ps1

are no longer actively maintained.

**This project provides a maintained alternative that works with current Confluence Cloud environments.
Features**

    * Automated Confluence Cloud Backup
    * PowerShell based
    * Works with Atlassian API Token authentication
    * Suitable for Task Scheduler, Azure Automation and scheduled jobs
    * Backup download automation

Script
Create-ConfluenceBackup.ps1

**Automates the complete Confluence Cloud backup process:**

    * Trigger backup creation
    * Monitor backup progress
    * Download backup when finished

**Search Keywords**
* Confluence Cloud Backup
* Automated Confluence Backup
* PowerShell Confluence Backup
* Atlassian Backup Automation
* backup-confluence-api-token.ps1 replacement
* automatic-cloud-backup replacement
