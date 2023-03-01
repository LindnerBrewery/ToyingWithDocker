[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $User,
    [Parameter()]
    [String[]]
    $Extensions = @('ms-vscode.powershell', 'TylerLeonhardt.vscode-inline-values-powershell', 'Gruntfuggly.todo-tree')
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if ($user) {
    $UserHome = Join-Path 'C:\Users\' $User
}
else {
    $UserHome = $home
}


# get commit id from latest vscode version
$Url = 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user'

# Using Invoke-Webrequest will not work in PS5.1
# $response = Invoke-WebRequest $url -method Head -UseBasicParsing
# $commitId = $response.BaseResponse.RequestMessage.RequestUri.Segments[-2].trim('/')
# $codeVersion = $response.BaseResponse.RequestMessage.RequestUri.Segments[-1].trim('.exe').Split('-')[-1]

$request = [System.Net.HttpWebRequest]::Create($Url)
$request.Method = "HEAD"
$response = $request.GetResponse()
$rUri = $response.ResponseUri
$commitID = ($rUri.AbsolutePath -split '/')[-2]
$codeVersion = ($rUri.AbsolutePath -split '/')[-1].trim('.exe').Split('-')[-1]

Write-Output "Found commitID for VSCode $codeVersion `n$commitID"
# download and unzip newest vscode Server Version
$Url = "https://update.code.visualstudio.com/commit:$commitID/server-win32-x64/stable" 
Write-Output "Downloading VSCode-Server"
Invoke-WebRequest "https://update.code.visualstudio.com/commit:$commitID/server-win32-x64/stable" -OutFile $UserHome/$commitID.zip -UseBasicParsing
Write-Output "Expanding VSCode-Server"
Expand-Archive -Path $UserHome/$commitID.zip -DestinationPath $UserHome\.vscode-server\bin\ -Force

Write-Output "Removing Zip file"
Remove-Item -Path $UserHome/$commitID.zip
Rename-Item -Path $UserHome\.vscode-server\bin\vscode-server-win32-x64 -NewName $commitID

# without 0 file vscode throws an error on first connect and re-downloads the file # ToDo: Check this again!
New-item $UserHome\.vscode-server\bin\$commitID\0 -ItemType File

# install vscode extensions
Get-ChildItem -Path $UserHome\.vscode-server\bin\ -Recurse | Where-Object name -like node.exe
$node = Get-Command (Get-ChildItem -Path $UserHome\.vscode-server\bin\ -Recurse | Where-Object name -EQ node.exe)
$rootPath = Split-Path $node.path
foreach ($ex in $Extensions) {
    & $node "$rootPath\out\server-main.js" --install-extension $ex --force
}

# set vscode Settings
$settingsJson = @"
{
    "powershell.powerShellAdditionalExePaths": {
        "Downloaded PowerShell 7": "c:/programdata/pwsh/pwsh.exe",
    },
    "powershell.powerShellDefaultVersion": "Downloaded PowerShell 7",
}
"@
$settingsJson | Out-File $home\.vscode-server\data\machine\settings.json -force
# copy extension to designated user
if($user){
    Copy-Item -Path $Home\.vscode-server -Recurse -Destination $UserHome -Container -force
}
