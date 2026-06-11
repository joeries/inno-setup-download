Set-Location $Env:TEMP

Write-Host "InnoSetup: Getting lastest innoextract release"
$extract_release = Invoke-WebRequest https://api.github.com/repos/dscharrer/innoextract/releases/latest | ConvertFrom-Json

$extract_assets = $extract_release.assets
$extract_url = ""

Write-Host "InnoSetup: Getting windows zip"
foreach ($asset in $extract_assets) {
	if ($asset.name -match '-windows\.zip$') {
		Write-Host "InnoSetup: Windows zip found name ${asset.name}"
		$extract_url = $asset.browser_download_url
	}
}

if (-not $extract_url) {
	Write-Host "InnoSetup: Windows zip not found"
	exit 1
}

Write-Host "InnoSetup: Downloading innoextract"
Invoke-WebRequest -URI $extract_url -OutFile innoextract.zip
Write-Host "InnoSetup: Extracting innoextract.zip"
Expand-Archive innoextract.zip -DestinationPath innoextract
Set-Alias -Name Inno-Extract -Value "$(Get-Location)\innoextract\innoextract.exe"

Write-Host "InnoSetup: Downloading InnoSetup executable"
$dl_url = "https://github.com/jrsoftware/issrc/releases/download/is-" + ${env:IS_VERSION}.replace('.','_')
Invoke-WebRequest -URI $dl_url/innosetup-${env:IS_VERSION}.exe -OutFile inno.exe

Write-Host "InnoSetup: Extracting InnoSetup"
Inno-Extract inno.exe --output-dir ./ --include app
Rename-Item app -NewName inno

Write-Host "InnoSetup: Downloading encryption dll"
Invoke-WebRequest -URI https://res.uu163yun.com/directlink/idse/ISCrypt.dll -OutFile .\inno\ISCrypt.dll


Write-Host "InnoSetup: Adding InnoSetup to path"
Add-Content $Env:GITHUB_PATH "$(Get-Location)\inno"

Write-Host "InnoSetup: Set License Key if available"
Get-PSDrive -PSProvider Registry
# Set variables to indicate value and key to set
$RegistryPath = 'HKCU:\Software\Jordan Russell\Inno Setup'
$Name         = 'License'

# Create the key since it unlikely exists
If (-NOT (Test-Path $RegistryPath)) {
  New-Item -Path $RegistryPath -Force | Out-Null
}
# Now set the value
New-ItemProperty -Path $RegistryPath -Name $Name -Value ${env:IS_LICENSEKEY} -PropertyType String -Force
