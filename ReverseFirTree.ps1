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

# ===== TIE-BREAKING / RANKING =====
# Data type size order for tie-breaking (lower index = larger type)
$typeOrder = @(
    'long double', 'double', 'int64_t', 'long long', 'unsigned long long',
    'int32_t', 'int', 'float', 'unsigned int', 'short', 'char', 'bool'
)

function Get-TypeRank($type) {
    $type = $type.Trim()
    $idx = $typeOrder.IndexOf($type)
    if ($idx -ge 0) { return $idx }
    # Try to match partials (e.g., "unsigned int" in "unsigned int last_cursor_pos")
    foreach ($t in $typeOrder) {
        if ($type -like "$t*") { return $typeOrder.IndexOf($t) }
    }
    return [int]::MaxValue
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

        # Try to split type and variable for type-based sorting
        $type = ""
        if ($lhs -match '^(.*\S)\s+([a-zA-Z_]\w*)$') {
            $type = $matches[1]
        }
        elseif ($lhs -match '^([a-zA-Z_][\w\*]*)([a-zA-Z_]\w*)$') {
            $type = $matches[1]
        }
        else {
            $type = $lhs
        }

        $assignments += [PSCustomObject]@{
            LHS  = $lhs
            RHS  = $rhs
            Type = $type
        }
    }
    # Lines that don't match the assignment pattern are silently ignored.
}

# ===== REVERSE FIR TREE SORTING =====
# Sort assignment by longest to shortest, then by type size, then alphabetically
$assignments = $assignments | Sort-Object `
@{Expression = { ($_.LHS.Length + $_.RHS.Length) }; Descending = $true },
@{Expression = { Get-TypeRank $_.Type }; Ascending = $true },
@{Expression = { $_.LHS }; Ascending = $true }

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
Write-Information "Output written to: $outputFile"

# https://github.com/sukibaby
