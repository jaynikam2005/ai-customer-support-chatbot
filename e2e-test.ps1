$u = 'uiuser' + (Get-Random)
$pwd = 'UiPass1!'
Write-Host "Testing user $u"
$body = @{ username = $u; password = $pwd } | ConvertTo-Json

function Decode-Payload($jwt){
	$parts = $jwt.Split('.')
	if($parts.Length -ne 3){ return '<invalid-structure>' }
	$p = $parts[1].Replace('-','+').Replace('_','/')
	while(($p.Length % 4) -ne 0){ $p += '=' }
	try { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($p)) } catch { '<decode-error>' }
}

try {
	$reg = Invoke-RestMethod -Method Post -Uri 'http://localhost:8080/api/auth/register' -Body $body -ContentType 'application/json'
} catch {
	Write-Host 'Registration HTTP error:' $_.Exception.Message
	exit 1
}

if (-not $reg -or -not $reg.token) { Write-Host 'Registration failed (no token)'; exit 1 }
Write-Host 'Registered OK'
$token = $reg.token
Write-Host ('Token length: ' + $token.Length)
$payload = Decode-Payload $token
Write-Host ('Token payload: ' + $payload)

$headers = @{ Authorization = 'Bearer ' + $token }
$chatBody = @{ message = 'Health check 3+5' } | ConvertTo-Json

Write-Host 'Calling /api/chat...'
try {
	# Use Invoke-WebRequest first to capture status explicitly
	$chatResp = Invoke-WebRequest -Method Post -Uri 'http://localhost:8080/api/chat' -Headers $headers -Body $chatBody -ContentType 'application/json' -ErrorAction Stop
	$status = $chatResp.StatusCode
	$chatJson = $chatResp.Content | ConvertFrom-Json
	Write-Host ("Chat OK status=$status intent=" + $chatJson.intent + ' reply-length=' + $chatJson.reply.Length)
} catch {
	Write-Host 'Chat call failed:' $_.Exception.Message
	if($_.Exception.Response){
		$respObj = $_.Exception.Response
		Write-Host ("Failure StatusCode (reported): " + [int]$respObj.StatusCode)
		Write-Host 'Failure Headers:'
		$respObj.Headers | Get-Member -MemberType *Property | Where-Object { $_.Name -ne 'Item' } | ForEach-Object {
			$hn = $_.Name; $hv = $respObj.Headers[$hn]; if($hv){ Write-Host ("  $hn`:` $hv") }
		}
		$respStream = $respObj.GetResponseStream(); $reader = New-Object IO.StreamReader($respStream); $respBody = $reader.ReadToEnd();
		Write-Host 'Response Body: ' $respBody
	}
	Write-Host 'Retrying via login...'
	# attempt login fallback
	$loginBody = @{ username = $u; password = $pwd } | ConvertTo-Json
	try {
		$login = Invoke-RestMethod -Method Post -Uri 'http://localhost:8080/api/auth/login' -Body $loginBody -ContentType 'application/json'
		if($login.token){
			Write-Host 'Login fallback produced token'
			$token = $login.token
			$payload = Decode-Payload $token
			Write-Host ('Login token payload: ' + $payload)
			$headers.Authorization = 'Bearer ' + $token
			try {
				$chatResp2 = Invoke-WebRequest -Method Post -Uri 'http://localhost:8080/api/chat' -Headers $headers -Body $chatBody -ContentType 'application/json' -ErrorAction Stop
				$status2 = $chatResp2.StatusCode
				$chatJson2 = $chatResp2.Content | ConvertFrom-Json
				Write-Host ("Chat after login status=$status2 intent=" + $chatJson2.intent)
			} catch {
				Write-Host 'Second chat attempt failed:' $_.Exception.Message
				if($_.Exception.Response){
					$respStream2 = $_.Exception.Response.GetResponseStream(); $reader2 = New-Object IO.StreamReader($respStream2); $respBody2 = $reader2.ReadToEnd();
					Write-Host 'Second Response Body: ' $respBody2
				}
			}
		} else { Write-Host 'Login fallback failed (no token)' }
	} catch { Write-Host 'Login fallback error:' $_.Exception.Message }
}

Start-Sleep -Seconds 1
try {
	$hist = Invoke-RestMethod -Method Get -Uri ("http://localhost:8080/api/history/" + $u) -Headers $headers
	Write-Host ("History count: " + $hist.Length)
} catch {
	Write-Host 'History fetch failed:' $_.Exception.Message
}

Write-Host 'E2E test complete.'

Write-Host 'Fetching recent backend access/chat logs (last 30s)...'
try {
	$logLines = docker logs chatbot-java-backend --since=30s 2>$null | Select-String -Pattern '/api/chat'
	if($logLines){
		Write-Host '--- /api/chat related log lines ---'
		$logLines | ForEach-Object { Write-Host $_ }
	} else { Write-Host 'No recent /api/chat log lines found.' }
} catch {
	Write-Host 'Could not fetch docker logs:' $_.Exception.Message
}
