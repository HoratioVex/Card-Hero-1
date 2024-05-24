# Insert headers with Atlas pointers into a raw text dump

# *** Defs ***
$rompath = "..\Card Hero (Japan).gbc"
$endbytes = @(0xFF,0xFF)
$endtoken = "<EN>"

function FindIndices($array, $sequence) {
    $indices = @(0) #always start at index 0
    
    $sequenceLength = $sequence.Length
    $arrayLength = $array.Length
    
    for($i=0; $i -lt $arrayLength - $sequenceLength + 1; $i++) {
        $found = $true
        
        for($j=0; $j -lt $sequenceLength; $j++) {
            if($array[$i + $j] -ne $sequence[$j]) {
                $found = $false
                break
            }
        }
        
        if($found) {
            $indices += $i
        }
    }
    
    return $indices
}
function ConvertBank ($fileoffset) {
	$bank = [Int32]($fileoffset / 0x4000)
	if ($bank -eq 0)
		{$addr = $fileoffset} 
	else 
		{$addr = $fileoffset+0x4000-($bank*0x4000)}
	$s=$bank.ToString("X2")+":"+$addr.ToString("X4")
	return $s
}

# *** Main ***

if ($args.count -ne 3)
	{write-host "Required arguments: StartOffset EndOffset TargetTextfile"
	return}
	
$startoffset = [Int32]("0x"+$args[0])
$endoffset = [Int32]("0x"+$args[1])
$readlength = $endoffset - $startoffset + 1

[byte[]]$rawdata = @(0) * $readlength
$romfile = Get-Item $rompath
$instream = $romfile.OpenRead()
$instream.Seek($startoffset, [System.IO.SeekOrigin]::Begin)
$instream.Read($rawdata, 0, $readlength)
$instream.Dispose()

$indices = FindIndices $rawdata $endbytes

#$textfile = Get-Content -Path $args[2]
$textfile = Get-Content -Path "File.txt"
$newtext = @()
$counter = 0

$thisindex = $startoffset + $indices[$counter] 
$bankformat = ConvertBank $thisindex
$hexoffset = $thisindex.ToString("X")
$newtext += "// $counter -- $bankformat"
$newtext += "#WRITE(Ptr,`$$hexoffset)"
$newtext += ""
$counter++

Foreach ($Line in $textfile)
{    
    $newtext += $Line

    if ($Line.Contains($endtoken)) 
    {
		$thisindex = $startoffset + $indices[$counter] + 2 #string starts after the two endtoken bytes
		$bankformat = ConvertBank $thisindex
		$hexoffset = $thisindex.ToString("X")
		$newtext += ""
        $newtext += "// $counter -- $bankformat"
		$newtext += "#WRITE(Ptr,`$$hexoffset)"
		$counter++
    } 
}

#$newtext | Set-Content -Path $args[2]
$newtext