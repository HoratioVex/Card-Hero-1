# Extract string location and convert in to Atlas pointer in raw text dump

# *** Defs ***
$rompath = "..\Card Hero (Japan).gbc"
$linestart = "//"


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

$newtext = @()
$counter = 0

for($i=0; $i -lt 4; $i++) { #copy header
	$newtext += $textfile[$i]
}


for($i=4; $i -lt $textfile.Length; $i++) {
    $Line = $textfile[$i]
    $newtext += $linestart + $Line

    if ($Line.Contains("STRING #")) 
    {
		$spl = $Line.split("`$") # split off string adress
		$hexoffset = $spl[2]
		$thisindex = [Int32]("0x"+$hexoffset)
		$bankformat = ConvertBank $thisindex
		$newtext += ""
		$newtext += "// $counter -- $bankformat"
		$newtext += "#WRITE(Ptr,`$$hexoffset)"
		$newtext += "$hexoffset<LF>"
		$counter++
    } 
}

$len = $newtext.Length
$newtext+= "// ********************************"
$newtext+= "// End Block"
$newtext+= "// ********************************"
$newtext+= ""


#[IO.File]::WriteAllLines($filename, $content)
#$output | out-file -encoding utf8 "cardhero1_carto_6b.txt"
#$newtext | Set-Content -Path $args[2]

$newtext | out-file -encoding utf8 $args[0]
