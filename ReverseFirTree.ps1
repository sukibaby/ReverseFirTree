<#
.SYNOPSIS
    Formats assignment statements from an input file into a reverse fir tree (reverse XMAS tree) pattern.

.DESCRIPTION
    This script reads a file containing assignment statements, normalizes spacing,
    and sorts them by total line length (shortest to longest). It also considers the
    sizes of common C++ datatypes to further refine the sorting.
    
    The reverse fir tree style is preferred by Kernel Maintainers KVM 5.4.2. "Coding Style".

.PARAMETER InputFile
    The full path to the file containing assignment statements to be processed.
    Each line should follow the pattern: [type] variable = value;
    Extraneous whitespace will be trimmed and normalized.
	
.LINK
    https://github.com/sukibaby/ReverseFirTree
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
    # Extended precision (GCC-specific)
    'long double',

    # 64-bit types
    'double',
    'int64_t', 'uint64_t',
    'long long', 'unsigned long long',
    '__int64', 'unsigned __int64',

    # 32- or 64-bit, depending on platform
    'long', 'unsigned long',

    # 32-bit types
    'int32_t', 'uint32_t',
    'int', 'unsigned int',
    '__int32', 'unsigned __int32',

    # 16-bit types
    'int16_t', 'uint16_t',
    'short', 'unsigned short',
    '__int16', 'unsigned __int16',

    # 8-bit types
    'int8_t', 'uint8_t',
    'char', 'unsigned char',
    '__int8', 'unsigned __int8',

    # Boolean and pointer-sized types
    'bool',
    'intptr_t', 'uintptr_t',
    'size_t', 'ssize_t',
    'ptrdiff_t'
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

    # TODO: Fix handling of uninitialized variables (e.g. `int x;`)
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
# Sort by the combined length of LHS and RHS (descending), then by type
# size (ascending), then by LHS alphabetically (ascending)
$assignments = $assignments | Sort-Object @(
    @{Expression={($_.LHS.Length + $_.RHS.Length)}; Descending=$true},
    @{Expression={Get-TypeRank $_.Type}; Ascending=$true},
    @{Expression={$_.LHS}; Ascending=$true}
)

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

<#
Copyright (c) 2025 sukibaby

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>
