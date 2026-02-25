$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$uid1 = -join ((65..90) + (97..122) | Get-Random -Count 14 | % { [char]$_ })
$uid2 = -join ((65..90) + (97..122) | Get-Random -Count 13 | % { [char]$_ })
$nativeCode = @"
using System;
using System.Runtime.InteropServices;
public class $uid1 {
    [DllImport("user32.dll")] private static extern uint SendInput(uint n, INPUT[] i, int s);
    [StructLayout(LayoutKind.Sequential)] private struct INPUT { public uint type; public MOUSEINPUT mi; }
    [StructLayout(LayoutKind.Sequential)] private struct MOUSEINPUT {
        public int dx,dy; public uint mouseData,dwFlags,time; public IntPtr dwExtraInfo;
    }
    const uint IM=0,LD=2,LU=4,RD=8,RU=16;
    public static void ClickLeft()  { var a=new INPUT[2]; a[0].type=a[1].type=IM; a[0].mi.dwFlags=LD; a[1].mi.dwFlags=LU; SendInput(2,a,System.Runtime.InteropServices.Marshal.SizeOf(typeof(INPUT))); }
    public static void ClickRight() { var a=new INPUT[2]; a[0].type=a[1].type=IM; a[0].mi.dwFlags=RD; a[1].mi.dwFlags=RU; SendInput(2,a,System.Runtime.InteropServices.Marshal.SizeOf(typeof(INPUT))); }
}
public class $uid2 {
    [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int v);
    public static bool IsPressed(int v) { return (GetAsyncKeyState(v) & 0x8000) != 0; }
}
"@
if (-not ([System.Management.Automation.PSTypeName]$uid1).Type) { Add-Type -TypeDefinition $nativeCode }
$C = @{
    bg      = [System.Drawing.Color]::FromArgb(10,10,10)
    panel   = [System.Drawing.Color]::FromArgb(28,28,28)
    border  = [System.Drawing.Color]::FromArgb(50,50,50)
    yellow  = [System.Drawing.Color]::FromArgb(255,204,0)
    yellowD = [System.Drawing.Color]::FromArgb(200,160,0)
    text    = [System.Drawing.Color]::FromArgb(220,220,220)
    dimText = [System.Drawing.Color]::FromArgb(120,120,120)
    active  = [System.Drawing.Color]::FromArgb(255,204,0)
    idle    = [System.Drawing.Color]::FromArgb(50,50,50)
    white   = [System.Drawing.Color]::White
}
function MakeFont($name,$size,$style='Regular') {
    New-Object System.Drawing.Font($name,$size,[System.Drawing.FontStyle]::$style)
}
$S = @{
    leftActive=$false; rightActive=$false
    leftCps=10;        rightCps=10
    leftVK=0;          rightVK=0
    waitL=$false;      waitR=$false
    skipL=$false;      skipR=$false
    prevL=$false;      prevR=$false
    timerL=$null;      timerR=$null
    timerPoll=$null;   timerAnim=$null
    dragForm=$false;   dragPt=$null
    dragL=$false;      dragR=$false
    nodes=@(); animTick=0
}
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
for ($i=0; $i -lt 40; $i++) {
    $S.nodes += @{
        x  = $rng.NextDouble() * 460
        y  = $rng.NextDouble() * 420
        vx = ($rng.NextDouble() - 0.5) * 0.4
        vy = ($rng.NextDouble() - 0.5) * 0.4
    }
}
$form = New-Object System.Windows.Forms.Form
$form.Text            = 'ShadowClicker'
$form.Size            = New-Object System.Drawing.Size(460, 420)
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = $C.bg
$form.FormBorderStyle = 'None'
$form.TopMost         = $true
$form.KeyPreview      = $true
$form.DoubleBuffered  = $true
$canvas = New-Object System.Windows.Forms.PictureBox
$canvas.Location = New-Object System.Drawing.Point(0,0)
$canvas.Size     = $form.Size
$canvas.BackColor= $C.bg
$form.Controls.Add($canvas)
$canvas.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $edgePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40,255,204,0))
    $edgePen.Width = 0.8
    foreach ($a in $S.nodes) {
        foreach ($b in $S.nodes) {
            if ($a -eq $b) { continue }
            $dx2 = $a.x - $b.x; $dy2 = $a.y - $b.y
            $d = [math]::Sqrt($dx2*$dx2 + $dy2*$dy2)
            if ($d -lt 110) {
                $alpha = [int](55 * (1 - $d/110))
                $pen2 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($alpha,255,204,0))
                $pen2.Width = 0.8
                $g.DrawLine($pen2,[float]$a.x,[float]$a.y,[float]$b.x,[float]$b.y)
                $pen2.Dispose()
            }
        }
    }
    $edgePen.Dispose()
    foreach ($n in $S.nodes) {
        $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(180,255,204,0))
        $g.FillEllipse($br,[float]($n.x-2),[float]($n.y-2),4,4)
        $br.Dispose()
    }
})
$card = New-Object System.Windows.Forms.Panel
$card.Location  = New-Object System.Drawing.Point(80, 60)
$card.Size      = New-Object System.Drawing.Size(300, 295)
$card.BackColor = [System.Drawing.Color]::FromArgb(32,32,32)
$canvas.Controls.Add($card)
$card.Add_Paint({
    param($s,$e)
    $rect = New-Object System.Drawing.Rectangle(0,0,$card.Width-1,$card.Height-1)
    $pen  = New-Object System.Drawing.Pen($C.border, 1)
    $e.Graphics.DrawRectangle($pen, $rect)
    $pen.Dispose()
})
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = 'SHADOW CLICKER'
$lblTitle.Location  = New-Object System.Drawing.Point(0, 16)
$lblTitle.Size      = New-Object System.Drawing.Size(300, 36)
$lblTitle.Font      = MakeFont 'Impact' 20 'Regular'
$lblTitle.ForeColor = $C.yellow
$lblTitle.TextAlign = 'MiddleCenter'
$lblTitle.BackColor = [System.Drawing.Color]::Transparent
$card.Controls.Add($lblTitle)
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = '• Auto Clicker •'
$lblSub.Location  = New-Object System.Drawing.Point(0, 52)
$lblSub.Size      = New-Object System.Drawing.Size(300, 18)
$lblSub.Font      = MakeFont 'Segoe UI' 8 'Regular'
$lblSub.ForeColor = $C.dimText
$lblSub.TextAlign = 'MiddleCenter'
$lblSub.BackColor = [System.Drawing.Color]::Transparent
$card.Controls.Add($lblSub)
$sep = New-Object System.Windows.Forms.Panel
$sep.Location  = New-Object System.Drawing.Point(20, 76)
$sep.Size      = New-Object System.Drawing.Size(260, 1)
$sep.BackColor = $C.border
$card.Controls.Add($sep)
function Make-Slot {
    param($parent, $yOff, $labelText, [ref]$btnRef, [ref]$lblCpsRef, [ref]$fillRef)
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $labelText
    $lbl.Location  = New-Object System.Drawing.Point(20, $yOff)
    $lbl.Size      = New-Object System.Drawing.Size(260, 18)
    $lbl.Font      = MakeFont 'Segoe UI' 8 'Bold'
    $lbl.ForeColor = $C.dimText
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $parent.Controls.Add($lbl)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = 'BIND KEY'
    $btn.Location  = New-Object System.Drawing.Point(20, $yOff+22)
    $btn.Size      = New-Object System.Drawing.Size(100, 26)
    $btn.FlatStyle = 'Flat'
    $btn.BackColor = $C.idle
    $btn.ForeColor = $C.text
    $btn.Font      = MakeFont 'Segoe UI' 8 'Bold'
    $btn.FlatAppearance.BorderColor = $C.border
    $btn.FlatAppearance.BorderSize  = 1
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $parent.Controls.Add($btn)
    $btnRef.Value = $btn
    $lblCps = New-Object System.Windows.Forms.Label
    $lblCps.Text      = '10 CPS'
    $lblCps.Location  = New-Object System.Drawing.Point(130, $yOff+22)
    $lblCps.Size      = New-Object System.Drawing.Size(150, 26)
    $lblCps.Font      = MakeFont 'Segoe UI' 11 'Bold'
    $lblCps.ForeColor = $C.yellow
    $lblCps.BackColor = [System.Drawing.Color]::Transparent
    $lblCps.TextAlign = 'MiddleRight'
    $parent.Controls.Add($lblCps)
    $lblCpsRef.Value = $lblCps
    $slBg = New-Object System.Windows.Forms.Panel
    $slBg.Location    = New-Object System.Drawing.Point(20, $yOff+54)
    $slBg.Size        = New-Object System.Drawing.Size(260, 8)
    $slBg.BackColor   = $C.idle
    $slBg.Cursor      = [System.Windows.Forms.Cursors]::Hand
    $slFill = New-Object System.Windows.Forms.Panel
    $slFill.Location  = New-Object System.Drawing.Point(0,0)
    $slFill.Size      = New-Object System.Drawing.Size(5,8)
    $slFill.BackColor = $C.yellow
    $slFill.Enabled   = $false
    $slBg.Controls.Add($slFill)
    $parent.Controls.Add($slBg)
    $fillRef.Value = $slFill
    return $slBg
}
$btnL = $null; $lblCpsL = $null; $fillL = $null
$slBgL = Make-Slot $card 90 'ACTION 1 — LEFT CLICK' ([ref]$btnL) ([ref]$lblCpsL) ([ref]$fillL)
$btnR = $null; $lblCpsR = $null; $fillR = $null
$slBgR = Make-Slot $card 175 'ACTION 2 — RIGHT CLICK' ([ref]$btnR) ([ref]$lblCpsR) ([ref]$fillR)
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = '● READY'
$lblStatus.Location  = New-Object System.Drawing.Point(0, 260)
$lblStatus.Size      = New-Object System.Drawing.Size(300, 28)
$lblStatus.Font      = MakeFont 'Segoe UI' 9 'Italic'
$lblStatus.ForeColor = $C.dimText
$lblStatus.BackColor = [System.Drawing.Color]::Transparent
$lblStatus.TextAlign = 'MiddleCenter'
$card.Controls.Add($lblStatus)
$footer = New-Object System.Windows.Forms.Label
$footer.Text      = 'Made by dpsss0   |   github: ShadowClicker'
$footer.Location  = New-Object System.Drawing.Point(0, 380)
$footer.Size      = New-Object System.Drawing.Size(460, 20)
$footer.Font      = MakeFont 'Segoe UI' 7 'Regular'
$footer.ForeColor = [System.Drawing.Color]::FromArgb(60,60,60)
$footer.TextAlign = 'MiddleCenter'
$footer.BackColor = [System.Drawing.Color]::Transparent
$canvas.Controls.Add($footer)
function MakeWinBtn($text, $x) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text      = $text
    $b.Location  = New-Object System.Drawing.Point($x, 10)
    $b.Size      = New-Object System.Drawing.Size(28,22)
    $b.FlatStyle = 'Flat'
    $b.BackColor = [System.Drawing.Color]::Transparent
    $b.ForeColor = $C.dimText
    $b.Font      = MakeFont 'Segoe UI' 9 'Regular'
    $b.FlatAppearance.BorderSize  = 0
    $b.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $b.Add_MouseEnter({ $b.ForeColor = $C.white })
    $b.Add_MouseLeave({ $b.ForeColor = $C.dimText })
    $canvas.Controls.Add($b)
    return $b
}
$btnMin   = MakeWinBtn '—' 404
$btnClose = MakeWinBtn '✕' 432
$btnClose.Add_MouseEnter({ $btnClose.ForeColor = [System.Drawing.Color]::FromArgb(255,80,80) })
$btnMin.Add_Click({ $form.WindowState = 'Minimized' })
$btnClose.Add_Click({
    foreach ($t in @($S.timerL,$S.timerR,$S.timerPoll,$S.timerAnim)) {
        if ($t) { $t.Stop(); $t.Dispose() }
    }
    $form.Close()
})
$canvas.Add_MouseDown({
    param($s,$e)
    if ($e.Button -eq 'Left' -and $e.Y -lt 60) {
        $S.dragForm = $true; $S.dragPt = $e.Location
    }
})
$canvas.Add_MouseMove({
    param($s,$e)
    if ($S.dragForm) {
        $form.Location = New-Object System.Drawing.Point(
            ($form.Location.X + $e.X - $S.dragPt.X),
            ($form.Location.Y + $e.Y - $S.dragPt.Y))
    }
})
$canvas.Add_MouseUp({ $S.dragForm = $false })
function Wire-Slider {
    param($slBg, $fill, $lblCps, [ref]$cpsVar, [ref]$timerRef, $clickFn)
    $slBg.Add_MouseDown({
        param($s,$e)
        $S["drag_$($s.Name)"] = $true
        $nc = [math]::Max(1,[math]::Min(500,[int]($e.X/260.0*500)))
        $cpsVar.Value = $nc; $lblCps.Text = "$nc CPS"
        $fill.Width = [int](260*($nc/500.0))
    })
    $slBg.Add_MouseMove({
        param($s,$e)
        if ($S["drag_$($s.Name)"]) {
            $nc = [math]::Max(1,[math]::Min(500,[int]($e.X/260.0*500)))
            $cpsVar.Value = $nc; $lblCps.Text = "$nc CPS"
            $fill.Width = [int](260*($nc/500.0))
        }
    })
    $slBg.Add_MouseUp({ param($s,$e) $S["drag_$($s.Name)"] = $false })
}
$slBgL.Name = 'slL'; $slBgR.Name = 'slR'
$btnL.Add_Click({
    $S.waitL = $true
    $btnL.Text = '...'; $btnL.BackColor = $C.yellow; $btnL.ForeColor = [System.Drawing.Color]::Black
    $lblStatus.Text = '● PRESS A KEY'; $form.Focus()
})
$btnR.Add_Click({
    $S.waitR = $true
    $btnR.Text = '...'; $btnR.BackColor = $C.yellow; $btnR.ForeColor = [System.Drawing.Color]::Black
    $lblStatus.Text = '● PRESS A KEY'; $form.Focus()
})
$form.Add_KeyDown({
    param($s,$e)
    $ks = $e.KeyCode.ToString()
    if ($S.waitL -and $keyMap.ContainsKey($ks)) {
        $S.leftVK = $keyMap[$ks]
        $btnL.Text = $ks; $btnL.BackColor = $C.idle; $btnL.ForeColor = $C.text
        $lblStatus.Text = "● KEY SET: $ks"; $S.waitL=$false; $S.skipL=$true
    } elseif ($S.waitR -and $keyMap.ContainsKey($ks)) {
        $S.rightVK = $keyMap[$ks]
        $btnR.Text = $ks; $btnR.BackColor = $C.idle; $btnR.ForeColor = $C.text
        $lblStatus.Text = "● KEY SET: $ks"; $S.waitR=$false; $S.skipR=$true
    }
})
function Toggle-Left {
    $S.leftActive = -not $S.leftActive
    if ($S.leftActive) {
        $btnL.BackColor = $C.yellow; $btnL.ForeColor = [System.Drawing.Color]::Black
        $lblStatus.Text = '▶ ACTION 1 ACTIVE'
        $lblStatus.ForeColor = $C.yellow
        if ($S.timerL) { $S.timerL.Stop(); $S.timerL.Dispose() }
        $S.timerL = New-Object System.Windows.Forms.Timer
        $S.timerL.Interval = [math]::Max(1,[int](1000.0/$S.leftCps))
        $S.timerL.Add_Tick({ Invoke-Expression "[$uid1]::ClickLeft()" })
        $S.timerL.Start()
    } else {
        $btnL.BackColor = $C.idle; $btnL.ForeColor = $C.text
        $lblStatus.Text = '■ ACTION 1 STOPPED'; $lblStatus.ForeColor = $C.dimText
        if ($S.timerL) { $S.timerL.Stop() }
    }
}
function Toggle-Right {
    $S.rightActive = -not $S.rightActive
    if ($S.rightActive) {
        $btnR.BackColor = $C.yellow; $btnR.ForeColor = [System.Drawing.Color]::Black
        $lblStatus.Text = '▶ ACTION 2 ACTIVE'
        $lblStatus.ForeColor = $C.yellow
        if ($S.timerR) { $S.timerR.Stop(); $S.timerR.Dispose() }
        $S.timerR = New-Object System.Windows.Forms.Timer
        $S.timerR.Interval = [math]::Max(1,[int](1000.0/$S.rightCps))
        $S.timerR.Add_Tick({ Invoke-Expression "[$uid1]::ClickRight()" })
        $S.timerR.Start()
    } else {
        $btnR.BackColor = $C.idle; $btnR.ForeColor = $C.text
        $lblStatus.Text = '■ ACTION 2 STOPPED'; $lblStatus.ForeColor = $C.dimText
        if ($S.timerR) { $S.timerR.Stop() }
    }
}
$slBgL.Add_MouseMove({
    param($s,$e)
    if ($S['drag_slL'] -and $S.leftActive) {
        if ($S.timerL) { $S.timerL.Stop(); $S.timerL.Dispose() }
        $S.timerL = New-Object System.Windows.Forms.Timer
        $S.timerL.Interval = [math]::Max(1,[int](1000.0/$S.leftCps))
        $S.timerL.Add_Tick({ Invoke-Expression "[$uid1]::ClickLeft()" })
        $S.timerL.Start()
    }
})
$slBgR.Add_MouseMove({
    param($s,$e)
    if ($S['drag_slR'] -and $S.rightActive) {
        if ($S.timerR) { $S.timerR.Stop(); $S.timerR.Dispose() }
        $S.timerR = New-Object System.Windows.Forms.Timer
        $S.timerR.Interval = [math]::Max(1,[int](1000.0/$S.rightCps))
        $S.timerR.Add_Tick({ Invoke-Expression "[$uid1]::ClickRight()" })
        $S.timerR.Start()
    }
})
Wire-Slider $slBgL $fillL $lblCpsL ([ref]$S.leftCps) ([ref]$S.timerL) $null
Wire-Slider $slBgR $fillR $lblCpsR ([ref]$S.rightCps) ([ref]$S.timerR) $null
$S.timerPoll = New-Object System.Windows.Forms.Timer
$S.timerPoll.Interval = 50
$S.timerPoll.Add_Tick({
    if ($S.leftVK -ne 0) {
        $p = Invoke-Expression "[$uid2]::IsPressed($($S.leftVK))"
        if ($p -and -not $S.prevL) {
            if (-not $S.skipL) { Toggle-Left } else { $S.skipL = $false }
            $S.prevL = $true
        } elseif (-not $p) { $S.prevL = $false }
    }
    if ($S.rightVK -ne 0) {
        $p = Invoke-Expression "[$uid2]::IsPressed($($S.rightVK))"
        if ($p -and -not $S.prevR) {
            if (-not $S.skipR) { Toggle-Right } else { $S.skipR = $false }
            $S.prevR = $true
        } elseif (-not $p) { $S.prevR = $false }
    }
})
$S.timerPoll.Start()
$S.timerAnim = New-Object System.Windows.Forms.Timer
$S.timerAnim.Interval = 30
$S.timerAnim.Add_Tick({
    foreach ($n in $S.nodes) {
        $n.x += $n.vx; $n.y += $n.vy
        if ($n.x -lt 0)   { $n.x = 0;   $n.vx = [math]::Abs($n.vx) }
        if ($n.x -gt 460) { $n.x = 460; $n.vx = -[math]::Abs($n.vx) }
        if ($n.y -lt 0)   { $n.y = 0;   $n.vy = [math]::Abs($n.vy) }
        if ($n.y -gt 420) { $n.y = 420; $n.vy = -[math]::Abs($n.vy) }
    }
    $canvas.Invalidate()
})
$S.timerAnim.Start()
$form.Add_FormClosing({
    foreach ($t in @($S.timerL,$S.timerR,$S.timerPoll,$S.timerAnim)) {
        if ($t) { $t.Stop(); $t.Dispose() }
    }
})
[void]$form.ShowDialog()