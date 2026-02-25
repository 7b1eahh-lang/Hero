$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$script:uid1 = -join ((65..90)+(97..122) | Get-Random -Count 14 | % {[char]$_})
$script:uid2 = -join ((65..90)+(97..122) | Get-Random -Count 13 | % {[char]$_})

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class $($script:uid1) {
    [DllImport("user32.dll")] static extern uint SendInput(uint n, INPUT[] i, int s);
    [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public MI mi; }
    [StructLayout(LayoutKind.Sequential)] struct MI {
        public int dx,dy; public uint md,fl,t; public IntPtr ei;
    }
    public static void ClickLeft()  { var a=new INPUT[2]; a[0].type=a[1].type=0; a[0].mi.fl=2; a[1].mi.fl=4;  SendInput(2,a,System.Runtime.InteropServices.Marshal.SizeOf(typeof(INPUT))); }
    public static void ClickRight() { var a=new INPUT[2]; a[0].type=a[1].type=0; a[0].mi.fl=8; a[1].mi.fl=16; SendInput(2,a,System.Runtime.InteropServices.Marshal.SizeOf(typeof(INPUT))); }
}
public class $($script:uid2) {
    [DllImport("user32.dll")] static extern short GetAsyncKeyState(int v);
    public static bool IsPressed(int v) { return (GetAsyncKeyState(v) & 0x8000) != 0; }
}
"@

$script:leftVK=0; $script:rightVK=0
$script:leftCps=10; $script:rightCps=10
$script:leftActive=$false; $script:rightActive=$false
$script:waitL=$false; $script:waitR=$false
$script:skipL=$false; $script:skipR=$false
$script:prevL=$false; $script:prevR=$false
$script:timerL=$null; $script:timerR=$null
$script:timerPoll=$null; $script:timerAnim=$null
$script:dragForm=$false; $script:dragPt=$null
$script:activeSlot=$null
$script:nodes=@()

$keyMap = @{
    'F1'=0x70;'F2'=0x71;'F3'=0x72;'F4'=0x73;'F5'=0x74;'F6'=0x75
    'F7'=0x76;'F8'=0x77;'F9'=0x78;'F10'=0x79;'F11'=0x7A;'F12'=0x7B
    'A'=0x41;'B'=0x42;'C'=0x43;'D'=0x44;'E'=0x45;'F'=0x46
    'G'=0x47;'H'=0x48;'I'=0x49;'J'=0x4A;'K'=0x4B;'L'=0x4C
    'M'=0x4D;'N'=0x4E;'O'=0x4F;'P'=0x50;'Q'=0x51;'R'=0x52
    'S'=0x53;'T'=0x54;'U'=0x55;'V'=0x56;'W'=0x57;'X'=0x58
    'Y'=0x59;'Z'=0x5A
    'D0'=0x30;'D1'=0x31;'D2'=0x32;'D3'=0x33;'D4'=0x34
    'D5'=0x35;'D6'=0x36;'D7'=0x37;'D8'=0x38;'D9'=0x39
    'Space'=0x20;'Shift'=0x10;'Control'=0x11;'Alt'=0x12
    'XButton1'=0x05;'XButton2'=0x06
}

$rng = New-Object System.Random
for ($i=0; $i -lt 45; $i++) {
    $script:nodes += [PSCustomObject]@{
        x  = $rng.NextDouble()*460
        y  = $rng.NextDouble()*440
        vx = ($rng.NextDouble()-0.5)*0.5
        vy = ($rng.NextDouble()-0.5)*0.5
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

function F($n,$sz,$b='Regular') { New-Object System.Drawing.Font($n,$sz,[System.Drawing.FontStyle]::$b) }

$form=New-Object System.Windows.Forms.Form
$form.Text='HERO Clicker'
$form.ClientSize=New-Object System.Drawing.Size(460,440)
$form.StartPosition='CenterScreen'
$form.BackColor=$CB
$form.FormBorderStyle='None'
$form.TopMost=$true
$form.KeyPreview=$true
$form.DoubleBuffered=$true

$bgPanel=New-Object System.Windows.Forms.Panel
$bgPanel.Location=New-Object System.Drawing.Point(0,0)
$bgPanel.Size=New-Object System.Drawing.Size(460,440)
$bgPanel.BackColor=$CB
$form.Controls.Add($bgPanel)

$bgPanel.Add_Paint({
    param($s,$e)
    $g=$e.Graphics
    $g.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear($CB)

    for ($ai=0; $ai -lt $script:nodes.Count; $ai++) {
        $a=$script:nodes[$ai]
        for ($bi=$ai+1; $bi -lt $script:nodes.Count; $bi++) {
            $b=$script:nodes[$bi]
            $dx=[float]($a.x-$b.x); $dy=[float]($a.y-$b.y)
            $d=[math]::Sqrt($dx*$dx+$dy*$dy)
            if ($d -lt 110) {
                $alpha=[int](60*(1.0-$d/110.0))
                if ($alpha -gt 0) {
                    $col=[System.Drawing.Color]::FromArgb($alpha,255,204,0)
                    $pen=New-Object System.Drawing.Pen($col,0.8)
                    $g.DrawLine($pen,[float]$a.x,[float]$a.y,[float]$b.x,[float]$b.y)
                    $pen.Dispose()
                }
            }
        }
    }

    foreach ($n in $script:nodes) {
        $br=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180,255,204,0))
        $g.FillEllipse($br,[float]($n.x-2.5),[float]($n.y-2.5),5.0,5.0)
        $br.Dispose()
    }
})

$bgPanel.Add_MouseDown({
    param($s,$e)
    if($e.Button -eq 'Left'){$script:dragForm=$true;$script:dragPt=$e.Location}
})
$bgPanel.Add_MouseMove({
    param($s,$e)
    if($script:dragForm){
        $form.Location=New-Object System.Drawing.Point(
            ($form.Location.X+$e.X-$script:dragPt.X),
            ($form.Location.Y+$e.Y-$script:dragPt.Y))
    }
})
$bgPanel.Add_MouseUp({$script:dragForm=$false})

$card=New-Object System.Windows.Forms.Panel
$card.Location=New-Object System.Drawing.Point(80,50)
$card.Size=New-Object System.Drawing.Size(300,336)
$card.BackColor=$CC
$card.BorderStyle='None'
$bgPanel.Controls.Add($card)

$card.Add_Paint({
    param($s,$e)
    $g=$e.Graphics
    $p=New-Object System.Drawing.Pen($CR,1)
    $g.DrawRectangle($p,0,0,$card.Width-1,$card.Height-1)
    $p.Dispose()
    $p2=New-Object System.Drawing.Pen($CY,2)
    $g.DrawLine($p2,0,0,$card.Width,0)
    $p2.Dispose()
})

$lblTitle=New-Object System.Windows.Forms.Label
$lblTitle.Text='HERO'
$lblTitle.Location=New-Object System.Drawing.Point(0,12)
$lblTitle.Size=New-Object System.Drawing.Size(300,44)
$lblTitle.Font=F 'Impact' 30
$lblTitle.ForeColor=$CY
$lblTitle.TextAlign='MiddleCenter'
$lblTitle.BackColor=[System.Drawing.Color]::Transparent
$card.Controls.Add($lblTitle)

$lblSub=New-Object System.Windows.Forms.Label
$lblSub.Text='• Auto Clicker •'
$lblSub.Location=New-Object System.Drawing.Point(0,56)
$lblSub.Size=New-Object System.Drawing.Size(300,16)
$lblSub.Font=F 'Segoe UI' 8
$lblSub.ForeColor=$CD
$lblSub.TextAlign='MiddleCenter'
$lblSub.BackColor=[System.Drawing.Color]::Transparent
$card.Controls.Add($lblSub)

function MakeSep($y) {
    $p=New-Object System.Windows.Forms.Panel
    $p.Location=New-Object System.Drawing.Point(20,$y)
    $p.Size=New-Object System.Drawing.Size(260,1)
    $p.BackColor=$CR
    $card.Controls.Add($p)
}
MakeSep 78; MakeSep 165; MakeSep 254

$TRACK_W=240; $THUMB_W=14; $TRACK_H=6; $THUMB_H=22

function MakeSlot($yBase,$label,$side) {
    $lbl=New-Object System.Windows.Forms.Label
    $lbl.Text=$label
    $lbl.Location=New-Object System.Drawing.Point(20,$yBase)
    $lbl.Size=New-Object System.Drawing.Size(260,16)
    $lbl.Font=F 'Segoe UI' 8 'Bold'
    $lbl.ForeColor=$CD
    $lbl.BackColor=[System.Drawing.Color]::Transparent
    $card.Controls.Add($lbl)

    $btn=New-Object System.Windows.Forms.Button
    $btn.Text='BIND KEY'
    $btn.Location=New-Object System.Drawing.Point(20,($yBase+20))
    $btn.Size=New-Object System.Drawing.Size(110,28)
    $btn.FlatStyle='Flat'
    $btn.BackColor=$CK
    $btn.ForeColor=$CT
    $btn.Font=F 'Segoe UI' 8 'Bold'
    $btn.FlatAppearance.BorderColor=$CR
    $btn.FlatAppearance.BorderSize=1
    $btn.Cursor=[System.Windows.Forms.Cursors]::Hand
    $card.Controls.Add($btn)

    $lblCps=New-Object System.Windows.Forms.Label
    $lblCps.Text='10 CPS'
    $lblCps.Location=New-Object System.Drawing.Point(140,($yBase+20))
    $lblCps.Size=New-Object System.Drawing.Size(140,28)
    $lblCps.Font=F 'Segoe UI' 12 'Bold'
    $lblCps.ForeColor=$CY
    $lblCps.BackColor=[System.Drawing.Color]::Transparent
    $lblCps.TextAlign='MiddleRight'
    $card.Controls.Add($lblCps)

    $trackY=$yBase+56
    $track=New-Object System.Windows.Forms.Panel
    $track.Location=New-Object System.Drawing.Point(20,$trackY)
    $track.Size=New-Object System.Drawing.Size($TRACK_W,$TRACK_H)
    $track.BackColor=$CK
    $track.Cursor=[System.Windows.Forms.Cursors]::Hand
    $card.Controls.Add($track)

    $fill=New-Object System.Windows.Forms.Panel
    $fill.Location=New-Object System.Drawing.Point(0,0)
    $fill.Size=New-Object System.Drawing.Size(1,$TRACK_H)
    $fill.BackColor=$CY
    $fill.Enabled=$false
    $track.Controls.Add($fill)

    $thumbAbsX=$card.Left+20-[int]($THUMB_W/2)
    $thumbAbsY=$card.Top+$trackY-[int](($THUMB_H-$TRACK_H)/2)
    $thumb=New-Object System.Windows.Forms.Panel
    $thumb.Size=New-Object System.Drawing.Size($THUMB_W,$THUMB_H)
    $thumb.BackColor=$CY
    $thumb.Cursor=[System.Windows.Forms.Cursors]::Hand
    $thumb.Location=New-Object System.Drawing.Point($thumbAbsX,$thumbAbsY)
    $bgPanel.Controls.Add($thumb)

    return @{btn=$btn;lblCps=$lblCps;track=$track;fill=$fill;thumb=$thumb;side=$side;trackY=$trackY}
}

$slotL=MakeSlot 87  'ACTION 1  -  LEFT CLICK'  'L'
$slotR=MakeSlot 175 'ACTION 2  -  RIGHT CLICK' 'R'

$lblStatus=New-Object System.Windows.Forms.Label
$lblStatus.Text='● READY'
$lblStatus.Location=New-Object System.Drawing.Point(0,263)
$lblStatus.Size=New-Object System.Drawing.Size(300,34)
$lblStatus.Font=F 'Segoe UI' 9 'Italic'
$lblStatus.ForeColor=$CD
$lblStatus.BackColor=[System.Drawing.Color]::Transparent
$lblStatus.TextAlign='MiddleCenter'
$card.Controls.Add($lblStatus)

$lblCredits=New-Object System.Windows.Forms.Label
$lblCredits.Text='Made by dpsss0'
$lblCredits.Location=New-Object System.Drawing.Point(0,305)
$lblCredits.Size=New-Object System.Drawing.Size(300,22)
$lblCredits.Font=F 'Segoe UI' 7
$lblCredits.ForeColor=[System.Drawing.Color]::FromArgb(50,50,50)
$lblCredits.BackColor=[System.Drawing.Color]::Transparent
$lblCredits.TextAlign='MiddleCenter'
$card.Controls.Add($lblCredits)

$btnMin=New-Object System.Windows.Forms.Button
$btnMin.Text='-'
$btnMin.Location=New-Object System.Drawing.Point(400,12)
$btnMin.Size=New-Object System.Drawing.Size(24,20)
$btnMin.FlatStyle='Flat'
$btnMin.BackColor=[System.Drawing.Color]::Transparent
$btnMin.ForeColor=$CD
$btnMin.Font=F 'Segoe UI' 10 'Bold'
$btnMin.FlatAppearance.BorderSize=0
$btnMin.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnMin.Add_MouseEnter({$btnMin.ForeColor=$CW})
$btnMin.Add_MouseLeave({$btnMin.ForeColor=$CD})
$btnMin.Add_Click({$form.WindowState='Minimized'})
$bgPanel.Controls.Add($btnMin)

$btnClose=New-Object System.Windows.Forms.Button
$btnClose.Text='X'
$btnClose.Location=New-Object System.Drawing.Point(428,12)
$btnClose.Size=New-Object System.Drawing.Size(24,20)
$btnClose.FlatStyle='Flat'
$btnClose.BackColor=[System.Drawing.Color]::Transparent
$btnClose.ForeColor=$CD
$btnClose.Font=F 'Segoe UI' 9 'Bold'
$btnClose.FlatAppearance.BorderSize=0
$btnClose.Cursor=[System.Windows.Forms.Cursors]::Hand
$btnClose.Add_MouseEnter({$btnClose.ForeColor=[System.Drawing.Color]::FromArgb(255,70,70)})
$btnClose.Add_MouseLeave({$btnClose.ForeColor=$CD})
$btnClose.Add_Click({
    foreach($t in @($script:timerL,$script:timerR,$script:timerPoll,$script:timerAnim)){if($t){$t.Stop();$t.Dispose()}}
    $form.Close()
})
$bgPanel.Controls.Add($btnClose)

function UpdateSlider($slot,$cps) {
    $pct=($cps-1)/499.0
    $px=[int]($TRACK_W*$pct)
    $slot.fill.Width=[math]::Max(1,$px)
    $tl=$card.Left+$slot.track.Left+$px-[int]($THUMB_W/2)
    $tt=$card.Top+$slot.trackY-[int](($THUMB_H-$TRACK_H)/2)
    $slot.thumb.Location=New-Object System.Drawing.Point($tl,$tt)
    $slot.lblCps.Text="$cps CPS"
}

function ApplyCps($slot,$rawX) {
    $cl=[math]::Max(0,[math]::Min($TRACK_W,$rawX))
    $nc=[math]::Max(1,[math]::Min(500,[int]($cl/$TRACK_W*499)+1))
    if ($slot.side -eq 'L') {
        $script:leftCps=$nc
        if($script:leftActive -and $script:timerL){$script:timerL.Interval=[math]::Max(1,[int](1000.0/$nc))}
    } else {
        $script:rightCps=$nc
        if($script:rightActive -and $script:timerR){$script:timerR.Interval=[math]::Max(1,[int](1000.0/$nc))}
    }
    UpdateSlider $slot $nc
}

UpdateSlider $slotL 10
UpdateSlider $slotR 10

foreach ($sl in @($slotL,$slotR)) {
    $s=$sl
    $s.thumb.Add_MouseDown({param($src,$e);if($e.Button -eq 'Left'){$script:activeSlot=$s;$form.Capture=$true}})
    $s.track.Add_MouseDown({param($src,$e);if($e.Button -eq 'Left'){$script:activeSlot=$s;ApplyCps $s $e.X;$form.Capture=$true}})
}

$form.Add_MouseMove({
    param($src,$e)
    if($script:activeSlot -ne $null){
        $sp=$form.PointToScreen($e.Location)
        $cp=$card.PointToClient($sp)
        ApplyCps $script:activeSlot ($cp.X-$script:activeSlot.track.Left)
    }
})
$form.Add_MouseUp({$script:activeSlot=$null;$form.Capture=$false})

function Toggle-Left {
    $script:leftActive=-not $script:leftActive
    if($script:leftActive){
        $slotL.btn.BackColor=$CY;$slotL.btn.ForeColor=[System.Drawing.Color]::Black
        $lblStatus.Text='▶ ACTION 1 ACTIVE';$lblStatus.ForeColor=$CY
        if($script:timerL){$script:timerL.Stop();$script:timerL.Dispose()}
        $script:timerL=New-Object System.Windows.Forms.Timer
        $script:timerL.Interval=[math]::Max(1,[int](1000.0/$script:leftCps))
        $script:timerL.Add_Tick({Invoke-Expression "[$($script:uid1)]::ClickLeft()"})
        $script:timerL.Start()
    } else {
        $slotL.btn.BackColor=$CK;$slotL.btn.ForeColor=$CT
        $lblStatus.Text='■ ACTION 1 STOPPED';$lblStatus.ForeColor=$CD
        if($script:timerL){$script:timerL.Stop()}
    }
}

function Toggle-Right {
    $script:rightActive=-not $script:rightActive
    if($script:rightActive){
        $slotR.btn.BackColor=$CY;$slotR.btn.ForeColor=[System.Drawing.Color]::Black
        $lblStatus.Text='▶ ACTION 2 ACTIVE';$lblStatus.ForeColor=$CY
        if($script:timerR){$script:timerR.Stop();$script:timerR.Dispose()}
        $script:timerR=New-Object System.Windows.Forms.Timer
        $script:timerR.Interval=[math]::Max(1,[int](1000.0/$script:rightCps))
        $script:timerR.Add_Tick({Invoke-Expression "[$($script:uid1)]::ClickRight()"})
        $script:timerR.Start()
    } else {
        $slotR.btn.BackColor=$CK;$slotR.btn.ForeColor=$CT
        $lblStatus.Text='■ ACTION 2 STOPPED';$lblStatus.ForeColor=$CD
        if($script:timerR){$script:timerR.Stop()}
    }
}

$slotL.btn.Add_Click({
    $script:waitL=$true
    $slotL.btn.Text='...';$slotL.btn.BackColor=$CY;$slotL.btn.ForeColor=[System.Drawing.Color]::Black
    $lblStatus.Text='● PRESS A KEY';$lblStatus.ForeColor=$CY;$form.Focus()
})
$slotR.btn.Add_Click({
    $script:waitR=$true
    $slotR.btn.Text='...';$slotR.btn.BackColor=$CY;$slotR.btn.ForeColor=[System.Drawing.Color]::Black
    $lblStatus.Text='● PRESS A KEY';$lblStatus.ForeColor=$CY;$form.Focus()
})

$form.Add_KeyDown({
    param($s,$e)
    $ks=$e.KeyCode.ToString()
    if($script:waitL -and $keyMap.ContainsKey($ks)){
        $script:leftVK=$keyMap[$ks]
        $slotL.btn.Text=$ks;$slotL.btn.BackColor=$CK;$slotL.btn.ForeColor=$CT
        $lblStatus.Text="● KEY SET: $ks";$lblStatus.ForeColor=$CD
        $script:waitL=$false;$script:skipL=$true
    } elseif($script:waitR -and $keyMap.ContainsKey($ks)){
        $script:rightVK=$keyMap[$ks]
        $slotR.btn.Text=$ks;$slotR.btn.BackColor=$CK;$slotR.btn.ForeColor=$CT
        $lblStatus.Text="● KEY SET: $ks";$lblStatus.ForeColor=$CD
        $script:waitR=$false;$script:skipR=$true
    }
})

$script:timerPoll=New-Object System.Windows.Forms.Timer
$script:timerPoll.Interval=50
$script:timerPoll.Add_Tick({
    if($script:leftVK -ne 0){
        $p=Invoke-Expression "[$($script:uid2)]::IsPressed($script:leftVK)"
        if($p -and -not $script:prevL){
            if(-not $script:skipL){Toggle-Left}else{$script:skipL=$false}
            $script:prevL=$true
        } elseif(-not $p){$script:prevL=$false}
    }
    if($script:rightVK -ne 0){
        $p=Invoke-Expression "[$($script:uid2)]::IsPressed($script:rightVK)"
        if($p -and -not $script:prevR){
            if(-not $script:skipR){Toggle-Right}else{$script:skipR=$false}
            $script:prevR=$true
        } elseif(-not $p){$script:prevR=$false}
    }
})
$script:timerPoll.Start()

$script:timerAnim=New-Object System.Windows.Forms.Timer
$script:timerAnim.Interval=28
$script:timerAnim.Add_Tick({
    foreach($n in $script:nodes){
        $n.x+=$n.vx;$n.y+=$n.vy
        if($n.x -lt 0){$n.x=0;$n.vx=[math]::Abs($n.vx)}
        if($n.x -gt 460){$n.x=460;$n.vx=-[math]::Abs($n.vx)}
        if($n.y -lt 0){$n.y=0;$n.vy=[math]::Abs($n.vy)}
        if($n.y -gt 440){$n.y=440;$n.vy=-[math]::Abs($n.vy)}
    }
    $bgPanel.Invalidate($false)
})
$script:timerAnim.Start()

$form.Add_FormClosing({
    foreach($t in @($script:timerL,$script:timerR,$script:timerPoll,$script:timerAnim)){if($t){$t.Stop();$t.Dispose()}}
})

$bgPanel.Controls.SetChildIndex($card,0)

[void]$form.ShowDialog()
