param (
    [Parameter(Position = 0)]
    [string]$TargetDir = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($TargetDir -eq "") {
    $ProjectRoot = Resolve-Path "."
} else {
    $ProjectRoot = Resolve-Path $TargetDir -ErrorAction SilentlyContinue
    if (-not $ProjectRoot) {
        $ProjectRoot = $TargetDir
    }
}
$ProjectRootPath = if ($ProjectRoot.Path) { $ProjectRoot.Path } else { $ProjectRoot.ToString() }

$IsTTY = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected -and [string]::IsNullOrEmpty($env:PROMPTKIT_NO_INTERACTIVE)

# 1. Warn if non-empty
if ((Test-Path $ProjectRootPath) -and (Get-ChildItem -Path $ProjectRootPath -Force | Measure-Object).Count -gt 0) {
    Write-Host "⚠️  Warning: Target directory is not empty ($ProjectRootPath)" -ForegroundColor Yellow
    if ($IsTTY) {
        $confirm = Read-Host "Continue anyway? [y/N]"
        if ($confirm -notmatch "^[Yy]$") {
            Write-Host "Aborting."
            exit 1
        }
    } else {
        Write-Host "Non-interactive mode, aborting on non-empty directory."
        exit 1
    }
} else {
    if (-not (Test-Path $ProjectRootPath)) {
        New-Item -ItemType Directory -Path $ProjectRootPath -Force | Out-Null
    }
}

# Auth Provider Interactive Menu
if ($IsTTY) {
    Write-Host "`n💡 Auth Provider Selection" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host "  [1] NextAuth (v5) (Recommended)" -ForegroundColor Yellow
    Write-Host "  [2] Lucia (coming soon)" -ForegroundColor DarkGray
    Write-Host "  [3] Clerk (coming soon)" -ForegroundColor DarkGray
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    $authChoice = Read-Host "Choose auth provider [1-3, default 1]"
    if ($authChoice -eq "2" -or $authChoice -eq "3") {
        Write-Host "Coming in a future release. Defaulting to NextAuth." -ForegroundColor Yellow
    }
}

# Copy boilerplate
Write-Host "Scaffolding Next.js App Router + NextAuth + Stripe + Prisma + PostgreSQL boilerplate..."
$TemplateDir = Join-Path $ScriptDir "templates/nextjs-app"
if (-not (Test-Path $TemplateDir)) {
    Write-Host "Error: Template directory not found at $TemplateDir" -ForegroundColor Red
    exit 1
}
Copy-Item -Path "$TemplateDir\*" -Destination $ProjectRootPath -Recurse -Force
if (Test-Path (Join-Path $TemplateDir ".env.example")) {
    Copy-Item -Path (Join-Path $TemplateDir ".env.example") -Destination $ProjectRootPath -Force
}

# npm install prompt
$RunNpm = $false
if ($IsTTY) {
    $npmChoice = Read-Host "Run npm install? [Y/n]"
    if ($npmChoice -match "^[Yy]$" -or [string]::IsNullOrWhiteSpace($npmChoice)) {
        $RunNpm = $true
    }
}
if ($RunNpm) {
    Write-Host "Running npm install..."
    Set-Location $ProjectRootPath
    npm install
}

# prisma generate prompt
$RunPrisma = $false
if ($IsTTY) {
    $prismaChoice = Read-Host "Run npx prisma generate? [Y/n]"
    if ($prismaChoice -match "^[Yy]$" -or [string]::IsNullOrWhiteSpace($prismaChoice)) {
        $RunPrisma = $true
    }
}
if ($RunPrisma) {
    Write-Host "Running npx prisma generate..."
    Set-Location $ProjectRootPath
    npx prisma generate
}

Write-Host "`nSaaS Scaffold complete! ✨" -ForegroundColor Green
