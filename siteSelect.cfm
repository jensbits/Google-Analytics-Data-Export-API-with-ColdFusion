<!---ajax post is expecting something back in the response so set to none for no errors--->
<cfset errormsg = "none" />

<cfif isDefined("form.tableId")>
		<cflock scope="session" type="exclusive" timeout="5">
			<cfset session.tableId =  Mid(form.tableId,1,Find("|",form.tableId)-1) />
			<cfset session.site = Mid(form.tableId,Find("|",form.tableId)+1,Len(form.tableId)-Find("|",form.tableId)) />
			
			<cfset StructDelete(session,"getNewData") />
       </cflock>
	</cfif>
<cfoutput>#serializeJSON(errormsg)#</cfoutput>