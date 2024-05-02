
function Set-HaloUser {
  [CmdletBinding()]
  param (
    $tenant_id,
    $user_id,
    $action
  )
  #Get Halo PSA Token based on the config we have.
  $Table = Get-CIPPTable -TableName Extensionsconfig
  $Configuration = ((Get-CIPPAzDataTableEntity @Table).config | ConvertFrom-Json).HaloPSA

  $token = Get-HaloToken -configuration $Configuration
  

  if ($action -eq 'Sync') {
    $object | Add-Member -MemberType NoteProperty -Name 'tickettype_id' -Value $Configuration.TicketType
    $body = ConvertTo-Json -Compress -Depth 10 -InputObject @($Object)

  }
  elseif ($action -eq 'Disable') {
    #use the token to create a new ticket in HaloPSA
    $body = ConvertTo-Json -Compress -Depth 10 -InputObject @($Object)
  }
  elseif ($action -eq 'Delete') {
    # Delete the user
    $body = ConvertTo-Json -Compress -Depth 10 -InputObject @($Object)

  }
  else {
    throw "Action is required. Must be one of 'Sync', 'Disable', or 'Delete'"
  }
  
Write-Host "Running $Action on User $($User.user_id) at HaloPSA"
  Write-Host $body
  try {
    $Ticket = Invoke-RestMethod -Uri "$($Configuration.ResourceURL)/Tickets" -ContentType 'application/json; charset=utf-8' -Method Post -Body $body -Headers @{Authorization = "Bearer $($token.access_token)" }
  } catch {
    $Message = if ($_.ErrorDetails.Message) {
      Get-NormalizedError -Message $_.ErrorDetails.Message
    } else {
      $_.Exception.message
    }
    Write-LogMessage -message "Failed to send ticket to HaloPSA: $Message" -API 'HaloPSATicket' -sev Error
    Write-Host "Failed to send ticket to HaloPSA: $Message" 
  }
