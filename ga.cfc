<cfcomponent>
 
 	<cffunction name="googleOauth2Login" access="public" hint="GA account authorization">
        <cfargument name="code" type="string" required="yes" default="">
        <cfargument name="client_id" type="string" required="yes" default="">
        <cfargument name="client_secret" type="string" required="yes" default="">
        <cfargument name="redirect_uri" type="string" required="yes" default="">
        <cfargument name="state" type="string"required="yes" default="">
        <cfargument name="gaOauthUrl" type="string" required="no" default="https://accounts.google.com/o/oauth2/token">
    
        <cfset jsonResponse = StructNew() />
		<cfset var loginAuth = "" />
           
        <cfhttp url="#arguments.gaOauthUrl#" method="post">
       		<cfhttpparam name="code" type="formField" value="#arguments.code#">
       		<cfhttpparam name="client_id" type="formField" value="#arguments.client_id#">
       		<cfhttpparam name="client_secret" type="formField" value="#arguments.client_secret#">
       		<cfhttpparam name="redirect_uri" type="formField" value="#arguments.redirect_uri#">
       		<cfhttpparam name="grant_type" type="formField" value="authorization_code">
		</cfhttp>
    
        <cfset jsonResponse = DeserializeJSON(cfhttp.filecontent) />
        <cfif StructKeyExists(jsonResponse, "access_token")>
	        <cfset loginAuth = jsonResponse.access_token />
        <cfelse>
         	<cfset loginAuth = "Authorization Failed " & cfhttp.filecontent />
        </cfif>

        <cflock scope="session" type="exclusive" timeout="5">
			<cfset session.ga_loginAuth = loginAuth />
		</cflock>
    </cffunction>
       
    <cffunction name="googleLogin" access="public" returntype="string" hint="GA account authorization">
        <!---No longer used for security reasons--->
        <cfargument name="email" type="string" required="yes" default="">
        <cfargument name="password" type="string"required="yes" default="">
        <cfargument name="gaLoginUrl" type="string" required="no" default="https://www.google.com/accounts/ClientLogin">
    
        <cfset var loginAuth = "" />
           
        <cfhttp url="#arguments.gaLoginUrl#" method="post">
            <cfhttpparam name="accountType" type="url" value="GOOGLE">
            <cfhttpparam name="Email" type="url" value="#arguments.email#">
            <cfhttpparam name="Passwd" type="url" value="#arguments.password#">
            <cfhttpparam name="service" type="url" value="analytics">
            <cfhttpparam name="source" type="url" value="popcenter-analytics">
        </cfhttp>
    
        <cfif NOT FindNoCase("Auth=",cfhttp.filecontent)>
            <cfset loginAuth = "Authorization Failed" />
        <cfelse>
            <cfset loginAuth = Mid(cfhttp.filecontent, FindNoCase("Auth=",cfhttp.filecontent) + (Len("Auth=")), Len(cfhttp.filecontent)) />
        </cfif>
        
         <cflock scope="session" type="exclusive" timeout="5">
				<cfset session.ga_loginAuth = loginAuth />
		</cflock>

        <cfreturn loginAuth />
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
    
    <cffunction name="parseProfiles" access="public" returntype="array" hint="GA profiles as array of structures">
    	<cfargument name="gaUrl" type="string" required="no" default="https://www.googleapis.com/analytics/v3/management/accounts/~all/webproperties/~all/profiles">
        <cfargument name="authToken" type="string" required="yes">
    
        <cfset var accountsResponse = callApi(arguments.gaUrl,arguments.authToken) />
		<cfset var accountsArray =  ArrayNew(1) />
        <cfset var profilesArray = ArrayNew(1) />
        <cfset var entryStruct = StructNew() />
        
         <!---check to see if they have any GA account profiles--->
        <cfif StructKeyExists(accountsResponse,"items")>
         	<cfset accountsArray = accountsResponse.items />
            <cfloop from="1" to="#ArrayLen(accountsArray)#" index="num">
				<cfset entryStruct.title = accountsArray[num].name />
            	<cfset entryStruct.tableId = accountsArray[num].id/>
                
                <cfset arrayAppend(profilesArray,duplicate(entryStruct)) />
            </cfloop>
        </cfif>
        
        <cfdump var="#profilesArray#">
        <cfabort>
        
        <cfif NOT ArrayLen(profilesArray)><!---they have no GA account profiles--->
        	<cflock scope="session" type="exclusive" timeout="5">
				<cfset session.ga_loginAuth = "Authorization Failed" />
			</cflock>
		</cfif>
        
        <cfreturn profilesArray />      
    </cffunction>

    <cffunction name="parseData" access="public" returntype="array" hint="GA data as array of structures">
        <cfargument name="gaUrl" type="string" required="yes">
        <cfargument name="authToken" type="string" required="yes">
        
        <cfset var returnArray = ArrayNew(1) />
        <cfset dataStruct = StructNew() />
                  
         <cfset dataNodes = callApi(arguments.gaUrl,arguments.authToken) />
         
         <cfif StructKeyExists(dataNodes,"error") AND dataNodes.error.message EQ "Forbidden">
         
         	<cflock scope="session" type="exclusive" timeout="5">
				<cfset session.ga_loginAuth = "Authorization Failed" />
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