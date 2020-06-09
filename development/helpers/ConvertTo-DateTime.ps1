function ConvertTo-DateTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)][int32]$time
    );

    return (Get-Date "1/1/1970").ToUniversalTime().AddSeconds($time);
}