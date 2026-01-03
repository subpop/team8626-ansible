# FRC Team 8626 - Browser Bookmarks Installer
# Adds FRC Resources bookmarks to Chrome and Edge
#
# Standalone usage: .\Install-Bookmarks.ps1
# Module usage: . .\Install-Bookmarks.ps1; Install-BrowserBookmarks

#Requires -RunAsAdministrator

param(
    [switch]$Standalone
)

# Import shared modules
$modulePath = $PSScriptRoot
. "$modulePath\FRCConfig.ps1"
. "$modulePath\FRCHelpers.ps1"

# ============================================================================
# Installation Functions
# ============================================================================

function Set-EdgeStartPage {
    <#
    .SYNOPSIS
        Configures Edge start page to show only a search bar
    .DESCRIPTION
        Disables all start page content (news, quick links, top sites) 
        while keeping the search bar via Edge policies
    #>
    param([string]$Step = "1/1")
    
    Write-Step $Step "Configuring Edge start page (search bar only)..."

    $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

    try {
        # Create Edge policy key if it doesn't exist
        if (-not (Test-Path $edgePolicyPath)) {
            New-Item -Path $edgePolicyPath -Force | Out-Null
        }

        # Disable content feed (news, articles, etc.)
        Set-ItemProperty -Path $edgePolicyPath -Name "NewTabPageContentEnabled" -Value 0 -Type DWord

        # Disable quick links
        Set-ItemProperty -Path $edgePolicyPath -Name "NewTabPageQuickLinksEnabled" -Value 0 -Type DWord

        # Hide default top sites
        Set-ItemProperty -Path $edgePolicyPath -Name "NewTabPageHideDefaultTopSites" -Value 1 -Type DWord

        # Disable sponsored content
        Set-ItemProperty -Path $edgePolicyPath -Name "NewTabPagePrerenderEnabled" -Value 0 -Type DWord

        # Set background to no image (solid color)
        Set-ItemProperty -Path $edgePolicyPath -Name "NewTabPageAllowedBackgroundTypes" -Value 1 -Type DWord

        Write-Success "Edge start page configured (search bar only)"
    } catch {
        Write-Info "Could not configure Edge start page: $_"
    }
}

function Install-BrowserBookmarks {
    param([string]$Step = "1/1")
    
    Write-Step $Step "Installing FRC browser bookmarks..."

    # Browser configurations (Chromium-based browsers share the same bookmark format)
    $browsers = @(
        @{ Name = "Chrome"; ProfilePath = "Google\Chrome\User Data" }
        @{ Name = "Edge"; ProfilePath = "Microsoft\Edge\User Data" }
    )

    # Get all user profile directories
    $userProfiles = Get-ChildItem "C:\Users" -Directory | Where-Object {
        $_.Name -notin @("Public", "Default", "Default User", "All Users") -and
        -not $_.Name.StartsWith(".")
    }

    $bookmarksAdded = $false

    foreach ($userProfile in $userProfiles) {
        foreach ($browser in $browsers) {
            $browserDataPath = Join-Path $userProfile.FullName "AppData\Local\$($browser.ProfilePath)"
            $bookmarkFile = Join-Path $browserDataPath "Default\Bookmarks"
            $bookmarkDir = Split-Path $bookmarkFile -Parent

            # Skip if browser profile doesn't exist (browser never launched)
            if (-not (Test-Path $bookmarkDir)) {
                continue
            }

            try {
                # Check if bookmark file is locked (browser is running)
                $fileStream = $null
                if (Test-Path $bookmarkFile) {
                    try {
                        $fileStream = [System.IO.File]::Open($bookmarkFile, 'Open', 'ReadWrite', 'None')
                        $fileStream.Close()
                    } catch {
                        Write-Info "Skipping $($browser.Name) for $($userProfile.Name) - browser may be running"
                        continue
                    }
                }

                # Load existing bookmarks or create new structure
                if (Test-Path $bookmarkFile) {
                    $bookmarkData = Get-Content $bookmarkFile -Raw | ConvertFrom-Json
                } else {
                    # Create new bookmark structure
                    $bookmarkData = [PSCustomObject]@{
                        checksum = ""
                        roots = [PSCustomObject]@{
                            bookmark_bar = [PSCustomObject]@{
                                children = @()
                                date_added = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000)
                                date_last_used = "0"
                                date_modified = "0"
                                guid = [guid]::NewGuid().ToString()
                                id = "1"
                                name = "Bookmarks bar"
                                type = "folder"
                            }
                            other = [PSCustomObject]@{
                                children = @()
                                date_added = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000)
                                date_last_used = "0"
                                date_modified = "0"
                                guid = [guid]::NewGuid().ToString()
                                id = "2"
                                name = "Other bookmarks"
                                type = "folder"
                            }
                            synced = [PSCustomObject]@{
                                children = @()
                                date_added = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000)
                                date_last_used = "0"
                                date_modified = "0"
                                guid = [guid]::NewGuid().ToString()
                                id = "3"
                                name = "Mobile bookmarks"
                                type = "folder"
                            }
                        }
                        version = 1
                    }
                }

                # Check if FRC Resources folder already exists
                $bookmarkBar = $bookmarkData.roots.bookmark_bar
                $frcFolder = $bookmarkBar.children | Where-Object { $_.name -eq "FRC Resources" -and $_.type -eq "folder" }

                if ($frcFolder) {
                    Write-Info "$($browser.Name) bookmarks already configured for $($userProfile.Name)"
                    continue
                }

                # Get the next available ID
                $maxId = 3
                function Get-MaxId($node) {
                    if ($node.id) {
                        $id = [int]$node.id
                        if ($id -gt $script:maxId) { $script:maxId = $id }
                    }
                    if ($node.children) {
                        foreach ($child in $node.children) {
                            Get-MaxId $child
                        }
                    }
                }
                Get-MaxId $bookmarkData.roots.bookmark_bar
                Get-MaxId $bookmarkData.roots.other
                if ($bookmarkData.roots.synced) { Get-MaxId $bookmarkData.roots.synced }

                $nextId = $maxId + 1
                $timestamp = [string]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000)

                # Create FRC Resources folder with bookmarks
                $frcBookmarkChildren = @()
                foreach ($bookmark in $FRCConfig.FRCBookmarks) {
                    $nextId++
                    $frcBookmarkChildren += [PSCustomObject]@{
                        date_added = $timestamp
                        date_last_used = "0"
                        guid = [guid]::NewGuid().ToString()
                        id = [string]$nextId
                        name = $bookmark.Name
                        type = "url"
                        url = $bookmark.Url
                    }
                }

                $nextId++
                $frcResourcesFolder = [PSCustomObject]@{
                    children = $frcBookmarkChildren
                    date_added = $timestamp
                    date_last_used = "0"
                    date_modified = $timestamp
                    guid = [guid]::NewGuid().ToString()
                    id = [string]$nextId
                    name = "FRC Resources"
                    type = "folder"
                }

                # Add FRC Resources folder to bookmark bar
                $bookmarkBar.children = @($frcResourcesFolder) + @($bookmarkBar.children)

                # Update date_modified on bookmark bar
                $bookmarkBar.date_modified = $timestamp

                # Save bookmarks
                $bookmarkJson = $bookmarkData | ConvertTo-Json -Depth 20
                Set-Content -Path $bookmarkFile -Value $bookmarkJson -Encoding UTF8

                Write-Success "Added FRC bookmarks to $($browser.Name) for $($userProfile.Name)"
                $bookmarksAdded = $true

            } catch {
                Write-Info "Could not update $($browser.Name) bookmarks for $($userProfile.Name): $_"
            }
        }
    }

    if (-not $bookmarksAdded) {
        Write-Info "No browser profiles found or all already configured"
    }
}

# ============================================================================
# Standalone Execution
# ============================================================================

# Detect if running standalone (not dot-sourced)
$isStandalone = $MyInvocation.InvocationName -notin @(".", "&") -or $Standalone

if ($isStandalone) {
    Write-Banner "FRC Team 8626 - Browser Configuration"
    
    Install-BrowserBookmarks -Step "1/2"
    Set-EdgeStartPage -Step "2/2"
    
    Write-Banner "Installation Complete!"
    Write-Host "Browser configuration applied:" -ForegroundColor White
    Write-Host "  - FRC Resources bookmarks added to Chrome and Edge" -ForegroundColor Green
    Write-Host "  - Edge start page set to search bar only" -ForegroundColor Green
}

