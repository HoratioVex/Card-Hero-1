# Insert headers with Atlas pointers into a raw text dump, 1 End Byte

# *** Defs ***
$rompath = "..\Card Hero (Japan).gbc"
$endbytes = @(0xFF)
$endtoken = "<LF>"
$linestart = "//"

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
function ConvertBank ($fileoffset) { #convert file offset to GB memory mapping
	$bank = [Int32]([math]::floor($fileoffset / 0x4000))
	if ($bank -eq 0)
		{$addr = $fileoffset} 
	else 
		{$addr = $fileoffset+0x4000-($bank*0x4000)}
	$s=$bank.ToString("X2")+":"+$addr.ToString("X4")
	return $s
}

# *** Main ***

if ($args.count -ne 1)
	{write-host "Required arguments: TargetTextfile"
	return}

$textfile = Get-Content -Path $args[0] -encoding utf8

$startoffset = 0
$endoffset = 0

for($i=0; $i -lt $textfile.Length; $i++) {
		$s = $textfile[$i]
		if ($s.Contains("Range")) {
			$sp = $s.split("$")
			$start = ("0x"+$sp[1])
			$start = $start.split(" ")
			$startoffset = [Int32]$start[0]
			$endoffset = [Int32]("0x"+$sp[2])
			break
		} 
}

if ($startoffset -eq 0 -Or $endoffset -eq 0)
	{write-host "Error: No Offset Range found in textfile"
	return}

$readlength = $endoffset - $startoffset + 1

[byte[]]$rawdata = @(0) * $readlength
$romfile = Get-Item $rompath
$instream = $romfile.OpenRead()
$instream.Seek($startoffset, [System.IO.SeekOrigin]::Begin)
$instream.Read($rawdata, 0, $readlength)
$instream.Dispose()

$indices = FindIndices $rawdata $endbytes

$newtext = @()
$counter = 0

for($i=0; $i -lt 4; $i++) { #copy header
	$newtext += $textfile[$i]
}

$thisindex = $startoffset + $indices[$counter] 
$bankformat = ConvertBank $thisindex
$hexoffset = $thisindex.ToString("X")
$newtext += "// $counter -- $bankformat"
$newtext += "#WRITE(Ptr,`$$hexoffset)"
$newtext += "$hexoffset<EN>"
$counter++

for($i=4; $i -lt $textfile.Length; $i++) {
    $Line = $textfile[$i]
    $newtext += $linestart + $Line

    if ($Line.Contains($endtoken)) 
    {
		$thisindex = $startoffset + $indices[$counter] + $endbytes.Count #string starts after the endtoken bytes
		$bankformat = ConvertBank $thisindex
		$hexoffset = $thisindex.ToString("X")
		$newtext += ""
		$newtext += "// $counter -- $bankformat"
		$newtext += "#WRITE(Ptr,`$$hexoffset)"
		$newtext += "$hexoffset<EN>"
		$counter++
    } 
}

$len = $newtext.Length
$newtext[$len-4] = "// ********************************"
$newtext[$len-3] = "// End Block"
$newtext[$len-2] = "// ********************************"
$newtext[$len-1] = ""


#[IO.File]::WriteAllLines($filename, $content)
#$output | out-file -encoding utf8 "cardhero1_carto_6b.txt"
#$newtext | Set-Content -Path $args[2]
$newtext | out-file -encoding utf8 $args[0]
