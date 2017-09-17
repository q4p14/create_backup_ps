#### Variable Assignment #######################################################
################################################################################

# Get source and destination from user input, assign as global variables
Param($global:src,$global:dst)

# Global variables src and dst, assigning for testing
#$global:src = "C:\Users\bob\Documents\Test"
#$global:dst = "C:\Users\bob\Documents\Backups"
# Get the current date for renaming folders later
$current_date = Get-Date -Format "yyyy-MM-dd-hh-mm"
$check_date = Get-Date
# Set the time offsets to decide when to do a full, differential and incremental
# backup
$offset_full = New-TimeSpan -Hours 1
$offset_diff = New-TimeSpan -Minutes 10
# Pattern matching created folders
$bak_pattern = '^....-..-..-..-..-[v,i,d]$'
#$src_itmes = Get-ChildItem -Path "$global:src" -Recurse
# Get the latest backup in the backup base directory
$dst_last = Get-ChildItem -Directory -Path $global:dst | Sort-Object `
LastWriteTime -Descending | Select-Object -First 1

#### Function Block ############################################################
################################################################################

# Full Backup Function
function FullBackup (){
  # Assign the value of the global variables to their local counterparts
  $local:src = $global:src
  $local:dst = $global:dst

  # Copy all items in the source path to the new subdirectory of the
  # destination path
  Copy-Item -Recurse -Path "$local:src" -Destination `
  "$local:dst\$current_date-v"

  # The LastWriteTime of the original file should be preserved. First get all
  # items in the new backup subdirectory
  Get-ChildItem -Recurse -Path "$local:dst\$current_date-v\*" | ForEach-Object {
    # For each parsed item, get the original item by replacing the path in front
    # of the items name by the path of the orignal source file. Then store the
    # the LastWriteTime of the orignal item in a variable
    $original_lwt = ( Get-Item ($_.Fullname -replace `
    [regex]::Escape("$dst\$current_date-v"),"$local:src")).LastWriteTime

    # Assign the previously gained value to the destination files LastWriteTime
    # Attribute
  }
}

# Differential Backup Function
function DiffBackup (){
  # Assign the value of the global variables to their local counterparts
  $local:src = $global:src
  $local:dst = $global:dst

  # Get the last full backup by filtering all items in the destination. Then
  # sort them by last write time and get the last one (ergo newest)
  $last_full = Get-ChildItem -Directory -Path $local:dst\* -Filter "*-v" | Sort-Object `
  LastWriteTime -Descending | Select-Object -First 1

  # For each item in the source that is newer than the creation time of the last
  # full backup...
  foreach ($item in (Get-ChildItem -Recurse -Path $local:src\* | Where-Object { $_.LastWriteTime -gt (Get-Item $last_full).LastWriteTime})) {
    # ... create all subdirectories by spliting the path of the original file,
    # and replacing everything the matches the source to the new destination
    New-Item -Type Directory -Path ((Split-Path $item.FullName) -replace [regex]::Escape("$local:src"),"$local:dst\$current_date-d")
  }

  # Do a similiar thing as with item creation...
  foreach ($item in (Get-ChildItem -Recurse -Path $local:src\* | Where-Object { $_.LastWriteTime -gt (Get-Item $last_full).LastWriteTime})) {
  # ... but this time copy the files found to the newly created subdirectories
  Copy-Item -Path $item.FullName -Destination ($item.FullName -replace [regex]::Escape("$local:src"),"$local:dst\$current_date-d")
  }
}

# Incremental Backup Function
function IncrBackup (){
  # Assign the value of the global variables to their local counterparts
  $local:src = $global:src
  $local:dst = $global:dst

  # Get the last incremental backup by filtering all items in the destination. Then
  # sort them by last write time and get the last one (ergo newest)
  $last_incr = Get-ChildItem -Directory -Path $local:dst\* -Filter "*-i" | Sort-Object `
  LastWriteTime -Descending | Select-Object -First 1

  # If there is a a last incremetal backup (path not empty)...
  if ($last_incr) {
    # For each item in the source that is newer than the creation time of the last
    # incremental backup...
      foreach ($item in (Get-ChildItem -Recurse -Path $local:src\* | Where-Object { $_.LastWriteTime -gt (Get-Item $last_incr).LastWriteTime})) {
      # ... create all subdirectories by spliting the path of the original file,
      # and replacing everything the matches the source to the new destination
      New-Item -Type Directory -Path ((Split-Path $item.FullName) -replace [regex]::Escape("$local:src"),"$local:dst\$current_date-i")
    }

    # Do a similiar thing as with item creation...
    foreach ($item in (Get-ChildItem -Recurse -Path $local:src\* | Where-Object { $_.LastWriteTime -gt (Get-Item $last_incr).LastWriteTime})) {
    # ... but this time copy the files found to the newly created subdirectories
    Copy-Item -Path $item.FullName -Destination ($item.FullName -replace [regex]::Escape("$local:src"),"$local:dst\$current_date-i")
    }

    # If the path was empty, there was no no incremental backup
  } else {
    # Get the last full backup by filtering all items in the destination. Then
    # sort them by last write time and get the last one (ergo newest)
    $last_full = Get-ChildItem -Directory -Path $local:dst\* -Filter "*-v" | Sort-Object `
    LastWriteTime -Descending | Select-Object -First 1

    # For each item in the source that is newer than the creation time of the last
    # full backup...
    foreach ($item in (Get-ChildItem -Recurse -Path $local:src\* | Where-Object { $_.LastWriteTime -gt (Get-Item $last_full).LastWriteTime})) {
      # ... create all subdirectories by spliting the path of the original file,
      # and replacing everything the matches the source to the new destination
      New-Item -Type Directory -Path ((Split-Path $item.FullName) -replace [regex]::Escape("$local:src"),"$local:dst\$current_date-i")
    }

    # Do a similiar thing as with item creation...
    foreach ($item in (Get-ChildItem -Recurse -Path $local:src\* | Where-Object { $_.LastWriteTime -gt (Get-Item $last_full).LastWriteTime})) {
      # ... but this time copy the files found to the newly created subdirectories
      Copy-Item -Path $item.FullName -Destination ($item.FullName -replace [regex]::Escape("$local:src"),"$local:dst\$current_date-i")
    }
  }
 }

#### Testing which backup to run ###############################################
################################################################################

# If there is no previous backup, start a full backup. Else...
If (!(Get-ChildItem -Path "$global:dst" | Where-Object { $_.Name -match `
  $bak_pattern }))
{
  FullBackup $gloabal:dst $gloabal:src
  $test = Get-ChildItem -Path "$global:dst" -Filter "$bak_pattern"
}else{
  # ... decide which backup to run:
  # If the files are older than the offset for a full backup, start a full
  # backup.
  # If the files are older than the offset for the differential backup, run a
  # differential backup.
  # Otherwise the file is newer than the offset for the diff backup and an
  # incremental backup will be run.
  If (Test-Path -Path $dst_last.FullName -OlderThan ($check_date - $offset_full))
  {
    FullBackup
  }else{
    If (Test-Path -Path $dst_last.FullName -OlderThan ($check_date - $offset_diff))
    {
      DiffBackup
      #Write-Host "l2p m7+1"
    }else{
      IncrBackup
      #Write-Host "u wat m8"
     }
  }

}
