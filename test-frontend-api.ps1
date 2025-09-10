# Test frontend API connectivity
Write-Host "Testing frontend-backend connectivity..."

# Test 1: Backend health from host
Write-Host "`n1. Testing backend health from host:"
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method GET
    Write-Host "✅ Backend health OK: $($health.status)"
} catch {
    Write-Host "❌ Backend health failed: $($_.Exception.Message)"
}

# Test 2: CORS preflight
Write-Host "`n2. Testing CORS preflight:"
try {
    $corsTest = Invoke-WebRequest -Uri "http://localhost:8080/api/auth/register" -Method OPTIONS -Headers @{
        "Origin"="http://localhost:3000"
        "Access-Control-Request-Method"="POST"
        "Access-Control-Request-Headers"="Content-Type"
    }
    Write-Host "✅ CORS preflight OK: $($corsTest.StatusCode)"
    Write-Host "   Allow-Origin: $($corsTest.Headers['Access-Control-Allow-Origin'])"
} catch {
    Write-Host "❌ CORS preflight failed: $($_.Exception.Message)"
}

# Test 3: API call with CORS headers
Write-Host "`n3. Testing API call with CORS:"
try {
    $testUser = "testuser$(Get-Random)"
    $apiTest = Invoke-WebRequest -Uri "http://localhost:8080/api/auth/register" -Method POST -ContentType "application/json" -Headers @{
        "Origin"="http://localhost:3000"
    } -Body "{`"username`":`"$testUser`",`"password`":`"TestPass1!`"}"
    Write-Host "✅ API call OK: $($apiTest.StatusCode)"
} catch {
    Write-Host "❌ API call failed: $($_.Exception.Message)"
}

# Test 4: Frontend accessibility
Write-Host "`n4. Testing frontend accessibility:"
try {
    $frontendTest = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET
    Write-Host "✅ Frontend accessible: $($frontendTest.StatusCode)"
} catch {
    Write-Host "❌ Frontend not accessible: $($_.Exception.Message)"
}

Write-Host "`nTest complete. If all tests pass, the issue might be in browser cache or JavaScript errors."
Write-Host "Try: Hard refresh (Ctrl+F5) or open browser dev tools to check console errors."