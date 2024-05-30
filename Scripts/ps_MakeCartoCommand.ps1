$rompath = "..\Card Hero (Japan).gbc"
$result=@()
$result2=@()
$output=@()

$romfile = Get-Item $rompath
$instream = $romfile.OpenRead()
$seek=$instream.Seek(0x1ac9e3, [System.IO.SeekOrigin]::Begin)

for($i=0; $i -lt 201; $i++) {
	$lo=$instream.ReadByte()
	$hi=$instream.ReadByte()
	$ba=$instream.ReadByte()
	$addr=$lo+($hi*0x100)+(($ba-1)*0x4000)
	$result+=$addr
}

$result=$result | sort -Unique

for($i=0; $i -lt $result.Length; $i++){
	$seek=$instream.Seek($result[$i], [System.IO.SeekOrigin]::Begin)

	for($j=0; $j -lt 13+1; $j++) {
		$lo=$instream.ReadByte()
		$hi=$instream.ReadByte()
		$ba=[math]::floor($result[$i]/0x4000)
		$addr=$lo+($hi*0x100)+(($ba-1)*0x4000)
		$result2+=$addr
	}
}

$result2=$result2 | sort -Unique

$output+="#GAME NAME:		Card Hero 1 (GBC)"

for($i=0; $i -lt $result2.Length; $i++){
	$start=[Int32]$result2[$i]
	$seek=$instream.Seek($start, [System.IO.SeekOrigin]::Begin)
	while ($true) {
		$hi=$instream.ReadByte()
		if ($hi -eq 0) {break}
	}
	$end=[Int32]($instream.Position-1)
	$bank=[math]::floor($start/0x4000)
	$base=[Int32](($bank-1)*0x4000)
	
	$startx=$start.ToString("X")
	$endx=$end.ToString("X")
	$basex=$base.ToString("X")
	
	$output+="#BLOCK NAME:			0082-$i Block 6B-A -- Rules"
	$output+="#TYPE:					NORMAL"
	$output+="#METHOD:				POINTER_RELATIVE"
	$output+="#POINTER ENDIAN:		BIG"
	$output+="#POINTER TABLE START:	`$$startx"
	$output+="#POINTER TABLE STOP:	`$$endx"
	$output+="#POINTER SIZE:			`$02"
	$output+="#POINTER SPACE:			`$00"
	$output+="#ATLAS PTRS: 			No"
	$output+="#BASE POINTER:			`$$basex"
	$output+="#TABLE:					cardhero1-jap-short-PT.tbl"
	$output+="#COMMENTS:				Yes"
	$output+="#END BLOCK"
	$output+=""
}


$instream.Dispose()
#for($i=0; $i -lt $result3.Length; $i++){
#	$result3[$i].ToString("X")
#}
#[IO.File]::WriteAllLines($filename, $content)
$output | out-file -encoding utf8 "cardhero1_carto_6b.txt"