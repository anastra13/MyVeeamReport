# Cartographie des Jobs VEEAM
# SOBR Obligatoire
# Ne support pas les backup NAS

#region VersionInfo
$MVRversion = "1.0"
# Save HTML output to a file
$saveHTML = $true
$rptTitle = "Rapport Veeam CLIENT-A - Cartographie des backups VEEAM 12"
# HTML File output path and filename
$pathHTML = "C:\Veeam\VeeamReport_$(Get-Date -format MMddyyyy_hhmmss).htm"
# Launch HTML file after creation
$launchHTML = $true

# VBR Server (Server Name, FQDN or IP)
$vbrServer = $env:computername

# Email configuration
$sendEmail = $true
$emailHost = "smtp.yourSRV.com"
$emailPort = 25
$emailEnableSSL = $false
$emailUser = ""
$emailPass = ""
$emailFrom = "client-A@domain.com"
$emailTo = "your@domain.com"
# Send HTML report as attachment (else HTML report is body)
$emailAttach = $true
# Email Subject 
$emailSubject = $rptTitle
# Append Report Mode to Email Subject E.g. My Veeam Report (Last 24 Hours)
$modeSubject = $true
# Append VBR Server name to Email Subject
$vbrSubject = $false
# Append Date and Time to Email Subject
$dtSubject = $true 

#Restore Points Enable ? $true / $false
$RestorePoints = $true



#======== BACKUP ===========
$JOBNAME = ""

# Location of Veeam executable (Veeam.Backup.Shell.exe)
$veeamExePath = (get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication").corepath + "Veeam.Backup.Shell.exe"

Function Get-VeeamVersion {
  Try {
    $veeamExe = Get-Item $veeamExePath
    $VeeamVersion = $veeamExe.VersionInfo.ProductVersion
    Return $VeeamVersion
  } Catch {
    Write-Host "Unable to Locate Veeam executable, check path - $veeamExePath" -ForegroundColor Red
    exit  
  }
}
# Get Veeam Version
$VeeamVersion = Get-VeeamVersion

# Toggle VBR Server name in report header
If ($showVBR) {
  $vbrName = "VBR Server - $vbrServer"
} Else {
  $vbrName = $null
}


$jobBackup = Get-VBRJob  | Where-Object { $_.name -match $JOBNAME} |  where { $_.JobType -eq "NasBackup" -or $_.JobType -eq "Backup" -or $_.JobType -eq "EpAgentBackup" }  | select -Property @{N="Name"; E={$_.Name}},`
@{N="IsScheduleEnabled"; E={$_.IsScheduleEnabled}}, @{N="SyntheticDays"; E={$_.BackupTargetOptions.TransformToSyntethicDays}}, `
@{N="StartTime"; E={($_.ScheduleOptions.StartDateTimeLocal.TimeOfDay).ToString()}}, @{N="DaysSrv"; E={($_.ScheduleOptions.OptionsDaily).DaysSrv -join ","}},`
@{N="Retention"; E={if ($_.JobType -eq "NasBackup") {$_.Options.NasBackupRetentionPolicy.ShortTermRetention}if ($_.JobType -eq "EpAgentBackup") {$_.BackupStorageOptions.RetainCycles} if ( $_.JobType -eq "Backup") { if ($_.BackupStorageOptions.RetentionType -eq "Cycles"){$_.BackupStorageOptions.RetainCycles}if ($_.BackupStorageOptions.RetentionType -eq "day") {$_.BackupStorageOptions.RetainDaysToKeep}}}},`
@{N="RetentionType"; E={if ($_.JobType -eq "NasBackup") {$_.Options.NasBackupRetentionPolicy.ShortTermRetentionUnit}if ($_.JobType -eq "EpAgentBackup") {$_.BackupStorageOptions.RetentionType} if ( $_.JobType -eq "Backup") {$_.BackupStorageOptions.RetentionType}}},`
@{N="TargetRepository"; E={$job=Get-VBRJob -Name $_.name ; $repository = (Get-VBRBackupRepository -ScaleOut | where {$_.id -eq $job.Info.TargetRepositoryId}).name ; if ($repository -eq $null) {(Get-VBRBackupRepository | where {$_.id -eq $job.Info.TargetRepositoryId}).name } else {$repository }}},`
@{N="VBRJobObject"; E={(Get-VBRJobObject $_).name -join "," }},`
@{N="VBRJobObjectCount"; E={((Get-VBRJobObject $_).name).count}},`
@{N="ExcludeVBRJobObject"; E={$ExcludeVBRJobObject=(Get-VBRJob -name $_.name).GetObjectsInJob() | Where-Object {$_.Type -eq "Exclude"};$ExcludeVBRJobObject.Name -join ","}},`
@{N="ExcludeVBRJobObjectCount"; E={$ExcludeVBRJobObjectCount=(Get-VBRJob -name $_.name).GetObjectsInJob() | Where-Object {$_.Type -eq "Exclude"};($ExcludeVBRJobObjectCount).count}},`
@{N="StorageEncryptionEnabled"; E={$_.BackupStorageOptions.StorageEncryptionEnabled}},@{N="VssOptionsEnabled"; E={$_.VssOptions.Enabled}},@{N="Description"; E={$_.Description}}

<#
$GFS = Get-VBRJob | Where-Object { $_.name -match $JOBNAME} | Where-Object { $_.GetOptions().GFSpolicy.isEnabled -eq $True} | where { $_.JobType -eq "Backup" -or $_.JobType -eq "SimpleBackupCopyPolicy" -or $_.JobType -eq "BackupSync" }| select -Property @{N="Name"; E={$_.Name}},@{N="Jobtype"; E={$_.Jobtype}},`
@{N="GFSEnable"; E={$_.GetOptions().GFSpolicy.isEnabled}},`
@{N="IsScheduleEnabled"; E={$_.IsScheduleEnabled}}, `
@{N="RetainDaysToKeep"; E={$_.Options.BackupStorageOptions.RetainDaysToKeep}},`
@{N="GFSWeeklyBackups"; E={$_.Options.generationpolicy.GFSWeeklyBackups}},`
@{N="GFSMonthlyBackups"; E={$_.Options.generationpolicy.GFSMonthlyBackups}},`
@{N="GFSYearlyBackups"; E={$_.Options.generationpolicy.GFSYearlyBackups}}, `
@{N="BackupJobSource"; E={ $idbackcopy=(Get-VBRJob  -Name $_.Name ).LinkedJobIDs.Guid ;$Jobname = [string[]]::new($idbackcopy.count); $i=0 ;$idbackcopy|ForEach-Object {$titi=$_ ;$Jobname[$i]+=(Get-VBRJob | where {$_.Id -match $titi }).name ;$i++};$Jobname -join "," }},`
@{N="TargetRepository"; E={$job=Get-VBRJob -Name $_.name ; $repository = (Get-VBRBackupRepository -ScaleOut | where {$_.id -eq $job.Info.TargetRepositoryId}).name ; if ($repository -eq $null) {(Get-VBRBackupRepository | where {$_.id -eq $job.Info.TargetRepositoryId}).name } else {$repository }}}
#>

$GFS = Get-VBRJob | Where-Object { $_.name -match $JOBNAME} | Where-Object { $_.GetOptions().GFSpolicy.isEnabled -eq $True} | where { $_.JobType -eq "Backup" -or $_.JobType -eq "SimpleBackupCopyPolicy" -or $_.JobType -eq "BackupSync" -or $_.JobType -eq "EpAgentBackup"}| select -Property @{N="Name"; E={$_.Name}},@{N="Jobtype"; E={$_.Jobtype}},`
@{N="GFSEnable"; E={$_.GetOptions().GFSpolicy.isEnabled}},`
@{N="IsScheduleEnabled"; E={$_.IsScheduleEnabled}}, `
#@{N="RetainDaysToKeep"; E={$_.Options.generationpolicy.SimpleRetentionRestorePoints}},`
@{N="GFSWeeklyBackups"; E={if ($_.Options.GfsPolicy.Weekly.IsEnabled -eq "True") {$_.Options.GfsPolicy.Weekly.KeepBackupsForNumberOfWeeks}}},`
@{N="WeeklyBackupOn"; E={if ($_.Options.GfsPolicy.Weekly.IsEnabled -eq "True") {$_.Options.GfsPolicy.Weekly.DesiredTime}}},`
@{N="GFSMonthlyBackups"; E={if ($_.Options.GfsPolicy.Monthly.IsEnabled -eq "True") {$_.Options.GfsPolicy.Monthly.KeepBackupsForNumberOfMonths}}},`
@{N="MonthlyUseWeeklyBakupOn"; E={if ($_.Options.GfsPolicy.Monthly.IsEnabled -eq "True") {$_.Options.GfsPolicy.Monthly.DesiredTime}}},`
@{N="GFSYearlyBackups"; E={if ($_.Options.GfsPolicy.Yearly.IsEnabled -eq "True") {$_.Options.GfsPolicy.Yearly.KeepBackupsForNumberOfYears}}}, `
@{N="YearlyUseMontlyBackupOn"; E={if ($_.Options.GfsPolicy.Yearly.IsEnabled -eq "True") {$_.Options.GfsPolicy.Yearly.DesiredTime}}}, `
@{N="BackupJobSource"; E={ $idbackcopy=(Get-VBRJob  -Name $_.Name ).LinkedJobIDs.Guid ;$Jobname = [string[]]::new($idbackcopy.count); $i=0 ;$idbackcopy|ForEach-Object {$titi=$_ ;$Jobname[$i]+=(Get-VBRJob | where {$_.Id -match $titi }).name ;$i++};$Jobname -join "," }},`
@{N="TargetRepository"; E={$job=Get-VBRJob -Name $_.name ; $repository = (Get-VBRBackupRepository -ScaleOut | where {$_.id -eq $job.Info.TargetRepositoryId}).name ; if ($repository -eq $null) {(Get-VBRBackupRepository | where {$_.id -eq $job.Info.TargetRepositoryId}).name } else {$repository }}}


# RepositoryS3
$repositoryS3 = Get-VBRBackupRepository -ScaleOut | select Name,CapacityExtent,CapacityTierCopyPolicyEnabled,CapacityTierMovePolicyEnabled,ArchivePeriod,OperationalRestorePeriod,EncryptionEnabled

# ObjectStorageRepository
$objectStorageRepository = Get-VBRObjectStorageRepository | select Name,BackupImmutabilityEnabled,ImmutabilityPeriod

# Restore Points
if ($RestorePoints)
{
$list = Get-VBRBackup  | Where-Object { $_.name -match $JOBNAME}  
$results = @()

foreach($backup in $list) {
    
   
    $limit = (Get-Date).AddHours(-48)
    $rps = Get-VBRRestorePoint -Backup $backup
    #$rps = Get-VBRRestorePoint -Backup $backup | Where-Object {$_.CreationTime -gt $limit} | Sort "CreationTime" 

    #$shadowbackup = $backup.GetAllChildrenStorages()
    foreach($rp in $rps) {
        # Bucket info
        $sobr = Get-VBRBackupRepository -ScaleOut -name ($rp.FindRepository()).name 
        $extents = Get-VBRCapacityExtent -Repository $sobr
        $storage = $rp.GetStorage()
        foreach ($extent in $extents) {
            try {
                $shadowStorage = [Veeam.Backup.Core.CStorage]::GetShadowStorageByOriginalStorageId($storage.Id, $extent.Id)
                if ($shadowStorage -ne $null) {
                    $ShadowCopyS3 = "YES"
                    $Bucket = $extent.Repository.name
                    break
                }
            } catch {
                continue
            }
        }
        if ($ShadowCopyS3 -ne "YES") {
            $ShadowCopyS3 = "No"
            $Bucket = "NA"
        }
        $result = New-Object PSObject -Property @{
            "RestorePointName" = $rp.Name
            "FilePath" = $storage.FilePath
            "CreationTime" = $storage.CreationTime
            "ExternalContentMode" = $storage.ExternalContentMode
            "ShadowCopyS3" = $ShadowCopyS3
            "ListBuckets" = ($extents | ForEach-Object {$_.Repository.name}) -join(",")
            "BucketUse" = $Bucket
            "BackupType" = $rp.GetBackup().TypeToString
            "FindRepository" = ($rp.FindRepository()).name 
            "IsFullFast" = $storage.IsFullFast
            "IsIncrementalFast" = $storage.IsIncrementalFast
            "BackupName" = $backup.Name
        }
        $results += $result
    } 
}


$newResults = $results | Sort-Object CreationTime | Select-Object RestorePointName,BackupName,BackupType,ExternalContentMode,ShadowCopyS3,FindRepository,BucketUse,IsFullFast,IsIncrementalFast,ListBuckets,FilePath,CreationTime

 }

#============

$bodyTop = @"
    <body>
        <center>
            <table>
                <tr>
                    <td style="width: 50%;height: 14px;border: none;background-color: #279dd1;color: White;font-size: 10px;vertical-align: bottom;text-align: left;padding: 2px 0px 0px 5px;"><img src="https://espaceclient-xpr.freepro.com/assets/jn/logo_white_trans.png" alt="JAGUAR NETWORK"></td>
                    <td style="width: 50%;height: 14px;border: none;background-color: #279dd1;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 2px 5px 0px 0px;">Report generated on $(Get-Date -format g)</td>
                </tr>
                <tr>
                    <td style="width: 50%;height: 14px;border: none;background-color: #279dd1;color: White;font-size: 10px;vertical-align: bottom;text-align: left;padding: 2px 0px 0px 5px;"></td>
                    <td style="width: 50%;height: 14px;border: none;background-color: #279dd1;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 2px 5px 0px 0px;"></td>
                </tr>
                <tr>
                    <td style="width: 50%;height: 24px;border: none;background-color: #279dd1;color: White;font-size: 24px;vertical-align: bottom;text-align: left;padding: 0px 0px 0px 15px;">$rptTitle $rptTitleMonth $rptTitleYear</td>
                    <td style="width: 50%;height: 24px;border: none;background-color: #279dd1;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 0px 5px 2px 0px;">$vbrName</td>
                </tr>
                <tr>
                    <td style="width: 50%;height: 12px;border: none;background-color: #279dd1;color: White;font-size: 12px;vertical-align: bottom;text-align: left;padding: 0px 0px 0px 5px;"></td>
                    <td style="width: 50%;height: 12px;border: none;background-color: #279dd1;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 0px 5px 0px 0px;">Version VEEAM v$VeeamVersion</td>
                </tr>
                <tr>
                    <td style="width: 50%;height: 12px;border: none;background-color: #279dd1;color: White;font-size: 12px;vertical-align: bottom;text-align: left;padding: 0px 0px 2px 5px;"></td>
                    <td style="width: 50%;height: 12px;border: none;background-color: #279dd1;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 0px 5px 2px 0px;">JN Script v$MVRversion</td>
                </tr>
                 <tr>
                    <td style="width: 50%;height: 12px;border: none;background-color: #279dd1;color: White;font-size: 12px;vertical-align: bottom;text-align: left;padding: 0px 0px 2px 5px;"></td>
                    <td style="width: 50%;height: 12px;border: none;background-color: #279dd1;color: White;font-size: 12px;vertical-align: bottom;text-align: right;padding: 0px 5px 2px 0px;">$rptMode</td>
                </tr>
            </table>
            <table>
                <tr>
                    <td style="height: 10px;background-color: #626365;padding: 5px 0 0 15px;border-top: 5px solid white;border-bottom: none;"></td>
			    </tr>
<tr>
<td style="height: 40px"></td>
</tr>
                <tr>
                    <td style="height: 10px;background-color: #626365;padding: 5px 0 0 15px;border-top: 5px solid white;border-bottom: none;"></td>
			    </tr>
            </table>
"@

$grouped_restorepoints = @{}

foreach ($result in $newResults) {
    $rp = $result.RestorePointName
    $key = $rp
    if ($rp -match "(JSX000\w+)") {
        $key = $matches[1]
    }
    if (-not $grouped_restorepoints.ContainsKey($key)) {
        $grouped_restorepoints[$key] = @()
    }
    $grouped_restorepoints[$key] += $result
}

$htmlRestorePoints = ""

foreach ($key in $grouped_restorepoints.Keys) {
    $htmlRestorePoints += "<h2>$key</h2>"
    $htmlRestorePoints += $grouped_restorepoints[$key] | ConvertTo-Html -Fragment
    $htmlRestorePoints += "<hr>"
}



# Now, $htmlRestorePoints contains a separate table for each RestorePointName

# Convert to HTML

#$html = ConvertTo-Html -Title "Veeam Report" -Body "$bodyTop <h2>Job Backup</h2>$($jobBackup | ConvertTo-Html -Fragment)<h2>GFS</h2>$($GFS | ConvertTo-Html -Fragment)<h2>Repository S3</h2>$($repositoryS3 | ConvertTo-Html -Fragment)<h2>Object Storage Repository</h2>$($objectStorageRepository | ConvertTo-Html -Fragment)<h2>Restore Points</h2>$htmlRestorePoints"

# Convert to HTML
$body = "$bodyTop <h2>Job Backup</h2>$($jobBackup | ConvertTo-Html -Fragment)<h2>GFS</h2>$($GFS | ConvertTo-Html -Fragment)<h2>Repository S3</h2>$($repositoryS3 | ConvertTo-Html -Fragment)<h2>Object Storage Repository</h2>$($objectStorageRepository | ConvertTo-Html -Fragment)"



if ($RestorePoints -eq $true) {
    $body += "<h2>Restore Points</h2>$htmlRestorePoints"
}

$html = ConvertTo-Html -Title "Veeam Report" -Body $body


# Replace commas with <br/>
$html = $html.Replace(",", "<br/>")

# Define CSS styles
$style = "<style>
body {font-family: Arial; font-size: 10pt;}
table {border-collapse: collapse; width: 100%; margin-bottom: 10px;}
th {background-color: #0046c3; color: white; padding: 4px; border: 1px solid #6A90B6;}
td {padding: 4px; border: 1px solid #6A90B6;}
tr:nth-child(even) {background-color: #f2f2f2;}
</style>"


# Add the styles to the HTML
$html = $html.Replace("<head>", "<head>" + $style)

# Change the color of cells containing 'External'
$html = $html.Replace("<td>External<","<td style=""color: #ffc000;"">External<") 
$html = $html.Replace("<td>False<","<td style=""color: red;"">False<")
$html = $html.Replace("<td>True<","<td style=""color: green;"">True<")


# Write to file
#Out-File -FilePath $pathHTML -InputObject $html 



# Send Report via Email
If ($sendEmail) {
  $smtp = New-Object System.Net.Mail.SmtpClient($emailHost, $emailPort)
  $smtp.Credentials = New-Object System.Net.NetworkCredential($emailUser, $emailPass)
  $smtp.EnableSsl = $emailEnableSSL
  $msg = New-Object System.Net.Mail.MailMessage($emailFrom, $emailTo)
  $msg.Subject = $emailSubject
  If ($emailAttach) {
    $body = "Rapport VEEAM"
    $msg.Body = $body
    $tempFile = "$env:TEMP\$($rptTitle)_$(Get-Date -format MMddyyyy_hhmmss).htm"
    $html | Out-File $tempFile
    $attachment = new-object System.Net.Mail.Attachment $tempFile
    $msg.Attachments.Add($attachment)
  } Else {
    $body = $htmlOutput
    $msg.Body = $body
    $msg.isBodyhtml = $true
  }       
  $smtp.send($msg)
  If ($emailAttach) {
    $attachment.dispose()
    Remove-Item $tempFile
  }
}


# Save HTML Report to File
If ($saveHTML) {       
  $html | Out-File $pathHTML
  If ($launchHTML) {
    Invoke-Item $pathHTML
  }
}
 
