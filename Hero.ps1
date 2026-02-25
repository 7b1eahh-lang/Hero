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
    $($k9774=130;$b=[byte[]](0xc4,0xb3);-join($b|%{[char]($_-bxor$k9774)}))=0x70;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k9245=242;$b=[byte[]](0xa0,0x98,0xbb,0xcf);-join($b|%{[char]($_-bxor$k9245)})))))=0x71;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RjM=')))=0x72;$($k6228=113;$b=[byte[]](0x37,0x45);-join($b|%{[char]($_-bxor$k6228)}))=0x73;$($k1829=',IFuH';$b=[byte[]](0x6A,0x7C);$kb=[System.Text.Encoding]::UTF8.GetBytes($k1829);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x74;$($k4337=25;$b=[byte[]](0x5f,0x2f);-join($b|%{[char]($_-bxor$k4337)}))=0x75
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k6048=141;$b=[byte[]](0xdf,0xe7,0xee,0xb0);-join($b|%{[char]($_-bxor$k6048)})))))=0x76;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RuKAjTjigIw=')))=0x77;$($k1348='%78qch,s6?';$b=[byte[]](0x63,0x0E);$kb=[System.Text.Encoding]::UTF8.GetBytes($k1348);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x78;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k6288='_U+0=';$b=[byte[]](0x0D,0x3F,0x6E,0x47);$kb=[System.Text.Encoding]::UTF8.GetBytes($k6288);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})))))=0x79;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UmpFeA=='))))))=0x7A;$($k1062=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('JTBHQG17bXNHQjY=')));$b=[byte[]](0x63,0x01,0x75);$kb=[System.Text.Encoding]::UTF8.GetBytes($k1062);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x7B
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UVE9PQ=='))))))=0x41;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JI=')))=0x42;$($k6694=180;$b=[byte[]](0x64,0x15);-join($b|%{[char]($_-bxor$k6694)}))=0x43;$($k5827='S%(pmVEteC)';$b=[byte[]](0x17,0xC7,0xA8,0xFD);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5827);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x44;$($k1205=210;$b=[byte[]](0x97);-join($b|%{[char]($_-bxor$k1205)}))=0x45;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Umc9PQ=='))))))=0x46
    $($k4950=126;$b=[byte[]](0x39);-join($b|%{[char]($_-bxor$k4950)}))=0x47;$($k5895=200;$b=[byte[]](0x18,0x55);-join($b|%{[char]($_-bxor$k5895)}))=0x48;$($k4168='V:pcB?2M;3q$b';$b=[byte[]](0x1F,0xD8,0xF0,0xE8);$kb=[System.Text.Encoding]::UTF8.GetBytes($k4168);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x49;$($k2841=231;$b=[byte[]](0xad);-join($b|%{[char]($_-bxor$k2841)}))=0x4A;$($k9200=209;$b=[byte[]](0x9a,0x33,0x51,0x5c);-join($b|%{[char]($_-bxor$k9200)}))=0x4B;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VEE9PQ=='))))))=0x4C
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k8969=77;$b=[byte[]](0x19,0x1c,0x70,0x70);-join($b|%{[char]($_-bxor$k8969)})))))=0x4D;$($k9105=$($k1575='MDsf>i5c0';$b=[byte[]](0x0D,0x0A,0x30,0x5D,0x47,0x07,0x76,0x3B,0x74);$kb=[System.Text.Encoding]::UTF8.GetBytes($k1575);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}));$b=[byte[]](0x0E);$kb=[System.Text.Encoding]::UTF8.GetBytes($k9105);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x4E;$($k5861=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('fXUobF5OIW8wbg==')));$b=[byte[]](0x32);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5861);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x4F;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VUE9PQ=='))))))=0x50;$($k5483=245;$b=[byte[]](0xa4);-join($b|%{[char]($_-bxor$k5483)}))=0x51;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VWc9PQ=='))))))=0x52
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VXc9PQ=='))))))=0x53;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k9964='H$q!y>I7yR+';$b=[byte[]](0x1E,0x65,0x4C,0x1C);$kb=[System.Text.Encoding]::UTF8.GetBytes($k9964);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})))))=0x54;$($k3224=47;$b=[byte[]](0x7a);-join($b|%{[char]($_-bxor$k3224)}))=0x55;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Vg==')))=0x56;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Vnc9PQ=='))))))=0x57;$($k3779=226;$b=[byte[]](0xba);-join($b|%{[char]($_-bxor$k3779)}))=0x58
    $($k5132=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('IUdsWlBGVmlLPyNKOzQ=')));$b=[byte[]](0x78);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5132);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x59;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Wg==')))=0x5A
    $($k1994='BJoy)%k';$b=[byte[]](0x06,0xA8,0xEF,0xF4,0x19,0xC7,0xEB,0xC9);$kb=[System.Text.Encoding]::UTF8.GetBytes($k1994);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x30;$($k6739=8;$b=[byte[]](0x4c,0xd8,0x8e);-join($b|%{[char]($_-bxor$k6739)}))=0x31;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k7111='4s_=sI;&pU;E!y';$b=[byte[]](0x66,0x37,0x16,0x00);$kb=[System.Text.Encoding]::UTF8.GetBytes($k7111);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})))))=0x32;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UkRNPQ=='))))))=0x33;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UkRRPQ=='))))))=0x34
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UkRVPQ=='))))))=0x35;$($k1270='r5q%Z';$b=[byte[]](0x36,0x03);$kb=[System.Text.Encoding]::UTF8.GetBytes($k1270);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))=0x36;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('ROKAizfigIs=')))=0x37;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k4448='7T+GA';$b=[byte[]](0x65,0x10,0x4C,0x7A);$kb=[System.Text.Encoding]::UTF8.GetBytes($k4448);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})))))=0x38;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RDk=')))=0x39
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VTNCaFkyVT0='))))))=0x20;$($k2071=134;$b=[byte[]](0xd5,0xee,0xef,0xe0,0xf2);-join($b|%{[char]($_-bxor$k2071)}))=0x10;$($k1770=142;$b=[byte[]](0x5e,0x2f,0x5e,0x30,0xe0,0xfa,0xfc,0x5e,0x30,0xe2);-join($b|%{[char]($_-bxor$k1770)}))=0x11;([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UVd4MA=='))))))=0x12
    ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('V0VKMWRIUnZiakU9'))))))=0x05;$($k7139=208;$b=[byte[]](0x88,0x32,0x50,0x5b,0x92,0x32,0x50,0x5b,0xa5,0x32,0x50,0x5b,0xa4,0x32,0x50,0x5c,0xa4,0x32,0x50,0x5c,0xbf,0x32,0x50,0x5d,0xbe,0x32,0x50,0x5c,0xe2,0x32,0x50,0x5c);-join($b|%{[char]($_-bxor$k7139)}))=0x06
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
$form.StartPosition=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k5788=53;$b=[byte[]](0x64,0x07,0x63,0x40,0x51,0x72,0x63,0x4c,0x60,0x07,0x7b,0x4c,0x6f,0x62,0x63,0x40);-join($b|%{[char]($_-bxor$k5788)})))))
$form.BackColor=$CB
$form.FormBorderStyle=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VG05dVpRPT0='))))))
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
$lblTitle.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k7195='mku}:8A}';$b=[byte[]](0x3E,0x2E,0x23,0x2E,0x6E,0x4F,0x7C,0x40);$kb=[System.Text.Encoding]::UTF8.GetBytes($k7195);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))))); $lblTitle.Location=New-Object System.Drawing.Point(0,12)
$lblTitle.Size=New-Object System.Drawing.Size(300,44); $lblTitle.Font=F $($k3330=']o>}@HwLr6j=Z)K';$b=[byte[]](0x14,0x8D,0xBE,0xF0,0x2D,0xAA,0xF7,0xC1,0x02,0xD4,0xEA,0xB6,0x3B,0xCB,0xCB,0xD1,0x0C,0xDC,0xFD,0xCD,0x3C,0x95,0xCC,0xF9);$kb=[System.Text.Encoding]::UTF8.GetBytes($k3330);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) 30
$lblTitle.ForeColor=$CY; $lblTitle.TextAlign=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VFdsa1pHeGxRMlZ1ZEdWeQ==')))))); $lblTitle.BackColor=[System.Drawing.Color]::Transparent
$card.Controls.Add($lblTitle)

$lblSub=New-Object System.Windows.Forms.Label
$lblSub.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('4oCi4oCLIOKAi0HigI114oCMdOKAi2/igI0g4oCLQ+KAjGzigI1p4oCLY+KAjWvigI1l4oCMcuKAjCDigIvigKLigIs='))); $lblSub.Location=New-Object System.Drawing.Point(0,56)
$lblSub.Size=New-Object System.Drawing.Size(300,16); $lblSub.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VTJWbmIyVWdWVWs9')))))) 8
$lblSub.ForeColor=$CD; $lblSub.TextAlign=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k2661='(R*#!p3,_mcX';$b=[byte[]](0x7C,0x05,0x46,0x48,0x7B,0x37,0x4B,0x40,0x0E,0x5F,0x35,0x2D,0x4C,0x15,0x7C,0x5A);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2661);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))))); $lblSub.BackColor=[System.Drawing.Color]::Transparent
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
$lblL.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('QeKAi0PigItU4oCLSeKAi0/igItO4oCMIOKAizHigIsg4oCLIOKAiy3igI0g4oCNIOKAi0zigI1F4oCNRuKAjVTigI0g4oCMQ+KAjUzigIxJ4oCNQ+KAjUvigI0='))); $lblL.Location=New-Object System.Drawing.Point(20,87)
$lblL.Size=New-Object System.Drawing.Size(260,16); $lblL.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VTJWbmIyVWdWVWs9')))))) 8 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UW05c1pBPT0='))))))
$lblL.ForeColor=$CD; $lblL.BackColor=[System.Drawing.Color]::Transparent; $card.Controls.Add($lblL)

$btnL=New-Object System.Windows.Forms.Button
$btnL.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UWtsT1JDQkxSVms9')))))); $btnL.Location=New-Object System.Drawing.Point(20,107)
$btnL.Size=New-Object System.Drawing.Size(110,28); $btnL.FlatStyle=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RuKAjGzigI1h4oCMdOKAjQ==')))
$btnL.BackColor=$CK; $btnL.ForeColor=$CT; $btnL.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k2274=81;$b=[byte[]](0x04,0x63,0x07,0x3f,0x33,0x63,0x04,0x36,0x07,0x04,0x3a,0x6c);-join($b|%{[char]($_-bxor$k2274)}))))) 8 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('QuKAi2/igIts4oCNZOKAjQ==')))
$btnL.FlatAppearance.BorderColor=$CR; $btnL.FlatAppearance.BorderSize=1
$btnL.Cursor=[System.Windows.Forms.Cursors]::Hand; $card.Controls.Add($btnL)

$lblCpsL=New-Object System.Windows.Forms.Label
$lblCpsL.Text=$($k2773=$($k8849='$fgLJP{f';$b=[byte[]](0x6D,0x42,0x2D,0x0C,0x31,0x18,0x0C,0x35,0x5D,0x0B,0x4E,0x0A,0x10,0x11);$kb=[System.Text.Encoding]::UTF8.GetBytes($k8849);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}));$b=[byte[]](0x78,0x14,0x6A,0x03,0x2B,0x1B);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2773);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})); $lblCpsL.Location=New-Object System.Drawing.Point(140,107)
$lblCpsL.Size=New-Object System.Drawing.Size(140,28); $lblCpsL.Font=F $($k7243=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('KiMhOExuPjdlTTdLWUU=')));$b=[byte[]](0x79,0x46,0x46,0x57,0x29,0x4E,0x6B,0x7E);$kb=[System.Text.Encoding]::UTF8.GetBytes($k7243);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) 12 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JLQvmxk')))
$lblCpsL.ForeColor=$CY; $lblCpsL.BackColor=[System.Drawing.Color]::Transparent; $lblCpsL.TextAlign=$($k4218='6VvtoZwYA]_y';$b=[byte[]](0x7B,0xB4,0xF6,0xFF,0x06,0xB8,0xF7,0xD2,0x25,0xBF,0xDF,0xF5,0x52,0xB4,0xF6,0xFF,0x03,0xB8,0xF7,0xD4,0x24,0xBF,0xDF,0xF5,0x64,0xB4,0xF6,0xF8,0x06,0xB8,0xF7,0xD2,0x26,0xBF,0xDF,0xF4,0x5E,0xB4,0xF6,0xF9,0x1B,0xB8,0xF7,0xD5);$kb=[System.Text.Encoding]::UTF8.GetBytes($k4218);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))
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
$lblR.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JDQodCiSdCeTiAyICAtICBSSUfQndCiINChTEnQodCa'))); $lblR.Location=New-Object System.Drawing.Point(20,175)
$lblR.Size=New-Object System.Drawing.Size(260,16); $lblR.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U+KAi2XigIxn4oCLb+KAi2XigIwg4oCLVeKAjUnigIs='))) 8 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k7020='J]ye_PLow1uj>r';$b=[byte[]](0x1B,0x30,0x40,0x16,0x05,0x11,0x71,0x52);$kb=[System.Text.Encoding]::UTF8.GetBytes($k7020);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})))))
$lblR.ForeColor=$CD; $lblR.BackColor=[System.Drawing.Color]::Transparent; $card.Controls.Add($lblR)

$btnR=New-Object System.Windows.Forms.Button
$btnR.Text=$($k8326=39;$b=[byte[]](0xf7,0xb5,0x6e,0x69,0x63,0x07,0xf7,0xbd,0xf7,0xb2,0xf5,0x89);-join($b|%{[char]($_-bxor$k8326)})); $btnR.Location=New-Object System.Drawing.Point(20,195)
$btnR.Size=New-Object System.Drawing.Size(110,28); $btnR.FlatStyle=$($k6826='O&z[#v3+2:lK';$b=[byte[]](0x09,0xC4,0xFA,0xD7,0x4F,0x94,0xB3,0xA7,0x53,0xD8,0xEC,0xC6,0x3B,0xC4,0xFA,0xD7);$kb=[System.Text.Encoding]::UTF8.GetBytes($k6826);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))
$btnR.BackColor=$CK; $btnR.ForeColor=$CT; $btnR.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('U9C1Z9C+0LUgVUk='))) 8 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('QuKAjW/igIxs4oCMZOKAjQ==')))
$btnR.FlatAppearance.BorderColor=$CR; $btnR.FlatAppearance.BorderSize=1
$btnR.Cursor=[System.Windows.Forms.Cursors]::Hand; $card.Controls.Add($btnR)

$lblCpsR=New-Object System.Windows.Forms.Label
$lblCpsR.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TVRBZ1ExQlQ=')))))); $lblCpsR.Location=New-Object System.Drawing.Point(140,195)
$lblCpsR.Size=New-Object System.Drawing.Size(140,28); $lblCpsR.Font=F $($k6853=$($k8404=90;$b=[byte[]](0x05,0x27,0x37,0x7c,0x67,0x1f,0x73);-join($b|%{[char]($_-bxor$k8404)}));$b=[byte[]](0x0C,0x18,0x0A,0x49,0x58,0x65,0x7C,0x16);$kb=[System.Text.Encoding]::UTF8.GetBytes($k6853);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) 12 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JLQvmxk')))
$lblCpsR.ForeColor=$CY; $lblCpsR.BackColor=[System.Drawing.Color]::Transparent; $lblCpsR.TextAlign=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JzRlmRkbNC1UtGWZ2h0')))
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
$lblStatus.Text=$($k6063='VkjSa(P5';$b=[byte[]](0xB4,0xFC,0xE5,0xB1,0xE1,0xA3,0x70,0xD7,0xD6,0xE7,0x38,0xB1,0xE1,0xA3,0x15,0xD7,0xD6,0xE6,0x2B,0xB1,0xE1,0xA4,0x14,0xD7,0xD6,0xE7,0x33,0xB1,0xE1,0xA3);$kb=[System.Text.Encoding]::UTF8.GetBytes($k6063);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})); $lblStatus.Location=New-Object System.Drawing.Point(0,263)
$lblStatus.Size=New-Object System.Drawing.Size(300,34); $lblStatus.Font=F $($k6459=253;$b=[byte[]](0xae,0x2d,0x48,0x9a,0x2d,0x43,0x2d,0x48,0xdd,0xa8,0xb4);-join($b|%{[char]($_-bxor$k6459)})) 9 $($k4424=6;$b=[byte[]](0x4f,0x72,0xd6,0xb6,0x6a,0xd7,0x90,0xd7,0x87);-join($b|%{[char]($_-bxor$k4424)}))
$lblStatus.ForeColor=$CD; $lblStatus.BackColor=[System.Drawing.Color]::Transparent; $lblStatus.TextAlign=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VFdsa1pHeGxRMlZ1ZEdWeQ=='))))))
$card.Controls.Add($lblStatus)

$lblCred=New-Object System.Windows.Forms.Label
$lblCred.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k3342=200;$b=[byte[]](0x9c,0x9f,0x8e,0xa3,0x92,0x9b,0x8a,0xa1,0xad,0x9b,0x8a,0xa3,0xab,0x80,0x86,0xb2,0xab,0xb2,0x89,0xf5);-join($b|%{[char]($_-bxor$k3342)}))))); $lblCred.Location=New-Object System.Drawing.Point(0,305)
$lblCred.Size=New-Object System.Drawing.Size(300,22); $lblCred.Font=F ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('VTJWbmIyVWdWVWs9')))))) 7
$lblCred.ForeColor=[System.Drawing.Color]::FromArgb(50,50,50); $lblCred.BackColor=[System.Drawing.Color]::Transparent
$lblCred.TextAlign=$($k3166=200;$b=[byte[]](0x85,0xa1,0xac,0xac,0xa4,0xad,0x8b,0xad,0xa6,0xbc,0xad,0xba);-join($b|%{[char]($_-bxor$k3166)})); $card.Controls.Add($lblCred)

$btnMin=New-Object System.Windows.Forms.Button; $btnMin.Text=$($k8913=$($k7158=236;$b=[byte[]](0xd0,0xdb,0x9b,0x86,0xbe,0x99);-join($b|%{[char]($_-bxor$k7158)}));$b=[byte[]](0x11);$kb=[System.Text.Encoding]::UTF8.GetBytes($k8913);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))
$btnMin.Location=New-Object System.Drawing.Point(400,12); $btnMin.Size=New-Object System.Drawing.Size(24,20)
$btnMin.FlatStyle=$($k2462=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('cjBkN1JrfShj')));$b=[byte[]](0x34,0x5C,0x05,0x43);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2462);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})); $btnMin.BackColor=[System.Drawing.Color]::Transparent; $btnMin.ForeColor=$CD
$btnMin.Font=F $($k4862=$($k7884='?;n{8^eV9374MV';$b=[byte[]](0x4A,0x5D,0x56,0x55,0x5D,0x23,0x21,0x66,0x7C,0x16,0x14,0x49,0x77,0x2C);$kb=[System.Text.Encoding]::UTF8.GetBytes($k7884);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}));$b=[byte[]](0x26,0x03,0x5F,0x41,0x00,0x5D,0x11,0x79);$kb=[System.Text.Encoding]::UTF8.GetBytes($k4862);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) 10 ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('0JLQvmxk'))); $btnMin.FlatAppearance.BorderSize=0
$btnMin.Add_MouseEnter({$btnMin.ForeColor=$CW}); $btnMin.Add_MouseLeave({$btnMin.ForeColor=$CD})
$btnMin.Add_Click({$form.WindowState=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TeKAjGnigI1u4oCMaeKAjW3igI1p4oCLeuKAjGXigItk4oCM')))}); $form.Controls.Add($btnMin)

$btnClose=New-Object System.Windows.Forms.Button; $btnClose.Text=$($k9526=175;$b=[byte[]](0xf7,0x4d,0x2f,0x23);-join($b|%{[char]($_-bxor$k9526)}))
$btnClose.Location=New-Object System.Drawing.Point(428,12); $btnClose.Size=New-Object System.Drawing.Size(24,20)
$btnClose.FlatStyle=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Um14aGRBPT0=')))))); $btnClose.BackColor=[System.Drawing.Color]::Transparent; $btnClose.ForeColor=$CD
$btnClose.Font=F $($k6929=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('bCtfOTpjZikqSGJERihz')));$b=[byte[]](0x3F,0x4E,0x38,0x56,0x5F,0x43,0x33,0x60);$kb=[System.Text.Encoding]::UTF8.GetBytes($k6929);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) 9 $($k4937=76;$b=[byte[]](0x9c,0xde,0x9c,0xf2,0x20,0x28);-join($b|%{[char]($_-bxor$k4937)})); $btnClose.FlatAppearance.BorderSize=0
$btnClose.Add_MouseEnter({$btnClose.ForeColor=[System.Drawing.Color]::FromArgb(255,70,70)})
$btnClose.Add_MouseLeave({$btnClose.ForeColor=$CD})
$btnClose.Add_Click({
    Invoke-Expression ($($k5026=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('RCtVRSo=')));$b=[byte[]](0x1F);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5026);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $($script:uid1) + $($k2714=$($k4513=143;$b=[byte[]](0xa4,0xe6,0xc9,0xe4,0xfd,0xe3,0xbf,0xe9,0xfb,0xfa,0xb5);-join($b|%{[char]($_-bxor$k4513)}));$b=[byte[]](0x76,0x53,0x7C,0x38,0x06,0x03,0x40,0x2A,0x11,0x13,0x4E,0x03,0x40);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2714);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})))
    Invoke-Expression ($($k3098='oqhTh;Pb%_%cW?u';$b=[byte[]](0x34,0x93,0xE8,0xD8);$kb=[System.Text.Encoding]::UTF8.GetBytes($k3098);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('XTo6U3TQvtGAUtGWZ2h0KCk='))))
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
    if($script:leftActive){ Invoke-Expression ($($k2523=$($k8274=172;$b=[byte[]](0x87,0xe7,0x82,0xd5,0x92,0xdd,0x92,0xcf,0xc1,0xca,0xc4);-join($b|%{[char]($_-bxor$k8274)}));$b=[byte[]](0x70);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2523);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $($script:uid1) + $($k7919=9;$b=[byte[]](0x54,0x33,0x33,0x5a,0x6c,0x7d,0x4a,0x79,0x7a,0x45,0x6c,0x6f,0x7d,0x21);-join($b|%{[char]($_-bxor$k7919)})) + $nc + $($k8767=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('PTVMRTYrWGk2enZ1Uw==')));$b=[byte[]](0x14);$kb=[System.Text.Encoding]::UTF8.GetBytes($k8767);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))) }
}
function SetCpsR($rawX){
    $cl=[math]::Max(0,[math]::Min($SW,$rawX))
    $nc=[math]::Max(1,[math]::Min(500,[int]($cl/$SW*499)+1))
    $script:rightCps=$nc
    $px=[int]($SW*($nc-1)/499.0)
    $fillR.Width=[math]::Max(1,$px)
    $thumbR.Location=New-Object System.Drawing.Point(($card.Left+$trackR.Left+$px-[int]($TH/2)),($card.Top+$trackR.Top-[int](($TV-$TK)/2)))
    $lblCpsR.Text=($nc + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('SUVOUVV3PT0=')))))))
    if($script:rightActive){ Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('V3c9PQ==')))))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k1087='x.uMIn&7nwZ;ILQ';$b=[byte[]](0x20,0x7A,0x1A,0x7B,0x1C,0x5C,0x70,0x07,0x3F,0x44,0x18,0x41,0x1C,0x21,0x3D,0x16,0x4F,0x3D,0x1C,0x26);$kb=[System.Text.Encoding]::UTF8.GetBytes($k1087);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))))) + $nc + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('S1E9PQ=='))))))) }
}

SetCpsL ([int]($SW*9/499.0))
SetCpsR ([int]($SW*9/499.0))

$trackL.Add_MouseDown({param($s,$e);if($e.Button -eq $($k3748=134;$b=[byte[]](0xca,0xe3,0xe0,0xf2);-join($b|%{[char]($_-bxor$k3748)}))){$script:draggingL=$true;SetCpsL $e.X;$form.Capture=$true}})
$thumbL.Add_MouseDown({param($s,$e);if($e.Button -eq $($k2960=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UzpkfXJHI2N4b2s=')));$b=[byte[]](0x1F,0x5F,0x02,0x09);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2960);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))){$script:draggingL=$true;$form.Capture=$true}})
$trackR.Add_MouseDown({param($s,$e);if($e.Button -eq ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k4535=67;$b=[byte[]](0x17,0x04,0x15,0x2e,0x27,0x02,0x7e,0x7e);-join($b|%{[char]($_-bxor$k4535)})))))){$script:draggingR=$true;SetCpsR $e.X;$form.Capture=$true}})
$thumbR.Add_MouseDown({param($s,$e);if($e.Button -eq ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TOKAjWXigIxm4oCNdOKAiw==')))){$script:draggingR=$true;$form.Capture=$true}})

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
    if($e.Button -eq ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('TOKAjGXigI1m4oCLdOKAjQ=='))) -and $e.Y -lt 45 -and -not $script:draggingL -and -not $script:draggingR){
        $script:dragForm=$true;$script:dragPt=$e.Location
    }
})

function Toggle-Left {
    $script:leftActive=-not $script:leftActive
    if($script:leftActive){
        $btnL.BackColor=$CY;$btnL.ForeColor=$BK
        $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k4697=77;$b=[byte[]](0x79,0x3d,0x2c,0x7f,0x04,0x08,0x0b,0x09,0x1b,0x08,0x21,0x1d,0x19,0x24,0x0c,0x35,0x04,0x08,0x0b,0x09,0x1b,0x08,0x21,0x1a,0x1f,0x1c,0x70,0x70);-join($b|%{[char]($_-bxor$k4697)})))));$lblStatus.ForeColor=$CY
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('W+KAjQ=='))) + $($script:uid1) + $($k2274=141;$b=[byte[]](0xd0,0x6f,0x0d,0x06,0xb7,0x6f,0x0d,0x01,0xb7,0x6f,0x0d,0x01,0xde,0x6f,0x0d,0x06,0xf9,0x6f,0x0d,0x06,0xec,0x6f,0x0d,0x00,0xff,0x6f,0x0d,0x06,0xf9,0x6f,0x0d,0x00,0xc1,0x6f,0x0d,0x06,0xe8,0x6f,0x0d,0x01,0xeb,0x6f,0x0d,0x06,0xf9,0x6f,0x0d,0x01,0xa5,0x6f,0x0d,0x00);-join($b|%{[char]($_-bxor$k2274)})) + $script + $($k9769='M+!s0l[O[';$b=[byte[]](0x77,0xC9,0xA1,0xF8,0x5C,0x8E,0xDB,0xC3,0x3E,0xAF,0xAB,0xAA,0x15,0xD2,0xEC,0xD0,0x3B,0xB9,0xCD,0xA6,0x62,0x91,0xB0,0xE0,0x2B,0xAD,0xDB,0xC1,0x58,0xC3,0xF3,0xBD,0x45,0xB9,0xCF,0xD0);$kb=[System.Text.Encoding]::UTF8.GetBytes($k9769);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})))
    } else {
        $btnL.BackColor=$CK;$btnL.ForeColor=$CT
        $lblStatus.Text=$($k5791=72;$b=[byte[]](0xaa,0xde,0xe8,0xaa,0xc8,0xc5,0x68,0xaa,0xc8,0xc4,0x09,0xaa,0xc8,0xc3,0x0b,0xaa,0xc8,0xc3,0x1c,0xaa,0xc8,0xc3,0x01,0xaa,0xc8,0xc3,0x07,0xaa,0xc8,0xc3,0x06,0xaa,0xc8,0xc4,0x68,0xaa,0xc8,0xc4,0x79,0xaa,0xc8,0xc5,0x68,0xaa,0xc8,0xc5,0x1b,0xaa,0xc8,0xc5,0x1c,0xaa,0xc8,0xc5,0x07,0xaa,0xc8,0xc3,0x18,0xaa,0xc8,0xc3,0x18,0xaa,0xc8,0xc5,0x0d,0xaa,0xc8,0xc3,0x0c,0xaa,0xc8,0xc5);-join($b|%{[char]($_-bxor$k5791)}));$lblStatus.ForeColor=$CD
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k4103=131;$b=[byte[]](0xd4,0xf4,0xbe,0xbe);-join($b|%{[char]($_-bxor$k4103)}))))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k2594=127;$b=[byte[]](0x27,0x2b,0x10,0x49,0x2a,0x4c,0x2d,0x09,0x1c,0x3a,0x07,0x13,0x25,0x11,0x2e,0x10,0x34,0x2e,0x42,0x42);-join($b|%{[char]($_-bxor$k2594)}))))))
    }
}
function Toggle-Right {
    $script:rightActive=-not $script:rightActive
    if($script:rightActive){
        $btnR.BackColor=$CY;$btnR.ForeColor=$BK
        $lblStatus.Text=$($k4390='0qC<n3aymB{';$b=[byte[]](0xD2,0xE7,0xF5,0xDE,0xEE,0xBF,0x41,0x9B,0xED,0xCE,0x3A,0xD2,0xF1,0xC8,0x7F,0x8C,0xB3,0xEC,0x2D,0x8F,0xC2,0xF7,0x79,0x93,0xC3,0xB7,0x21,0xD1,0xE1,0xF5,0x23,0xA0,0xFB,0xBD,0x51,0xA1,0xBC,0xE3,0x01,0x83,0xF9,0xE0,0x62,0x99,0xB0,0xFC,0x02,0xDE,0xEE,0xBE,0x22,0x9B,0xED,0xCE,0x2F,0xD2,0xF1,0xCE,0x75,0x8C,0xB3,0xEA,0x2F,0x8F,0xC2,0xF0,0x75,0x93,0xC3,0xB7);$kb=[System.Text.Encoding]::UTF8.GetBytes($k4390);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}));$lblStatus.ForeColor=$CY
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k3971='aN1B-zxS';$b=[byte[]](0x36,0x39,0x0C,0x7F);$kb=[System.Text.Encoding]::UTF8.GetBytes($k3971);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('WFRvNlUzUmhjblJTYVdkb2RDZz0=')))))) + $script + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('T25KcFoyaDBRM0J6S1E9PQ==')))))))
    } else {
        $btnR.BackColor=$CK;$btnR.ForeColor=$CT
        $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('NHBhZ0lFRkRWRWxQVGlBeUlGTlVUMUJRUlVRPQ=='))))));$lblStatus.ForeColor=$CD
        Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('V3c9PQ==')))))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k7924=78;$b=[byte[]](0x16,0x1a,0x21,0x78,0x1b,0x7d,0x1c,0x38,0x2d,0x08,0x04,0x3e,0x14,0x7c,0x26,0x7e,0x05,0x0d,0x25,0x73);-join($b|%{[char]($_-bxor$k7924)}))))))
    }
}

$btnL.Add_Click({
    $script:waitL=$true
    $btnL.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('Li4u')));$btnL.BackColor=$CY;$btnL.ForeColor=$BK
    $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k9181=248;$b=[byte[]](0xcc,0x88,0x9d,0xa8,0xb1,0xbe,0xba,0xab,0xaa,0xae,0xb6,0xac,0xb1,0xbd,0xbd,0x9f,0xab,0xc8,0xae,0xa2);-join($b|%{[char]($_-bxor$k9181)})))));$lblStatus.ForeColor=$CY;$form.Focus()
})
$btnR.Add_Click({
    $script:waitR=$true
    $btnR.Text=$($k7970=245;$b=[byte[]](0xdb,0xdb,0xdb);-join($b|%{[char]($_-bxor$k7970)}));$btnR.BackColor=$CY;$btnR.ForeColor=$BK
    $lblStatus.Text=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('NHBlUElGQlNSVk5USUVFZ1MwVlo='))))));$lblStatus.ForeColor=$CY;$form.Focus()
})

$form.Add_KeyDown({
    param($s,$e)
    $ks=$e.KeyCode.ToString()
    if($script:waitL -and $keyMap.ContainsKey($ks)){
        $script:leftVK=$keyMap[$ks]
        $btnL.Text=$ks;$btnL.BackColor=$CK;$btnL.ForeColor=$CT
        $lblStatus.Text=($($k5245=37;$b=[byte[]](0xc7,0xb2,0xaa,0x05,0xf5,0xbf,0xf5,0xb0,0xf7,0x8b,0x05,0x76,0xf5,0xb0,0xf5,0x87,0x1f,0x05);-join($b|%{[char]($_-bxor$k5245)})) + $ks);$lblStatus.ForeColor=$CD
        $script:waitL=$false;$script:skipL=$true
    } elseif($script:waitR -and $keyMap.ContainsKey($ks)){
        $script:rightVK=$keyMap[$ks]
        $btnR.Text=$ks;$btnR.BackColor=$CK;$btnR.ForeColor=$CT
        $lblStatus.Text=($($k7909='{_;g30_pfs@';$b=[byte[]](0x99,0xC8,0xB4,0x85,0xB3,0xBD,0x7F,0x92,0xE6,0xFE,0x0B,0x99,0xDF,0xB6,0x22,0xD1,0xB0,0xD3,0x29,0x84,0xF3,0xCB,0x5B,0xBD,0xBB,0xEA,0x60,0xD2,0xDF,0xFD,0x23,0x91,0xC0,0xF7,0x0B,0xD9,0xE7,0xB8,0x0A,0xBD,0xF0,0xED,0x53,0xA2,0xFB,0xD2);$kb=[System.Text.Encoding]::UTF8.GetBytes($k7909);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $ks);$lblStatus.ForeColor=$CD
        $script:waitR=$false;$script:skipR=$true
    }
})

$script:timerPoll=New-Object System.Windows.Forms.Timer
$script:timerPoll.Interval=50
$script:timerPoll.Add_Tick({
    if($script:leftVK -ne 0){
        $p=Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k2540='$bOvX[Sdom';$b=[byte[]](0x73,0x15,0x72,0x4B);$kb=[System.Text.Encoding]::UTF8.GetBytes($k2540);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))))) + $($script:uid2) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String(([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('WFRvNlNYTlFjbVZ6YzJWa0tBPT0=')))))) + $script + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k5756='c9&9SxxE#';$b=[byte[]](0x2C,0x54,0x5E,0x55,0x09,0x16,0x2A,0x12,0x70,0x1A,0x52,0x1B);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5756);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))))))
        if($p -and -not $script:prevL){
            if(-not $script:skipL){Toggle-Left}else{$script:skipL=$false}
            $script:prevL=$true
        } elseif(-not $p){$script:prevL=$false}
    }
    if($script:rightVK -ne 0){
        $p=Invoke-Expression ($($k3481=$($k4518='b{qKS0M';$b=[byte[]](0x3D,0x13,0x44,0x6F,0x0E,0x62);$kb=[System.Text.Encoding]::UTF8.GetBytes($k4518);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}));$b=[byte[]](0x04);$kb=[System.Text.Encoding]::UTF8.GetBytes($k3481);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $($script:uid2) + $($k4445=([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UTFaTFhIWCpMN1gmPA==')));$b=[byte[]](0x0C,0x0B,0x60,0x05,0x2B,0x18,0x2A,0x4F,0x3F,0x44,0x3D,0x42,0x14);$kb=[System.Text.Encoding]::UTF8.GetBytes($k4445);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])})) + $script + $($k5569=122;$b=[byte[]](0x40,0x08,0x13,0x1d,0x12,0x0e,0x2c,0x31,0x53);-join($b|%{[char]($_-bxor$k5569)})))
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
    Invoke-Expression (([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k5185='Cu>uEU^-M';$b=[byte[]](0x14,0x02,0x03,0x48);$kb=[System.Text.Encoding]::UTF8.GetBytes($k5185);-join(0..($b.Length-1)|%{[char]($b[$_]-bxor$kb[$_%$kb.Length])}))))) + $($script:uid1) + ([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($($k7998=168;$b=[byte[]](0xf0,0xfc,0xc7,0x9e,0xfd,0x9b,0xfa,0xde,0xcb,0xed,0xd0,0xc4,0xf2,0xc6,0xf9,0xc7,0xe3,0xf9,0x95,0x95);-join($b|%{[char]($_-bxor$k7998)}))))))
    Invoke-Expression ($($k6495=138;$b=[byte[]](0xd1);-join($b|%{[char]($_-bxor$k6495)})) + $($script:uid1) + $($k4272=64;$b=[byte[]](0x1d,0x7a,0x7a,0x13,0x34,0x2f,0x30,0x12,0x29,0x27,0x28,0x34,0x68,0x69);-join($b|%{[char]($_-bxor$k4272)})))
    foreach($t in @($script:timerPoll,$script:timerAnim)){if($t){$t.Stop();$t.Dispose()}}
    if($script:bmp){$script:bmp.Dispose()}
})

[void]$form.ShowDialog()
