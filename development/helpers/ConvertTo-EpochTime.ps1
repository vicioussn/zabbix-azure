function ConvertTo-EpochTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline)][datetime]$time
    );

    return [int64](($time).ToUniversalTime() - (Get-Date "1/1/1970")).TotalSeconds;
}