$ErrorActionPreference = 'Stop';
$files = ""
Write-Host Starting build

Write-Host Updating base images
docker pull microsoft/windowsservercore
docker pull microsoft/nanoserver

Write-Host Removing old images
$ErrorActionPreference = 'SilentlyContinue';
docker rmi $(docker images --no-trunc --format '{{.Repository}}:{{.Tag}}' | sls -notmatch -pattern '(REPOSITORY|microsoft\/(windowsservercore|nanoserver))')
$ErrorActionPreference = 'Stop';
Write-Host Prune system
docker system prune -f

if ( $env:APPVEYOR_PULL_REQUEST_NUMBER ) {
  Write-Host Pull request $env:APPVEYOR_PULL_REQUEST_NUMBER
  $files = $(git --no-pager diff --name-only FETCH_HEAD $(git merge-base FETCH_HEAD master))
} else {
  Write-Host Branch $env:APPVEYOR_REPO_BRANCH
  $files = $(git diff --name-only HEAD~1)
}

Write-Host Changed files:

$dirs = @{}

$files | ForEach-Object {
  Write-Host $_
  $dir = $_ -replace "\/[^\/]+$", ""
  $dir = $dir -replace "/", "\"
  dir $dir
  if (Test-Path "$dir\build.bat") {
    Write-Host "Storing $dir for build"
    $dirs.Set_Item($dir, 1)
  } else {
    $dir = $dir -replace "\\[^\\]+$", ""
    if (Test-Path "$dir\build.bat") {
      Write-Host "Storing $dir for build"
      $dirs.Set_Item($dir, 1)
    }
  }
}

$dirs.GetEnumerator() | Sort-Object Name | ForEach-Object {
  $dir = $_.Name
  Write-Host Building in directory $dir
  pushd $dir
  . .\build.bat
  popd
}

docker images
