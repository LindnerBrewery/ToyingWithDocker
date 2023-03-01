$tag = 'ltsc2019'
$registry = 'mcr.microsoft.com'
$repo = 'windows'
Push-Location $psscriptroot
docker build -t emrysmacinally/stage5:$tag --build-arg registry=$registry  --build-arg repo=$repo --build-arg tag=$tag .
docker push emrysmacinally/stage5:$tag
Pop-Location