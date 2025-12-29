<#  X-FSE Hook Bootstrap  #>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-SplashFromFile
{
	param ([Parameter(Mandatory)]
		[string]$ImagePath)
	
	if (-not (Test-Path -LiteralPath $ImagePath)) { throw "Splash image not found: $ImagePath" }
	
	$bytes = [System.IO.File]::ReadAllBytes($ImagePath)
	$ms = New-Object System.IO.MemoryStream( ,$bytes)
	$img = [System.Drawing.Image]::FromStream($ms)
	
	$form = New-Object System.Windows.Forms.Form
	$form.FormBorderStyle = 'None'
	$form.StartPosition = 'CenterScreen'
	$form.ShowInTaskbar = $false
	$form.BackColor = [System.Drawing.Color]::Black
	$form.ClientSize = New-Object System.Drawing.Size($img.Width, $img.Height)
	
	$form.TopMost = $true
	$form.Add_Shown({ $this.TopMost = $true; $this.Activate() })
	
	$pb = New-Object System.Windows.Forms.PictureBox
	$pb.Dock = 'Fill'
	$pb.SizeMode = 'Zoom'
	$pb.Image = $img
	$form.Controls.Add($pb)
	
	$form.Show()
	[System.Windows.Forms.Application]::DoEvents()
	
	[pscustomobject]@{
		Form   = $form
		Image  = $img
		Stream = $ms
		Pump   = { [System.Windows.Forms.Application]::DoEvents() }
		Close  = {
			try { $form.TopMost = $false }
			catch { }
			try { $form.Close() }
			catch { }
			try { $img.Dispose() }
			catch { }
			try { $ms.Dispose() }
			catch { }
			try { $form.Dispose() }
			catch { }
		}
	}
}

function Stop-XboxRelatedApps
{
	$selfPid = $PID
	
	Get-Process -ErrorAction SilentlyContinue |
	Where-Object { $_.Id -ne $selfPid -and $_.ProcessName -match 'xbox' } |
	ForEach-Object { try { Stop-Process -Id $_.Id -Force -ErrorAction Stop }
		catch { } }
	
	Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
	Where-Object { $_.Name -match 'xbox' } |
	ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
		catch { } }
}

function Start-HookTarget
{
	param ([Parameter(Mandatory)]
		[string]$TargetPath)
	
	$target = $TargetPath.Trim().Trim([char]0xFEFF).Trim('"')
	if (-not (Test-Path -LiteralPath $target)) { throw "Target not found: $target" }
	
	$ext = [IO.Path]::GetExtension($target).ToLowerInvariant()
	
	switch ($ext)
	{
		".ps1" { return Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$target`"" -PassThru }
		".bat" { return Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$target`"" -PassThru }
		".cmd" { return Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$target`"" -PassThru }
		default { return Start-Process -FilePath $target -PassThru }
	}
}

function Wait-UntilTargetRunning_AndXboxGone
{
	param (
		[Parameter(Mandatory)]
		[string]$TargetPath,
		[Parameter(Mandatory)]
		$Splash,
		[int]$TimeoutSeconds = 240,
		[int]$InitialGraceSeconds = 12,
		[int]$XboxGoneHoldSeconds = 5,
		[int]$TargetHoldSeconds = 2
	)
	
	$targetClean = $TargetPath.Trim().Trim([char]0xFEFF).Trim('"')
	$targetName = [IO.Path]::GetFileNameWithoutExtension($targetClean)
	
	# If the target is a script, "running" will be powershell/cmd, so we fall back to "process object exists"
	$targetIsExe = ([IO.Path]::GetExtension($targetClean).ToLowerInvariant() -eq ".exe")
	
	$start = Get-Date
	$xboxGoneSince = $null
	$targetSeenSince = $null
	
	while (((Get-Date) - $start).TotalSeconds -lt $TimeoutSeconds)
	{
		
		& $Splash.Pump
		$elapsed = ((Get-Date) - $start).TotalSeconds
		
		# Let Xbox-related stuff appear briefly, then start enforcing closure
		if ($elapsed -ge $InitialGraceSeconds)
		{
			Stop-XboxRelatedApps
		}
		
		# Any "xbox*" processes running?
		$anyXbox = (Get-Process -ErrorAction SilentlyContinue |
			Where-Object { $_.ProcessName -match 'xbox' } |
			Select-Object -First 1) -ne $null
		
		if (-not $anyXbox)
		{
			if (-not $xboxGoneSince) { $xboxGoneSince = Get-Date }
		}
		else
		{
			$xboxGoneSince = $null
		}
		
		$xboxGoneLongEnough = $false
		if ($xboxGoneSince)
		{
			$xboxGoneLongEnough = (((Get-Date) - $xboxGoneSince).TotalSeconds -ge $XboxGoneHoldSeconds)
		}
		
		# Is the TARGET running?
		$targetRunning = $false
		
		if ($targetIsExe)
		{
			$targetRunning = (Get-Process -Name $targetName -ErrorAction SilentlyContinue) -ne $null
		}
		else
		{
			# For ps1/bat/cmd: consider it "running" if the launched process still exists
			# (best effort: we can't map it perfectly without extra tracking)
			$targetRunning = $true
		}
		
		if ($targetRunning)
		{
			if (-not $targetSeenSince) { $targetSeenSince = Get-Date }
		}
		else
		{
			$targetSeenSince = $null
		}
		
		$targetLongEnough = $false
		if ($targetSeenSince)
		{
			$targetLongEnough = (((Get-Date) - $targetSeenSince).TotalSeconds -ge $TargetHoldSeconds)
		}
		
		# Close splash ONLY when TARGET is running AND Xbox is gone (for a few seconds)
		if ($targetLongEnough -and $xboxGoneLongEnough) { return }
		
		Start-Sleep -Milliseconds 300
	}
	
	throw "Timed out waiting for the target app to be running and for all Xbox-named processes to stop."
}

$splash = $null

try
{
	$splashPath = "C:\Program Files (x86)\TetraDev\X-FSE Hook\X-FSE_Hook.png"
	$splash = Show-SplashFromFile -ImagePath $splashPath
	& $splash.Pump
	
	Stop-XboxRelatedApps
	& $splash.Pump
	
	$hookFile = "$env:LOCALAPPDATA\X-FSE Hook\hook.txt"
	if (-not (Test-Path -LiteralPath $hookFile))
	{
		throw "Bootstrap not set properly! Run X-FSE Hook again and select an app."
	}
	
	$target = Get-Content -LiteralPath $hookFile |
	ForEach-Object { $_.Trim() } |
	Where-Object { $_ } |
	Select-Object -First 1
	
	if (-not $target) { throw "hook.txt is empty (it must contain a path)." }
	
	# Launch target
	$null = Start-HookTarget -TargetPath $target
	
	# Keep splash until the TARGET app is running AND all "xbox*" processes are gone
	Wait-UntilTargetRunning_AndXboxGone -TargetPath $target -Splash $splash -TimeoutSeconds 300 -InitialGraceSeconds 12 -XboxGoneHoldSeconds 6 -TargetHoldSeconds 2
}
catch
{
	[System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "X-FSE Hook", "OK", "Error") | Out-Null
}
finally
{
	if ($splash) { & $splash.Close }
}
