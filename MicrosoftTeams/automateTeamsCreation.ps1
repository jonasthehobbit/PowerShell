[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [validateSet("Global", "Hong Kong", "UK")]
    [string]$Region,
    [Parameter(Mandatory)]
    [validateSet("IT", "Marketing", "Finance")]
    [string]$BusinessUnit,
    [Parameter(Mandatory)]
    [string]$Team,
    [Parameter(Mandatory)]
    [validatepattern('^\w+([-+.'']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$')]
    [string]$TeamOwner
)
process {
    try {
        # Define AppId, secret and scope, your tenant name and endpoint URL
        $AppId = ''
        $AppSecret = ''
        $TenantName = ""

        $Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"

        # Add System.Web for urlencode
        Add-Type -AssemblyName System.Web
        # Create body
        $TokenBody = @{
            client_id     = $AppId
            client_secret = $AppSecret
            scope         = 'https://graph.microsoft.com/.default'
            grant_type    = 'client_credentials'
        }
        # Parameters for Invoke-Restmethod for cleaner code
        $TokenPost = @{
            ContentType = 'application/x-www-form-urlencoded'
            Method      = 'POST'
            # Create string by joining bodylist with '&'
            Body        = $TokenBody
            Uri         = $Url
        }
        # Request the token!
        $token = Invoke-RestMethod @TokenPost -ErrorAction Stop
        #Use Auth token to create Team using deploy.json
        $Header = @{
            Authorization = "$($Token.token_type) $($Token.access_token)"
        }

        # Check that the UPN is a user in Azure AD using Graph API call
        $owner = Invoke-RestMethod -Headers $Header -Method get -Uri "https://graph.microsoft.com/v1.0/users/$($TeamOwner)"  -ErrorAction Stop

        # JSON Build - Team settings such as name, description etc
        $teamName = "$($Region)-$($BusinessUnit)-$($((Get-Culture).TextInfo.ToTitleCase($team)).replace(' ',''))"
        $description = "$($teamName) created on $($(get-date).ToString(“MM-dd-yyyy”)) by $($owner.displayname)"
        $visibility = "Private"
        # JSON Build - Creates the channels and channel settigns
        $chAnnouncements = @{
            displayName         = 'Announcements'
            isFavoriteByDefault = $true
            description         = 'Pinned Team Announcements, important information for your team'
        }
        $chFeedback = @{
            displayName         = 'Feedback'
            isFavoriteByDefault = $true
            description         = 'Suggestions on how the Team might be run better, new features you''d like to see'
        }
        $chSocial = @{
            displayName         = 'Social'
            isFavoriteByDefault = $true
            description         = 'The virtual water cooler chat channel, catch up with your colleagues'
        }
        $channels = @(
            $chAnnouncements,
            $chSocial,
            $chFeedback
        )
        # Set the Member settings
        $memberSettings = @{
            allowCreateUpdateChannels         = $True
            allowDeleteChannels               = $True
            allowAddRemoveApps                = $True
            allowCreateUpdateRemoveTabs       = $True
            allowCreateUpdateRemoveConnectors = $True
        }
        # Set Team Fun settings
        $funSettings = @{
            allowGiphy            = $True
            giphyContentRating    = 'Moderate'
            allowStickersAndMemes = $True
            allowCustomMemes      = $True
        }
        # Set Team Message settings
        $messageSettings = @{
            allowUserEditMessages    = $True
            allowUserDeleteMessages  = $True
            allowOwnerDeleteMessages = $True
            allowTeamMentions        = $True
            allowChannelMentions     = $True
        }
        # Set the Team Discovery settings
        $discoverySettings = @{
            showInTeamsSearchAndSuggestions = $true
        }
        # Set the which applications are installed by default to the Team
        $installedApps = @(
            #@{'teamsApp@odata.bind' = 'https://graph.microsoft.com/v1.0/appCatalogs/teamsApps(''com.microsoft.teamspace.tab.vsts'')'},
            #@{'teamsApp@odata.bind' = 'https://graph.microsoft.com/v1.0/appCatalogs/teamsApps(''1542629c-01b3-4a6d-8f76-1938b779e48d'')'}
        )
        # Collect all settings and build JSON payload
        $bodyjson = @{
            'template@odata.bind' = 'https://graph.microsoft.com/beta/teamsTemplates(''standard'')'
            'owners@odata.bind'   = @("https://graph.microsoft.com/v1.0/users/$($owner.id)
            ")
            visibility            = $visibility
            displayName           = $teamName
            description           = $description
            channels              = $channels
            memberSettings        = $memberSettings
            funSettings           = $funSettings
            messageSettings       = $messageSettings
            discoverySettings     = $discoverySettings
            installedApps         = $installedApps
        } 
        $TeamBody = ConvertTo-Json $bodyjson -ErrorAction Stop
        # SPLAT parameters for API call
        $TeamCreatePost = @{
            ContentType = 'application/json'
            Method      = 'POST'
            Body        = $TeamBody
            Uri         = 'https://graph.microsoft.com/beta/teams'
            Header      = $header
        }
        # Deploy to Teams via graph API
        Invoke-RestMethod @TeamCreatePost -ErrorAction Stop
    }
    catch {
        Write-Warning $Error[0]
    }
}