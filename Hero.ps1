$ErrorActionPreference = $($k4531=138;$b=[byte[]](0xd9,0xe3,0xe6,0xef,0xe4,0xfe,0xe6,0xf3,0xc9,0xe5,0xe4,0xfe,0xe3,0xe4,0xff,0xef);-join($b|%{[char]($_-bxor$k4531)}))
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
    $($k9774=130;$b=[byte[]](0xc4,0xb3);-join($b|%{[char]($_-bxor$k9774)}))=0x70;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RjI=')))=0x71;'F3'=0x72;$($k6228=113;$b=[byte[]](0x37,0x45);-join($b|%{[char]($_-bxor$k6228)}))=0x73;'F5'=0x74;$($k4337=25;$b=[byte[]](0x5f,0x2f);-join($b|%{[char]($_-bxor$k4337)}))=0x75
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Rjc=')))=0x76;'F‍8‌'=0x77;'F9'=0x78;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RjEw')))=0x79;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RjEx')))=0x7A;$($k1062='%0G@m{msGB6';$b=[byte[]](0x63,0x01,0x75);$kb=[System.Text.Encoding]::UTF8.GetBytes($k1062);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x7B
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('QQ==')))=0x41;'В'=0x42;'С'=0x43;'D‍'=0x44;$($k1205=210;$b=[byte[]](0x97);-join($b|%{[char]($_-bxor$k1205)}))=0x45;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Rg==')))=0x46
    $($k4950=126;$b=[byte[]](0x39);-join($b|%{[char]($_-bxor$k4950)}))=0x47;'Н'=0x48;'I​'=0x49;'J'=0x4A;'K‍'=0x4B;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TA==')))=0x4C
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TQ==')))=0x4D;$($k9105='@NC;ynCXD';$b=[byte[]](0x0E);$kb=[System.Text.Encoding]::UTF8.GetBytes($k9105);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x4E;$($k5861='}u(l^N!o0n';$b=[byte[]](0x32);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5861);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x4F;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UA==')))=0x50;$($k5483=245;$b=[byte[]](0xa4);-join($b|%{[char]($_-bxor$k5483)}))=0x51;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ug==')))=0x52
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Uw==')))=0x53;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VA==')))=0x54;$($k3224=47;$b=[byte[]](0x7a);-join($b|%{[char]($_-bxor$k3224)}))=0x55;'V'=0x56;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Vw==')))=0x57;$($k3779=226;$b=[byte[]](0xba);-join($b|%{[char]($_-bxor$k3779)}))=0x58
    $($k5132='!GlZPFViK?#J;4';$b=[byte[]](0x78);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5132);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x59;'Z'=0x5A
    'D‍0​'=0x30;'DІ'=0x31;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDI=')))=0x32;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDM=')))=0x33;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDQ=')))=0x34
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDU=')))=0x35;'D6'=0x36;'D​7​'=0x37;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDg=')))=0x38;'D9'=0x39
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U3BhY2U=')))=0x20;$($k2071=134;$b=[byte[]](0xd5,0xee,0xef,0xe0,0xf2);-join($b|%{[char]($_-bxor$k2071)}))=0x10;'Соntrоl'=0x11;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('QWx0')))=0x12
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('WEJ1dHRvbjE=')))=0x05;'X​B​u​t‌t‌o‍n‌2‌'=0x06
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

function F($n,$sz,$b=$($k8209=69;$b=[byte[]](0x17,0x20,0x22,0x30,0x29,0x24,0x37);-join($b|%{[char]($_-bxor$k8209)}))){New-Object System.Drawing.Font($n,$sz,[System.Drawing.FontStyle]::$b)}

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
$form.Text=$($k9644=94;$b=[byte[]](0x16,0x1b,0x0c,0x11,0x7e,0x1d,0x32,0x37,0x3d,0x35,0x3b,0x2c);-join($b|%{[char]($_-bxor$k9644)}))
$form.ClientSize=New-Object System.Drawing.Size(460,440)
$form.StartPosition=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Q2VudGVyU2NyZWVu')))
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
$lblTitle.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('SEVSTw=='))); $lblTitle.Location=New-Object System.Drawing.Point(0,12)
$lblTitle.Size=New-Object System.Drawing.Size(300,44); $lblTitle.Font=F 'I‍m‍p​a‌c‍t​' 30
$lblTitle.ForeColor=$CY; $lblTitle.TextAlign=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TWlkZGxlQ2VudGVy'))); $lblTitle.BackColor=[System.Drawing.Color]::Transparent
$card.Controls.Add($lblTitle)

$lblSub=New-Object System.Windows.Forms.Label
$lblSub.Text='•​ ​A‍u‌t​o‍ ​C‌l‍i​c‍k‍e‌r‌ ​•​'; $lblSub.Location=New-Object System.Drawing.Point(0,56)
$lblSub.Size=New-Object System.Drawing.Size(300,16); $lblSub.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U2Vnb2UgVUk='))) 8
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
$lblL.Text='A​C​T​I​O​N‌ ​1​ ​ ​-‍ ‍ ​L‍E‍F‍T‍ ‌C‍L‌I‍C‍K‍'; $lblL.Location=New-Object System.Drawing.Point(20,87)
$lblL.Size=New-Object System.Drawing.Size(260,16); $lblL.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U2Vnb2UgVUk='))) 8 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Qm9sZA==')))
$lblL.ForeColor=$CD; $lblL.BackColor=[System.Drawing.Color]::Transparent; $card.Controls.Add($lblL)

$btnL=New-Object System.Windows.Forms.Button
$btnL.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('QklORCBLRVk='))); $btnL.Location=New-Object System.Drawing.Point(20,107)
$btnL.Size=New-Object System.Drawing.Size(110,28); $btnL.FlatStyle='F‌l‍a‌t‍'
$btnL.BackColor=$CK; $btnL.ForeColor=$CT; $btnL.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U2Vnb2UgVUk='))) 8 'B​o​l‍d‍'
$btnL.FlatAppearance.BorderColor=$CR; $btnL.FlatAppearance.BorderSize=1
$btnL.Cursor=[System.Windows.Forms.Cursors]::Hand; $card.Controls.Add($btnL)

$lblCpsL=New-Object System.Windows.Forms.Label
$lblCpsL.Text=$($k2773='I$J@{HwSym)FZA';$b=[byte[]](0x78,0x14,0x6A,0x03,0x2B,0x1B);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2773);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})); $lblCpsL.Location=New-Object System.Drawing.Point(140,107)
$lblCpsL.Size=New-Object System.Drawing.Size(140,28); $lblCpsL.Font=F $($k7243='*#!8Ln>7eM7KYE';$b=[byte[]](0x79,0x46,0x46,0x57,0x29,0x4E,0x6B,0x7E);$kb=[System.Text.Encoding]::UTF8.GetBytes($k7243);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) 12 'Воld'
$lblCpsL.ForeColor=$CY; $lblCpsL.BackColor=[System.Drawing.Color]::Transparent; $lblCpsL.TextAlign='M​i​d‌d​l‍e‌R‌i​g‍h‍t‌'
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
$lblR.Text='АСТIОN 2  -  RIGНТ СLIСК'; $lblR.Location=New-Object System.Drawing.Point(20,175)
$lblR.Size=New-Object System.Drawing.Size(260,16); $lblR.Font=F 'S​e‌g​o​e‌ ​U‍I​' 8 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Qm9sZA==')))
$lblR.ForeColor=$CD; $lblR.BackColor=[System.Drawing.Color]::Transparent; $card.Controls.Add($lblR)

$btnR=New-Object System.Windows.Forms.Button
$btnR.Text='ВIND КЕҮ'; $btnR.Location=New-Object System.Drawing.Point(20,195)
$btnR.Size=New-Object System.Drawing.Size(110,28); $btnR.FlatStyle='F‌l‌a‍t‌'
$btnR.BackColor=$CK; $btnR.ForeColor=$CT; $btnR.Font=F 'Sеgое UI' 8 'B‍o‌l‌d‍'
$btnR.FlatAppearance.BorderColor=$CR; $btnR.FlatAppearance.BorderSize=1
$btnR.Cursor=[System.Windows.Forms.Cursors]::Hand; $card.Controls.Add($btnR)

$lblCpsR=New-Object System.Windows.Forms.Label
$lblCpsR.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('MTAgQ1BT'))); $lblCpsR.Location=New-Object System.Drawing.Point(140,195)
$lblCpsR.Size=New-Object System.Drawing.Size(140,28); $lblCpsR.Font=F $($k6853='_}m&=E)';$b=[byte[]](0x0C,0x18,0x0A,0x49,0x58,0x65,0x7C,0x16);$kb=[System.Text.Encoding]::UTF8.GetBytes($k6853);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) 12 'Воld'
$lblCpsR.ForeColor=$CY; $lblCpsR.BackColor=[System.Drawing.Color]::Transparent; $lblCpsR.TextAlign='МіddlеRіght'
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
$lblStatus.Text='●​ ‌R​E‍A‌D‌Y​'; $lblStatus.Location=New-Object System.Drawing.Point(0,263)
$lblStatus.Size=New-Object System.Drawing.Size(300,34); $lblStatus.Font=F 'Sеgое UI' 9 'Itаlіс'
$lblStatus.ForeColor=$CD; $lblStatus.BackColor=[System.Drawing.Color]::Transparent; $lblStatus.TextAlign=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TWlkZGxlQ2VudGVy')))
$card.Controls.Add($lblStatus)

$lblCred=New-Object System.Windows.Forms.Label
$lblCred.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TWFkZSBieSBkcHNzczA='))); $lblCred.Location=New-Object System.Drawing.Point(0,305)
$lblCred.Size=New-Object System.Drawing.Size(300,22); $lblCred.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U2Vnb2UgVUk='))) 7
$lblCred.ForeColor=[System.Drawing.Color]::FromArgb(50,50,50); $lblCred.BackColor=[System.Drawing.Color]::Transparent
$lblCred.TextAlign=$($k3166=200;$b=[byte[]](0x85,0xa1,0xac,0xac,0xa4,0xad,0x8b,0xad,0xa6,0xbc,0xad,0xba);-join($b|%{[char]($_-bxor$k3166)})); $card.Controls.Add($lblCred)

$btnMin=New-Object System.Windows.Forms.Button; $btnMin.Text=$($k8913='<7wjRu';$b=[byte[]](0x11);$kb=[System.Text.Encoding]::UTF8.GetBytes($k8913);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))
$btnMin.Location=New-Object System.Drawing.Point(400,12); $btnMin.Size=New-Object System.Drawing.Size(24,20)
$btnMin.FlatStyle=$($k2462='r0d7Rk}(c';$b=[byte[]](0x34,0x5C,0x05,0x43);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2462);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})); $btnMin.BackColor=[System.Drawing.Color]::Transparent; $btnMin.ForeColor=$CD
$btnMin.Font=F $($k4862='uf8.e}D0E%#}:z';$b=[byte[]](0x26,0x03,0x5F,0x41,0x00,0x5D,0x11,0x79);$kb=[System.Text.Encoding]::UTF8.GetBytes($k4862);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) 10 'Воld'; $btnMin.FlatAppearance.BorderSize=0
$btnMin.Add_MouseEnter({$btnMin.ForeColor=$CW}); $btnMin.Add_MouseLeave({$btnMin.ForeColor=$CD})
$btnMin.Add_Click({$form.WindowState='M‌i‍n‌i‍m‍i​z‌e​d‌'}); $form.Controls.Add($btnMin)

$btnClose=New-Object System.Windows.Forms.Button; $btnClose.Text='X‌'
$btnClose.Location=New-Object System.Drawing.Point(428,12); $btnClose.Size=New-Object System.Drawing.Size(24,20)
$btnClose.FlatStyle=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RmxhdA=='))); $btnClose.BackColor=[System.Drawing.Color]::Transparent; $btnClose.ForeColor=$CD
$btnClose.Font=F $($k6929='l+_9:cf)*HbDF(s';$b=[byte[]](0x3F,0x4E,0x38,0x56,0x5F,0x43,0x33,0x60);$kb=[System.Text.Encoding]::UTF8.GetBytes($k6929);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) 9 'Воld'; $btnClose.FlatAppearance.BorderSize=0
$btnClose.Add_MouseEnter({$btnClose.ForeColor=[System.Drawing.Color]::FromArgb(255,70,70)})
$btnClose.Add_MouseLeave({$btnClose.ForeColor=$CD})
$btnClose.Add_Click({
    Invoke-Expression ($($k5026='D+UE*';$b=[byte[]](0x1F);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5026);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $($script:uid1) + $($k2714='+iFkrl0ftu:';$b=[byte[]](0x76,0x53,0x7C,0x38,0x06,0x03,0x40,0x2A,0x11,0x13,0x4E,0x03,0x40);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2714);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})))
    Invoke-Expression ('[‌' + $($script:uid1) + ']::StорRіght()')
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
    $lblCpsL.Text=($nc + $($k1584=82;$b=[byte[]](0x72,0x11,0x02,0x01);-join($b|%{[char]($_-bxor$k1584)})))
    if($script:leftActive){ Invoke-Expression ($($k2523='+K.y>q>cmfh';$b=[byte[]](0x70);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2523);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $($script:uid1) + $($k7919=9;$b=[byte[]](0x54,0x33,0x33,0x5a,0x6c,0x7d,0x4a,0x79,0x7a,0x45,0x6c,0x6f,0x7d,0x21);-join($b|%{[char]($_-bxor$k7919)})) + $nc + $($k8767='=5LE6+Xi6zvuS';$b=[byte[]](0x14);$kb=[System.Text.Encoding]::UTF8.GetBytes($k8767);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))) }
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

$trackL.Add_MouseDown({param($s,$e);if($e.Button -eq $($k3748=134;$b=[byte[]](0xca,0xe3,0xe0,0xf2);-join($b|%{[char]($_-bxor$k3748)}))){$script:draggingL=$true;SetCpsL $e.X;$form.Capture=$true}})
$thumbL.Add_MouseDown({param($s,$e);if($e.Button -eq $($k2960='S:d}rG#cxok';$b=[byte[]](0x1F,0x5F,0x02,0x09);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2960);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))){$script:draggingL=$true;$form.Capture=$true}})
$trackR.Add_MouseDown({param($s,$e);if($e.Button -eq ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TGVmdA==')))){$script:draggingR=$true;SetCpsR $e.X;$form.Capture=$true}})
$thumbR.Add_MouseDown({param($s,$e);if($e.Button -eq 'L‍e‌f‍t​'){$script:draggingR=$true;$form.Capture=$true}})

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
    if($e.Button -eq 'L‌e‍f​t‍' -and $e.Y -lt 45 -and -not $script:draggingL -and -not $script:draggingR){
        $script:dragForm=$true;$script:dragPt=$e.Location
    }
})

function Toggle-Left {
    $script:leftActive=-not $script:leftActive
    if($script:leftActive){
        $btnL.BackColor=$CY;$btnL.ForeColor=$BK
        $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pa2IEFDVElPTiAxIEFDVElWRQ==')));$lblStatus.ForeColor=$CY
        Invoke-Expression ('[‍' + $($script:uid1) + ']​:‌:‌S​t​a‍r​t‍L​e‌f​t‌(‍' + $script + ':​l‌e​f​t‍C‌p‌s‍)​')
    } else {
        $btnL.BackColor=$CK;$btnL.ForeColor=$CT
        $lblStatus.Text='■‍ ‌A​C​T​I​O​N‌ ‌1‍ ‍S‍T‍O​P​P‍E​D‍';$lblStatus.ForeColor=$CD
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U3RvcExlZnQoKQ=='))))
    }
}
function Toggle-Right {
    $script:rightActive=-not $script:rightActive
    if($script:rightActive){
        $btnR.BackColor=$CY;$btnR.ForeColor=$BK
        $lblStatus.Text='▶‌ ‌A​C‍T‌I​O‌N‍ ‍2‍ ‍A‍C‌T‍I​V​E​';$lblStatus.ForeColor=$CY
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U3RhcnRSaWdodCg='))) + $script + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('OnJpZ2h0Q3BzKQ=='))))
    } else {
        $btnR.BackColor=$CK;$btnR.ForeColor=$CT
        $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pagIEFDVElPTiAyIFNUT1BQRUQ=')));$lblStatus.ForeColor=$CD
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U3RvcFJpZ2h0KCk='))))
    }
}

$btnL.Add_Click({
    $script:waitL=$true
    $btnL.Text='...';$btnL.BackColor=$CY;$btnL.ForeColor=$BK
    $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pePIFBSRVNTIEEgS0VZ')));$lblStatus.ForeColor=$CY;$form.Focus()
})
$btnR.Add_Click({
    $script:waitR=$true
    $btnR.Text='...';$btnR.BackColor=$CY;$btnR.ForeColor=$BK
    $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4pePIFBSRVNTIEEgS0VZ')));$lblStatus.ForeColor=$CY;$form.Focus()
})

$form.Add_KeyDown({
    param($s,$e)
    $ks=$e.KeyCode.ToString()
    if($script:waitL -and $keyMap.ContainsKey($ks)){
        $script:leftVK=$keyMap[$ks]
        $btnL.Text=$ks;$btnL.BackColor=$CK;$btnL.ForeColor=$CT
        $lblStatus.Text=('● КЕҮ SЕТ: ' + $ks);$lblStatus.ForeColor=$CD
        $script:waitL=$false;$script:skipL=$true
    } elseif($script:waitR -and $keyMap.ContainsKey($ks)){
        $script:rightVK=$keyMap[$ks]
        $btnR.Text=$ks;$btnR.BackColor=$CK;$btnR.ForeColor=$CT
        $lblStatus.Text=('●‍ ‍K‍E‌Y​ ‍S‍E‌T​:​ ‍' + $ks);$lblStatus.ForeColor=$CD
        $script:waitR=$false;$script:skipR=$true
    }
})

$script:timerPoll=New-Object System.Windows.Forms.Timer
$script:timerPoll.Interval=50
$script:timerPoll.Add_Tick({
    if($script:leftVK -ne 0){
        $p=Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid2) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6SXNQcmVzc2VkKA=='))) + $script + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('OmxlZnRWSyk='))))
        if($p -and -not $script:prevL){
            if(-not $script:skipL){Toggle-Left}else{$script:skipL=$false}
            $script:prevL=$true
        } elseif(-not $p){$script:prevL=$false}
    }
    if($script:rightVK -ne 0){
        $p=Invoke-Expression ($($k3481='_h5$]R';$b=[byte[]](0x04);$kb=[System.Text.Encoding]::UTF8.GetBytes($k3481);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $($script:uid2) + $($k4445='Q1ZLXHX*L7X&<';$b=[byte[]](0x0C,0x0B,0x60,0x05,0x2B,0x18,0x2A,0x4F,0x3F,0x44,0x3D,0x42,0x14);$kb=[System.Text.Encoding]::UTF8.GetBytes($k4445);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $script + $($k5569=122;$b=[byte[]](0x40,0x08,0x13,0x1d,0x12,0x0e,0x2c,0x31,0x53);-join($b|%{[char]($_-bxor$k5569)})))
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
    Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Ww=='))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U3RvcExlZnQoKQ=='))))
    Invoke-Expression ($($k6495=138;$b=[byte[]](0xd1);-join($b|%{[char]($_-bxor$k6495)})) + $($script:uid1) + $($k4272=64;$b=[byte[]](0x1d,0x7a,0x7a,0x13,0x34,0x2f,0x30,0x12,0x29,0x27,0x28,0x34,0x68,0x69);-join($b|%{[char]($_-bxor$k4272)})))
    foreach($t in @($script:timerPoll,$script:timerAnim)){if($t){$t.Stop();$t.Dispose()}}
    if($script:bmp){$script:bmp.Dispose()}
})

[void]$form.ShowDialog()
