<cfcomponent>   
    <cffunction name="googleLogin" access="public" hint="GA account authorization">
        <cfargument name="email" type="string" required="yes" default="">
        <cfargument name="password" type="string"required="yes" default="">
        <cfargument name="gaLoginUrl" type="string" required="no" default="https://www.google.com/accounts/ClientLogin">
    
        <cfset var loginAuth = "" />
           
        <cfhttp url="#arguments.gaLoginUrl#" method="post">
            <cfhttpparam name="accountType" type="url" value="GOOGLE">
            <cfhttpparam name="Email" type="url" value="#arguments.email#">
            <cfhttpparam name="Passwd" type="url" value="#arguments.password#">
            <cfhttpparam name="service" type="url" value="analytics">
            <cfhttpparam name="source" type="url" value="my-analytics">
        </cfhttp>
    
        <cfif NOT FindNoCase("Auth=",cfhttp.filecontent)>
            <cfset loginAuth = "Authorization Failed" />
        <cfelse>
            <cfset loginAuth = Mid(cfhttp.filecontent, FindNoCase("Auth=",cfhttp.filecontent) + (Len("Auth=")), Len(cfhttp.filecontent)) />
        </cfif>
        
         <cflock scope="session" type="exclusive" timeout="5">
				<cfset session.ga_loginAuth = loginAuth />
		 </cflock>
    </cffunction>
    
    <cffunction name="googleAuthSubLogin" access="public">
        <cfargument name="urlToken" type="string" required="yes">
       
        <cfset var authSubToken = 'AuthSub token="' & arguments.urlToken & '"' />
    	<cfset var output = "" />
    	<cfset var authSubSessionToken = "" />
       
        <cfhttp url="https://www.google.com/accounts/AuthSubSessionToken" method="get">
            <cfhttpparam name="Authorization" type="header" value="#authSubToken#">
        </cfhttp>
    
        <cfset output = cfhttp.filecontent />
            
        <cfset authSubSessionToken = Mid(output, FindNoCase("Token=",output) + (Len("Token=")), Len(output)) />       
        <cflock scope="session" type="exclusive" timeout="5">
				<cfset session.ga_loginAuth = authSubSessionToken />
                <cfset session.authSubLogin = true />
		 </cflock>
	</cffunction>
    
    <cffunction name="callApi" access="public" returntype="array" hint="GA data as array of structures">
        <cfargument name="gaUrl" type="string" required="yes">
        <cfargument name="authToken" type="string" required="no" default="#session.ga_loginAuth#" />
        
        <cfset var authTokenHeader = "" /> 
        <cfset var responseOutput = "" />
           
        <cfif isDefined("session.authSubLogin") AND session.authSubLogin>
        	<cfset authTokenHeader = 'AuthSub token="' & arguments.authToken & '"' />
        <cfelse>
			<cfset authTokenHeader = 'GoogleLogin auth=' & arguments.authToken />
        </cfif>
           
        <cfhttp url="#arguments.gaUrl#" method="get">
            <cfhttpparam name="Authorization" type="header" value="#authTokenHeader#">
        </cfhttp>
        
        <cfset responseOutput = cfhttp.filecontent />      
        <!---remove dxp: prefix from nodes that have it and strip xmlns from feed element --->
         <cfset responseOutput = responseOutput.ReplaceAll("(</?)(\w+:)","$1") />
         <cfset responseOutput = REReplaceNoCase(responseOutput,"<feed[^>]*>","<feed>") />
         <!---entry nodes hold the data--->
         <cfset entryNodes = XmlSearch(responseOutput, '//entry/') />
         
         <cfreturn entryNodes />
    </cffunction>
    
    <cffunction name="parseProfiles" access="public" returntype="array" hint="GA profiles as array of structures">
    	<cfargument name="gaUrl" type="string" required="no" default="https://www.google.com/analytics/feeds/accounts/default" />
    	<cfargument name="authToken" type="string" required="no" default="#session.ga_loginAuth#" />
    
		<cfset var profileArray = ArrayNew(1) />
        <cfset var entryStruct = StructNew() />
        
        <cfset entryNodes = callApi(arguments.gaUrl) />
        
        <cfloop array="#entryNodes#" index="entry">
            <cfset entryStruct = StructNew() />
        
            <cfset entryStruct.title = entry.title.XmlText />
            <cfset entryStruct.tableId = entry.tableId.XmlText />
         
            <cfset arrayAppend(profileArray,duplicate(entryStruct)) />       
        </cfloop>
		
        <cfreturn profileArray />        
    </cffunction>
  
    <cffunction name="parseData" access="public" returntype="array" hint="GA data as array of structures">
        <cfargument name="gaUrl" type="string" required="yes">
        <cfargument name="authToken" type="string" required="no" default="#session.ga_loginAuth#" />
        
        <cfset var returnArray = ArrayNew(1) />
        <cfset var entryStruct = StructNew() />
                  
         <cfset entryNodes = callApi(arguments.gaUrl) />
         
         <!---loop through the entries and put each data point in structure--->
            <cfloop array="#entryNodes#" index="entry">
                <!---rest of the stats data from GA, first check if dimension exists--->
				<cfif StructKeyExists(entry,"dimension")>
                	<cfloop array="#entry.dimension#" index="dimension">
                 	<cfset "entryStruct.#Mid(dimension.XmlAttributes["name"],4,Len(dimension.XmlAttributes["name"]))#" = dimension.XmlAttributes["value"] />
                 	</cfloop>
                 </cfif>
                 
                 <cfloop array="#entry.metric#" index="metric">
                 		<cfset "entryStruct.#Mid(metric.XmlAttributes["name"],4,Len(metric.XmlAttributes["name"]))#" = metric.XmlAttributes["value"] />
                  </cfloop>

                <cfset arrayAppend(returnArray,duplicate(entryStruct)) />       
           </cfloop>
        <cfreturn returnArray />
    </cffunction>       
</cfcomponent>