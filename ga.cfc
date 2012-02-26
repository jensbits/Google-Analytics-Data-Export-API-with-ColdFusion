<cfcomponent>
 
 	<cffunction name="googleOauth2Login" access="public" hint="GA account authorization">
        <cfargument name="code" type="string" required="yes" default="">
        <cfargument name="gaOauthUrl" type="string" required="no" default="https://accounts.google.com/o/oauth2/token">
    
        <cfset jsonResponse = StructNew() />
		<cfset var accessToken = "" />
           
        <cfhttp url="#arguments.gaOauthUrl#" method="post">
       		<cfhttpparam name="code" type="formField" value="#arguments.code#">
       		<cfhttpparam name="client_id" type="formField" value="#request.oauthSettings['client_id']#">
       		<cfhttpparam name="client_secret" type="formField" value="#request.oauthSettings['client_secret']#">
       		<cfhttpparam name="redirect_uri" type="formField" value="#request.oauthSettings['redirect_uri']#">
       		<cfhttpparam name="grant_type" type="formField" value="authorization_code">
		</cfhttp>
    
        <cfset jsonResponse = DeserializeJSON(cfhttp.filecontent) />
        <cfif StructKeyExists(jsonResponse, "access_token")>
	        <cfset accessToken = jsonResponse.access_token />
	        <cfset expires_in = jsonResponse.expires_in />
        <cfelse>
         	<cfset accessToken = "Authorization Failed " & cfhttp.filecontent />
        </cfif>

        <cflock scope="session" type="exclusive" timeout="5">
			<cfset session.ga_accessToken = accessToken />
			<cfset session.ga_accessTokenExpiry = DateAdd("s",expires_in,Now()) />
		</cflock>
		<!---send back to login to show auth error message or profile select options--->
		<!---this also strips code URL param to prevent inadvertent refresh with one-time use code--->
		<cflocation url="login.cfm" addtoken="no"/>
    </cffunction>
    
    <cffunction name="logout" access="public" hint="logout">
    	<cflock scope="session" type="exclusive" timeout="5">
	    	<cfset StructDelete(session,"ga_accessToken") />
	        <cfset StructDelete(session,"profileID") />
	        <cfset StructDelete(session,"getNewData") />
	        
	        <cfset StructDelete(session,"startdate") />
	        <cfset StructDelete(session,"enddate") />
	        
	        <cfset StructDelete(session,"profilesArray") />
	        <cfset StructDelete(session,"visitsSnapshotArray") />
	        <cfset StructDelete(session,"visitorLoyaltyArray") />
	        <cfset StructDelete(session,"visitsChartArray") />
	        <cfset StructDelete(session,"countryChartArray") />
	        <cfset StructDelete(session,"topPagesArray") />
    	</cflock>
    
   		<cfif isDefined("session.ga_accessTokenExpiry") AND DateCompare(session.ga_accessTokenExpiry,Now()) LT 0>
    		<cfset session.ga_accessToken = "Authorization Failed: Access token expired" />
    	</cfif>
    </cffunction>
    
    <cffunction name="callApi" access="public" returntype="any" hint="GA data">
        <cfargument name="gaUrl" type="string" required="yes">
        <cfargument name="authToken" type="string" required="yes">
            
        <cfset var authSubToken = 'Bearer ' & arguments.authToken />
        <cfset var responseOutput = "" />
           
        <cfhttp url="#arguments.gaUrl#" method="get">
            <cfhttpparam name="Authorization" type="header" value="#authSubToken#">
        </cfhttp>
        
        <cfset responseOutput = DeserializeJSON(cfhttp.filecontent) />
         
         <cfreturn responseOutput />
    </cffunction>
    
    <cffunction name="parseProfiles" access="public" hint="GA profiles as array of structures">
    	<cfargument name="gaUrl" type="string" required="no" default="https://www.googleapis.com/analytics/v3/management/accounts/~all/webproperties/~all/profiles">
        <cfargument name="authToken" type="string" required="no" default="#session.ga_accessToken#">
    
        <cfset var profilesResponse = callApi(arguments.gaUrl,arguments.authToken) />
        <cfset var profilesArray = ArrayNew(1) />
		<cfset var itemsArray =  ArrayNew(1) />
        <cfset var itemStruct = StructNew() />
        
         <!---check to see if they have any GA profiles, put any found in struct--->
        <cfif StructKeyExists(profilesResponse,"items")>
         	<cfset itemsArray = profilesResponse.items />
            <cfloop from="1" to="#ArrayLen(itemsArray)#" index="num">
				<cfset itemStruct.title = itemsArray[num].name />
                <cfset itemStruct.profileId = itemsArray[num].id />
                
                <cfset arrayAppend(profilesArray,duplicate(itemStruct)) />
            </cfloop>
        </cfif>
        <!---they have no GA account profiles--->
        <cfif NOT ArrayLen(profilesArray)>
        	<cflock scope="session" type="exclusive" timeout="5">
				<cfset session.ga_accessToken = "Authorization Failed: No Google Analytics profiles associated with account." />
			</cflock>
		</cfif>
        <!---if they only have 1 profile assoc w/ their login, send them to stats page --->
		<cfif isDefined("session.profilesArray") AND ArrayLen(session.profilesArray) EQ 1>
 			<cflock scope="session" type="exclusive" timeout="5">
				<cfset session.profileId = session.profilesArray[1].profileId />
        		<cfset session.site = session.profilesArray[1].title />
			</cflock>
			<cflocation url="index.cfm" addtoken="no"/>
		<cfelse>
			<cflock scope="session" type="exclusive" timeout="5">
				<cfset session.profilesArray = profilesArray />
			</cflock>
		</cfif>     
    </cffunction>

    <cffunction name="parseData" access="public" returntype="array" hint="GA data as array of structures">
        <cfargument name="gaUrl" type="string" required="yes">
        <cfargument name="authToken" type="string" required="no" default="#session.ga_accessToken#">
        
        <cfset var returnArray = ArrayNew(1) />
        <cfset dataStruct = StructNew() />
                  
         <cfset dataNodes = callApi(arguments.gaUrl,arguments.authToken) />
         
         <cfif StructKeyExists(dataNodes,"error") AND dataNodes.error.message EQ "Forbidden">
         
         	<cflock scope="session" type="exclusive" timeout="5">
				<cfset session.ga_accessToken = "Authorization Failed" />
			</cflock>
            <cflocation url="index.cfm" addtoken="no"/>
            
         <cfelse>

         <cfloop from="1" to="#ArrayLen(dataNodes.rows)#" index="r">
         	<cfset dataStruct = StructNew() />
            <cfloop from="1" to="#ArrayLen(dataNodes.columnHeaders)#" index="h">
            	<cfset "dataStruct.#Mid(dataNodes.columnHeaders[h]["name"],4,Len(dataNodes.columnHeaders[h]["name"]))#" = dataNodes.rows[r][h] />
            </cfloop>
				<cfset arrayAppend(returnArray,duplicate(dataStruct)) />
            </cfloop>
            
		</cfif>
        
        <cfreturn returnArray />
    </cffunction>

</cfcomponent>