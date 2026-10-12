#-------------------------------------------------------------
# Original script: https://bitbucket.org/atlassianlabs/automatic-cloud-backup/src/master/backup-confluence-api-token.ps1
# Co-Author: Alex Schüßler
#-------------------------------------------------------------


#-------------------------------------------------------------
# Configuration
#-------------------------------------------------------------

# Credentials
$Email = 'my-mail@address.com' 
#TODO: Move this into environment variable
$ApiToken = 'XXX'
#$ApiToken = $env:ATLASSIAN_BACKUP_TOKEN

# Site URL
$SiteUrl = "https://{mysiteurl}.atlassian.net"

# Attachment Settings
$IncludeAttachments = $false # Set this to true only when necessary

# Paths
$DestinationPath = "D:\Backups\Confluence" # Adjust backup path as needed
$FilePrefix = "confluence_backup_csv_"

# Timing
$PollIntervalSeconds = 60
$MaxWaitMinutes = 180

#-------------------------------------------------------------
# The actual magic function
#-------------------------------------------------------------
function Create-ConfluenceBackup
{
    param (
        [Parameter(Mandatory)] [string] $SiteUrl,
        [Parameter(Mandatory)] [string] $Email,
        [Parameter(Mandatory)] [string] $ApiToken,
        [Parameter(Mandatory)] [string] $DestinationPath,
        [Parameter(Mandatory)] [string] $FilePrefix,
        [switch] $IncludeAttachments,
        [ValidateRange(5, 3600)]   [int] $PollIntervalSeconds = 30,
        [ValidateRange(1, 10000)]  [int] $MaxWaitMinutes = 720
    )

    begin{
        $ErrorActionPreference = 'Stop'

        #Speaking Clearly...
        $includeMediaString = 'false'
        if($IncludeAttachments){
            $includeMediaString = 'true'
        }

        #Prepare Destination Path
        if(!(Test-Path -path $DestinationPath)){
            New-Item $DestinationPath -ItemType Directory
        }

        # Set Atlassian Cloud backup endpoints
        $backupEndpoint = "$($SiteUrl)/wiki/rest/obm/1.0/runbackup"
        $backupStatusURL = "$($SiteUrl)/wiki/rest/obm/1.0/getprogress"
        $backupDownloadUrl = "$($SiteUrl)/wiki/download/$backupLocation"

        # Set deadline
        $deadline = (Get-Date).AddMinutes($MaxWaitMinutes)
    }

    process{
        # Building Authorization Header
        $auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($Email):$($ApiToken)"))
        $headers = @{
            "Authorization" = "Basic $auth"
            "Content-Type" = "application/json"
            "Accept" = "application/json"
        }

        # Building Request Body
        $body = @{
                  cbAttachments=$IncludeMediaString
                  exportToCloud='true'
                 }
        $bodyjson = $body | ConvertTo-Json

        # Do the actual backup!
        $backupResponse = Invoke-WebRequest -Method POST -Uri $backupEndpoint -Headers $headers -Body $bodyjson

        # Check if backup creation was successful
        if ($backupResponse.StatusCode -eq 200) {

            # Wait for the backup to be ready
            $backupReady = $false
            while (!$backupReady) {
                Write-Host "We're waiting $($PollIntervalSeconds) seconds to check the status of your backup."
                Start-Sleep -Seconds $PollIntervalSeconds

                #Get Backup Session ID
                $backupStatus = Invoke-WebRequest -Method GET -Headers $headers $backupStatusURL
                $statusResponse = $backupStatus
                $statusContent = $statusResponse.Content | ConvertFrom-Json
                $backupStatusOutput = $statusContent.alternativePercentage    
                $backupReady = $statusContent.currentStatus -eq "COMPLETE"
                
                Write-Host "Current backup status is $($backupStatusOutput)"
                if ((Get-Date) -gt $deadline) {
                    throw ('Abort: Backup creation still not completed after {0} minutes.' -f $MaxWaitMinutes)
                }
            }

             #Identify file location to download
            $parseResults = $backupStatus.Content | ConvertFrom-Json
            $backupLocation = $parseResults.fileName
            
            # Download the backup file
            $backupFilename = "$($fileprefix)$(Get-Date -Format "yyyy-MM-dd").zip"
            Invoke-WebRequest -Method Get -Uri $backupDownloadUrl -Headers $headers -OutFile "$($destinationPath)$($backupFilename)"
            Write-Host "Backup saved as $backupFilename"

        } else {
            Write-Host "Error: Failed to create Confluence backup. Status code: $($backupResponse.StatusCode)"
        } 
    }
}


#-------------------------------------------------------------
# Execute the script
#-------------------------------------------------------------
$BackupParams = @{
    SiteUrl             = $SiteUrl
    Email               = $Email
    ApiToken            = $ApiToken
    FilePrefix          = $FilePrefix
    DestinationPath     = $DestinationPath
    IncludeAttachments  = $IncludeAttachments
    PollIntervalSeconds = $PollIntervalSeconds
    MaxWaitMinutes      = $MaxWaitMinutes
}


Create-ConfluenceBackup @BackupParams
