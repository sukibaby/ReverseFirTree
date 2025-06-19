<#
.SYNOPSIS
    Formats assignment statements from an input file into a reverse fir tree (reverse XMAS tree) pattern.
    
.DESCRIPTION
    This script reads a file containing assignment statements, normalizes spacing,
    and sorts them by total line length (shortest to longest). The reverse fir tree
    style is preferred by Kernel Maintainers KVM 5.4.2. "Coding Style".

    TODO: add C++ data type awareness for better sorting
    
.PARAMETER InputFile
    The full path to the file containing assignment statements to be processed.
    Each line should follow the pattern: [type] variable = value;
    Extraneous whitespace will be trimmed and normalized.
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$InputFile
)

if (-not (Test-Path $InputFile)) {
    Write-Error "Input file does not exist: $InputFile"
    exit 1
}

# ===== OUTPUT FILE PREPARATION =====
# Default $dir to . if it's empty (for running within PowerShell ISE, etc)
$dir = Split-Path $InputFile
if ([string]::IsNullOrWhiteSpace($dir)) { $dir = "." }

# Construct the output file path by appending "_formatted" to the original filename
$base = [System.IO.Path]::GetFileNameWithoutExtension($InputFile) # Extract filename without extension
$ext = [System.IO.Path]::GetExtension($InputFile) # Extract file extension
$outputFile = Join-Path $dir ("${base}_formatted$ext")

# ===== INPUT FILE PROCESSING =====
$assignments = @()

# Read the input file line by line and extract assignment components
Get-Content $InputFile | ForEach-Object {
    # Normalize whitespace: Remove all tabs, then trim leading/trailing spaces
    $line = $_ -replace "`t", " " | ForEach-Object { $_.Trim() }

    # "lhs = rhs;"
    if ($line -match '^(.*?)\s*=\s*(.*?);$') {
        $lhs = $matches[1].TrimEnd()
        $rhs = $matches[2].Trim()
        $assignments += [PSCustomObject]@{
            LHS = $lhs
            RHS = $rhs
        }
    }
    # Lines that don't match the assignment pattern are silently ignored.
}

# ===== REVERSE FIR TREE SORTING =====
# Sort assignments by total length (lhs + rhs) from shortest to longest
$assignments = $assignments | Sort-Object { ($_.LHS.Length + $_.RHS.Length) }

# ===== OUTPUT FILE GENERATION =====
# Format each assignment with consistent spacing: "lhs = rhs;"
$outLines = $assignments | ForEach-Object {
    "$($_.LHS) = $($_.RHS);"
}

# Do one last pass to check for extraneous spaces.
$outLines = $outLines | ForEach-Object {
    ($_ -replace '\s+', ' ').Trim()
}

# Write the processed lines to the output file with UTF-8 encoding
$outLines | Set-Content $outputFile -Encoding UTF8

# Finish up :-D
Write-Host "Output written to: $outputFile"

# https://github.com/sukibaby
