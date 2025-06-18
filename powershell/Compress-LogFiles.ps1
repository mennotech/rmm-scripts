<#
.SYNOPSIS
    This script compresses log files in a specified directory and deletes files older than a specified number of days.

.DESCRIPTION
    The script compresses log files in a specified directory (default is C:\Logs) and deletes files older than a specified number of days (default is 365 days).
    It creates a log file for the compression process and handles errors during file operations.
.EXAMPLE
    Compress-LogFiles.ps1 -logDirectory "C:\MyLogs" -daysToKeep 180

    This example compresses log files in the C:\MyLogs directory and deletes files older than 180 days.
.OUTPUTS
    Displays messages indicating the status of file compression and deletion.
    Logs the actions taken in a log file named CompressLog-YYYY-MM.log in the specified directory.
.NOTES
    2025-06-18: Initial version of the script.
.LINK
    https://github.com/mennotech/rmm-scripts/blob/main/powershell/Compress-LogFiles.ps1
.LICENSE
    This script is released under the MIT License.
#>

# This script compresses log files in a specified directory. And deletes files older than a specified number of days.
param (
    [string]$logDirectory = "C:\Logs",
    [int]$daysToKeep = 365
)

# Get current year and month for log file naming with the format YYYY-MM
$formattedDate = (Get-Date).ToString("yyyy-MM")


$logFilePath = Join-Path -Path $logDirectory -ChildPath "CompressLog-$($formattedDate).log"
Start-Transcript -Path $logFilePath -Append


try {
    # Ensure the log directory exists
    if (-Not (Test-Path -Path $logDirectory)) {
        Write-Host "Log directory does not exist: $logDirectory"
        exit 1
    }

    # Get the current date
    $currentDate = Get-Date
    # Get all log files in the directory
    $logFiles = Get-ChildItem -Path $logDirectory -Filter "*.zip" -File
    # Filter files older than the specified number of days
    $oldFiles = $logFiles | Where-Object { $_.LastWriteTime -lt $currentDate.AddDays(-$daysToKeep) }

    # Delete old log files
    foreach ($file in $oldFiles) {
        try {
            Remove-Item -Path $file.FullName -Force
            Write-Host "Deleted old log file: $($file.FullName)"
        } catch {
            Write-Host "Failed to delete file: $($file.FullName). Error: $_"
        }
    }
    # Compress log files that are not already compressed
    $uncompressedFiles = Get-ChildItem -Path $logDirectory -Filter "*.log" -File | Where-Object { $_.LastWriteTime -le $currentDate.AddDays(-2) }

    foreach ($file in $uncompressedFiles) {
        $zipFileName = "$($file.FullName).zip"
        if (-Not (Test-Path -Path $zipFileName)) {
            try {
                Compress-Archive -Path $file.FullName -DestinationPath $zipFileName -Force
                # Set modified time of the zip file to match the original log file
                $zipFile = Get-Item -Path $zipFileName
                $zipFile.LastWriteTime = $file.LastWriteTime
                $zipFile.CreationTime = $file.CreationTime
                Write-Host "Compressed log file: $($file.FullName) to $zipFileName"
                Remove-Item -Path $file.FullName -Force
            } catch {
                Write-Host "Failed to compress file: $($file.FullName). Error: $_"
            }
        } else {
            Write-Host "Zip file already exists for: $($file.FullName)"
        }
    }
} catch {
    Write-Host "An error occurred: $_"
} finally {
    Stop-Transcript
}
