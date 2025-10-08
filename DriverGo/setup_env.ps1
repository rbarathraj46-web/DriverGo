\
# Interactive PowerShell script to create .env files for the Driver Hiring App
Write-Host "Driver Hiring App - Interactive Environment Setup (PowerShell)" -ForegroundColor Cyan

# Prompt for values
$firebaseProjectId = Read-Host "Enter your Firebase Project ID (e.g. my-firebase-project)"
$firebaseDatabaseUrl = Read-Host "Enter your Firebase Realtime Database URL (e.g. https://my-firebase-project.firebaseio.com)"
$firebaseStorageBucket = Read-Host "Enter your Firebase Storage Bucket (e.g. my-firebase-project.appspot.com)"
$razorpayKeyId = Read-Host "Enter your Razorpay Key ID (test)"
$razorpayKeySecret = Read-Host "Enter your Razorpay Key Secret (test)"
$databaseUrl = Read-Host "Enter your PostgreSQL DATABASE_URL (e.g. postgres://user:pass@host:5432/dbname)"
$googleMapsKey = Read-Host "Enter your Google Maps API Key"
$jwtSecret = Read-Host "Enter a JWT secret for backend (or press Enter to use default)"

if ([string]::IsNullOrWhiteSpace($jwtSecret)) {
  $jwtSecret = "replace_with_secure_jwt_secret"
}

# Create backend .env content
$backendEnv = @"
PORT=4000
NODE_ENV=development
DATABASE_URL=$databaseUrl
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
FIREBASE_PROJECT_ID=$firebaseProjectId
FIREBASE_DATABASE_URL=$firebaseDatabaseUrl
FIREBASE_STORAGE_BUCKET=$firebaseStorageBucket
RAZORPAY_KEY_ID=$razorpayKeyId
RAZORPAY_KEY_SECRET=$razorpayKeySecret
JWT_SECRET=$jwtSecret
BACKEND_BASE_URL=http://localhost:4000
FRONTEND_BASE_URL=http://localhost:3000
MOBILE_API_BASE_URL=http://10.0.2.2:4000
GOOGLE_MAPS_API_KEY=$googleMapsKey
"@

# Write backend .env
$backendPath = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "backend") -ChildPath ".env"
Write-Host "Writing backend .env to $backendPath"
$backendEnv | Out-File -FilePath $backendPath -Encoding UTF8

# Create admin .env.local content
$adminEnv = @"
REACT_APP_API_URL=http://localhost:4000
REACT_APP_FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
REACT_APP_FIREBASE_AUTH_DOMAIN=$firebaseProjectId.firebaseapp.com
REACT_APP_FIREBASE_PROJECT_ID=$firebaseProjectId
REACT_APP_FIREBASE_STORAGE_BUCKET=$firebaseStorageBucket
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=YOUR_FIREBASE_SENDER_ID
REACT_APP_FIREBASE_APP_ID=YOUR_FIREBASE_APP_ID
REACT_APP_GOOGLE_MAPS_API_KEY=$googleMapsKey
"@
$adminPath = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "admin") -ChildPath ".env.local"
Write-Host "Writing admin .env.local to $adminPath"
$adminEnv | Out-File -FilePath $adminPath -Encoding UTF8

# Create mobile .env content (flutter_dotenv style)
$mobileEnv = @"
API_BASE_URL=http://10.0.2.2:4000
RAZORPAY_KEY_ID=$razorpayKeyId
GOOGLE_MAPS_API_KEY=$googleMapsKey
FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
FIREBASE_PROJECT_ID=$firebaseProjectId
FIREBASE_APP_ID=YOUR_FIREBASE_APP_ID
"@
$mobilePath = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "mobile") -ChildPath ".env"
Write-Host "Writing mobile .env to $mobilePath"
$mobileEnv | Out-File -FilePath $mobilePath -Encoding UTF8

Write-Host "`nSetup completed. Please place your Firebase service account JSON (serviceAccountKey.json) in the backend folder."
Write-Host "Also add google-services.json (Android) or GoogleService-Info.plist (iOS) into the mobile folder as instructed in the mobile/README.md."
Write-Host "Run 'npm install' in backend and admin, and 'flutter pub get' in mobile to continue."
