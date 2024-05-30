# Define the path to the table file and binary file
$tableFilePath = "C:\path\to\table.txt"
$binaryFilePath = "C:\path\to\binaryfile.bin"

# Read the table file and create a dictionary with the encoding
$encodingTable = @{}
Get-Content $tableFilePath | ForEach-Object {
    $parts = $_ -split "="
    $encodingTable[$parts[0]] = $parts[1]
}

# Read the binary file and extract strings based on the encoding
$binaryContent = [System.IO.File]::ReadAllBytes($binaryFilePath)
$extractedStrings = @()
$currentString = ""
foreach($byte in $binaryContent) {
    $byteString = [System.BitConverter]::ToString(@($byte)).Replace("-", "")

    if($encodingTable.ContainsKey("$byteString")) {
        $currentString += $encodingTable["$byteString"]
    } else {
        if($currentString -ne "") {
            $extractedStrings += $currentString
            $currentString = ""
        }
    }
}

# Output the extracted strings
$extractedStrings