$ErrorActionPreference = ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U2lsZW50bHlDb250aW51ZQ==')))
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:uid1 = -join ((65..90)+(97..122) | Get-Random -Count 14 | % {[char]$_})
$script:uid2 = -join ((65..90)+(97..122) | Get-Random -Count 13 | % {[char]$_})

Add-Type -TypeDefinition @"
using System;
using System.Threading;
using System.Runtime.InteropServices;

public class $($script:uid1) {
    [DllImport("user32.dll")] static extern uint SendInput(uint n, INPUT[] i, int s);
    [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public MI mi; }
    [StructLayout(LayoutKind.Sequential)] struct MI { public int dx,dy; public uint md,fl,t; public IntPtr ei; }

    public static void ClickLeft() {
        var a=new INPUT[2]; a[0].type=a[1].type=0; a[0].mi.fl=2; a[1].mi.fl=4;
        SendInput(2,a,System.Runtime.InteropServices.Marshal.SizeOf(typeof(INPUT)));
    }
    public static void ClickRight() {
        var a=new INPUT[2]; a[0].type=a[1].type=0; a[0].mi.fl=8; a[1].mi.fl=16;
        SendInput(2,a,System.Runtime.InteropServices.Marshal.SizeOf(typeof(INPUT)));
    }

    private static Thread _threadL;
    private static Thread _threadR;
    private static volatile bool _runL = false;
    private static volatile bool _runR = false;
    private static volatile int  _cpsL = 10;
    private static volatile int  _cpsR = 10;

    public static void StartLeft(int cps)  { _cpsL=cps; if(_runL) return; _runL=true;  _threadL=new Thread(LoopL){IsBackground=true}; _threadL.Start(); }
    public static void StopLeft()          { _runL=false; }
    public static void StartRight(int cps) { _cpsR=cps; if(_runR) return; _runR=true;  _threadR=new Thread(LoopR){IsBackground=true}; _threadR.Start(); }
    public static void StopRight()         { _runR=false; }
    public static void SetCpsLeft(int cps) { _cpsL=cps; }
    public static void SetCpsRight(int cps){ _cpsR=cps; }

    private static void LoopL() {
        while(_runL) {
            ClickLeft();
            int ms = Math.Max(1, (int)(1000.0/_cpsL));
            Thread.Sleep(ms);
        }
    }
    private static void LoopR() {
        while(_runR) {
            ClickRight();
            int ms = Math.Max(1, (int)(1000.0/_cpsR));
            Thread.Sleep(ms);
        }
    }
}

public class $($script:uid2) {
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int v);
    public static bool IsPressed(int v) { return (GetAsyncKeyState(v) & 0x8000) != 0; }
}
"@

$script:leftVK=0;   $script:rightVK=0
$script:leftCps=10; $script:rightCps=10
$script:leftActive=$false;  $script:rightActive=$false
$script:waitL=$false;  $script:waitR=$false
$script:skipL=$false;  $script:skipR=$false
$script:prevL=$false;  $script:prevR=$false
$script:timerPoll=$null; $script:timerAnim=$null
$script:dragForm=$false; $script:dragPt=$null
$script:draggingL=$false; $script:draggingR=$false
$script:nodes=@()
$script:bmp=New-Object System.Drawing.Bitmap(460,440)

$keyMap=@{
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RjE=')))=0x70;"$([char]0x46)$([char]0x32)"=0x71;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RjM=')))=0x72;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RjQ=')))=0x73;"$([char]0x46)$([char]0x35)"=0x74;(-join([char]0x46, [char]0x36))=0x75
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Rjc=')))=0x76;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Rjg=')))=0x77;([System.Text.Encoding]::UTF8.GetString([byte[]](0x46,0x39)))=0x78;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RjEw')))=0x79;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RjEx')))=0x7A;([System.Text.Encoding]::UTF8.GetString([byte[]](0x46,0x31,0x32)))=0x7B
    ([System.Text.Encoding]::UTF8.GetString([byte[]](0x41)))=0x41;"$([char]0x42)"=0x42;([System.Text.Encoding]::UTF8.GetString([byte[]](0x43)))=0x43;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RA==')))=0x44;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RQ==')))=0x45;([System.Text.Encoding]::UTF8.GetString([byte[]](0x46)))=0x46
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Rw==')))=0x47;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('SA==')))=0x48;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('SQ==')))=0x49;(-join([char]0x4A))=0x4A;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Sw==')))=0x4B;"$([char]0x4C)"=0x4C
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TQ==')))=0x4D;([System.Text.Encoding]::UTF8.GetString([byte[]](0x4E)))=0x4E;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Tw==')))=0x4F;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UA==')))=0x50;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UQ==')))=0x51;"$([char]0x52)"=0x52
    ([System.Text.Encoding]::UTF8.GetString([byte[]](0x53)))=0x53;"$([char]0x54)"=0x54;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VQ==')))=0x55;(-join([char]0x56))=0x56;(-join([char]0x57))=0x57;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('WA==')))=0x58
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('WQ==')))=0x59;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Wg==')))=0x5A
    "$([char]0x44)$([char]0x30)"=0x30;(-join([char]0x44, [char]0x31))=0x31;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDI=')))=0x32;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDM=')))=0x33;(-join([char]0x44, [char]0x34))=0x34
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDU=')))=0x35;"$([char]0x44)$([char]0x36)"=0x36;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDc=')))=0x37;(-join([char]0x44, [char]0x38))=0x38;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDk=')))=0x39
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U3BhY2U=')))=0x20;(-join([char]0x53, [char]0x68, [char]0x69, [char]0x66, [char]0x74))=0x10;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Q29udHJvbA==')))=0x11;([System.Text.Encoding]::UTF8.GetString([byte[]](0x41,0x6C,0x74)))=0x12
    (-join([char]0x58, [char]0x42, [char]0x75, [char]0x74, [char]0x74, [char]0x6F, [char]0x6E, [char]0x31))=0x05;([System.Text.Encoding]::UTF8.GetString([byte[]](0x58,0x42,0x75,0x74,0x74,0x6F,0x6E,0x32)))=0x06
}

$rng=New-Object System.Random
for($i=0;$i -lt 45;$i++){
    $script:nodes+=[PSCustomObject]@{
        x=$rng.NextDouble()*460; y=$rng.NextDouble()*440
        vx=($rng.NextDouble()-0.5)*0.6; vy=($rng.NextDouble()-0.5)*0.6
    }
}

$CY=[System.Drawing.Color]::FromArgb(255,204,0)
$CB=[System.Drawing.Color]::FromArgb(8,8,8)
$CC=[System.Drawing.Color]::FromArgb(22,22,22)
$CR=[System.Drawing.Color]::FromArgb(55,55,55)
$CT=[System.Drawing.Color]::FromArgb(210,210,210)
$CD=[System.Drawing.Color]::FromArgb(100,100,100)
$CK=[System.Drawing.Color]::FromArgb(40,40,40)
$CW=[System.Drawing.Color]::White
$BK=[System.Drawing.Color]::Black

function F($n,$sz,$b=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UmVndWxhcg==')))){New-Object System.Drawing.Font($n,$sz,[System.Drawing.FontStyle]::$b)}

function RenderConstellation {
    $g=[System.Drawing.Graphics]::FromImage($script:bmp)
    $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear($CB)
    $nd=$script:nodes; $cnt=$nd.Count
    for($ai=0;$ai -lt $cnt;$ai++){
        $a=$nd[$ai]
        for($bi=$ai+1;$bi -lt $cnt;$bi++){
            $b=$nd[$bi]
            $dx=$a.x-$b.x; $dy=$a.y-$b.y
            $d=[math]::Sqrt($dx*$dx+$dy*$dy)
            if($d -lt 110){
                $al=[int](65*(1.0-$d/110.0))
                if($al -gt 0){
                    $p=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($al,255,204,0),0.9)
                    $g.DrawLine($p,[float]$a.x,[float]$a.y,[float]$b.x,[float]$b.y)
                    $p.Dispose()
                }
            }
        }
    }
    foreach($n2 in $script:nodes){
        $br=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(200,255,204,0))
        $g.FillEllipse($br,[float]($n2.x-2.5),[float]($n2.y-2.5),5.0,5.0)
        $br.Dispose()
    }
    $g.Dispose()
    $form.BackgroundImage=$script:bmp
}

$form=New-Object System.Windows.Forms.Form
$form.Text="$([char]0x48)$([char]0x45)$([char]0x52)$([char]0x4F)$([char]0x20)$([char]0x43)$([char]0x6C)$([char]0x69)$([char]0x63)$([char]0x6B)$([char]0x65)$([char]0x72)"
$form.ClientSize=New-Object System.Drawing.Size(460,440)
$form.StartPosition=(-join([char]0x43, [char]0x65, [char]0x6E, [char]0x74, [char]0x65, [char]0x72, [char]0x53, [char]0x63, [char]0x72, [char]0x65, [char]0x65, [char]0x6E))
$form.BackColor=$CB
$form.FormBorderStyle=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Tm9uZQ==')))
$form.TopMost=$true
$form.KeyPreview=$true
$form.DoubleBuffered=$true

RenderConstellation

$card=New-Object System.Windows.Forms.Panel
$card.Location=New-Object System.Drawing.Point(80,50)
$card.Size=New-Object System.Drawing.Size(300,336)
$card.BackColor=$CC
$form.Controls.Add($card)

$card.Add_Paint({
    param($s,$e)
    $g=$e.Graphics
    $p=New-Object System.Drawing.Pen($CR,1)
    $g.DrawRectangle($p,0,0,$card.Width-1,$card.Height-1); $p.Dispose()
    $p2=New-Object System.Drawing.Pen($CY,2)
    $g.DrawLine($p2,0,0,$card.Width,0); $p2.Dispose()
})

$lblTitle=New-Object System.Windows.Forms.Label
$lblTitle.Text=([System.Text.Encoding]::UTF8.GetString([byte[]](0x48,0x45,0x52,0x4F))); $lblTitle.Location=New-Object System.Drawing.Point(0,12)
$lblTitle.Size=New-Object System.Drawing.Size(300,44); $lblTitle.Font=F (-join([char]0x49, [char]0x6D, [char]0x70, [char]0x61, [char]0x63, [char]0x74)) 30
$lblTitle.ForeColor=$CY; $lblTitle.TextAlign="$([char]0x4D)$([char]0x69)$([char]0x64)$([char]0x64)$([char]0x6C)$([char]0x65)$([char]0x43)$([char]0x65)$([char]0x6E)$([char]0x74)$([char]0x65)$([char]0x72)"; $lblTitle.BackColor=[System.Drawing.Color]::Transparent
$card.Controls.Add($lblTitle)

$lblSub=New-Object System.Windows.Forms.Label
$lblSub.Text=(-join([char]0x2022, [char]0x20, [char]0x41, [char]0x75, [char]0x74, [char]0x6F, [char]0x20, [char]0x43, [char]0x6C, [char]0x69, [char]0x63, [char]0x6B, [char]0x65, [char]0x72, [char]0x20, [char]0x2022)); $lblSub.Location=New-Object System.Drawing.Point(0,56)
$lblSub.Size=New-Object System.Drawing.Size(300,16); $lblSub.Font=F "$([char]0x53)$([char]0x65)$([char]0x67)$([char]0x6F)$([char]0x65)$([char]0x20)$([char]0x55)$([char]0x49)" 8
$lblSub.ForeColor=$CD; $lblSub.TextAlign=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TWlkZGxlQ2VudGVy'))); $lblSub.BackColor=[System.Drawing.Color]::Transparent
$card.Controls.Add($lblSub)

function MakeSep($y){
    $p=New-Object System.Windows.Forms.Panel
    $p.Location=New-Object System.Drawing.Point(20,$y)
    $p.Size=New-Object System.Drawing.Size(260,1); $p.BackColor=$CR
    $card.Controls.Add($p)
}
MakeSep 78; MakeSep 165; MakeSep 254

$SW=240; $TH=14; $TK=6; $TV=22

$lblL=New-Object System.Windows.Forms.Label
$lblL.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('QUNUSU9OIDEgIC0gIExFRlQgQ0xJQ0s='))); $lblL.Location=New-Object System.Drawing.Point(20,87)
$lblL.Size=New-Object System.Drawing.Size(260,16); $lblL.Font=F ([System.Text.Encoding]::UTF8.GetString([byte[]](0x53,0x65,0x67,0x6F,0x65,0x20,0x55,0x49))) 8 ([System.Text.Encoding]::UTF8.GetString([byte[]](0x42,0x6F,0x6C,0x64)))
$lblL.ForeColor=$CD; $lblL.BackColor=[System.Drawing.Color]::Transparent; $card.Controls.Add($lblL)

$btnL=New-Object System.Windows.Forms.Button
$btnL.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('QklORCBLRVk='))); $btnL.Location=New-Object System.Drawing.Point(20,107)
$btnL.Size=New-Object System.Drawing.Size(110,28); $btnL.FlatStyle=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RmxhdA==')))
$btnL.BackColor=$CK; $btnL.ForeColor=$CT; $btnL.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U2Vnb2UgVUk='))) 8 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Qm9sZA==')))
$btnL.FlatAppearance.BorderColor=$CR; $btnL.FlatAppearance.BorderSize=1
$btnL.Cursor=[System.Windows.Forms.Cursors]::Hand; $card.Controls.Add($btnL)

$lblCpsL=New-Object System.Windows.Forms.Label
$lblCpsL.Text=([System.Text.Encoding]::UTF8.GetString([byte[]](0x31,0x30,0x20,0x43,0x50,0x53))); $lblCpsL.Location=New-Object System.Drawing.Point(140,107)
$lblCpsL.Size=New-Object System.Drawing.Size(140,28); $lblCpsL.Font=F (-join([char]0x53, [char]0x65, [char]0x67, [char]0x6F, [char]0x65, [char]0x20, [char]0x55, [char]0x49)) 12 ([System.Text.Encoding]::UTF8.GetString([byte[]](0x42,0x6F,0x6C,0x64)))
$lblCpsL.ForeColor=$CY; $lblCpsL.BackColor=[System.Drawing.Color]::Transparent; $lblCpsL.TextAlign=(-join([char]0x4D, [char]0x69, [char]0x64, [char]0x64, [char]0x6C, [char]0x65, [char]0x52, [char]0x69, [char]0x67, [char]0x68, [char]0x74))
$card.Controls.Add($lblCpsL)

$trackL=New-Object System.Windows.Forms.Panel
$trackL.Location=New-Object System.Drawing.Point(20,143); $trackL.Size=New-Object System.Drawing.Size($SW,$TK)
$trackL.BackColor=$CK; $trackL.Cursor=[System.Windows.Forms.Cursors]::Hand; $card.Controls.Add($trackL)
$fillL=New-Object System.Windows.Forms.Panel
$fillL.Location=New-Object System.Drawing.Point(0,0); $fillL.Size=New-Object System.Drawing.Size(1,$TK)
$fillL.BackColor=$CY; $fillL.Enabled=$false; $trackL.Controls.Add($fillL)

$thumbL=New-Object System.Windows.Forms.Panel
$thumbL.Size=New-Object System.Drawing.Size($TH,$TV); $thumbL.BackColor=$CY
$thumbL.Cursor=[System.Windows.Forms.Cursors]::Hand
$thumbL.Location=New-Object System.Drawing.Point(($card.Left+20-[int]($TH/2)),($card.Top+143-[int](($TV-$TK)/2)))
$form.Controls.Add($thumbL)

$lblR=New-Object System.Windows.Forms.Label
$lblR.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('QUNUSU9OIDIgIC0gIFJJR0hUIENMSUNL'))); $lblR.Location=New-Object System.Drawing.Point(20,175)
$lblR.Size=New-Object System.Drawing.Size(260,16); $lblR.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U2Vnb2UgVUk='))) 8 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Qm9sZA==')))
$lblR.ForeColor=$CD; $lblR.BackColor=[System.Drawing.Color]::Transparent; $card.Controls.Add($lblR)

$btnR=New-Object System.Windows.Forms.Button
$btnR.Text=(-join([char]0x42, [char]0x49, [char]0x4E, [char]0x44, [char]0x20, [char]0x4B, [char]0x45, [char]0x59)); $btnR.Location=New-Object System.Drawing.Point(20,195)
$btnR.Size=New-Object System.Drawing.Size(110,28); $btnR.FlatStyle=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RmxhdA==')))
$btnR.BackColor=$CK; $btnR.ForeColor=$CT; $btnR.Font=F (-join([char]0x53, [char]0x65, [char]0x67, [char]0x6F, [char]0x65, [char]0x20, [char]0x55, [char]0x49)) 8 (-join([char]0x42, [char]0x6F, [char]0x6C, [char]0x64))
$btnR.FlatAppearance.BorderColor=$CR; $btnR.FlatAppearance.BorderSize=1
$btnR.Cursor=[System.Windows.Forms.Cursors]::Hand; $card.Controls.Add($btnR)

$lblCpsR=New-Object System.Windows.Forms.Label
$lblCpsR.Text=([System.Text.Encoding]::UTF8.GetString([byte[]](0x31,0x30,0x20,0x43,0x50,0x53))); $lblCpsR.Location=New-Object System.Drawing.Point(140,195)
$lblCpsR.Size=New-Object System.Drawing.Size(140,28); $lblCpsR.Font=F ([System.Text.Encoding]::UTF8.GetString([byte[]](0x53,0x65,0x67,0x6F,0x65,0x20,0x55,0x49))) 12 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Qm9sZA==')))
$lblCpsR.ForeColor=$CY; $lblCpsR.BackColor=[System.Drawing.Color]::Transparent; $lblCpsR.TextAlign="$([char]0x4D)$([char]0x69)$([char]0x64)$([char]0x64)$([char]0x6C)$([char]0x65)$([char]0x52)$([char]0x69)$([char]0x67)$([char]0x68)$([char]0x74)"
$card.Controls.Add($lblCpsR)

$trackR=New-Object System.Windows.Forms.Panel
$trackR.Location=New-Object System.Drawing.Point(20,231); $trackR.Size=New-Object System.Drawing.Size($SW,$TK)
$trackR.BackColor=$CK; $trackR.Cursor=[System.Windows.Forms.Cursors]::Hand; $card.Controls.Add($trackR)
$fillR=New-Object System.Windows.Forms.Panel
$fillR.Location=New-Object System.Drawing.Point(0,0); $fillR.Size=New-Object System.Drawing.Size(1,$TK)
$fillR.BackColor=$CY; $fillR.Enabled=$false; $trackR.Controls.Add($fillR)

$thumbR=New-Object System.Windows.Forms.Panel
$thumbR.Size=New-Object System.Drawing.Size($TH,$TV); $thumbR.BackColor=$CY
$thumbR.Cursor=[System.Windows.Forms.Cursors]::Hand
$thumbR.Location=New-Object System.Drawing.Point(($card.Left+20-[int]($TH/2)),($card.Top+231-[int](($TV-$TK)/2)))
$form.Controls.Add($thumbR)

$lblStatus=New-Object System.Windows.Forms.Label
$lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pePIFJFQURZ'))); $lblStatus.Location=New-Object System.Drawing.Point(0,263)
$lblStatus.Size=New-Object System.Drawing.Size(300,34); $lblStatus.Font=F (-join([char]0x53, [char]0x65, [char]0x67, [char]0x6F, [char]0x65, [char]0x20, [char]0x55, [char]0x49)) 9 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('SXRhbGlj')))
$lblStatus.ForeColor=$CD; $lblStatus.BackColor=[System.Drawing.Color]::Transparent; $lblStatus.TextAlign=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TWlkZGxlQ2VudGVy')))
$card.Controls.Add($lblStatus)

$lblCred=New-Object System.Windows.Forms.Label
$lblCred.Text=(-join([char]0x4D, [char]0x61, [char]0x64, [char]0x65, [char]0x20, [char]0x62, [char]0x79, [char]0x20, [char]0x64, [char]0x70, [char]0x73, [char]0x73, [char]0x73, [char]0x30)); $lblCred.Location=New-Object System.Drawing.Point(0,305)
$lblCred.Size=New-Object System.Drawing.Size(300,22); $lblCred.Font=F "$([char]0x53)$([char]0x65)$([char]0x67)$([char]0x6F)$([char]0x65)$([char]0x20)$([char]0x55)$([char]0x49)" 7
$lblCred.ForeColor=[System.Drawing.Color]::FromArgb(50,50,50); $lblCred.BackColor=[System.Drawing.Color]::Transparent
$lblCred.TextAlign=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TWlkZGxlQ2VudGVy'))); $card.Controls.Add($lblCred)

$btnMin=New-Object System.Windows.Forms.Button; $btnMin.Text=(-join([char]0x2D))
$btnMin.Location=New-Object System.Drawing.Point(400,12); $btnMin.Size=New-Object System.Drawing.Size(24,20)
$btnMin.FlatStyle=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RmxhdA=='))); $btnMin.BackColor=[System.Drawing.Color]::Transparent; $btnMin.ForeColor=$CD
$btnMin.Font=F "$([char]0x53)$([char]0x65)$([char]0x67)$([char]0x6F)$([char]0x65)$([char]0x20)$([char]0x55)$([char]0x49)" 10 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Qm9sZA=='))); $btnMin.FlatAppearance.BorderSize=0
$btnMin.Add_MouseEnter({$btnMin.ForeColor=$CW}); $btnMin.Add_MouseLeave({$btnMin.ForeColor=$CD})
$btnMin.Add_Click({$form.WindowState=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TWluaW1pemVk')))}); $form.Controls.Add($btnMin)

$btnClose=New-Object System.Windows.Forms.Button; $btnClose.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('WA==')))
$btnClose.Location=New-Object System.Drawing.Point(428,12); $btnClose.Size=New-Object System.Drawing.Size(24,20)
$btnClose.FlatStyle=([System.Text.Encoding]::UTF8.GetString([byte[]](0x46,0x6C,0x61,0x74))); $btnClose.BackColor=[System.Drawing.Color]::Transparent; $btnClose.ForeColor=$CD
$btnClose.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U2Vnb2UgVUk='))) 9 ([System.Text.Encoding]::UTF8.GetString([byte[]](0x42,0x6F,0x6C,0x64))); $btnClose.FlatAppearance.BorderSize=0
$btnClose.Add_MouseEnter({$btnClose.ForeColor=[System.Drawing.Color]::FromArgb(255,70,70)})
$btnClose.Add_MouseLeave({$btnClose.ForeColor=$CD})
$btnClose.Add_Click({
    Invoke-Expression ((-join([char]0x5B)) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([byte[]](0x5D,0x3A,0x3A,0x53,0x74,0x6F,0x70,0x4C,0x65,0x66,0x74,0x28,0x29))))
    Invoke-Expression ("$([char]0x5B)" + $($script:uid1) + "$([char]0x5D)$([char]0x3A)$([char]0x3A)$([char]0x53)$([char]0x74)$([char]0x6F)$([char]0x70)$([char]0x52)$([char]0x69)$([char]0x67)$([char]0x68)$([char]0x74)$([char]0x28)$([char]0x29)")
    foreach($t in @($script:timerPoll,$script:timerAnim)){if($t){$t.Stop();$t.Dispose()}}
    $script:bmp.Dispose(); $form.Close()
}); $form.Controls.Add($btnClose)

function SetCpsL($rawX){
    $cl=[math]::Max(0,[math]::Min($SW,$rawX))
    $nc=[math]::Max(1,[math]::Min(500,[int]($cl/$SW*499)+1))
    $script:leftCps=$nc
    $px=[int]($SW*($nc-1)/499.0)
    $fillL.Width=[math]::Max(1,$px)
    $thumbL.Location=New-Object System.Drawing.Point(($card.Left+$trackL.Left+$px-[int]($TH/2)),($card.Top+$trackL.Top-[int](($TV-$TK)/2)))
    $lblCpsL.Text=($nc + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('IENQUw=='))))
    if($script:leftActive){ Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U2V0Q3BzTGVmdCg='))) + $nc + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('KQ==')))) }
}
function SetCpsR($rawX){
    $cl=[math]::Max(0,[math]::Min($SW,$rawX))
    $nc=[math]::Max(1,[math]::Min(500,[int]($cl/$SW*499)+1))
    $script:rightCps=$nc
    $px=[int]($SW*($nc-1)/499.0)
    $fillR.Width=[math]::Max(1,$px)
    $thumbR.Location=New-Object System.Drawing.Point(($card.Left+$trackR.Left+$px-[int]($TH/2)),($card.Top+$trackR.Top-[int](($TV-$TK)/2)))
    $lblCpsR.Text=($nc + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('IENQUw=='))))
    if($script:rightActive){ Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U2V0Q3BzUmlnaHQo'))) + $nc + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('KQ==')))) }
}

SetCpsL ([int]($SW*9/499.0))
SetCpsR ([int]($SW*9/499.0))

$trackL.Add_MouseDown({param($s,$e);if($e.Button -eq "$([char]0x4C)$([char]0x65)$([char]0x66)$([char]0x74)"){$script:draggingL=$true;SetCpsL $e.X;$form.Capture=$true}})
$thumbL.Add_MouseDown({param($s,$e);if($e.Button -eq ([System.Text.Encoding]::UTF8.GetString([byte[]](0x4C,0x65,0x66,0x74)))){$script:draggingL=$true;$form.Capture=$true}})
$trackR.Add_MouseDown({param($s,$e);if($e.Button -eq (-join([char]0x4C, [char]0x65, [char]0x66, [char]0x74))){$script:draggingR=$true;SetCpsR $e.X;$form.Capture=$true}})
$thumbR.Add_MouseDown({param($s,$e);if($e.Button -eq ([System.Text.Encoding]::UTF8.GetString([byte[]](0x4C,0x65,0x66,0x74)))){$script:draggingR=$true;$form.Capture=$true}})

$form.Add_MouseMove({
    param($src,$e)
    if($script:draggingL){
        $cp=$card.PointToClient($form.PointToScreen($e.Location))
        SetCpsL ($cp.X-$trackL.Left)
    }
    if($script:draggingR){
        $cp=$card.PointToClient($form.PointToScreen($e.Location))
        SetCpsR ($cp.X-$trackR.Left)
    }
    if($script:dragForm){
        $form.Location=New-Object System.Drawing.Point(
            ($form.Location.X+$e.X-$script:dragPt.X),
            ($form.Location.Y+$e.Y-$script:dragPt.Y))
    }
})
$form.Add_MouseUp({$script:draggingL=$false;$script:draggingR=$false;$script:dragForm=$false;$form.Capture=$false})
$form.Add_MouseDown({
    param($s,$e)
    if($e.Button -eq ([System.Text.Encoding]::UTF8.GetString([byte[]](0x4C,0x65,0x66,0x74))) -and $e.Y -lt 45 -and -not $script:draggingL -and -not $script:draggingR){
        $script:dragForm=$true;$script:dragPt=$e.Location
    }
})

function Toggle-Left {
    $script:leftActive=-not $script:leftActive
    if($script:leftActive){
        $btnL.BackColor=$CY;$btnL.ForeColor=$BK
        $lblStatus.Text="$([char]0x25B6)$([char]0x20)$([char]0x41)$([char]0x43)$([char]0x54)$([char]0x49)$([char]0x4F)$([char]0x4E)$([char]0x20)$([char]0x31)$([char]0x20)$([char]0x41)$([char]0x43)$([char]0x54)$([char]0x49)$([char]0x56)$([char]0x45)";$lblStatus.ForeColor=$CY
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U3RhcnRMZWZ0KA=='))) + $script + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('OmxlZnRDcHMp'))))
    } else {
        $btnL.BackColor=$CK;$btnL.ForeColor=$CT
        $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pagIEFDVElPTiAxIFNUT1BQRUQ=')));$lblStatus.ForeColor=$CD
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U3RvcExlZnQoKQ=='))))
    }
}
function Toggle-Right {
    $script:rightActive=-not $script:rightActive
    if($script:rightActive){
        $btnR.BackColor=$CY;$btnR.ForeColor=$BK
        $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pa2IEFDVElPTiAyIEFDVElWRQ==')));$lblStatus.ForeColor=$CY
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U3RhcnRSaWdodCg='))) + $script + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('OnJpZ2h0Q3BzKQ=='))))
    } else {
        $btnR.BackColor=$CK;$btnR.ForeColor=$CT
        $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pagIEFDVElPTiAyIFNUT1BQRUQ=')));$lblStatus.ForeColor=$CD
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U3RvcFJpZ2h0KCk='))))
    }
}

$btnL.Add_Click({
    $script:waitL=$true
    $btnL.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Li4u')));$btnL.BackColor=$CY;$btnL.ForeColor=$BK
    $lblStatus.Text=(-join([char]0x25CF, [char]0x20, [char]0x50, [char]0x52, [char]0x45, [char]0x53, [char]0x53, [char]0x20, [char]0x41, [char]0x20, [char]0x4B, [char]0x45, [char]0x59));$lblStatus.ForeColor=$CY;$form.Focus()
})
$btnR.Add_Click({
    $script:waitR=$true
    $btnR.Text=(-join([char]0x2E, [char]0x2E, [char]0x2E));$btnR.BackColor=$CY;$btnR.ForeColor=$BK
    $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([byte[]](0xE2,0x97,0x8F,0x20,0x50,0x52,0x45,0x53,0x53,0x20,0x41,0x20,0x4B,0x45,0x59)));$lblStatus.ForeColor=$CY;$form.Focus()
})

$form.Add_KeyDown({
    param($s,$e)
    $ks=$e.KeyCode.ToString()
    if($script:waitL -and $keyMap.ContainsKey($ks)){
        $script:leftVK=$keyMap[$ks]
        $btnL.Text=$ks;$btnL.BackColor=$CK;$btnL.ForeColor=$CT
        $lblStatus.Text=(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pePIEtFWSBTRVQ6IA=='))) + $ks);$lblStatus.ForeColor=$CD
        $script:waitL=$false;$script:skipL=$true
    } elseif($script:waitR -and $keyMap.ContainsKey($ks)){
        $script:rightVK=$keyMap[$ks]
        $btnR.Text=$ks;$btnR.BackColor=$CK;$btnR.ForeColor=$CT
        $lblStatus.Text=(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pePIEtFWSBTRVQ6IA=='))) + $ks);$lblStatus.ForeColor=$CD
        $script:waitR=$false;$script:skipR=$true
    }
})

$script:timerPoll=New-Object System.Windows.Forms.Timer
$script:timerPoll.Interval=50
$script:timerPoll.Add_Tick({
    if($script:leftVK -ne 0){
        $p=Invoke-Expression ("$([char]0x5B)" + $($script:uid2) + "$([char]0x5D)$([char]0x3A)$([char]0x3A)$([char]0x49)$([char]0x73)$([char]0x50)$([char]0x72)$([char]0x65)$([char]0x73)$([char]0x73)$([char]0x65)$([char]0x64)$([char]0x28)" + $script + (-join([char]0x3A, [char]0x6C, [char]0x65, [char]0x66, [char]0x74, [char]0x56, [char]0x4B, [char]0x29)))
        if($p -and -not $script:prevL){
            if(-not $script:skipL){Toggle-Left}else{$script:skipL=$false}
            $script:prevL=$true
        } elseif(-not $p){$script:prevL=$false}
    }
    if($script:rightVK -ne 0){
        $p=Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid2) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6SXNQcmVzc2VkKA=='))) + $script + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('OnJpZ2h0Vksp'))))
        if($p -and -not $script:prevR){
            if(-not $script:skipR){Toggle-Right}else{$script:skipR=$false}
            $script:prevR=$true
        } elseif(-not $p){$script:prevR=$false}
    }
})
$script:timerPoll.Start()

$script:timerAnim=New-Object System.Windows.Forms.Timer
$script:timerAnim.Interval=33
$script:timerAnim.Add_Tick({
    foreach($n in $script:nodes){
        $n.x+=$n.vx; $n.y+=$n.vy
        if($n.x -lt 0){$n.x=0;$n.vx=[math]::Abs($n.vx)}
        if($n.x -gt 460){$n.x=460;$n.vx=-[math]::Abs($n.vx)}
        if($n.y -lt 0){$n.y=0;$n.vy=[math]::Abs($n.vy)}
        if($n.y -gt 440){$n.y=440;$n.vy=-[math]::Abs($n.vy)}
    }
    RenderConstellation
})
$script:timerAnim.Start()

$form.Add_FormClosing({
    Invoke-Expression ((-join([char]0x5B)) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([byte[]](0x5D,0x3A,0x3A,0x53,0x74,0x6F,0x70,0x4C,0x65,0x66,0x74,0x28,0x29))))
    Invoke-Expression ("$([char]0x5B)" + $($script:uid1) + (-join([char]0x5D, [char]0x3A, [char]0x3A, [char]0x53, [char]0x74, [char]0x6F, [char]0x70, [char]0x52, [char]0x69, [char]0x67, [char]0x68, [char]0x74, [char]0x28, [char]0x29)))
    foreach($t in @($script:timerPoll,$script:timerAnim)){if($t){$t.Stop();$t.Dispose()}}
    if($script:bmp){$script:bmp.Dispose()}
})

[void]$form.ShowDialog()
