<!---ajax post is expecting something back in the response so set to none for no errors--->
<cfset errormsg = "none" />

<cfset start_date = CreateDate(Mid(form.startdate,1,4),Mid(form.startdate,6,2),Mid(form.startdate,9,2)) />
<cfset end_date = CreateDate(Mid(form.enddate,1,4),Mid(form.enddate,6,2),Mid(form.enddate,9,2)) />

<cfif DateCompare(start_date,end_date) GT 0>

	<cfset errormsg = "invalid" />

<cfelse>

	 <cflock scope="session" type="exclusive" timeout="5">
        <cfset session.startdate = DateFormat(start_date, "yyyy-mm-dd") />
        <cfset session.enddate = DateFormat(end_date,"yyyy-mm-dd") />
        
        <cfset StructDelete(session,"visitsSnapshotArray") />
        <cfset StructDelete(session,"visitorLoyaltyArray") />
        <cfset StructDelete(session,"visitsChartArray") />
        <cfset StructDelete(session,"countryChartArray") />
        <cfset StructDelete(session,"topPagesArray") />
        <cfset StructDelete(session,"pdfDownloadsArray") />
        <cfset StructDelete(session,"pdfDownloadsTotalsArray") />
    </cflock>

</cfif>
<cfoutput>#serializeJSON(errormsg)#</cfoutput>