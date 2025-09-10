# Input bindings are passed in via param block.
param($Timer)


function UnwrapSecureString() {
    param (
        [Parameter(Mandatory = $true)]
        $SecureString
    )

    $incomingType = $SecureString.GetType().Name
    if ($incomingType -eq "String") {
        return $SecureString
    } else {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
            return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }

}

function SendLogToWorkspace ($logObject,$bearerToken) {

    $payloadArray = @()

    Try {
    
    
        # First Examing the log object
        if ($logObject -eq $null) {
            Write-Warning "Got a null Log Object, nothing to do."
            return
        }

        #Write-Warning "Sending Log data ... "
        

    
        if ($logObject.count -lt 2) {    
             $body = "[" + $( $logObject | ConvertTo-Json) + "]"
             $payloadArray += $body    
        } else {

            # Max payload size is 1Mb, so we need to split the logObject if it exceeds this size
            # lets use 80% of 1Mb to be safe
            $maxPayloadSize = 1024 * 1024 * 0.80 # 80% of 1Mb
            #Lets sample a record size
            $sampleRecordSize = ($logObject | Select-Object -First 1 | ConvertTo-Json).Length

            $splitSize = [math]::Floor($maxPayloadSize / $sampleRecordSize)
            if ($splitSize -gt 1000) {
                # Extra safety check to avoid too large payloads
                $splitSize = 1000 # Limit to 1000 records per payload
            }

            $tmpBodyArray = @()
            $logObject | ForEach-Object {
                
                if ($tmpBodyArray.Count -le $splitSize) {
                    $tmpBodyArray += $_
                } else {
                    # Ok, lets split and add to payloadArray, then clear tmpBodyArray
                    $payloadArray += ($tmpBodyArray | ConvertTo-Json -Depth 99)
                    $tmpBodyArray = @()
                }
            }
            # Add the remaining records to the payloadArray
            if ($tmpBodyArray.Count -gt 0) {
                $payloadArray += ($tmpBodyArray | ConvertTo-Json -Depth 99)
            }
 

        }
 
    
        # Prepare the request headers and URI
        $headers = @{"Authorization"="Bearer $(UnwrapSecureString -SecureString $bearerToken)";"Content-Type"="application/json"};

        $uri = "$MONITOR_ENDPOINT_URI/dataCollectionRules/$MONITOR_DCR_IMMUTABLE_ID/streams/$($MONITOR_STREAM_NAME)?api-version=$MONITOR_API_VERSION"
        Write-Verbose "URI: $uri"


        Write-Warning "Sending $($payloadArray.Count) payloads to the workspace..."
        $payloadArray | ForEach-Object {
            $body = $_
            Write-Verbose "Sending payload of size: $($body.Length) bytes"
    
            $uploadResponse = Invoke-WebRequest -Uri $uri -Method "Post" -Body $body -Headers $headers   -UseBasicParsing
    
            Write-Warning "Send Log data: $($uploadResponse.StatusCode) SUCCESS"
        }

    } catch {
    
        Write-Warning "There was an error sending the log data."
        $_
        $uploadResponse

    }
}


function GetSpotPlacementScores([string[]]$SKUs,[string[]]$Regions,$subscription,$RequestRegion) {

    $MAX_API_SKU    = 5
    $INSTANCE_COUNT = 1000

    if ($null -eq $RequestRegion) {
        $RequestRegion=$Regions[0]
    }
    
    # if ($SKUs.Count -gt $MAX_API_SKU) {
    #     Write-Warning "Received $($SKUs.Count) total"
    #     Write-Verbose "The API supports up to $MAX_API_SKU SKUs per request. Splitting the requests."    
    # }

    $ProcessedSkus=0

    while ($ProcessedSkus -lt $SKUs.count) {
        $CurrentSkus = $SKUs[$ProcessedSkus..($ProcessedSkus+$MAX_API_SKU-1)]

        $ProcessedSkus += $CurrentSkus.Count
        $resourceSkus=@()
        $CurrentSkus | ForEach-Object {
            $resourceSkus+= @{sku = $_}
        }
        Write-Warning "Currently checking SKUS: $($CurrentSkus -join ', '), Using Regions: $($regions -join ', '), Request Region: $RequestRegion and Subscription: $subscription"

        try {
            $response = Invoke-AzSpotPlacementScore `
                -Location $RequestRegion `
                -DesiredCount $INSTANCE_COUNT `
                -DesiredLocation $regions `
                -DesiredSize $resourceSkus `
                -SubscriptionId $subscription `
                #-ErrorAction Stop

            $response.placementscore | foreach {
                [PSCustomObject]@{
                    Sku =  $_.Sku
                    Region =  $_.Region
                    QuotaAvailable = $_.IsQuotaAvailable
                    Score =  $_.Score
                    Subscription = $subscription
                }
            }
        } catch {
            Write-Error "Failed to get spot placement scores: $_"
        }
    }
}


if (-not $ENV:MONITOR_ENDPOINT_URI) {
    Write-Error "MONITOR_ENDPOINT_URI environment variable is not set."
    exit 1
}
if (-not $ENV:MONITOR_DCR_IMMUTABLE_ID) {
    Write-Error "MONITOR_DCR_IMMUTABLE_ID environment variable is not set."
    exit 1
}
if (-not $ENV:SPOT_SKUS) {
    Write-Error "SPOT_SKUS environment variable is not set."
    exit 1
}
if (-not $ENV:SPOT_REGIONS) {
    Write-Error "SPOT_REGIONS environment variable is not set."
    exit 1
}


$MONITOR_API_VERSION       = "2023-01-01"
$MONITOR_STREAM_NAME       = "Custom-spot_placement_scores_CL" #name of the stream in the DCR that represents the destination table

$MONITOR_ENDPOINT_URI      = $ENV:MONITOR_ENDPOINT_URI
$MONITOR_DCR_IMMUTABLE_ID  = $ENV:MONITOR_DCR_IMMUTABLE_ID
$SKUs                      = $ENV:SPOT_SKUS -replace ' ' -split ","
$REGIONS                   = $ENV:SPOT_REGIONS -replace ' ' -split ","
$subscription              = $ENV:SUBSCRIPTION_ID

if (-not $subscription) {
    $subscription = (Get-AzContext).Subscription.Id
}


#Write-host "SKUS:"
#$SKUs
#Write-host "REGIONS:"
#$regions

# For manual run, disable the environment variable checks and uncomment the lines below
# $SKUs = @("Standard_D48as_v5","Standard_D48as_v6","Standard_D48as_v4","Standard_D48ads_v5")
# $regions = @("eastus2","centralus","eastus")
# Connect-AzAccount -Identity

# Get the routes from the Route Server
$StartTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")



$PlacementScores=GetSpotPlacementScores -SKUs $SKUs -Regions $regions -subscription $subscription


if ($PlacementScores) {

    Write-Warning "Request Result: Received $($PlacementScores.Count) placement scores."


    $PlacementScores | ForEach-Object {
        $_ | Add-Member -MemberType NoteProperty -Name "TimeGenerated" -Value $StartTime -Force
    }

    try {
        # Get the bearer token for authentication
        $bearerToken = (Get-AzAccessToken -ResourceUrl "https://monitor.azure.com").Token

        # Send the routes to the Log Analytics workspace
        SendLogToWorkspace -logObject $PlacementScores -bearerToken $bearerToken

    } catch {
        Write-Error "Failed to send placement scores to Log Analytics: $_"
    }

} else {
    Write-Error "Request Result: No placement scores received."
}



