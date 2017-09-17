#### Variable Assignment #######################################################
################################################################################

# Get source and destination from user input, assign as global variables
Param($global:src,$global:dst)

# Global variables src and dst, assigning for testing
#$src = "C:\Users\bob\Documents\Backups2"
#$dst = "C:\Users\bob\Documents\Test2"

#### Check for backups and restore #############################################
################################################################################
# Get the last full backup
$last_full = Get-ChildItem -Directory -Path $src\* -Filter "*-v" | Sort-Object `
LastWriteTime -Descending | Select-Object -First 1

# If there is a full backup, restore the full backup
if ($last_full) {

    # Copy the full backup to the destination
    Copy-Item -Recurse -Path $last_full\* -Destination $dst
    Write-Host "Restored $last_full"

    # Get the date of the last full backup for comparison
    $last_date = $last_full.LastWriteTime

    # Get the last differential backup
    $last_diff = Get-ChildItem -Directory -Path $src\* -Filter "*-d" | `
    Where-Object { $_.LastWriteTime -gt $last_date } | Sort-Object LastWriteTime -Descending `
    | Select-Object -First 1

    # If there is a differential backup, restore the differential backup
    if ($last_diff){

      # Copy the differential backup to the destination
      Copy-Item -Recurse -Path $last_diff\* -Force -Destination $dst
      Write-Host "Restored $last_diff"

      # Get the last differential backup date
      $last_date = $last_diff.LastWriteTime
    }

    # Get the last set of incremental backups and sort by oldest to newest
    $last_incr = Get-ChildItem -Directory -Path $src\* -Filter "*-i" | `
    Where-Object { $_.LastWriteTime -gt $last_date } | Sort-Object LastWriteTime

    # If there are incremental backups, restore incremental backups from oldest to newest
    if ($last_incr){

      # Copy each incremental backup to the destination
      foreach ($folder in $last_incr) {
      Copy-Item -Recurse -Path $folder\* -Force -Destination $dst
      Write-Host "Restored $folder"
        }
    }

  # If there was no full backup, there is nothing to restore
} else {
  Write-Host "No full backup found, nothing to restore"
}
