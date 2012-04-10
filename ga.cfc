<<<<<<< HEAD
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
    
    <cffunction name="init" access="public" hint="initialize vars">
   		<!---dates for one full year of stats (default)--->
		<cfif (NOT isDefined("session.startdate")) AND (NOT isDefined("session.enddate"))>
		    <cflock scope="session" type="exclusive" timeout="5">
		        <cfset session.startdate = DateFormat(DateAdd("d",-366,Now()), "yyyy-mm-dd") />
		        <cfset session.enddate = DateFormat(DateAdd("d", -1, Now()),"yyyy-mm-dd") />
		    </cflock>
		</cfif>
		<!---feed URLs - set dimensions and metrics for data returned here--->
		<cfset dataExportURL = "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:" & session.profileID & "&" />
		<cfset startEndDates = "&start-date=" & session.startdate & "&end-date=" & session.enddate />
					
		<cfset visitsSnapshotUrl = dataExportURL & "metrics=ga:newVisits,ga:pageviews,ga:visits,ga:visitors,ga:timeOnSite" & startEndDates />
		<cfset visitorLoyaltyUrl = dataExportURL & "dimensions=ga:visitorType&metrics=ga:visits,ga:organicSearches" & startEndDates />
		<cfset visitsChartUrl = dataExportURL & "dimensions=ga:month,ga:year&metrics=ga:visits&sort=ga:year,ga:month" & startEndDates />
		<cfset countryChartUrl = dataExportURL & "dimensions=ga:country&metrics=ga:visits&sort=-ga:visits" & startEndDates & "&max-results=5" />          
		<cfset topPagesUrl = dataExportURL & "dimensions=ga:pageTitle&metrics=ga:pageviews&filters=ga:pageTitle!~Page%20Not%20Found&sort=-ga:pageviews" & startEndDates & "&max-results=25" />
                  	
		<!---check for session.getNewData to avoid calling/processing GA on page refresh.--->	
		<cfif NOT isDefined("session.getNewData")>	
		 	<!---calls GA API and gets data array returned--->
		 	<cfset visitsSnapshotArray = parseData(visitsSnapshotUrl) />
			<cfset visitorLoyaltyArray = parseData(visitorLoyaltyUrl) />
			<cfset visitsChartArray = parseData(visitsChartUrl) />
			<cfset countryChartArray = parseData(countryChartUrl) />
			<cfset topPagesArray = parseData(topPagesUrl) />
		        
			<!---set session vars with data to prevent running calls to GA on page refresh--->
		    <cflock scope="session" type="exclusive" timeout="5">
		        <cfset session.getNewData = "no" />
		        <cfset session.visitsSnapshotArray = visitsSnapshotArray />
		        <cfset session.visitorLoyaltyArray = visitorLoyaltyArray />
				<cfset session.visitsChartArray = visitsChartArray />
		        <cfset session.countryChartArray = countryChartArray />
		        <cfset session.topPagesArray = topPagesArray />
			</cflock>                        
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

=======
<cfcomponent>
 
 	<cffunction name="googleOauth2Login" access="public" hint="GA account authorization">
        <cfargument name="code" type="string" required="yes" default="">
        <cfargument name="gaOauthUrl" type="string" required="no" default="https://accounts.google.com/o/oauth2/token">
        <!---cfscript providers cleaner local var set--->
        <cfscript>
			var jsonResponse = StructNew();
			var accessToken = "";
			var expires_in = "";
		</cfscript>
           
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
    
    <cffunction name="init" access="public" hint="initialize vars">
   		<cfscript>
			var dataExportURL = "";
			var startEndDates = "";
			var visitsSnapshotUrl = "";
			var visitorLoyaltyUrl =  "";
			var visitsChartUrl =  "";
			var countryChartUrl = "";
			var topPagesUrl = "";
		</cfscript>
        
		<!---dates for one full year of stats (default)--->
		<cfif (NOT isDefined("session.startdate")) AND (NOT isDefined("session.enddate"))>
		    <cflock scope="session" type="exclusive" timeout="5">
		        <cfset session.startdate = DateFormat(DateAdd("d",-366,Now()), "yyyy-mm-dd") />
		        <cfset session.enddate = DateFormat(DateAdd("d", -1, Now()),"yyyy-mm-dd") />
		    </cflock>
		</cfif>
		<!---feed URLs - set dimensions and metrics for data returned here--->
		<cfset dataExportURL = "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:" & session.profileID & "&" />
		<cfset startEndDates = "&start-date=" & session.startdate & "&end-date=" & session.enddate />
					
		<cfset visitsSnapshotUrl = dataExportURL & "metrics=ga:newVisits,ga:pageviews,ga:visits,ga:visitors,ga:timeOnSite" & startEndDates />
		<cfset visitorLoyaltyUrl = dataExportURL & "dimensions=ga:visitorType&metrics=ga:visits,ga:organicSearches" & startEndDates />
		<cfset visitsChartUrl = dataExportURL & "dimensions=ga:month,ga:year&metrics=ga:visits&sort=ga:year,ga:month" & startEndDates />
		<cfset countryChartUrl = dataExportURL & "dimensions=ga:country&metrics=ga:visits&sort=-ga:visits" & startEndDates & "&max-results=5" />          
		<cfset topPagesUrl = dataExportURL & "dimensions=ga:pageTitle&metrics=ga:pageviews&filters=ga:pageTitle!~Page%20Not%20Found&sort=-ga:pageviews" & startEndDates & "&max-results=25" />
                  	
		<!---check for session.getNewData to avoid calling/processing GA on page refresh.--->	
		<cfif NOT isDefined("session.getNewData")>	
		 	<!---calls GA API and gets data array returned
				set session vars with data to prevent running calls to GA on page refresh--->
		    <cflock scope="session" type="exclusive" timeout="5">
		        <cfset session.getNewData = "no" />
		        <cfset session.visitsSnapshotArray = parseData(visitsSnapshotUrl) />
		        <cfset session.visitorLoyaltyArray = parseData(visitorLoyaltyUrl) />
				<cfset session.visitsChartArray = parseData(visitsChartUrl) />
		        <cfset session.countryChartArray = parseData(countryChartUrl) />
		        <cfset session.topPagesArray = parseData(topPagesUrl) />
			</cflock>                        
		</cfif> 
    </cffunction>
    
    <cffunction name="callApi" access="public" returntype="any" hint="GA data">
        <cfargument name="gaUrl" type="string" required="yes">
        <cfargument name="authToken" type="string" required="yes">
        <cfscript>    
        	var authSubToken = 'Bearer ' & arguments.authToken;
        	var responseOutput = "";
        </cfscript>
          
        <cfhttp url="#arguments.gaUrl#" method="get">
            <cfhttpparam name="Authorization" type="header" value="#authSubToken#">
        </cfhttp>
        
        <cfset responseOutput = DeserializeJSON(cfhttp.filecontent) />
         
         <cfreturn responseOutput />
    </cffunction>
    
    <cffunction name="parseProfiles" access="public" hint="GA profiles as array of structures">
    	<cfargument name="gaUrl" type="string" required="no" default="https://www.googleapis.com/analytics/v3/management/accounts/~all/webproperties/~all/profiles">
        <cfargument name="authToken" type="string" required="no" default="#session.ga_accessToken#">
    	<cfscript>
        	var profilesResponse = callApi(arguments.gaUrl,arguments.authToken);
        	var profilesArray = ArrayNew(1);
			var itemsArray =  ArrayNew(1);
        	var itemStruct = StructNew();
        	var num = 0;
        </cfscript>
        
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
        <cfscript>
        	var returnArray = ArrayNew(1);
        	var dataStruct = StructNew();
        	var dataNodes = callApi(arguments.gaUrl,arguments.authToken);
        	var r = 0;
			var h = 0;
		</cfscript>
         
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

>>>>>>> 9c705795cc283b02142a3aa7b4eb8a17ae2e47e8
</cfcomponent>