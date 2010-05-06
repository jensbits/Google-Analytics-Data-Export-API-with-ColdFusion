<cfif NOT isDefined("session.ga_loginAuth") OR session.ga_loginAuth EQ "Authorization Failed">
	<cflocation url="login.cfm" addtoken="no" />
</cfif>

<!---dates for one full year of stats (default)--->
<cfif (NOT isDefined("session.startdate")) AND (NOT isDefined("session.enddate"))>
    <cflock scope="session" type="exclusive" timeout="5">
        <cfset session.startdate = DateFormat(DateAdd("d",-365,CreateDate(Year(Now()),Month(Now()),Day(Now()))), "yyyy-mm-dd") />
        <cfset session.enddate = DateFormat(DateAdd("d", -1, Now()),"yyyy-mm-dd") />
    </cflock>
</cfif>
<!---used for calculating some of the stats--->
<cfset daysInRange = DateDiff("d",session.startdate,session.enddate) + 1 />

<!---feed URLs - set dimensions and metrics for data returned here--->			
        	<cfset statsUrl = "https://www.google.com/analytics/feeds/data?ids=" & session.tableId & "&metrics=ga:newVisits,ga:pageviews,ga:visits,ga:visitors,ga:timeOnSite&start-date=" & session.startdate & "&end-date=" & session.enddate />

              <cfset visitorLoyaltyUrl = "https://www.google.com/analytics/feeds/data?ids=" & session.tableId & "&dimensions=ga:daysSinceLastVisit&metrics=ga:newVisits&filters=ga:daysSinceLastVisit%3D%3D0&start-date=" & session.startdate & "&end-date=" & session.enddate />
              
              <cfset visitsChartUrl = "https://www.google.com/analytics/feeds/data?ids=" & session.tableId & "&dimensions=ga:month,ga:year&metrics=ga:visits&sort=ga:year&start-date=" & session.startdate & "&end-date=" & session.enddate />
              
             <cfset countryChartUrl = "https://www.google.com/analytics/feeds/data?ids=" & session.tableId & "&dimensions=ga:country&metrics=ga:visits&sort=-ga:visits&start-date=" & session.startdate & "&end-date=" & session.enddate & "&max-results=5" />
             
              <cfset topPagesUrl = "https://www.google.com/analytics/feeds/data?ids=" & session.tableId & "&dimensions=ga:pageTitle&metrics=ga:pageviews&filters=ga:pageTitle!~Page%20Not%20Found&sort=-ga:pageviews&start-date=" & session.startdate & "&end-date=" & session.enddate & "&max-results=25" />
                    	
        <!---check for session.statsDataArray to avoid calling/processing GA on page refresh. Info is day old anyway.--->	
        <cfif NOT isDefined("session.getNewData")>	
        
        <!---calls GA API and gets data array returned--->
            <cfinvoke component="ga" method="parseData" returnvariable="statsDataArray">
                <cfinvokeargument name="gaUrl" value="#statsUrl#" />
            </cfinvoke>

            <cfinvoke component="ga" method="parseData" returnvariable="visitorLoyaltyArray">
                <cfinvokeargument name="gaUrl" value="#visitorLoyaltyUrl#" />
            </cfinvoke>
            
             <cfinvoke component="ga" method="parseData" returnvariable="visitsChartArray">
                <cfinvokeargument name="gaUrl" value="#visitsChartUrl#" />
            </cfinvoke> 
            
            <cfinvoke component="ga" method="parseData" returnvariable="countryChartArray">
                <cfinvokeargument name="gaUrl" value="#countryChartUrl#" />
            </cfinvoke>
            
            <cfinvoke component="ga" method="parseData" returnvariable="topPagesArray">
                <cfinvokeargument name="gaUrl" value="#topPagesUrl#" />
            </cfinvoke>
        
        	<!---set getNewData session var and session vars with data to prevent running calls to GA on page refresh--->
            <cflock scope="session" type="exclusive" timeout="5">
           		<cfset session.getNewData = true />
                
				<cfset session.statsDataArray = statsDataArray />
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
<title>Results: Google Analytics Web Stats</title>
<script language="javascript" type="text/javascript" src="js/jquery-1.4.2.min.js"></script>
<script language="javascript" type="text/javascript" src="js/jquery-ui-1.8.custom.min.js"></script>

<link rel="stylesheet" type="text/css" href="css/960.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/redmond/jquery-ui-1.8.custom.css" media="screen" />
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
		$('#date_dialog').dialog('open');
	});
	
	$('button#selectSite').click(function(){
		$('#site_dialog').dialog('open');
	});
});

$(function(){									
	$('#date_dialog').dialog({
		autoOpen: false,
		width: 400,
		modal: true,
		resizable: false,
		close: function() {
			$("#startdate").datepicker('hide');
			$("#enddate").datepicker('hide');
		 },
		buttons: {
			"Submit": function() { 
				dataString = $('form').serialize();
				$.ajax({
				type: "POST",
				url: "dateRange.cfm",
				data: dataString,
				dataType: "json",
				success: function(data) {				
					if(data == 'invalid'){ 
						$('#message_date').html("<div class='errorMessage'>Date range is invalid.</div>"); 
					} else {
						$('#message_date').html("<div class='successMessage'>Loading new data. Please wait.</div>");
						$('#dateRangeForm').hide();
						$('.ui-dialog-buttonpane').hide();
						$('.ui-dialog-titlebar-close').hide();
					    $('#date_dialog').dialog({ closeOnEscape: false });
						location.reload();
					}
				}
				
			  });
				return false;				
			}, 
			"Close": function() { 
				$(this).dialog("close"); 
				$('#startdate').datepicker('hide');
				$('#enddate').datepicker('hide');
			} 
		}
	});
});

$(function(){									
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
					$('#siteSelectForm').hide();
					$('.ui-dialog-buttonpane').hide();
   					$(".ui-dialog-titlebar-close").hide();
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
		<h1><span>Google Analytics:</span> #session.site#</h1>
        <h2>#DateFormat(session.startdate,"mmmm d, yyyy")# - #DateFormat(session.enddate,"mmmm d, yyyy")#</h2>
	</div>

<div id="content-wrap" class="container_16">

<div id="logout"><a href="login.cfm?logout=true">Logout</a></div>
<div style="width: 400px">
	<cfif ArrayLen(session.profilesArray) GT 1>
		<button id="selectSite">Select New Site</button>
	</cfif>
	<button id="selectDateRange">Select New Date Range</button>	 
</div>	  
			<div class="grid_16" style="margin-top: 1em;">
            
            <div class="grid_5">
            <table cellpadding="0" cellspacing="0" border="0" class="dataTable">
            <caption><h2>Page View Summary</h2></caption>
            
             <tr class="oddrow">
             	<th><h3>Pageviews</h3></th>
                <td class="align-right">#NumberFormat(session.statsDataArray[1].pageviews,",")#</td>
             </tr>
             <tr>
                <th><h3>Average Pageviews Per Day</h3></th>
                <td class="align-right">#NumberFormat(session.statsDataArray[1].pageviews/daysInRange,",")#</td>
             </tr>
             <tr class="oddrow">
                <th><h3>Average Page Views per Visit</h3></th>
                <td class="align-right">#NumberFormat(session.statsDataArray[1].pageviews/session.statsDataArray[1].visits,"0.00")#</td>
             </tr>

            </table>
            </div>
            
            <div class="grid_5" >
            <table cellpadding="0" cellspacing="0" border="0" class="dataTable">
            <caption><h2>Visit Summary</h2></caption>
            
             <tr class="oddrow">
             	<th><h3>Visits</h3></th>
                <td class="align-right">#NumberFormat(session.statsDataArray[1].visits,",")#</td>
             </tr>
             <tr>
             	<th><h3>Average Per Day</h3></th>
                <td class="align-right">#NumberFormat(session.statsDataArray[1].visits/daysInRange,",")#</td>
             </tr>
             <tr class="oddrow">
                <th><h3>Average Visit Duration</h3></th>
                <td class="align-right">#TimeFormat(CreateTime((session.statsDataArray[1].timeOnSite/session.statsDataArray[1].visits)/3600,(session.statsDataArray[1].timeOnSite/session.statsDataArray[1].visits)/60,(session.statsDataArray[1].timeOnSite/session.statsDataArray[1].visits) Mod 60), "HH:mm:ss")#</td>
             </tr>

            </table>
            </div>	
            
            <div class="grid_5" >
            <table cellpadding="0" cellspacing="0" border="0" class="dataTable">
            <caption><h2>Visitor Summary</h2></caption>
            
             <tr class="oddrow">
             	<th><h3>Visitors</h3></th>
                <td class="align-right">#NumberFormat(session.statsDataArray[1].visitors,",")#</td>
             </tr>
             <tr>
                <th><h3>Visitors Who Visited Once</h3></th>
                <td class="align-right">#NumberFormat(session.visitorLoyaltyArray[1].newVisits,",")#</td>
             </tr>
             <tr class="oddrow">
                <th><h3>Visitors Who Visited More Than Once</h3></th>
                    <td class="align-right">#NumberFormat(session.statsDataArray[1].visitors-session.visitorLoyaltyArray[1].newVisits,",")#</td>
             </tr>
              <tr>
                <th><h3>Average Visits per Visitor</h3></th>
                <td class="align-right">#NumberFormat(session.statsDataArray[1].visits/session.statsDataArray[1].visitors,"0.00")#</td>
             </tr>

            </table>
            </div>
            
            </div>
            
            <div class="grid_16" style="margin-top: 1em;text-align: center;">
            
            <h2>Visits Trend</h2>
            
            <!--- style for webcharts --->
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
            <cfset chartwidth = 600 />
            <!---if months req GT 12--->
            <cfif ArrayLen(session.visitsChartArray) GT 12>
            	<cfset chartwidth = 800 />
            </cfif>
                    
            <cfchart yaxistitle="Number of Visits" chartwidth="#chartwidth#" style="#style#" format="jpg" tipstyle="none">
            	<cfchartseries type="bar" datalabelstyle="value">
                    <cfloop array="#session.visitsChartArray#" index="visitsChart">
                    		<cfchartdata item="#MonthAsString(visitsChart.month)# #visitsChart.year#" value="#visitsChart.visits#" />
                    </cfloop>
                </cfchartseries>
            </cfchart>
                      
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
                	<cfloop array="#session.countryChartArray#" index="countryChart">
                    	<cfchartdata item="#countryChart.country#" value="#countryChart.visits#" />
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
<!---create date modal form--->
<div id="date_dialog" title="Select Date Range">
<div id="message_date"></div>
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
</cfoutput>
</body>
</html>