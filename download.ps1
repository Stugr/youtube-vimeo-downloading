$outputDir = $PSScriptRoot # optional - if you want to output somewhere other than script path
$workingDir = $PSScriptRoot # optional - if you don't want to put the exe's on %path% or locate source.txt in the same folder as the script
$whatif = $false # toggle to true to output without actually downloading

# required exes
$exes = @(
    'youtube-dl.exe',
    'AtomicParsley.exe',
    'ffmpeg.exe'
)

# change working dir
Push-Location $workingDir

# wrap execution in try/finally to return to orginal workingDir at end
try {
    # create output dir
    mkdir($outputDir) -ErrorAction Ignore

    # look for each exe
    foreach ($exe in $exes) {
        # if exe not found on %path%
        if (-not (Get-Command $exe -ErrorAction SilentlyContinue) -and -not (Get-Command (Join-Path $workingDir $exe) -ErrorAction SilentlyContinue)) {
            Write-Warning "$exe missing from %path% or $workingDir. Aborting"
            return
        }
    }

    # load text containing download urls from source
    $siteText = Get-Content (Join-Path $workingDir source.txt)

    # loop through text and pull out links
    $urls = [Collections.Generic.List[psobject]]@()
    foreach ($line in $siteText -split '\n') {
        # if looks like url
        if ($url = $line | Select-String -pattern 'http[s]?:\/\/[^\s,]+') {
            # if unique
            if (-not ($urls | ? {$_.url -eq $url.Matches.value})) {
                # add to list
                $urls.Add((New-Object PSObject –Property @{
                    "url" = $url.Matches.value;
                    "status" = "";
                }))
            }
        }
    }

    # loop through urls
    foreach ($url in $urls) {
        # youtube & vimeo
        if ($url.url -like "*youtube*" -or $url.url -like "*vimeo*") {
            if (-not $whatif) {
                &"youtube-dl.exe" $url.url --add-metadata --embed-thumbnail -o "$outputDir\%(title)s [%(id)s].%(ext)s" -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'
            }
            $url.status = "downloaded"
        } else {
            $url.status = "not supported"
        }
    }

    $urls | sort status, url

} finally {
    Pop-Location
}