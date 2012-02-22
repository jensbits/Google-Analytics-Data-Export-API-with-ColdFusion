<!---dates for one full year of stats (default)--->
<cfif (NOT isDefined("session.startdate")) AND (NOT isDefined("session.enddate"))>
    <cflock scope="session" type="exclusive" timeout="5">
        <cfset session.startdate = DateFormat(DateAdd("d",-365,CreateDate(Year(Now()),Month(Now()),Day(Now()))), "yyyy-mm-dd") />
        <cfset session.enddate = DateFormat(DateAdd("d", -1, Now()),"yyyy-mm-dd") />
    </cflock>
</cfif>

<cfset daysInRange = DateDiff("d",session.startdate,session.enddate) + 1 />

<cfif isDefined("URL.logout") and URL.logout EQ "true">
    
    <cflock scope="session" type="exclusive" timeout="5">
    	<cfset StructDelete(session,"ga_loginAuth") />
        <cfset StructDelete(session,"ga_profileID") />
        
        <cfset StructDelete(session,"startdate") />
        <cfset StructDelete(session,"enddate") />
        
        <cfset StructDelete(session,"visitsSnapshotArray") />
        <cfset StructDelete(session,"visitorLoyaltyArray") />
        <cfset StructDelete(session,"visitsChartArray") />
        <cfset StructDelete(session,"countryChartArray") />
        <cfset StructDelete(session,"topPagesArray") />
    </cflock>

</cfif>

<cfif NOT isDefined("session.ga_loginAuth") OR session.ga_loginAuth EQ "Authorization Failed">
	<cflocation url="login.cfm" addtoken="no" /> 
</cfif>

<!---feed URLs - set dimensions and metrics for data returned here--->

			<cfset dataExportURL = "https://www.googleapis.com/analytics/v3/data/ga?ids=ga:" & session.ga_profileID & "&" />
            <cfset startEndDates = "&start-date=" & session.startdate & "&end-date=" & session.enddate />
			
        	<cfset visitsSnapshotUrl = dataExportURL & "metrics=ga:newVisits,ga:pageviews,ga:visits,ga:visitors,ga:timeOnSite" & startEndDates />

            <cfset visitorLoyaltyUrl =
dataExportURL & "dimensions=ga%3AvisitorType&metrics=ga%3Avisits,ga:organicSearches" & startEndDates />
              
            <cfset visitsChartUrl = dataExportURL & "dimensions=ga:month&metrics=ga:visits" & startEndDates />
              
           <cfset countryChartUrl = dataExportURL & "dimensions=ga:country&metrics=ga:visits&sort=-ga:visits" & startEndDates & "&max-results=5" />
             
            <cfset topPagesUrl = dataExportURL & "dimensions=ga:pageTitle&metrics=ga:pageviews&filters=ga:pageTitle!~Page%20Not%20Found&sort=-ga:pageviews" & startEndDates & "&max-results=25" />
                  	
        <!---check for session.visitsSnapshotArray to avoid calling/processing GA on page refresh. Info is day old anyway.--->	
        <cfif NOT isDefined("session.visitsSnapshotArray")>	
        
        <!---calls GA API and gets data array returned--->

           <cfinvoke component="ga" method="parseData" returnvariable="visitsSnapshotArray">
                <cfinvokeargument name="gaUrl" value="#visitsSnapshotUrl#" />
                <cfinvokeargument name="authToken" value="#session.ga_loginAuth#" />
            </cfinvoke>

            <cfinvoke component="ga" method="parseData" returnvariable="visitorLoyaltyArray">
                <cfinvokeargument name="gaUrl" value="#visitorLoyaltyUrl#" />
                <cfinvokeargument name="authToken" value="#session.ga_loginAuth#" />
            </cfinvoke>
            
             <cfinvoke component="ga" method="parseData" returnvariable="visitsChartArray">
                <cfinvokeargument name="gaUrl" value="#visitsChartUrl#" />
                <cfinvokeargument name="authToken" value="#session.ga_loginAuth#" />
            </cfinvoke> 
            
            <cfinvoke component="ga" method="parseData" returnvariable="countryChartArray">
                <cfinvokeargument name="gaUrl" value="#countryChartUrl#" />
                <cfinvokeargument name="authToken" value="#session.ga_loginAuth#" />
            </cfinvoke>
            
            <cfinvoke component="ga" method="parseData" returnvariable="topPagesArray">
                <cfinvokeargument name="gaUrl" value="#topPagesUrl#" />
                <cfinvokeargument name="authToken" value="#session.ga_loginAuth#" />
            </cfinvoke>
        
        	<!---set session vars with data to prevent running calls to GA on page refresh--->
            <cflock scope="session" type="exclusive" timeout="5">
                <cfset session.visitsSnapshotArray = visitsSnapshotArray />
                <cfset session.visitorLoyaltyArray = visitorLoyaltyArray />
				<cfset session.visitsChartArray = visitsChartArray />
                <cfset session.countryChartArray = countryChartArray />
                <cfset session.topPagesArray = topPagesArray />
			</cflock>

                            
        </cfif> 
        
<!DOCTYPE html>
<html>
<head>

<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>CPOP Web Stats</title>
<link rel="stylesheet" type="text/css" href="http://ajax.googleapis.com/ajax/libs/jqueryui/1/themes/blitzer/jquery-ui.css" media="screen" />
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>
<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1/jquery-ui.min.js"></script>

<link rel="stylesheet" type="text/css" href="css/reset.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/960.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/text.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/style.css" media="screen" />


<cfoutput>
<cfheader name='expires' value='#Now()#'>
<cfheader name='pragma' value='no-cache'>
<cfheader name='cache-control' value='no-cache, no-store, must-revalidate'>
</cfoutput>
<script type="text/javascript" language="javascript">
$().ready(function() {
		$("#startdate").datepicker({altField: '#start_alternate',altFormat: 'yy-mm-dd',minDate: new Date(2008, 8 - 1, 1),maxDate: -1});
		$("#enddate").datepicker({altField: '#end_alternate',altFormat: 'yy-mm-dd',minDate: new Date(2008, 8 - 1, 2),maxDate: -1});	
	
	$('button#selectDateRange').click(function(){
		$('#dialog').dialog('open');

	});

});

$(function(){
				
	// jQuery UI Dialog						
	$('#dialog').dialog({
		autoOpen: false,
		width: 400,
		modal: true,
		resizable: false,
		buttons: {
			"Close": function() { 
				
				$(this).dialog("close"); 
			}, 
			"Submit": function() { 
			var errors = 0;
			
			if (errors == 0){
				
				dataString = $('form').serialize();
				$.ajax({
				type: "POST",
				url: "dateRange.cfm",
				data: dataString,
				dataType: "json",
				success: function(data) {

				if(data == 'invalid'){ 
					$('#message').html("<div class='errorMessage'>Date range is invalid.</div>"); 
				} else {
					$('#message').html("<div class='successMessage'>Loading new data. Please wait.</div>");
					location.reload();
				}
			 	 
				}
				
				});
				
				return false;
				
			}
				
			}
		}
	});
	
	$('#site_dialog').dialog({
		autoOpen: false,
		width: 400,
		modal: true,
		resizable: false,
		buttons: {
			"Submit": function() {
				dataString = $('form').serialize();
				$.ajax({
					type: "POST",
					url: "siteSelect.cfm",
					data: dataString,
					dataType: "json",
					success: function(data) {
						$('#message_site').html("<div class='successMessage'>Loading new data. Please wait.</div>");
						$('#siteSelectForm, .ui-dialog-buttonpane, .ui-dialog-titlebar-close').hide();
						$('#site_dialog').dialog({ closeOnEscape: false });
						location.reload();
					}
				});
			return false;
			},
			"Close": function() {
				$(this).dialog("close");
			}
		}
	});
});
</script>
</head>
<body>
<cfoutput>
<div id="wrapper">
	
	<div id="header" class="container_16">
		<h1>Web Stats</h1>
        <h2>#DateFormat(session.startdate,"mmmm d, yyyy")# - #DateFormat(session.enddate,"mmmm d, yyyy")#</h2>
	</div>

<div id="content-wrap" class="container_16">

<div id="logout"><a href="index.cfm?logout=true">Logout</a></div>

<button id="selectDateRange">Select New Date Range</button>	 

        	<!---output--->
        
			<div class="grid_16" style="margin-top: 1em;">
            
            <div class="grid_5">
            <table cellpadding="0" cellspacing="0" border="0" class="dataTable">
            <caption><h2>Pageviews</h2></caption>
            
             <tr class="oddrow">
             	<th><h3>Pageviews</h3></th>
                <td class="align-right">#NumberFormat(session.visitsSnapshotArray[1].pageviews,",")#</td>
             </tr>
             <tr>
                <th><h3>Avg Per Day</h3></th>
                <td class="align-right">#NumberFormat(session.visitsSnapshotArray[1].pageviews/daysInRange,",")#</td>
             </tr>
             <tr class="oddrow">
                <th><h3>Avg per Visit</h3></th>
                <td class="align-right">#NumberFormat(session.visitsSnapshotArray[1].pageviews/session.visitsSnapshotArray[1].visits,"0.00")#</td>
             </tr>

            </table>
            </div>
                      
            <div class="grid_5" >
            <table cellpadding="0" cellspacing="0" border="0" class="dataTable">
            <caption><h2>Visits</h2></caption>
            
             <tr class="oddrow">
             	<th><h3>Visits</h3></th>
                <td class="align-right">#NumberFormat(session.visitsSnapshotArray[1].visits,",")#</td>
             </tr>
             <tr>
             	<th><h3>Avg Per Day</h3></th>
                <td class="align-right">#NumberFormat(session.visitsSnapshotArray[1].visits/daysInRange,",")#</td>
             </tr>
             <tr class="oddrow">
                <th><h3>Avg Visit Duration</h3></th>
                <td class="align-right">#TimeFormat(CreateTime((session.visitsSnapshotArray[1].timeOnSite/session.visitsSnapshotArray[1].visits)/3600,(session.visitsSnapshotArray[1].timeOnSite/session.visitsSnapshotArray[1].visits)/60,(session.visitsSnapshotArray[1].timeOnSite/session.visitsSnapshotArray[1].visits) Mod 60), "HH:mm:ss")#</td>
             </tr>

            </table>
            </div>	
            
            <div class="grid_5" >
            <table cellpadding="0" cellspacing="0" border="0" class="dataTable">
            <caption><h2>Visitors</h2></caption>
            
             <tr class="oddrow">
             	<th><h3>Visitors</h3></th>
                <td class="align-right">#NumberFormat(session.visitsSnapshotArray[1].visitors,",")#</td>
             </tr>
             <tr>
                <th><h3>Visits from New Visitors</h3></th>
                <td class="align-right">#NumberFormat(session.visitorLoyaltyArray[1].visits,",")#</td>
             </tr>
             <tr class="oddrow">
                <th><h3>Visits from Returning Visitors</h3></th>
                    <td class="align-right">#NumberFormat(session.visitorLoyaltyArray[2].visits,",")#</td>
             </tr>
              <tr>
                <th><h3>Avg Visits per Visitor</h3></th>
                <td class="align-right">#NumberFormat(session.visitsSnapshotArray[1].visits/session.visitsSnapshotArray[1].visitors,"0.00")#</td>
             </tr>

            </table>
            </div>
            
            </div>
            
            <div class="grid_16" style="margin-top: 1em;text-align: center;">
            
            <h2>Visits Trend</h2>
            
            <!--- style from webcharts --->
            <cfsavecontent variable="style">
               <?xml version="1.0" encoding="UTF-8"?>
             <frameChart is3D="false">
              <frame xDepth="12" yDepth="11"/>
              <xAxis>
                   <labelStyle color="##333333"/>
              </xAxis>
              <yAxis scaleMin="0" scaleMax="500">
                   <labelStyle color="##333333"/>
              </yAxis>
               <legend allowSpan="true" equalCols="false" isVisible="false" halign="Right" isMultiline="true">
               <decoration style="None"/>
          </legend>
              <decoration style="RoundShadow"/>
              <paint palette="Pastel" isVertical="true" min="47" max="83"/>
              <insets right="5"/>
    		</frameChart>
            </cfsavecontent>
          
          <cfif Year(session.startdate) EQ Year(session.enddate)>
            <cfchart yaxistitle="Number of Visits" chartwidth="600" style="#style#" format="jpg" tipstyle="none">
            	<cfchartseries type="bar" datalabelstyle="value">
                    <cfloop from="1" to="#ArrayLen(session.visitsChartArray)#" index="num">
                    		<cfchartdata item="#MonthAsString(session.visitsChartArray[num].month)#" value="#session.visitsChartArray[num].visits#" />
                    </cfloop>
                </cfchartseries>
            </cfchart>
            
            
            <cfelse>
            
             <cfchart yaxistitle="Number of Visits" chartwidth="600" style="#style#" format="jpg" tipstyle="none">
            	<cfchartseries type="bar" datalabelstyle="value">
                    <cfloop from="1" to="#ArrayLen(session.visitsChartArray)#" index="num">
                    		<cfchartdata item="#DateFormat(DateAdd('m',session.visitsChartArray[num].month-1, session.startdate),'mmm')#" value="#session.visitsChartArray[num].visits#" />
                    </cfloop>
                </cfchartseries>
            </cfchart>
            
            </cfif>
            </div>
            
           <div class="grid_16" style="margin-top: 1em;text-align: center;">
           <cfsavecontent variable="style2">
               <?xml version="1.0" encoding="UTF-8"?>
             <frameChart is3D="false">
              <frame xDepth="12" yDepth="11"/>
              <xAxis>
                   <labelStyle color="##333333"/>
              </xAxis>
              <yAxis scaleMin="0" scaleMax="500">
                   <labelStyle color="##333333"/>
              </yAxis>
               <legend allowSpan="true" equalCols="false" isVisible="false" halign="Right" isMultiline="true">
               <decoration style="None"/>
          </legend>
          <elements>
               <column index="0">
                    <paint color="##0066CC"/>
               </column>
               <column index="1">
                    <paint color="##66CC00"/>
               </column>
               <column index="3">
                    <paint color="##CC0066"/>
               </column>
               <column index="4">
                    <paint color="##6600CC"/>
               </column>
          </elements>
              <decoration style="RoundShadow"/>
              <paint palette="Pastel" isVertical="true" min="47" max="83"/>
              <insets right="5"/>
    		</frameChart>
            </cfsavecontent>
           
           <h2>Countries</h2>
            <cfchart yaxistitle="Number of Visits" chartwidth="500" style="#style2#" format="jpg" tipstyle="none">
            	<cfchartseries type="bar" datalabelstyle="value">
                	<cfloop from="1" to="#ArrayLen(session.countryChartArray)#" index="num">
                    	<cfchartdata item="#session.countryChartArray[num].country#" value="#session.countryChartArray[num].visits#" />
                    </cfloop>
                </cfchartseries>
            </cfchart>
            	
          </div>
          
           <div class="grid_14 prefix_1 suffix_1" style="margin-top: 1em;">
            <table width="100%" cellpadding="0" cellspacing="0" border="0" class="dataTable listTable">
            <caption><h2>Top Pages Summary</h2></caption>

            <tr class="headerRow">
            	<th>&nbsp;</th>
                <th>Title</th>
                <th width="10%">Pageviews</th>
            </tr>

            <cfloop from="1" to="#ArrayLen(session.topPagesArray)#" index="num">
            <tr <cfif num MOD 2> class="oddrow"</cfif>>
           		<td>#num#</td>
                <td>#session.topPagesArray[num].pageTitle#</td>
                <td class="align-right">#NumberFormat(session.topPagesArray[num].pageviews,",")#</td>
            </tr>
            </cfloop>

            </table>
           </div>       

</div>		 
</div>
</cfoutput>

<div id="dialog" title="Select Date Range">
<div id="message"></div>
	<form name="dateRange" id="dateRangeForm" action="index.cfm" method="post">
    <label for="startdate">Start Date</label>
    <input id="startdate" readonly="readonly" type="text" /><input type="hidden" name="startdate" id="start_alternate" />
    <label for="enddate">End Date</label>
    <input id="enddate" readonly="readonly" type="text" /><input type="hidden" name="enddate" id="end_alternate" />
    </form>
</div>
<!---select new site modal form--->
<div id="site_dialog" title="Select Site">
<div id="message_site"></div>
    <form name="siteSelect" id="siteSelectForm" action="index.cfm" method="post">
    <label for="tableId">Select Site</label>
    <select name="tableId" id="tableId">
    <cfloop array="#session.profilesArray#" index="profile">
    <option value="#profile.tableId#|#profile.title#">#profile.title#</option>
    </cfloop>
    </select>
    </form>
</div>
</body>
</html>