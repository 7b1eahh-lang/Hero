$ErrorActionPreference = 'SilentlyContinue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$uid1 = -join ((65..90)+(97..122) | Get-Random -Count 14 | % {[char]$_})
$uid2 = -join ((65..90)+(97..122) | Get-Random -Count 13 | % {[char]$_})

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

$S = @{
    leftActive  = $false; rightActive = $false
    leftCps     = 10;     rightCps    = 10
    leftVK      = 0;      rightVK     = 0
    waitL       = $false; waitR       = $false
    skipL       = $false; skipR       = $false
    prevL       = $false; prevR       = $false
    timerL      = $null;  timerR      = $null
    timerPoll   = $null;  timerAnim   = $null
    dragForm    = $false; dragPt      = $null
    dragSlL     = $false; dragSlR     = $false
    nodes       = @()
}

$rng = New-Object System.Random
for ($i=0; $i -lt 38; $i++) {
    $S.nodes += @{ x=$rng.NextDouble()*460; y=$rng.NextDouble()*430; vx=($rng.NextDouble()-0.5)*0.45; vy=($rng.NextDouble()-0.5)*0.45 }
}

$COL_BG     = [System.Drawing.Color]::FromArgb(8,8,8)
$COL_CARD   = [System.Drawing.Color]::FromArgb(26,26,26)
$COL_BORDER = [System.Drawing.Color]::FromArgb(55,55,55)
$COL_YELLOW = [System.Drawing.Color]::FromArgb(255,204,0)
$COL_TEXT   = [System.Drawing.Color]::FromArgb(210,210,210)
$COL_DIM    = [System.Drawing.Color]::FromArgb(110,110,110)
$COL_IDLE   = [System.Drawing.Color]::FromArgb(42,42,42)
$COL_BLACK  = [System.Drawing.Color]::Black

function F($n,$sz,$b='Regular') { New-Object System.Drawing.Font($n,$sz,[System.Drawing.FontStyle]::$b) }

$form = New-Object System.Windows.Forms.Form
$form.Text            = 'HERO Clicker'
$form.ClientSize      = New-Object System.Drawing.Size(460, 430)
$form.StartPosition   = 'CenterScreen'
$form.BackColor       = $COL_BG
$form.FormBorderStyle = 'None'
$form.TopMost         = $true
$form.KeyPreview      = $true
$form.DoubleBuffered  = $true

$canvas = New-Object System.Windows.Forms.PictureBox
$canvas.Dock      = 'Fill'
$canvas.BackColor = $COL_BG
$form.Controls.Add($canvas)

$canvas.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    foreach ($a in $S.nodes) {
        foreach ($b in $S.nodes) {
            if ($a -eq $b) { continue }
            $dx = $a.x-$b.x; $dy = $a.y-$b.y
            $d  = [math]::Sqrt($dx*$dx+$dy*$dy)
            if ($d -lt 105) {
                $al = [int](50*(1-$d/105))
                $p  = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb($al,255,204,0))
                $p.Width = 0.7
                $g.DrawLine($p,[float]$a.x,[float]$a.y,[float]$b.x,[float]$b.y)
                $p.Dispose()
            }
        }
    }
    foreach ($n in $S.nodes) {
        $br = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(170,255,204,0))
        $g.FillEllipse($br,[float]($n.x-2.5),[float]($n.y-2.5),5,5)
        $br.Dispose()
    }
})

$card = New-Object System.Windows.Forms.Panel
$card.Location  = New-Object System.Drawing.Point(80, 55)
$card.Size      = New-Object System.Drawing.Size(300, 318)
$card.BackColor = $COL_CARD
$canvas.Controls.Add($card)

$card.Add_Paint({
    param($s,$e)
    $pen = New-Object System.Drawing.Pen($COL_BORDER, 1)
    $e.Graphics.DrawRectangle($pen, 0, 0, $card.Width-1, $card.Height-1)
    $pen.Dispose()
    $pen2 = New-Object System.Drawing.Pen($COL_YELLOW, 2)
    $e.Graphics.DrawLine($pen2, 0, 0, $card.Width, 0)
    $pen2.Dispose()
})

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = 'HERO'
$lblTitle.Location  = New-Object System.Drawing.Point(0, 14)
$lblTitle.Size      = New-Object System.Drawing.Size(300, 42)
$lblTitle.Font      = F 'Impact' 28
$lblTitle.ForeColor = $COL_YELLOW
$lblTitle.TextAlign = 'MiddleCenter'
$lblTitle.BackColor = [System.Drawing.Color]::Transparent
$card.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = '• Auto Clicker •'
$lblSub.Location  = New-Object System.Drawing.Point(0, 56)
$lblSub.Size      = New-Object System.Drawing.Size(300, 16)
$lblSub.Font      = F 'Segoe UI' 8
$lblSub.ForeColor = $COL_DIM
$lblSub.TextAlign = 'MiddleCenter'
$lblSub.BackColor = [System.Drawing.Color]::Transparent
$card.Controls.Add($lblSub)

$sep0 = New-Object System.Windows.Forms.Panel
$sep0.Location  = New-Object System.Drawing.Point(20, 78)
$sep0.Size      = New-Object System.Drawing.Size(260, 1)
$sep0.BackColor = $COL_BORDER
$card.Controls.Add($sep0)

$lblL0 = New-Object System.Windows.Forms.Label
$lblL0.Text      = 'ACTION 1  —  LEFT CLICK'
$lblL0.Location  = New-Object System.Drawing.Point(20, 88)
$lblL0.Size      = New-Object System.Drawing.Size(260, 16)
$lblL0.Font      = F 'Segoe UI' 8 'Bold'
$lblL0.ForeColor = $COL_DIM
$lblL0.BackColor = [System.Drawing.Color]::Transparent
$card.Controls.Add($lblL0)

$btnL = New-Object System.Windows.Forms.Button
$btnL.Text      = 'BIND KEY'
$btnL.Location  = New-Object System.Drawing.Point(20, 108)
$btnL.Size      = New-Object System.Drawing.Size(110, 28)
$btnL.FlatStyle = 'Flat'
$btnL.BackColor = $COL_IDLE
$btnL.ForeColor = $COL_TEXT
$btnL.Font      = F 'Segoe UI' 8 'Bold'
$btnL.FlatAppearance.BorderColor = $COL_BORDER
$btnL.FlatAppearance.BorderSize  = 1
$btnL.Cursor    = [System.Windows.Forms.Cursors]::Hand
$card.Controls.Add($btnL)

$lblCpsL = New-Object System.Windows.Forms.Label
$lblCpsL.Text      = '10 CPS'
$lblCpsL.Location  = New-Object System.Drawing.Point(140, 108)
$lblCpsL.Size      = New-Object System.Drawing.Size(140, 28)
$lblCpsL.Font      = F 'Segoe UI' 12 'Bold'
$lblCpsL.ForeColor = $COL_YELLOW
$lblCpsL.BackColor = [System.Drawing.Color]::Transparent
$lblCpsL.TextAlign = 'MiddleRight'
$card.Controls.Add($lblCpsL)

$slBgL = New-Object System.Windows.Forms.Panel
$slBgL.Location  = New-Object System.Drawing.Point(20, 136)
$slBgL.Size      = New-Object System.Drawing.Size(260, 18)
$slBgL.BackColor = $COL_IDLE
$slBgL.Cursor    = [System.Windows.Forms.Cursors]::Hand
$card.Controls.Add($slBgL)

$fillL = New-Object System.Windows.Forms.Panel
$fillL.Location  = New-Object System.Drawing.Point(0,0)
$fillL.Size      = New-Object System.Drawing.Size(5,18)
$fillL.BackColor = $COL_YELLOW
$fillL.Enabled   = $false
$slBgL.Controls.Add($fillL)

$sep1 = New-Object System.Windows.Forms.Panel
$sep1.Location  = New-Object System.Drawing.Point(20, 164)
$sep1.Size      = New-Object System.Drawing.Size(260, 1)
$sep1.BackColor = $COL_BORDER
$card.Controls.Add($sep1)

$lblR0 = New-Object System.Windows.Forms.Label
$lblR0.Text      = 'ACTION 2  —  RIGHT CLICK'
$lblR0.Location  = New-Object System.Drawing.Point(20, 174)
$lblR0.Size      = New-Object System.Drawing.Size(260, 16)
$lblR0.Font      = F 'Segoe UI' 8 'Bold'
$lblR0.ForeColor = $COL_DIM
$lblR0.BackColor = [System.Drawing.Color]::Transparent
$card.Controls.Add($lblR0)

$btnR = New-Object System.Windows.Forms.Button
$btnR.Text      = 'BIND KEY'
$btnR.Location  = New-Object System.Drawing.Point(20, 194)
$btnR.Size      = New-Object System.Drawing.Size(110, 28)
$btnR.FlatStyle = 'Flat'
$btnR.BackColor = $COL_IDLE
$btnR.ForeColor = $COL_TEXT
$btnR.Font      = F 'Segoe UI' 8 'Bold'
$btnR.FlatAppearance.BorderColor = $COL_BORDER
$btnR.FlatAppearance.BorderSize  = 1
$btnR.Cursor    = [System.Windows.Forms.Cursors]::Hand
$card.Controls.Add($btnR)

$lblCpsR = New-Object System.Windows.Forms.Label
$lblCpsR.Text      = '10 CPS'
$lblCpsR.Location  = New-Object System.Drawing.Point(140, 194)
$lblCpsR.Size      = New-Object System.Drawing.Size(140, 28)
$lblCpsR.Font      = F 'Segoe UI' 12 'Bold'
$lblCpsR.ForeColor = $COL_YELLOW
$lblCpsR.BackColor = [System.Drawing.Color]::Transparent
$lblCpsR.TextAlign = 'MiddleRight'
$card.Controls.Add($lblCpsR)

$slBgR = New-Object System.Windows.Forms.Panel
$slBgR.Location  = New-Object System.Drawing.Point(20, 228)
$slBgR.Size      = New-Object System.Drawing.Size(260, 18)
$slBgR.BackColor = $COL_IDLE
$slBgR.Cursor    = [System.Windows.Forms.Cursors]::Hand
$card.Controls.Add($slBgR)

$fillR = New-Object System.Windows.Forms.Panel
$fillR.Location  = New-Object System.Drawing.Point(0,0)
$fillR.Size      = New-Object System.Drawing.Size(5,18)
$fillR.BackColor = $COL_YELLOW
$fillR.Enabled   = $false
$slBgR.Controls.Add($fillR)

$sep2 = New-Object System.Windows.Forms.Panel
$sep2.Location  = New-Object System.Drawing.Point(20, 256)
$sep2.Size      = New-Object System.Drawing.Size(260, 1)
$sep2.BackColor = $COL_BORDER
$card.Controls.Add($sep2)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = '● READY'
$lblStatus.Location  = New-Object System.Drawing.Point(0, 264)
$lblStatus.Size      = New-Object System.Drawing.Size(300, 34)
$lblStatus.Font      = F 'Segoe UI' 9 'Italic'
$lblStatus.ForeColor = $COL_DIM
$lblStatus.BackColor = [System.Drawing.Color]::Transparent
$lblStatus.TextAlign = 'MiddleCenter'
$card.Controls.Add($lblStatus)

$lblCredits = New-Object System.Windows.Forms.Label
$lblCredits.Text      = 'Made by dpsss0'
$lblCredits.Location  = New-Object System.Drawing.Point(0, 298)
$lblCredits.Size      = New-Object System.Drawing.Size(300, 22)
$lblCredits.Font      = F 'Segoe UI' 7
$lblCredits.ForeColor = [System.Drawing.Color]::FromArgb(55,55,55)
$lblCredits.BackColor = [System.Drawing.Color]::Transparent
$lblCredits.TextAlign = 'MiddleCenter'
$card.Controls.Add($lblCredits)

$btnMin = New-Object System.Windows.Forms.Button
$btnMin.Text      = '—'
$btnMin.Location  = New-Object System.Drawing.Point(400, 12)
$btnMin.Size      = New-Object System.Drawing.Size(24, 20)
$btnMin.FlatStyle = 'Flat'
$btnMin.BackColor = [System.Drawing.Color]::Transparent
$btnMin.ForeColor = $COL_DIM
$btnMin.Font      = F 'Segoe UI' 9
$btnMin.FlatAppearance.BorderSize = 0
$btnMin.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnMin.Add_MouseEnter({ $btnMin.ForeColor = [System.Drawing.Color]::White })
$btnMin.Add_MouseLeave({ $btnMin.ForeColor = $COL_DIM })
$btnMin.Add_Click({ $form.WindowState = 'Minimized' })
$canvas.Controls.Add($btnMin)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text      = '✕'
$btnClose.Location  = New-Object System.Drawing.Point(428, 12)
$btnClose.Size      = New-Object System.Drawing.Size(24, 20)
$btnClose.FlatStyle = 'Flat'
$btnClose.BackColor = [System.Drawing.Color]::Transparent
$btnClose.ForeColor = $COL_DIM
$btnClose.Font      = F 'Segoe UI' 9
$btnClose.FlatAppearance.BorderSize = 0
$btnClose.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnClose.Add_MouseEnter({ $btnClose.ForeColor = [System.Drawing.Color]::FromArgb(255,70,70) })
$btnClose.Add_MouseLeave({ $btnClose.ForeColor = $COL_DIM })
$btnClose.Add_Click({
    foreach ($t in @($S.timerL,$S.timerR,$S.timerPoll,$S.timerAnim)) { if ($t) { $t.Stop(); $t.Dispose() } }
    $form.Close()
})
$canvas.Controls.Add($btnClose)

$canvas.Add_MouseDown({
    param($s,$e)
    if ($e.Button -eq 'Left') { $S.dragForm = $true; $S.dragPt = $e.Location }
})
$canvas.Add_MouseMove({
    param($s,$e)
    if ($S.dragForm) {
        $form.Location = New-Object System.Drawing.Point(($form.Location.X+$e.X-$S.dragPt.X),($form.Location.Y+$e.Y-$S.dragPt.Y))
    }
})
$canvas.Add_MouseUp({ $S.dragForm = $false })

$slBgL.Add_MouseDown({
    param($s,$e)
    $S.dragSlL = $true
    $nc = [math]::Max(1,[math]::Min(500,[int]($e.X/260.0*500)))
    $S['leftCps'] = $nc; $lblCpsL.Text = "$nc CPS"
    $fillL.Width = [math]::Max(2,[int](260*$nc/500.0))
})
$slBgR.Add_MouseDown({
    param($s,$e)
    $S.dragSlR = $true
    $nc = [math]::Max(1,[math]::Min(500,[int]($e.X/260.0*500)))
    $S['rightCps'] = $nc; $lblCpsR.Text = "$nc CPS"
    $fillR.Width = [math]::Max(2,[int](260*$nc/500.0))
})

$card.Add_MouseMove({
    param($s,$e)
    if ($S.dragSlL) {
        $rx = $e.X - $slBgL.Left
        $nc = [math]::Max(1,[math]::Min(500,[int]($rx/260.0*500)))
        $S['leftCps'] = $nc; $lblCpsL.Text = "$nc CPS"
        $fillL.Width = [math]::Max(2,[int](260*$nc/500.0))
        if ($S.leftActive) {
            if ($S.timerL) { $S.timerL.Stop(); $S.timerL.Dispose() }
            $S.timerL = New-Object System.Windows.Forms.Timer
            $S.timerL.Interval = [math]::Max(1,[int](1000.0/$nc))
            $S.timerL.Add_Tick({ Invoke-Expression "[$uid1]::ClickLeft()" })
            $S.timerL.Start()
        }
    }
    if ($S.dragSlR) {
        $rx = $e.X - $slBgR.Left
        $nc = [math]::Max(1,[math]::Min(500,[int]($rx/260.0*500)))
        $S['rightCps'] = $nc; $lblCpsR.Text = "$nc CPS"
        $fillR.Width = [math]::Max(2,[int](260*$nc/500.0))
        if ($S.rightActive) {
            if ($S.timerR) { $S.timerR.Stop(); $S.timerR.Dispose() }
            $S.timerR = New-Object System.Windows.Forms.Timer
            $S.timerR.Interval = [math]::Max(1,[int](1000.0/$nc))
            $S.timerR.Add_Tick({ Invoke-Expression "[$uid1]::ClickRight()" })
            $S.timerR.Start()
        }
    }
})
$card.Add_MouseUp({ $S.dragSlL = $false; $S.dragSlR = $false })

$btnL.Add_Click({
    $S.waitL = $true
    $btnL.Text = '...'; $btnL.BackColor = $COL_YELLOW; $btnL.ForeColor = $COL_BLACK
    $lblStatus.Text = '● PRESS A KEY'; $lblStatus.ForeColor = $COL_YELLOW
    $form.Focus()
})
$btnR.Add_Click({
    $S.waitR = $true
    $btnR.Text = '...'; $btnR.BackColor = $COL_YELLOW; $btnR.ForeColor = $COL_BLACK
    $lblStatus.Text = '● PRESS A KEY'; $lblStatus.ForeColor = $COL_YELLOW
    $form.Focus()
})

$form.Add_KeyDown({
    param($s,$e)
    $ks = $e.KeyCode.ToString()
    if ($S.waitL -and $keyMap.ContainsKey($ks)) {
        $S['leftVK']   = $keyMap[$ks]
        $btnL.Text = $ks; $btnL.BackColor = $COL_IDLE; $btnL.ForeColor = $COL_TEXT
        $lblStatus.Text = "● KEY SET: $ks"; $lblStatus.ForeColor = $COL_DIM
        $S.waitL = $false; $S.skipL = $true
    } elseif ($S.waitR -and $keyMap.ContainsKey($ks)) {
        $S['rightVK']  = $keyMap[$ks]
        $btnR.Text = $ks; $btnR.BackColor = $COL_IDLE; $btnR.ForeColor = $COL_TEXT
        $lblStatus.Text = "● KEY SET: $ks"; $lblStatus.ForeColor = $COL_DIM
        $S.waitR = $false; $S.skipR = $true
    }
})

function Toggle-Left {
    $S.leftActive = -not $S.leftActive
    if ($S.leftActive) {
        $btnL.BackColor = $COL_YELLOW; $btnL.ForeColor = $COL_BLACK
        $lblStatus.Text = '▶ ACTION 1 ACTIVE'; $lblStatus.ForeColor = $COL_YELLOW
        if ($S.timerL) { $S.timerL.Stop(); $S.timerL.Dispose() }
        $S.timerL = New-Object System.Windows.Forms.Timer
        $S.timerL.Interval = [math]::Max(1,[int](1000.0/$S['leftCps']))
        $S.timerL.Add_Tick({ Invoke-Expression "[$uid1]::ClickLeft()" })
        $S.timerL.Start()
    } else {
        $btnL.BackColor = $COL_IDLE; $btnL.ForeColor = $COL_TEXT
        $lblStatus.Text = '■ ACTION 1 STOPPED'; $lblStatus.ForeColor = $COL_DIM
        if ($S.timerL) { $S.timerL.Stop() }
    }
}

function Toggle-Right {
    $S.rightActive = -not $S.rightActive
    if ($S.rightActive) {
        $btnR.BackColor = $COL_YELLOW; $btnR.ForeColor = $COL_BLACK
        $lblStatus.Text = '▶ ACTION 2 ACTIVE'; $lblStatus.ForeColor = $COL_YELLOW
        if ($S.timerR) { $S.timerR.Stop(); $S.timerR.Dispose() }
        $S.timerR = New-Object System.Windows.Forms.Timer
        $S.timerR.Interval = [math]::Max(1,[int](1000.0/$S['rightCps']))
        $S.timerR.Add_Tick({ Invoke-Expression "[$uid1]::ClickRight()" })
        $S.timerR.Start()
    } else {
        $btnR.BackColor = $COL_IDLE; $btnR.ForeColor = $COL_TEXT
        $lblStatus.Text = '■ ACTION 2 STOPPED'; $lblStatus.ForeColor = $COL_DIM
        if ($S.timerR) { $S.timerR.Stop() }
    }
}

$S.timerPoll = New-Object System.Windows.Forms.Timer
$S.timerPoll.Interval = 50
$S.timerPoll.Add_Tick({
    if ($S['leftVK'] -ne 0) {
        $p = Invoke-Expression "[$uid2]::IsPressed($($S['leftVK']))"
        if ($p -and -not $S.prevL) {
            if (-not $S.skipL) { Toggle-Left } else { $S.skipL = $false }
            $S.prevL = $true
        } elseif (-not $p) { $S.prevL = $false }
    }
    if ($S['rightVK'] -ne 0) {
        $p = Invoke-Expression "[$uid2]::IsPressed($($S['rightVK']))"
        if ($p -and -not $S.prevR) {
            if (-not $S.skipR) { Toggle-Right } else { $S.skipR = $false }
            $S.prevR = $true
        } elseif (-not $p) { $S.prevR = $false }
    }
})
$S.timerPoll.Start()

$S.timerAnim = New-Object System.Windows.Forms.Timer
$S.timerAnim.Interval = 28
$S.timerAnim.Add_Tick({
    foreach ($n in $S.nodes) {
        $n.x += $n.vx; $n.y += $n.vy
        if ($n.x -lt 0)   { $n.x=0;   $n.vx=[math]::Abs($n.vx) }
        if ($n.x -gt 460) { $n.x=460; $n.vx=-[math]::Abs($n.vx) }
        if ($n.y -lt 0)   { $n.y=0;   $n.vy=[math]::Abs($n.vy) }
        if ($n.y -gt 430) { $n.y=430; $n.vy=-[math]::Abs($n.vy) }
    }
    $canvas.Invalidate()
})
$S.timerAnim.Start()

$form.Add_FormClosing({
    foreach ($t in @($S.timerL,$S.timerR,$S.timerPoll,$S.timerAnim)) { if ($t) { $t.Stop(); $t.Dispose() } }
})

[void]$form.ShowDialog()
