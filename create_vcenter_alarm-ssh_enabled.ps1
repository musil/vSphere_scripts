#----------------------------------------------
#  SSH ENABLED ALARM
#----------------------------------------------
$mailto = "security@example.com"
$alarmMgr = Get-View AlarmManager
$spec = New-Object VMware.Vim.AlarmSpec
 Create AlarmSpec object
$alarm = New-Object VMware.Vim.AlarmSpec
$alarm.Name = "Security violation - SSH enabled"
$alarm.Description = "SSH is enabled on this host"
$alarm.Enabled = $TRUE
$expression1 = New-Object VMware.Vim.EventAlarmExpression
$expression1.EventType = "EventEx"
$expression1.eventTypeId = "esx.audit.ssh.enabled"
$expression1.objectType = "HostSystem"
$expression1.status = "red"
$alarm.expression = New-Object VMware.Vim.OrAlarmExpression
$alarm.expression.expression += $expression1
$alarmMgr.CreateAlarm("Folder-group-d1", $alarm)
Get-AlarmDefinition $alarm.Name | New-AlarmAction -Email -Subject "Security violation - SSH enabled" -To $mailTo
