# Get source and destination from user input, assign as global variables
#Param($global:src,$global:dst)

# Global variables src and dst, assigning for testing
$global:src = "C:\Users\bob\Documents\Test"
$global:dst = "C:\Users\bob\Documents\Backups"
# Get the current date for renaming folders later
$current_date = Get-Date -Format "yyyy-MM-dd-hh-mm"
# Set the time offsets to decide when to do a full, differential and incremental
# backup
$offset_full = New-TimeSpan -Hours 1
$timespan_diff = New-TimeSpan -Minutes 10
# Pattern matching created folders
$bak_pattern = '^................-[v,i,d]$'
#$src_itmes = Get-ChildItem -Path "$global:src" -Recursive

# Full Backup Function
function FullBackup ($local:src,$local:dst){

}

# Differential Backup Function
function DiffBackup ($local:src,$local:dst){

}

# Incremental Backup Function
function IncrBackup ($local:src,$local:dst){

}

# If there is no previous backup, start a full backup. Else...
If (!Get-ChildItem -Path "$global:dst" -Filter "$bak_pattern")
{
  FullBackup $gloabal:dst $gloabal:src
}else{
  # ... decide which backup to run:
  # If the files are older than the offset for a full backup, start a full backup.
  # If the files are older than the offset for the differential backup, run a
  # differential backup.
  # Otherwise the file is newer than the offset for the diff backup and an
  # incremental backup will be run.
  If (Test-Path -Path $dst_fin -OlderThan ($current_date - $timespan_full))
  {
    FullBackup $gloabal:dst $gloabal:src
  }else{
    If (Test-Path -Path $dst_fin -OlderThan ($current_date - $timespan_diff))
    {
      DiffBackup $gloabal:dst $gloabal:src
    }else{
      IncrBackup $gloabal:dst $gloabal:src
    }
  }

}
