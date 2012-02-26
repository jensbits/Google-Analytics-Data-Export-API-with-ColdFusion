<cfif isDefined("form.profileId")>
	<cflock scope="session" type="exclusive" timeout="5">
		<cfset session.profileId = ListGetAt(form.profileId, 1) />
		<cfset session.site = ListGetAt(form.profileId, 2) />
		<cfset StructDelete(session,"getNewData") />
    </cflock>
</cfif>