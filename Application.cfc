<cfcomponent output="false">

<!--- Application settings --->
<cfset this.name = "GAwebstats" />
<cfset this.sessionManagement = true />
<cfset this.sessionTimeout = createTimeSpan(0,2,30,0) />
<cfset THIS.SetClientCookies = false />
 
<cffunction
	name="OnApplicationStart"
	access="public"
	returntype="boolean"
	output="false"
	hint="Fires when the application is first created.">
 
	<cfreturn true />
</cffunction>

<cffunction
	name="OnSessionStart"
	access="public"
	returntype="void"
	output="false"
	hint="Fires when the session is first created.">
 
 	<!---set cfid/cftoken as non-persistent cookies so session ends on browser close --->
        <cfif not IsDefined("Cookie.CFID")>
            <cflock scope="session" type="readonly" timeout="5">
                <cfcookie name="CFID" value="#session.CFID#">
                <cfcookie name="CFTOKEN" value="#session.CFTOKEN#">
                 <cfset session.SessionStartTime = Now() />
            </cflock>
        </cfif>

	<cfreturn />
</cffunction>
 
<cffunction
	name="OnRequestStart"
	access="public"
	returntype="boolean"
	output="false"
	hint="Fires at first part of page processing.">
 
	<cfargument
		name="TargetPage"
		type="string"
		required="true"
		/>
 
	<cfreturn true />
</cffunction>
 
<cffunction
	name="OnRequest"
	access="public"
	returntype="void"
	output="true"
	hint="Fires after pre page processing is complete.">
 
	<cfargument
		name="TargetPage"
		type="string"
		required="true"
		/>
 
	<cfinclude template="#ARGUMENTS.TargetPage#" />
 
	<cfreturn />
</cffunction>
  
<cffunction
	name="OnRequestEnd"
	access="public"
	returntype="void"
	output="true"
	hint="Fires after the page processing is complete.">

	<cfreturn />
</cffunction>
 
 
<cffunction
	name="OnSessionEnd"
	access="public"
	returntype="void"
	output="false"
	hint="Fires when the session is terminated.">
 
	<cfargument
		name="SessionScope"
		type="struct"
		required="true"
		/>
 
	<cfargument
		name="ApplicationScope"
		type="struct"
		required="false"
		default="#StructNew()#"
		/>

	<cfreturn />
</cffunction>
 
<cffunction
	name="OnApplicationEnd"
	access="public"
	returntype="void"
	output="false"
	hint="Fires when the application is terminated.">
 
	<cfargument
		name="ApplicationScope"
		type="struct"
		required="false"
		default="#StructNew()#"
		/>
 
	<cfreturn />
</cffunction>
 
 
 
</cfcomponent>