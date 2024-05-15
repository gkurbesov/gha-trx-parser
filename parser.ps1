param(
    [string]$FileName
)

function Check-TestResults($trxFile, $trxContent)
{
    try
    {
        $TrxResults = New-Object -TypeName System.Xml.XmlDocument
        # Remove the first line with hidden character (BOM) and load as XML
        $trxContent = $trxContent.Substring($trxContent.IndexOf("<TestRun"))
        $TrxResults.LoadXml($trxContent)


        $TestDefinitions = @{ }

        $TrxResults.TestRun.TestDefinitions.UnitTest | ForEach-Object {
            $TestDefinitions.Add($_.Id, [PSCustomObject]@{
                Id = $_.id
                Name = $_.name
                ClassName = $_.TestMethod.className
                Owner = if ($_.Owners.FirstChild)
                {
                    $_.Owners.FirstChild.name
                }
                else
                {
                    $null
                }
            })
        }

        $TestResults = @()

        $TrxResults.TestRun.Results.UnitTestResult | ForEach-Object {
            $TestResults += [PSCustomObject]@{
                testName = $_.testName
                className = $TestDefinitions[$_.testId].ClassName
                duration = $_.duration
                state = $_.outcome
            }
        }

        $payloadjson = ($TestResults | ConvertTo-Json -Depth 4) -replace "\\\\n", "\n"
        Write-Output "Payload is $payloadjson"
    }
    catch
    {
        # skip error
        Write-Error $_
    }
}

if (-not $FileName)
{
    throw "Parameter 'FileName' is required and cannot be empty."
}

# Путь к .trx файл
$trxFile = Get-ChildItem -Filter $FileName -Recurse -Name | Select-Object -First 1

# Проверяем, найден ли файл
if ($trxFile)
{
    Write-Host "Getting test results from $trxFile"
    $testResults = Get-Content $trxFile -Raw
    if ( [string]::IsNullOrEmpty($testResults))
    {
        Write-Error "Test results is empty"
    }
    else
    {
        Write-Host "Checking test results from a $trxFile"
        Check-TestResults $trxFile $testResults
    }
}
else
{
    Write-Host "File '$FileName' not found."
}