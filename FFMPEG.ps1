###############################################################################################################################
#                                                                                                                             #
#  Powershell Script to modify video files without re-encoding                                                                #
#                                                                                                                             #
#  DISCLAIMER: THIS CODE IS PROVIDED FREE OF CHARGE. UNDER NO CIRCUMSTANCES SHALL I HAVE ANY LIABILITY TO YOU FOR ANY LOSS    #
#  OR DAMAGE OF ANY KIND INCURRED AS A RESULT OF THE USE OF THIS CODE. YOUR USE OF THIS CODE IS SOLELY AT YOUR OWN RISK.      #
#                                                                                                                             #
#  By Silvalined 2019                                                                                                         #
#                                                                                                                             #
###############################################################################################################################

###############################################################################################################################
### Version History																											###
###############################################################################################################################
# 1.0 : First release.                                                                                                        #
# 1.1 : Major rewrite, added new option (join), moved file selection into function, filtered files it displays for choice.    #
# 1.2 : Fixed file display bugs.                                                                                              #
# 1.3 : Fixed bug where it wouldnt copy all audio streams.                                                                    #
# 1.4 : Added option to change volume level.                                                                                  #
# 1.5 : 22/08/20 : Moved start time to beginning of command as this saves time parsing the input file.                        #
# 1.6 : 23/08/20 : Added 6th option to cut and re-encode in the case that the normal cut method results in frozen frames at   #
# the start.                                                                                                                  #
# 1.7 : 27/04/21 : Now has the option to remove video and leave audio                                                         #
# 1.8 : 19/09/21 : Added option to reverse a video.                                                                           #
# 1.9 : 27/05/22 : Added option to convert WAV to FLAC.                                                                       #
#                  Tidied up script.                                                                                          #
#                  Now asks to open file and then delete                                                                      #
#                                                                                                                             #
# Possible future changes:                                                                                                    #
# Join more then 2 files.                                                                                                     #
# Show progress bar.                                                                                                          #
# Make options more dynamic.                                                                                                  #
# Splice in another audio track                                                                                               #
###############################################################################################################################

###############################################################################################################################
### Script Location Checker                                                                                                 ###
###############################################################################################################################

# Get the full path of this script.
$scriptPath = $MyInvocation.MyCommand.Path
# Remove the "file" part of the path so that only the directory path remains.
$scriptPath = Split-Path $scriptPath
# Change location to where the script is being run.
Set-Location $scriptPath

###############################################################################################################################
### End Of Script Location Checker                                                                                          ###
###############################################################################################################################

###############################################################################################################################
### Functions                                                                                                               ###
###############################################################################################################################

Function Show-Menu {
    param (
        [string]$title = 'FFMPEG'
    )
    Clear-Host
    Write-Host "================ $title ================"
    
    Write-Host "Make your selection"
    Write-Host "1  -  Trim"
    Write-Host "2  -  Remove Audio"
    Write-Host "3  -  Remove Audio & Trim"
    Write-Host "4  -  Remove Video"
    Write-Host "5  -  Join 2 Videos (Must Be Same Codecs)"
    Write-Host "6  -  Change Volume"
    Write-Host "7  -  Cut And Convert To MP4 (THIS RE-ENCODES), if the normal cut method had freezing issues at the start then this may work better with the source file"
    Write-Host "8  -  Reverse A Video (THIS USES MASSIVE AMOUNTS OF RAM!!!)"
    Write-Host "9  -  Convert ALL WAV files to FLAC"
    Write-Host "10 -  Convert A Single WAV file to FLAC"
    Write-Host "Q  -  Submit 'Q' to quit"
}

New-Variable $script:ans1
New-Variable $script:ans2
New-Variable $script:outputFile

Function Show-SelectionMenu ($selection, [INT]$numberOfSelections) {

    "You chose option #$selection"
    if ($numberOfSelections -NE 0) {
        $filesPath = $scriptPath + "\*"
        $arrayFiles = Get-ChildItem -Path $filesPath -Attributes !Directory+!System -Include '*.mkv', '*.flv', '*.mp4', '*.m4a', '*.m4v', '*.f4v', '*.f4a', '*.m4b', '*.m4r', '*.f4b', '*.mov', '*.3gp', '*.3gp2', '*.3g2', '*.3gpp', '*.3gpp2', '*.ogg', '*.oga', '*.ogv', '*.ogx', '*.wmv', '*.wma', '*.asf', '*.VOB'
        $menu = @{ }

        For ($i = 1; $i -le $arrayFiles.count; $i++) {
            Write-Host "$i. $($arrayFiles[$i-1].name),$($arrayFiles[$i-1].status)" 
            $menu.Add($i, ($arrayFiles[$i - 1].name))
        }

        If ($numberOfSelections -EQ 1) {
            [INT]$ans = Read-Host -Prompt "Please select a file:"
            [STRING]$script:ans1 = $menu.Item($ans)
            [STRING]$script:outputFile = "$scriptPath\Edited Files\$ans1"
        }

        If ($numberOfSelections -EQ 2) {
            [INT]$ans = Read-Host "Please select the first file:"
            [STRING]$script:ans1 = $menu.Item($ans)
            [INT]$ans = Read-Host "Please select the second file:"
            [STRING]$script:ans2 = $menu.Item($ans)
            [STRING]$script:outputFile = "$scriptPath\Edited Files\JOINED $ans1 - $ans2"
        }
    }
}

Function HandleFile ($file) {
    $selection = Read-Host "Do you want to open the file? (y/n)"
    if ($selection -eq 'y') {
        Invoke-Item $file
        $selection = Read-Host "Delete? (y/n)"
        if ($selection -eq 'y') {
            try {
                Remove-Item $file
            }
            catch {
                Write-Warning '---'
                Write-Warning "OOPS! I COULDNT DELETE THE FOLLOWING FILE:"
                Write-Warning $file
                Write-Warning "The error message was:"
                Write-Warning $error[0]
                Write-Warning '---'
                Pause
            }
        }
    }
}

###############################################################################################################################
### End Of Functions                                                                                                        ###
###############################################################################################################################

DO {
    Show-Menu 
    $selection = Read-Host "Please make a selection"
    switch ($selection) {

        '1' {
            Show-SelectionMenu "1  -  Trim" 1

            # Prompts for the Start Time
            $startTime = Read-Host -Prompt "Start Time? (HH:MM:SS or HH:MM:SS.SSS)"
            # Prompts for the Stop Time
            $stopTime = Read-Host -Prompt "Stop Time? (HH:MM:SS or HH:MM:SS.SSS) OR just press enter to skip to end of file."

            if (![string]::IsNullOrWhiteSpace($stopTime)) {
                .\bin\ffmpeg.exe -ss $startTime -to $stopTime -i "$ans1" -acodec copy -vcodec copy -map 0 -avoid_negative_ts make_zero $outputFile
            }
            elseif ([string]::IsNullOrWhiteSpace($stopTime)) {
                .\bin\ffmpeg.exe -ss $startTime -i "$ans1" -acodec copy -vcodec copy -map 0 -avoid_negative_ts make_zero $outputFile
            }

            HandleFile $outputFile
        }

        '2' {
            Show-SelectionMenu "2  -  Remove Audio" 1

            .\bin\ffmpeg.exe -loglevel quiet -i "$ans1" -vcodec copy -an $outputFile

            HandleFile $outputFile
        }

        '3' {
            Show-SelectionMenu "3  -  Remove Audio & Trim" 1

            # Prompts for the Start Time
            $startTime = Read-Host -Prompt "Start Time? (HH:MM:SS or HH:MM:SS.SSS)"
            # Prompts for the Stop Time
            $stopTime = Read-Host -Prompt "Stop Time? (HH:MM:SS or HH:MM:SS.SSS) OR just press enter to skip to end of file."

            if (![string]::IsNullOrWhiteSpace($stopTime)) {
                .\bin\ffmpeg.exe -loglevel quiet -ss $startTime -to $stopTime -i "$ans1" -acodec copy -vcodec copy -an $outputFile
            }
            elseif ([string]::IsNullOrWhiteSpace($stopTime)) {
                .\bin\ffmpeg.exe -loglevel quiet -ss $startTime -i "$ans1" -acodec copy -vcodec copy -an $outputFile
            }

            HandleFile $outputFile
        }

        '4' {
            Show-SelectionMenu "4  -  Remove Video" 1

            .\bin\ffmpeg.exe -loglevel quiet -i "$ans1" -acodec copy -vn $outputFile

            HandleFile $outputFile
        }

        '5' {
            Show-SelectionMenu "5  -  Join 2 Videos (Must Be Same Codecs)" 2

            New-Item "$scriptPath\Input.txt"
            Add-Content -Path "$scriptPath\Input.txt" -Value "file '$ans1'"
            Add-Content -Path "$scriptPath\Input.txt" -Value "file '$ans2'"

            .\bin\ffmpeg.exe -loglevel quiet -f concat -safe 0 -i Input.txt -acodec copy -vcodec copy -map 0 $outputFile

            Remove-Item "$scriptPath\Input.txt"

            HandleFile $outputFile
        }

        '6' {
            Show-SelectionMenu "6  -  Change Volume" 1

            [string]$volume = Read-Host "Input dB change (use - to indicate a reduction)"

            $volume = $volume + 'dB'

            .\bin\ffmpeg.exe -loglevel quiet -i "$ans1" -vcodec copy -map 0 -af "volume=$volume" $outputFile

            HandleFile $outputFile
        }
		
        '7' {
            Show-SelectionMenu "7  -  Cut and convert to MP4 (THIS RE-ENCODES)" 1
			
            # Prompts for the Start Time
            $startTime = Read-Host -Prompt "Start Time? (HH:MM:SS or HH:MM:SS.SSS)"
            # Prompts for the Stop Time
            $stopTime = Read-Host -Prompt "Stop Time? (HH:MM:SS or HH:MM:SS.SSS) OR just press enter to skip to end of file."

            if (![string]::IsNullOrWhiteSpace($stopTime)) {
                .\bin\ffmpeg.exe -ss $startTime -i "$ans1" -to $stopTime -acodec copy -an $outputFile
            }
            elseif ([string]::IsNullOrWhiteSpace($stopTime)) {
                .\bin\ffmpeg.exe -ss $startTime -i "$ans1" -acodec copy -an $outputFile
            }

            HandleFile $outputFile
        }

        '8' {
            Show-SelectionMenu "8  -  Reverse a Video (THIS USES MASSIVE AMOUNTS OF RAM!!!)" 1

            .\bin\ffmpeg.exe -i "$ans1" -vf reverse -af areverse $outputFile

            HandleFile $outputFile
        }

        '9' {
            Show-SelectionMenu "9  -  Convert ALL WAV files to FLAC" 0

            $filesPath = $scriptPath + "\*"
            $arrayFiles = Get-ChildItem -Path $filesPath -Attributes !Directory+!System -Include '*.wav'

            foreach ($file in $arrayFiles) {
                .\bin\ffmpeg.exe -i $file ""$scriptPath'\Edited Files\'$($file.BaseName).FLAC""
            }
        }

        '10' {
            Show-SelectionMenu "10  -  Convert A Single WAV file to FLAC" 0

            $scriptPath = 'D:\FFMPEG'
            $filesPath = $scriptPath + "\*"
            $arrayFiles = Get-ChildItem -Path $filesPath -Attributes !Directory+!System -Include '*.wav'
            $menu = @{ }
            
            For ($i = 1; $i -le $arrayFiles.count; $i++) {
                Write-Host "$i. $($arrayFiles[$i-1].name),$($arrayFiles[$i-1].status)" 
                $menu.Add($i, ($arrayFiles[$i - 1].name))
            }

            [INT]$ans = Read-Host -Prompt "Please select a file:"
            [STRING]$ans1 = $menu.Item($ans)

            .\bin\ffmpeg.exe -i $ans1 ""$scriptPath'\Edited Files\'$($ans1.Substring(0,$ans1.Length-4)).FLAC""
        }

    }

}
Until ($selection -eq 'q')
