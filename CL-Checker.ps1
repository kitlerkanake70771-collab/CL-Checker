# Auto-admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""; exit
}
$ErrorActionPreference = 'SilentlyContinue'
$VERSION = '3.0'
$UPDATE_URL = 'https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/CL-Checker.ps1'
$VERSION_URL = 'https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/version.txt'
Add-Type -AssemblyName System.Windows.Forms,System.Drawing

# ========== THEME ==========
$bg  = [System.Drawing.Color]::FromArgb(255,20,20,35)
$pn  = [System.Drawing.Color]::FromArgb(255,28,28,50)
$cr  = [System.Drawing.Color]::FromArgb(255,35,35,62)
$ac  = [System.Drawing.Color]::FromArgb(255,255,75,100)
$a2  = [System.Drawing.Color]::FromArgb(255,100,65,165)
$gr  = [System.Drawing.Color]::FromArgb(255,0,200,100)
$gy  = [System.Drawing.Color]::FromArgb(255,60,60,75)
$wh  = [System.Drawing.Color]::White
$tx  = [System.Drawing.Color]::FromArgb(255,210,210,220)
$dm  = [System.Drawing.Color]::FromArgb(255,130,130,145)
$dk  = [System.Drawing.Color]::FromArgb(255,15,15,28)

$FF = 'Segoe UI'
$FH  = New-Object System.Drawing.Font($FF,14,[System.Drawing.FontStyle]::Bold)
$F9  = New-Object System.Drawing.Font($FF,9); $F9B= New-Object System.Drawing.Font($FF,9,[System.Drawing.FontStyle]::Bold)
$F8  = New-Object System.Drawing.Font($FF,8); $F8B= New-Object System.Drawing.Font($FF,8,[System.Drawing.FontStyle]::Bold)
$F85 = New-Object System.Drawing.Font($FF,8.5)
$F7B = New-Object System.Drawing.Font($FF,7,[System.Drawing.FontStyle]::Bold)
$F11B=New-Object System.Drawing.Font($FF,11,[System.Drawing.FontStyle]::Bold)
$FL  = New-Object System.Drawing.Font('Consolas',9)

# ========== FORM ==========
$f = New-Object System.Windows.Forms.Form
$f.Text='CL Checker'; $f.Size=New-Object System.Drawing.Size(1060,700)
$f.StartPosition='CenterScreen'; $f.BackColor=$bg; $f.FormBorderStyle='FixedDialog'; $f.MaximizeBox=$false

# ========== HEADER ==========
$hd = New-Object System.Windows.Forms.Panel
$hd.Size=New-Object System.Drawing.Size(1050,40); $hd.Location=New-Object System.Drawing.Point(0,0); $hd.BackColor=$pn
$lb = New-Object System.Windows.Forms.Label; $lb.Text='CL Checker'; $lb.Font=$FH; $lb.ForeColor=$ac
$lb.AutoSize=$true; $lb.Location=New-Object System.Drawing.Point(14,5); $hd.Controls.Add($lb)
# Version label
$verLbl = New-Object System.Windows.Forms.Label
$verLbl.Text="v$VERSION";$verLbl.Font=$F8;$verLbl.ForeColor=$dm;$verLbl.AutoSize=$true
$verLbl.Location=New-Object System.Drawing.Point(130,12);$hd.Controls.Add($verLbl)
# Update button
$updBtn = New-Object System.Windows.Forms.Label
$updBtn.Text='[check update]';$updBtn.Font=New-Object System.Drawing.Font($FF,7,[System.Drawing.FontStyle]::Underline)
$updBtn.ForeColor=$a2;$updBtn.AutoSize=$true;$updBtn.Location=New-Object System.Drawing.Point(170,13)
$updBtn.Cursor=[System.Windows.Forms.Cursors]::Hand
$updBtn.Add_Click({
    $this.Text='[checking...]'
    $lv = CheckUpdate
    if($lv){$this.Text='[update ready]';$this.ForeColor=$gr}
    else{$this.Text='[check update]';$this.ForeColor=$a2}
})
$hd.Controls.AddRange(@($verLbl,$updBtn))
$f.Controls.Add($hd)

# ========== TAB CONTROL ==========
$tc = New-Object System.Windows.Forms.TabControl
$tc.Size=New-Object System.Drawing.Size(360,552); $tc.Location=New-Object System.Drawing.Point(6,44); $tc.BackColor=$bg
$tc.DrawMode='OwnerDrawFixed'; $tc.ItemSize=New-Object System.Drawing.Size(115,26); $tc.Font=$F8

$brA=New-Object System.Drawing.SolidBrush($ac); $brC=New-Object System.Drawing.SolidBrush($cr)
$brW=New-Object System.Drawing.SolidBrush($wh); $brG=New-Object System.Drawing.SolidBrush($dm)
$fmt=New-Object System.Drawing.StringFormat; $fmt.Alignment='Center'; $fmt.LineAlignment='Center'

$tc.add_DrawItem({
    param($s,$e); $r=$s.GetTabRect($e.Index); $t=$s.TabPages[$e.Index].Text
    $rf=New-Object System.Drawing.RectangleF($r.X,$r.Y,$r.Width,$r.Height)
    if($e.Index -eq $s.SelectedIndex){$e.Graphics.FillRectangle($brA,$r);$e.Graphics.DrawString($t,$F8B,$brW,$rf,$fmt)}
    else{$e.Graphics.FillRectangle($brC,$r);$e.Graphics.DrawString($t,$F8,$brG,$rf,$fmt)}
})
$f.Controls.Add($tc)

# ========== LOG ==========
$lp = New-Object System.Windows.Forms.Panel
$lp.Size=New-Object System.Drawing.Size(676,442); $lp.Location=New-Object System.Drawing.Point(374,44); $lp.BackColor=$dk
$lg = New-Object System.Windows.Forms.RichTextBox
$lg.Size=New-Object System.Drawing.Size(668,434); $lg.Location=New-Object System.Drawing.Point(4,4)
$lg.BackColor=$dk; $lg.ForeColor=$wh; $lg.Font=$FL; $lg.ReadOnly=$true; $lg.BorderStyle='None'; $lg.WordWrap=$true
$lp.Controls.Add($lg); $f.Controls.Add($lp)

# Progress + Status
$pr = New-Object System.Windows.Forms.ProgressBar
$pr.Size=New-Object System.Drawing.Size(676,5); $pr.Location=New-Object System.Drawing.Point(374,490); $pr.Visible=$false
$f.Controls.Add($pr)

$st = New-Object System.Windows.Forms.Label; $st.Text='Ready'; $st.Font=$F8; $st.ForeColor=$dm
$st.AutoSize=$true; $st.Location=New-Object System.Drawing.Point(10,650); $f.Controls.Add($st)

# ========== BUTTONS ==========
function B($t,$x,$y,$w,$h,$c,$fs=9){
    $b=New-Object System.Windows.Forms.Button;$b.Text=$t;$b.Location=New-Object System.Drawing.Point($x,$y)
    $b.Size=New-Object System.Drawing.Size($w,$h);$b.BackColor=$c;$b.ForeColor=$wh
    $b.Font=New-Object System.Drawing.Font($FF,$fs,[System.Drawing.FontStyle]::Bold)
    $b.FlatStyle='Flat';$b.FlatAppearance.BorderSize=0;$b.Cursor=[System.Windows.Forms.Cursors]::Hand
    $b.UseVisualStyleBackColor=$false;return $b
}
$bAll=B 'ALL CHECKS'     374 502 250 30 $a2
$bClr=B 'CLEAR LOG'      632 502 130 30 $gy
$bSav=B 'SAVE LOG'       770 502 130 30 $gy
$f.Controls.AddRange(@($bAll,$bClr,$bSav))

# ========== CHECKBOX BUILDER ==========
$global:CB=@{}; $global:GC=@{}

function Cat($p,$t,$y){
    $k=$t -replace '[^a-zA-Z]',''
    $h=New-Object System.Windows.Forms.Panel;$h.Size=New-Object System.Drawing.Size(340,24)
    $h.Location=New-Object System.Drawing.Point(4,$y);$h.BackColor=$cr
    $l=New-Object System.Windows.Forms.Label;$l.Text=$t;$l.Font=$F9B;$l.ForeColor=$ac
    $l.AutoSize=$true;$l.Location=New-Object System.Drawing.Point(8,3);$h.Controls.Add($l)
    # run all in category
    $r=New-Object System.Windows.Forms.Label;$r.Text='run all';$r.Font=$F7B;$r.ForeColor=$gr
    $r.AutoSize=$true;$r.Location=New-Object System.Drawing.Point(277,5);$r.Cursor=[System.Windows.Forms.Cursors]::Hand
    $r.Tag=$k
    $r.Add_Click({$ck=$this.Tag;if($global:GC[$ck]){$ks=$global:GC[$ck];$pr.Visible=$true;$pr.Maximum=$ks.Count;$pr.Value=0;$rn=0;foreach($x in $ks){$a=$ACT[$x];if($a){if($a.C){$st.Text="$($a.L)...";& $a.C};if($a.F){$st.Text="$($a.L)...";& $a.F}};$rn++;$pr.Value=$rn};$pr.Visible=$false;$st.Text="Ready";ds "Category done ($rn)"}})
    $h.Controls.Add($r)
    $p.Controls.Add($h);$global:GC[$k]=@()
    return @{Y=$y+26;Cat=$k}
}
function Ch($p,$y,$key,$txt,$cat){
    $b=New-Object System.Windows.Forms.Button
    $b.Text="   $txt";$b.Size=New-Object System.Drawing.Size(338,22);$b.Location=New-Object System.Drawing.Point(6,$y)
    $b.BackColor=$bg;$b.ForeColor=$tx;$b.Font=$F85;$b.FlatStyle='Flat'
    $b.FlatAppearance.BorderSize=0;$b.TextAlign='MiddleLeft'
    $b.Cursor=[System.Windows.Forms.Cursors]::Hand;$b.Tag=$key
    $b.Add_Click({
        $k = $this.Tag
        $a = $script:ACT[$k]
        if (!$a) { return }
        $script:st.Text = "$($a.L)..."
        if ($a.C) { ds "$($a.L)"; & $a.C }
        if ($a.F) { ds "$($a.L)"; & $a.F }
        ds "Done"
        $script:st.Text = "Ready"
    })
    $p.Controls.Add($b);$global:GC[$cat]+=$key
}

# ========== TAB 1: Checks ==========
$t1=New-Object System.Windows.Forms.TabPage;$t1.Text='Checks';$t1.BackColor=$bg;$t1.AutoScroll=$true
$y=2;$s=Cat $t1 'SYSTEM' $y;$y=$s.Y
Ch $t1 $y 'c_mobo' 'Motherboard' $s.Cat;$y+=20;Ch $t1 $y 'c_install' 'Install Date' $s.Cat;$y+=20
Ch $t1 $y 'c_winver' 'Windows Version' $s.Cat;$y+=20;Ch $t1 $y 'c_bios' 'BIOS Info' $s.Cat;$y+=24
$s=Cat $t1 'SECURITY' $y;$y=$s.Y
Ch $t1 $y 'c_sboot' 'Secure Boot' $s.Cat;$y+=20;Ch $t1 $y 'c_dma' 'DMA Protection' $s.Cat;$y+=20
Ch $t1 $y 'c_virt' 'CPU Virtualization' $s.Cat;$y+=20;Ch $t1 $y 'c_hvci' 'HVCI' $s.Cat;$y+=20
Ch $t1 $y 'c_tpm' 'TPM' $s.Cat;$y+=24
$s=Cat $t1 'ANTIVIRUS' $y;$y=$s.Y
Ch $t1 $y 'c_val' 'Riot Vanguard' $s.Cat;$y+=20;Ch $t1 $y 'c_fac' 'FACEIT' $s.Cat;$y+=20
Ch $t1 $y 'c_def' 'Windows Defender' $s.Cat;$y+=20;Ch $t1 $y 'c_3rdav' '3rd Party AV' $s.Cat;$y+=24
$s=Cat $t1 'FORTNITE / EAC' $y;$y=$s.Y
Ch $t1 $y 'c_eac' 'EasyAntiCheat' $s.Cat;$y+=20;Ch $t1 $y 'c_fnpath' 'Fortnite Path' $s.Cat;$y+=20
Ch $t1 $y 'c_winupd' 'Recent Win Updates' $s.Cat;$y+=24
$s=Cat $t1 'BROWSER' $y;$y=$s.Y
Ch $t1 $y 'c_chrome' 'Chrome Policies' $s.Cat;$y+=20;Ch $t1 $y 'c_chromeinst' 'Chrome Installed' $s.Cat;$y+=20
Ch $t1 $y 'c_site' 'CL Site Permissions' $s.Cat;$y+=24
$s=Cat $t1 'EXTRAS' $y;$y=$s.Y
Ch $t1 $y 'c_fastboot' 'Fast Boot' $s.Cat;$y+=20;Ch $t1 $y 'c_smartscreen' 'SmartScreen' $s.Cat;$y+=20
Ch $t1 $y 'c_exploit' 'Exploit Protection' $s.Cat;$y+=20;Ch $t1 $y 'c_gamebar' 'Gamebar' $s.Cat;$y+=20
Ch $t1 $y 'c_osint' 'OS Integrity' $s.Cat;$y+=20;Ch $t1 $y 'c_vcredist' 'VC Redist' $s.Cat;$y+=20
Ch $t1 $y 'c_sandbox' 'Windows Sandbox' $s.Cat;$y+=20;Ch $t1 $y 'c_devmode' 'Developer Mode' $s.Cat;$y+=20
Ch $t1 $y 'c_24h2' 'Win11 24H2 Warning' $s.Cat;$y+=20;Ch $t1 $y 'c_netadapter' 'Network Adapters' $s.Cat;$y+=24
$tc.TabPages.Add($t1)

# ========== TAB 2: Fixes ==========
$t2=New-Object System.Windows.Forms.TabPage;$t2.Text='Fixes';$t2.BackColor=$bg;$t2.AutoScroll=$true
$y2=2;$s2=Cat $t2 'EAC & FORTNITE' $y2;$y2=$s2.Y
Ch $t2 $y2 'f_eacinst' 'Install EAC' $s2.Cat;$y2+=20;Ch $t2 $y2 'f_err30005' 'Fix Error 30005' $s2.Cat;$y2+=20
Ch $t2 $y2 'f_fnverify' 'Verify Fortnite' $s2.Cat;$y2+=24
$s2=Cat $t2 'SYSTEM REPAIR (slow)' $y2;$y2=$s2.Y
Ch $t2 $y2 'f_sfc' 'SFC /ScanNow' $s2.Cat;$y2+=20;Ch $t2 $y2 'f_dismchk' 'DISM CheckHealth' $s2.Cat;$y2+=20
Ch $t2 $y2 'f_dismrest' 'DISM RestoreHealth' $s2.Cat;$y2+=24
$s2=Cat $t2 'NETWORK & APPS' $y2;$y2=$s2.Y
Ch $t2 $y2 'f_netres' 'Network Reset' $s2.Cat;$y2+=20;Ch $t2 $y2 'f_xbox' 'Xbox & Store Repair' $s2.Cat;$y2+=24
$s2=Cat $t2 'BROWSER & SECURITY' $y2;$y2=$s2.Y
Ch $t2 $y2 'f_chromefix' 'Fix Chrome Policies' $s2.Cat;$y2+=20;Ch $t2 $y2 'f_hvcifix' 'Disable HVCI' $s2.Cat;$y2+=24
$s2=Cat $t2 'OTHER' $y2;$y2=$s2.Y
Ch $t2 $y2 'f_synctime' 'Sync Time' $s2.Cat;$y2+=20;Ch $t2 $y2 'f_delsymbols' 'Delete C:\Symbols' $s2.Cat;$y2+=20
Ch $t2 $y2 'f_winuninst' 'Uninstall KB5087051+KB5089549' $s2.Cat;$y2+=20;Ch $t2 $y2 'f_dns' 'DNS Flush' $s2.Cat;$y2+=20
Ch $t2 $y2 'f_disableupd' 'Disable Windows Updates' $s2.Cat;$y2+=20;Ch $t2 $y2 'f_chkdsk' 'CHKDSK (check disk)' $s2.Cat;$y2+=24
$tc.TabPages.Add($t2)

# ========== TAB 3: Quick ==========
$t3=New-Object System.Windows.Forms.TabPage;$t3.Text='Quick';$t3.BackColor=$bg
$qi=New-Object System.Windows.Forms.Label;$qi.Text='Select items > RUN QUICK FIXES';$qi.Font=$F9;$qi.ForeColor=$dm;$qi.AutoSize=$true;$qi.Location=New-Object System.Drawing.Point(14,10);$t3.Controls.Add($qi)
$qy=40;$qs=@(
    @{k='q_mobo';t='1. Motherboard'},@{k='q_install';t='2. Install Date'},@{k='q_eac';t='3. Fix Error 30005'}
    @{k='q_hvci';t='4. Check & Disable HVCI'},@{k='q_chrome';t='5. Fix Chrome Policies'},@{k='q_sboot';t='6. Secure Boot'}
    @{k='q_xbox';t='7. Fix Xbox & Store'},@{k='q_sfc';t='8. SFC /ScanNow'},@{k='q_winver';t='9. Windows Version'},@{k='q_val';t='10. Valorant/FACEIT'}
)
foreach($qi in $qs){
    $c=New-Object System.Windows.Forms.CheckBox;$c.Text=$qi.t;$c.Location=New-Object System.Drawing.Point(16,$qy)
    $c.Size=New-Object System.Drawing.Size(320,18);$c.ForeColor=$tx;$c.Font=$F85;$c.BackColor=$bg
    $t3.Controls.Add($c);$global:CB[$qi.k]=$c;$qy+=24
}
$qb=B 'RUN QUICK FIXES' 30 ($qy+10) 280 40 $gr 11; $t3.Controls.Add($qb)
$rb=B 'FULL RESET (SFC+DISM+Net+Xbox)' 30 ($qy+58) 280 34 $ac 9; $t3.Controls.Add($rb)
$tc.TabPages.Add($t3)

# ========== LOGGING ==========
function wl($m,$c='White'){
    $ts=Get-Date -Format 'HH:mm:ss';$lg.SelectionStart=$lg.TextLength;$lg.SelectionLength=0
    $cm=@{'White'=$wh;'Green'=[System.Drawing.Color]::FromArgb(255,0,220,100);'Yellow'=[System.Drawing.Color]::FromArgb(255,255,200,40);'Red'=[System.Drawing.Color]::FromArgb(255,255,70,70);'Cyan'=[System.Drawing.Color]::FromArgb(255,0,210,255);'Pink'=$ac}
    $lg.SelectionColor=$dm;$lg.AppendText("[$ts] ");$lg.SelectionColor=$cm[$c]
    $lg.AppendText("$m`n");$lg.ScrollToCaret();[System.Windows.Forms.Application]::DoEvents()
}
function ws($t){wl '';wl '----------------------------------------' 'Pink';wl "  $t" 'Pink';wl '----------------------------------------' 'Pink'}
function ok($m){wl "  [+] $m" 'Green'}
function wn($m){wl "  [!] $m" 'Yellow'}
function er($m){wl "  [X] $m" 'Red'}
function inf($m){wl "  [i] $m" 'Cyan'}

# ========== ASYNC ==========
function bgr($sb,$desc){
    inf "Running: $desc...";$st.Text="Running: $desc..."
    $jb=Start-Job -ScriptBlock $sb -ErrorAction SilentlyContinue;$t=0
    while($jb.State -eq 'Running'){[System.Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 300;$t++;if($t % 10 -eq 0){inf "  ... still running ($([math]::Round($t*0.3))s)"}}
    $o=Receive-Job $jb 2>&1;Remove-Job $jb -Force -ErrorAction SilentlyContinue
    if($o){foreach($l in $o){$ls="$l".Trim();if($ls -and $ls -notmatch 'Exception|HELPMSG|Hilfe'){inf "  $ls"}}}
    ok "$desc - Done"
}

# ========== CHECKS ==========
function ChkMobo{ws 'MOTHERBOARD';try{$m=Get-CimInstance -ClassName Win32_Baseboard -ErrorAction Stop;inf "Mfr: $($m.Manufacturer)";inf "Prod: $($m.Product)";inf "Serial: $($m.SerialNumber)"}catch{er "Failed"}}
function ChkInstallDate{ws 'INSTALL DATE';try{$os=Get-CimInstance -ClassName Win32_OperatingSystem;$d=$os.InstallDate;ok "$d";$lc=((Get-Culture).Name -split '-')[0].ToLower();$lm=@{'en'='Install Date';'de'='Installationsdatum';'fr'='installation';'es'='instalaci';'it'='installazione';'pt'='instala';'nl'='installatiedatum';'pl'='instalacji';'tr'='Yukleme';'cs'='instalace';'da'='installationsdato';'fi'='asennus';'hu'='telep';'no'='installasjonsdato';'sv'='installationsdatum';'ro'='instal';'sk'='instal'};$st='Install Date';if($lm[$lc]){$st=$lm[$lc]};$si=systeminfo 2>$null;if($si){$l=$si|?{$_ -match $st};if($l){inf "$($l.Trim())"}}}catch{er "Failed"}}
function ChkWinVer{ws 'WINDOWS VERSION';try{$i=Get-CimInstance -ClassName Win32_OperatingSystem;inf "$($i.Caption)";inf "Build: $($i.BuildNumber)";$b=$i.BuildNumber;if($b -ge 26100){ok "Win11 24H2"}elseif($b -ge 22621){ok "Win11 22H2+"}elseif($b -ge 19045){ok "Win10 22H2+"}else{wn "Older"}}catch{er "Failed"}}
function ChkBIOS{ws 'BIOS';try{$b=Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop;inf "Mfr: $($b.Manufacturer)";inf "Ver: $($b.SMBIOSBIOSVersion)";inf "Date: $($b.ReleaseDate)"}catch{er "Failed"}}
function ChkSecureBoot{ws 'SECURE BOOT';$on=$false;$sr='HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State';if(Test-Path $sr){$st=Get-ItemProperty -Path $sr -ErrorAction SilentlyContinue;if($st.UEFISecureBootEnabled -eq 1){$on=$true}};if($on){wn 'ON (should be OFF)'}else{ok 'OFF'}}
function ChkDMA{ws 'DMA PROTECTION';$dr='HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity';if(Test-Path $dr){$ds=Get-ItemProperty -Path $dr -ErrorAction SilentlyContinue;if($ds.DmaSecurity -eq 1){wn 'ON (should be OFF)'}else{ok 'OFF'}}else{ok 'OFF'}}
function ChkVirt{ws 'CPU VIRTUALIZATION';try{$vm=Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue;if($vm -and $vm.HypervisorPresent){wn 'Hypervisor present';inf 'Disable SVM/VMX in BIOS'}else{ok 'Not detected'}}catch{}}
function ChkHVCI{ws 'HVCI';$p='HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity';if(Test-Path $p){$h=Get-ItemProperty -Path $p -ErrorAction SilentlyContinue;if($h.Enabled -eq 1){wn 'ENABLED'}else{ok 'DISABLED'}}else{ok 'DISABLED'}}
function ChkTPM{ws 'TPM';try{$tw=Get-Tpm -ErrorAction SilentlyContinue;if($tw){inf "Present: $($tw.TpmPresent)";inf "Ready: $($tw.TpmReady)"}else{ok 'Not present'}}catch{ok 'N/A'}}
function ChkValorant{ws 'RIOT VANGUARD';$f=$false;if(Test-Path 'C:\Program Files\Riot Vanguard'){wn 'FOUND - BSOD risk!';$f=$true};$sv=Get-Service -Name 'vgc' -ErrorAction SilentlyContinue;if($sv){wn "vgc: $($sv.Status)";$f=$true};if(-not $f){ok 'Not found'}}
function ChkFaceit{ws 'FACEIT';if(Test-Path 'C:\Program Files\FACEIT AC'){wn 'FOUND - system risk!'}else{ok 'Not found'}}
function ChkDefender{ws 'WINDOWS DEFENDER';try{$d=Get-MpComputerStatus -ErrorAction SilentlyContinue;if($d){inf "RealTime: $($d.RealTimeProtectionEnabled)";inf "AV: $($d.AntivirusEnabled)"}}catch{}}
function Chk3rdPartyAV{ws '3RD PARTY AV';try{$av=Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction SilentlyContinue;if($av){$f=$false;foreach($a in $av){if($a.displayName -notmatch 'Defender|Microsoft'){wn "FOUND: $($a.displayName) - DISABLE!";$f=$true}};if(-not $f){ok 'None'}}else{ok 'None'}}catch{ok 'N/A'}}
function ChkEAC{ws 'EASYANTICHEAT';$fa=$false;foreach($p in @('C:\Program Files\Epic Games\Fortnite\FortniteGame\Binaries\Win64\EasyAntiCheat','C:\Program Files (x86)\EasyAntiCheat_EOS')){if(Test-Path $p){ok "Found: $p";$fa=$true}};if(-not $fa){wn 'Not found'}}
function ChkFortnitePath{ws 'FORTNITE PATH';foreach($p in @('C:\Program Files\Epic Games\Fortnite','D:\Epic Games\Fortnite','E:\Epic Games\Fortnite')){if(Test-Path $p){ok "Found: $p";return}};wn 'Not found'}
function ChkWinUpdates{ws 'RECENT UPDATES';try{$s=New-Object -ComObject Microsoft.Update.Session -ErrorAction SilentlyContinue;if($s){$s.CreateUpdateSearcher().QueryHistory(0,12)|Sort-Object Date -Descending|Select-Object -First 6|%{inf "$($_.Title)"}}}catch{};try{Get-CimInstance -ClassName Win32_QuickFixEngineering -ErrorAction SilentlyContinue|Sort-Object InstalledOn -Descending|Select-Object -First 6|%{inf "$($_.HotFixID) - $($_.InstalledOn)"}}catch{}}
function ChkChromePolicies{ws 'CHROME POLICIES';$hp=$false;$own=@('InsecurePrivateNetworkRequestsAllowed','InsecurePrivateNetworkRequestsAllowedForUrls');foreach($p in @('HKLM:\SOFTWARE\Policies\Google\Chrome','HKCU:\SOFTWARE\Policies\Google\Chrome')){if(Test-Path $p){$pr=Get-ItemProperty -Path $p -ErrorAction SilentlyContinue;$bad=$pr.PSObject.Properties|?{$_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider','default')+$own};if($bad){wn 'Unwanted policies found';foreach($b in $bad){inf "  $($b.Name) = $($b.Value)"};$hp=$true}}};if(-not $hp){ok 'No unwanted policies'}else{inf 'Auto-fixing...';FixChromePolicies}}
function ChkChromeInstalled{ws 'GOOGLE CHROME';if((Test-Path 'C:\Program Files\Google\Chrome\Application\chrome.exe') -or (Test-Path "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe")){ok 'Installed'}else{wn 'Not found'}}
function ChkCLSite{ws 'CL SITE PERMISSIONS';$url='https://dash.cheatloverz.store';$pol='HKLM:\SOFTWARE\Policies\Google\Chrome';try{if(-not(Test-Path $pol)){New-Item -Path $pol -Force -ErrorAction Stop|Out-Null};New-ItemProperty -Path $pol -Name 'InsecurePrivateNetworkRequestsAllowed' -Value 1 -PropertyType DWord -Force -ErrorAction Stop|Out-Null;New-ItemProperty -Path $pol -Name 'InsecurePrivateNetworkRequestsAllowedForUrls' -Value @($url) -PropertyType MultiString -Force -ErrorAction Stop|Out-Null;ok "Local network access granted"}catch{er 'Could not set - admin needed';inf 'Manual: Chrome > Site Settings > Allow all for dash.cheatloverz.store'}}
function ChkFastBoot{ws 'FAST BOOT';$fb='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power';if(Test-Path $fb){$h=Get-ItemProperty -Path $fb -ErrorAction SilentlyContinue;if($h.HiberbootEnabled -eq 1){wn 'ON (OFF needed)'}else{ok 'OFF'}}else{ok 'OFF'}}
function ChkSmartScreen{ws 'SMARTSCREEN';$ss='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer';if(Test-Path $ss){$h=Get-ItemProperty -Path $ss -ErrorAction SilentlyContinue;if($h.SmartScreenEnabled -eq 'On'){wn 'ON (OFF needed)'}else{ok 'OFF'}}else{ok 'OFF'}}
function ChkExploitProt{ws 'EXPLOIT PROTECTION';$ep='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ExploitProtection';if(Test-Path $ep){wn 'May be active'}else{ok 'Not configured'}}
function ChkGamebar{ws 'GAMEBAR';try{$pk=Get-AppxPackage -Name 'Microsoft.XboxGamingOverlay*' -ErrorAction SilentlyContinue;if($pk){ok "Installed"}else{wn 'Not installed'}}catch{wn 'Not installed'}}
function ChkOSIntegrity{ws 'OS INTEGRITY';dism /Online /Cleanup-Image /CheckHealth 2>&1|Out-Null;if($LASTEXITCODE -eq 0){ok 'Healthy'}else{wn "Issues possible (exit: $LASTEXITCODE)"}}
function ChkVCRedist{ws 'VC REDIST';$r=Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue|?{$_.DisplayName -match 'Visual C\+\+ 2'};if($r){ok "Found: $($r[0].DisplayName)"}else{wn 'Not found'}}

# ========== FIXES ==========
function FixEACInstall{ws 'INSTALL EAC';foreach($fp in @('C:\Program Files\Epic Games\Fortnite\FortniteGame\Binaries\Win64\EasyAntiCheat','D:\Epic Games\Fortnite\FortniteGame\Binaries\Win64\EasyAntiCheat','E:\Epic Games\Fortnite\FortniteGame\Binaries\Win64\EasyAntiCheat')){if(Test-Path $fp){$se=Join-Path $fp 'EasyAntiCheat_EOS_Setup.exe';if(Test-Path $se){inf "Running: install prod-fn";try{Start-Process -FilePath $se -ArgumentList 'install prod-fn' -Wait -NoNewWindow 2>$null;ok 'Done'}catch{er "Failed"};return}}};er 'EAC not found'}
function FixErr30005{ws 'FIX ERROR 30005';$del=$false;foreach($p in @('C:\Program Files (x86)\EasyAntiCheat_EOS\EasyAntiCheat_EOS.sys','C:\Program Files\EasyAntiCheat_EOS\EasyAntiCheat_EOS.sys')){if(Test-Path $p){try{Remove-Item -Path $p -Force -ErrorAction Stop;ok "Deleted";$del=$true}catch{er "Failed"}}};if($del){inf 'Restart PC before Epic'}else{wn 'Not found'}}
function FixFortniteVerify{ws 'VERIFY FORTNITE';inf 'Epic Launcher > Library > Fortnite > Manage > Verify'}
function FixSFC{ws 'SFC /SCANNOW';bgr {sfc /scannow 2>&1} 'SFC'}
function FixDISMCheck{ws 'DISM CHECKHEALTH';bgr {dism /Online /Cleanup-Image /CheckHealth 2>&1} 'DISM CheckHealth'}
function FixDISMRestore{ws 'DISM RESTOREHEALTH';bgr {dism /Online /Cleanup-Image /RestoreHealth 2>&1} 'DISM RestoreHealth'}
function FixNetworkReset{ws 'NETWORK RESET';bgr {
netsh winsock reset 2>&1;netsh int ip reset 2>&1;netsh interface ipv4 reset 2>&1;netsh interface ipv6 reset 2>&1;netsh interface tcp reset 2>&1
ipconfig /release 2>&1;ipconfig /renew 2>&1;ipconfig /flushdns 2>&1
net stop wuauserv 2>&1;net stop bits 2>&1;net stop winmgmt /y 2>&1
if(Test-Path 'C:\Windows\SoftwareDistribution'){Get-ChildItem 'C:\Windows\SoftwareDistribution' -Recurse -ErrorAction SilentlyContinue|Remove-Item -Force -Recurse -ErrorAction SilentlyContinue 2>&1}
net start wuauserv 2>&1;net start bits 2>&1;net start winmgmt 2>&1
} 'Network Reset'}
function FixXboxStore{ws 'XBOX & STORE REPAIR';bgr {wsreset.exe 2>&1;$as=@('Microsoft.XboxApp*','Microsoft.XboxGamingOverlay*','Microsoft.GamingApp*','Microsoft.XboxIdentityProvider*','Microsoft.WindowsStore*');foreach($a in $as){Get-AppxPackage -AllUsers -Name $a -ErrorAction SilentlyContinue|%{Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -ErrorAction SilentlyContinue 2>&1}}} 'Xbox & Store Repair'}
function FixChromePolicies{ws 'FIX CHROME POLICIES';$fx=$false;foreach($p in @('HKLM:\SOFTWARE\Policies\Google\Chrome','HKLM:\SOFTWARE\WOW6432Node\Policies\Google\Chrome','HKLM:\SOFTWARE\Policies\Google\Chromium','HKCU:\SOFTWARE\Policies\Google\Chrome')){if(Test-Path $p){$pr=Get-ItemProperty -Path $p -ErrorAction SilentlyContinue;$pr.PSObject.Properties|?{$_.Name -notin @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider','default')}|%{try{Remove-ItemProperty -Path $p -Name $_.Name -Force -ErrorAction Stop;ok "Removed: $($_.Name)";$fx=$true}catch{}}}};if(-not $fx){ok 'Nothing to remove'};inf 'Restart Chrome'}
function FixHVCI{ws 'DISABLE HVCI';try{$p='HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity';if(Test-Path $p){Set-ItemProperty -Path $p -Name 'Enabled' -Value 0 -ErrorAction Stop;ok 'HVCI=0'};$p2='HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard';if(Test-Path $p2){Set-ItemProperty -Path $p2 -Name 'EnableVirtualizationBasedSecurity' -Value 0};wn 'REBOOT REQUIRED'}catch{er "Failed (admin?)"}}
function FixSyncTime{ws 'SYNC TIME';bgr {w32tm /resync 2>&1;net start w32time 2>&1;w32tm /resync 2>&1} 'Sync Time'}
function FixDeleteSymbols{ws 'DELETE C:\SYMBOLS';if(Test-Path 'C:\Symbols'){try{Remove-Item -Path 'C:\Symbols' -Force -Recurse -ErrorAction Stop;ok 'Deleted'}catch{er "Failed"}}else{ok 'Not found'}}
function FixUninstallUpdates{ws 'UNINSTALL KB5087051 + KB5089549';bgr {foreach($kb in @('KB5087051','KB5089549')){$u=Get-CimInstance -ClassName Win32_QuickFixEngineering -Filter "HotFixID='$kb'" -ErrorAction SilentlyContinue;if($u){"Uninstalling $kb...";wusa /uninstall /kb:$($kb.Replace('KB','')) /quiet /norestart 2>&1}else{"$kb not installed"}};'Done - SKIP reboot!'} 'Uninstall KB updates'}
function FixDNSFlush{ws 'DNS FLUSH';try{$r=ipconfig /flushdns 2>&1;ok "Done"}catch{er "Failed"}}
function ChkSandbox{ws 'WINDOWS SANDBOX';$feat=Get-WindowsOptionalFeature -Online -FeatureName 'Containers-DisposableClientVM' -ErrorAction SilentlyContinue;if($feat -and $feat.State -eq 'Enabled'){wn 'ENABLED (should be OFF)'}else{ok 'Disabled/Not installed'}}
function ChkDevMode{ws 'DEVELOPER MODE';$dm='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock';if(Test-Path $dm){$d=Get-ItemProperty -Path $dm -ErrorAction SilentlyContinue;if($d.AllowDevelopmentWithoutDevLicense -eq 1){wn 'ON (Win11: should be OFF)'}else{ok 'OFF'}}else{ok 'OFF'}}
function ChkWin11Unsupported{ws 'WINDOWS 11 24H2 CHECK';try{$i=Get-CimInstance -ClassName Win32_OperatingSystem;if($i.BuildNumber -ge 26100){wn "BUILD $($i.BuildNumber) - 24H2 is UNSUPPORTED!";inf 'Downgrade to 23H2 or install Win10 22H2'}else{ok "Build $($i.BuildNumber) - Supported"}}catch{er "Failed"}}
function ChkNetAdapter{ws 'NETWORK ADAPTER';$bad=Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "NetEnabled=TRUE" -ErrorAction SilentlyContinue|Where-Object{$_.Status -ne 'OK' -and $_.Status -ne $null};if($bad){wn 'Adapter issues found';foreach($b in $bad){inf "  $($b.Name) - Status: $($b.Status)"}}else{ok 'No issues detected'}}
function FixChkDsk{ws 'CHKDSK (check only)';bgr {chkdsk C: 2>&1} 'CHKDSK'}
function FixDisableUpdates{ws 'DISABLE WINDOWS UPDATES';try{Stop-Service wuauserv -Force -ErrorAction SilentlyContinue;Set-Service wuauserv -StartupType Disabled -ErrorAction SilentlyContinue;$sr='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU';if(-not(Test-Path $sr)){New-Item -Path $sr -Force -ErrorAction SilentlyContinue|Out-Null};Set-ItemProperty -Path $sr -Name 'NoAutoUpdate' -Value 1 -ErrorAction SilentlyContinue;Set-ItemProperty -Path $sr -Name 'AUOptions' -Value 1 -ErrorAction SilentlyContinue;ok 'Windows Updates disabled'}catch{er "Failed (admin?)"}}

# ========== MAP ==========
$ACT=@{
    c_mobo       =@{C=${function:ChkMobo};           F=$null;                         L='Mobo'}
    c_install    =@{C=${function:ChkInstallDate};     F=$null;                         L='Install'}
    c_winver     =@{C=${function:ChkWinVer};          F=$null;                         L='WinVer'}
    c_bios       =@{C=${function:ChkBIOS};            F=$null;                         L='BIOS'}
    c_sboot      =@{C=${function:ChkSecureBoot};      F=$null;                         L='SecureBoot'}
    c_dma        =@{C=${function:ChkDMA};             F=$null;                         L='DMA'}
    c_virt       =@{C=${function:ChkVirt};            F=$null;                         L='Virt'}
    c_hvci       =@{C=${function:ChkHVCI};            F=${function:FixHVCI};           L='HVCI'}
    c_tpm        =@{C=${function:ChkTPM};             F=$null;                         L='TPM'}
    c_val        =@{C=${function:ChkValorant};        F=$null;                         L='Valorant'}
    c_fac        =@{C=${function:ChkFaceit};          F=$null;                         L='FACEIT'}
    c_def        =@{C=${function:ChkDefender};        F=$null;                         L='Defender'}
    c_3rdav      =@{C=${function:Chk3rdPartyAV};      F=$null;                         L='3rdAV'}
    c_eac        =@{C=${function:ChkEAC};             F=$null;                         L='EAC'}
    c_fnpath     =@{C=${function:ChkFortnitePath};    F=$null;                         L='FN Path'}
    c_winupd     =@{C=${function:ChkWinUpdates};      F=$null;                         L='WinUpd'}
    c_chrome     =@{C=${function:ChkChromePolicies};  F=${function:FixChromePolicies}; L='Chrome'}
    c_chromeinst =@{C=${function:ChkChromeInstalled}; F=$null;                         L='ChromeInst'}
    c_site       =@{C=${function:ChkCLSite};          F=$null;                         L='CL Site'}
    c_fastboot   =@{C=${function:ChkFastBoot};        F=$null;                         L='FastBoot'}
    c_smartscreen=@{C=${function:ChkSmartScreen};     F=$null;                         L='SmartScrn'}
    c_exploit    =@{C=${function:ChkExploitProt};     F=$null;                         L='Exploit'}
    c_gamebar    =@{C=${function:ChkGamebar};         F=$null;                         L='Gamebar'}
    c_osint      =@{C=${function:ChkOSIntegrity};     F=$null;                         L='OS Int'}
    c_vcredist   =@{C=${function:ChkVCRedist};        F=$null;                         L='VCRedist'}
    c_sandbox    =@{C=${function:ChkSandbox};         F=$null;                         L='Sandbox'}
    c_devmode    =@{C=${function:ChkDevMode};         F=$null;                         L='DevMode'}
    c_24h2       =@{C=${function:ChkWin11Unsupported};F=$null;                         L='24H2Warn'}
    c_netadapter =@{C=${function:ChkNetAdapter};      F=$null;                         L='NetAdapter'}
    f_eacinst    =@{C=$null;                          F=${function:FixEACInstall};     L='EACInst'}
    f_err30005   =@{C=$null;                          F=${function:FixErr30005};       L='Err30005'}
    f_fnverify   =@{C=$null;                          F=${function:FixFortniteVerify}; L='FNVerify'}
    f_sfc        =@{C=$null;                          F=${function:FixSFC};            L='SFC'}
    f_dismchk    =@{C=$null;                          F=${function:FixDISMCheck};      L='DISMChk'}
    f_dismrest   =@{C=$null;                          F=${function:FixDISMRestore};    L='DISMRest'}
    f_netres     =@{C=$null;                          F=${function:FixNetworkReset};   L='NetReset'}
    f_xbox       =@{C=$null;                          F=${function:FixXboxStore};      L='Xbox'}
    f_chromefix  =@{C=$null;                          F=${function:FixChromePolicies}; L='ChromeFix'}
    f_hvcifix    =@{C=${function:ChkHVCI};            F=${function:FixHVCI};           L='HVCI'}
    f_synctime   =@{C=$null;                          F=${function:FixSyncTime};       L='SyncTime'}
    f_delsymbols =@{C=$null;                          F=${function:FixDeleteSymbols};  L='DelSym'}
    f_winuninst  =@{C=$null;                          F=${function:FixUninstallUpdates};L='KBUninst'}
    f_dns        =@{C=$null;                          F=${function:FixDNSFlush};       L='DNS'}
    f_disableupd =@{C=$null;                          F=${function:FixDisableUpdates}; L='DisableUpd'}
    f_chkdsk     =@{C=$null;                          F=${function:FixChkDsk};         L='CHKDSK'}
    q_mobo       =@{C=${function:ChkMobo};            F=$null;                         L='Mobo'}
    q_install    =@{C=${function:ChkInstallDate};     F=$null;                         L='Install'}
    q_eac        =@{C=$null;                          F=${function:FixErr30005};       L='Err30005'}
    q_hvci       =@{C=${function:ChkHVCI};            F=${function:FixHVCI};           L='HVCI'}
    q_chrome     =@{C=$null;                          F=${function:FixChromePolicies}; L='Chrome'}
    q_sboot      =@{C=${function:ChkSecureBoot};      F=$null;                         L='SecureBoot'}
    q_xbox       =@{C=$null;                          F=${function:FixXboxStore};      L='Xbox'}
    q_sfc        =@{C=$null;                          F=${function:FixSFC};            L='SFC'}
    q_winver     =@{C=${function:ChkWinVer};          F=$null;                         L='WinVer'}
    q_val        =@{C=${function:ChkValorant};        F=$null;                         L='Valorant'}
}

# ========== RUN ==========
function RunAll{$ks=@();foreach($k in $ACT.Keys){if($k -like 'c_*'){$ks+=$k}};ws "ALL CHECKS ($($ks.Count))";$pr.Visible=$true;$pr.Maximum=$ks.Count;$pr.Value=0;$rn=0;foreach($k in $ks){$a=$ACT[$k];$st.Text="$($a.L)...";if($a.C){& $a.C};$rn++;$pr.Value=$rn};$pr.Visible=$false;ws "DONE ($rn)";$st.Text="All checks done"}
function RunQuick{$tr=@();if($global:CB['q_mobo'].Checked){$tr+='q_mobo'};if($global:CB['q_install'].Checked){$tr+='q_install'};if($global:CB['q_eac'].Checked){$tr+='q_eac'};if($global:CB['q_hvci'].Checked){$tr+='q_hvci'};if($global:CB['q_chrome'].Checked){$tr+='q_chrome'};if($global:CB['q_sboot'].Checked){$tr+='q_sboot'};if($global:CB['q_xbox'].Checked){$tr+='q_xbox'};if($global:CB['q_sfc'].Checked){$tr+='q_sfc'};if($global:CB['q_winver'].Checked){$tr+='q_winver'};if($global:CB['q_val'].Checked){$tr+='q_val'};if(!$tr.Count){wn 'Nothing checked';return};ws 'QUICK FIXES';$pr.Visible=$true;$pr.Maximum=$tr.Count;$pr.Value=0;$rn=0;foreach($k in $tr){$a=$ACT[$k];if($a.C){$st.Text="$($a.L)...";& $a.C};if($a.F){$st.Text="$($a.L)...";& $a.F};$rn++;$pr.Value=$rn};$pr.Visible=$false;ws 'QUICK DONE';$st.Text='Done'}
function RunFull{$r=[System.Windows.Forms.MessageBox]::Show('SFC+DISM+Net+Xbox (20+ min). Continue?','Confirm','YesNo','Warning');if($r -ne 'Yes'){return};ws 'FULL RESET';$stp=@(${function:FixSFC},${function:FixDISMCheck},${function:FixDISMRestore},${function:FixNetworkReset},${function:FixXboxStore});$pr.Visible=$true;$pr.Maximum=$stp.Count;$pr.Value=0;$rn=0;foreach($s in $stp){$st.Text="Reset $($rn+1)/$($stp.Count)...";& $s;$rn++;$pr.Value=$rn};$pr.Visible=$false;ws 'DONE - Reboot';$st.Text='Done'}

# ========== EVENTS ==========
$bAll.Add_Click({RunAll})
$bClr.Add_Click({$lg.Clear();$st.Text='Cleared'})
$bSav.Add_Click({$sd=New-Object System.Windows.Forms.SaveFileDialog;$sd.Filter='Text Files (*.txt)|*.txt';$sd.FileName="CL-Checker-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt";if($sd.ShowDialog() -eq 'OK'){[System.IO.File]::WriteAllText($sd.FileName,$lg.Text);ok "Saved: $($sd.FileName)";$st.Text='Saved'}})
$qb.Add_Click({RunQuick});$rb.Add_Click({RunFull})

# ========== UPDATER ==========
function CheckUpdate {
    try{
        $wc=New-Object System.Net.WebClient
        $remote=$wc.DownloadString($VERSION_URL).Trim()
        if($remote -and $remote -ne $VERSION){
            $r=[System.Windows.Forms.MessageBox]::Show("New version v$remote available (you have v$VERSION). Update now?","Update Available","YesNo","Information")
            if($r -eq 'Yes'){DoUpdate}
            return $true
        }
    }catch{}
    return $false
}
function DoUpdate {
    try{
        $tmp="$env:TEMP\CL-Checker_update.ps1"
        (New-Object System.Net.WebClient).DownloadFile($UPDATE_URL,$tmp)
        $scriptDir=Split-Path $PSCommandPath -Parent
        $bat=@"
@echo off
timeout /t 2 /nobreak >nul
copy /y "$tmp" "$scriptDir\CL-Checker.ps1"
start "" "$scriptDir\CL-Checker.bat"
"@
        $batPath="$env:TEMP\CL-Checker_update.bat"
        [System.IO.File]::WriteAllText($batPath,$bat)
        Start-Process $batPath -WindowStyle Hidden
        $f.Close()
    }catch{er "Update failed: $_"}
}

# ========== INIT ==========
wl '';wl '  +=============================+' 'Pink';wl '  |     CL CHECKER               |' 'Pink';wl '  |     Support Tool             |' 'Pink';wl '  +=============================+' 'Pink';wl ''
inf 'Admin mode | Check items > CHECK SELECTED / FIX SELECTED / ALL CHECKS';wl ''
$f.Add_Shown({$f.Activate()});[System.Windows.Forms.Application]::Run($f)
