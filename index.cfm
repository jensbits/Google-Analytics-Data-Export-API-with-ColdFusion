<!--- if logout requested or token expired, log out --->
<cfif (isDefined("URL.logout") and URL.logout EQ "true") OR (isDefined("session.ga_accessTokenExpiry") AND DateCompare(session.ga_accessTokenExpiry,Now(),"s") LT 0)>
    <cfinvoke component="ga" method="logout" />
</cfif>

<cfif NOT isDefined("session.ga_accessToken") OR session.ga_accessToken CONTAINS "Authorization Failed">
	<cflocation url="login.cfm" addtoken="no" /> 
</cfif>

<cfinvoke component="ga" method="init" />

<cfset daysInRange = DateDiff("d",session.startdate,session.enddate) + 1 />
      
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<title><cfoutput>#session.site#</cfoutput> Web Stats</title>
<link rel="stylesheet" href="//ajax.googleapis.com/ajax/libs/jqueryui/1/themes/blitzer/jquery-ui.css" />
<link rel="stylesheet" href="/css/bootstrap.min.css" />
<style>body {padding-top: 60px;}.float_right{float:right}</style>
<link rel="stylesheet" href="/css/bootstrap-responsive.min.css" />

<script src="//ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>
<script src="//ajax.googleapis.com/ajax/libs/jqueryui/1/jquery-ui.min.js"></script>
<script src="js/util.js"></script>
</head>
<body>
<cfoutput>
<div class="navbar navbar-fixed-top">
	<div class="navbar-inner">
		<div class="container">
        	<a class="btw btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
                <span class="icon-bar"></span>
            </a>
          <a class="brand" href="index.cfm">Google Analytics API with ColdFusion</a>
          <div class="nav-collapse">
              <ul class="nav">
                <li class="active"><a href="http://www.jensbits.com/">Home</a></li>
              </ul>
          </div>
        </div>
    </div>
</div>
<div class="container">   
<div class="hero-unit">
	<h1>#session.site#</h1>
    <h2>#DateFormat(session.startdate,"mmmm d, yyyy")# - #DateFormat(session.enddate,"mmmm d, yyyy")#</h2>
	<p class="float_right"><a class="btn btn-danger" href="index.cfm?logout=true">Logout</a></p> 
	<p><button class="btn btn-primary" id="selectDateRange">Select New Date Range</button>	
		<button class="btn btn-info" id="selectSite">Select New Site</button></p>
 </div>
     <div class="row">
     	<div class="span4">  	
        <!---output--->
            <table class="table table-bordered table-striped">
            	<caption><h2>Pageviews</h2></caption>
	             <tr>
	             	<th>Pageviews</th>
	                <td>#NumberFormat(session.visitsSnapshotArray[1].pageviews,",")#</td>
	             </tr>
	             <tr>
	                <th>Avg Per Day</th>
	                <td>#NumberFormat(session.visitsSnapshotArray[1].pageviews/daysInRange,",")#</td>
	             </tr>
	             <tr>
	                <th>Avg per Visit</th>
	                <td class="align-right">#NumberFormat(session.visitsSnapshotArray[1].pageviews/session.visitsSnapshotArray[1].visits,"0.00")#</td>
	             </tr>
            </table>
            </div>
                      
            <div class="span4"> 
            <table class="table table-bordered table-striped">
	            <caption><h2>Visits</h2></caption>
	             <tr>
	             	<th>Visits</th>
	                <td>#NumberFormat(session.visitsSnapshotArray[1].visits,",")#</td>
	             </tr>
	             <tr>
	             	<th>Avg Per Day</th>
	                <td>#NumberFormat(session.visitsSnapshotArray[1].visits/daysInRange,",")#</td>
	             </tr>
	             <tr>
	                <th>Avg Visit Duration</th>
	                <td>#TimeFormat(CreateTime((session.visitsSnapshotArray[1].timeOnSite/session.visitsSnapshotArray[1].visits)/3600,(session.visitsSnapshotArray[1].timeOnSite/session.visitsSnapshotArray[1].visits)/60,(session.visitsSnapshotArray[1].timeOnSite/session.visitsSnapshotArray[1].visits) Mod 60), "HH:mm:ss")#</td>
	             </tr>
            </table>
            </div>	
            
            <div class="span4"> 
            <table class="table table-bordered table-striped">
	            <caption><h2>Visitors</h2></caption>
	             <tr>
	             	<th>Visitors</th>
	                <td>#NumberFormat(session.visitsSnapshotArray[1].visitors,",")#</td>
	             </tr>
	             <tr>
	                <th>Visits from New Visitors</th>
	                <td>#NumberFormat(session.visitorLoyaltyArray[1].visits,",")#</td>
	             </tr>
	             <tr>
	                <th>Visits from Returning Visitors</th>
	                    <td>#NumberFormat(session.visitorLoyaltyArray[2].visits,",")#</td>
	             </tr>
	              <tr>
	                <th>Avg Visits per Visitor</th>
	                <td>#NumberFormat(session.visitsSnapshotArray[1].visits/session.visitsSnapshotArray[1].visitors,"0.00")#</td>
	             </tr>
            </table>
            </div>
            
        </div>
            
        <div class="row">
     	<div class="span9 offset3"> 
            
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
            
            <cfchart yaxistitle="Number of Visits" chartwidth="600" style="#style#" format="jpg" tipstyle="none">
            	<cfchartseries type="bar" datalabelstyle="value">
                    <cfloop from="1" to="#ArrayLen(session.visitsChartArray)#" index="num">
                    	<cfchartdata item="#MonthAsString(session.visitsChartArray[num].month)# #session.visitsChartArray[num].year#" value="#session.visitsChartArray[num].visits#" />
                    </cfloop>
                </cfchartseries>
            </cfchart>
            
          </div>
      </div>
      <div class="row">
     	<div class="span9 offset3">       

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
      </div>
      <div class="row">
     	<div class="span12">   
            <table class="table table-bordered table-striped">
	            <caption><h2>Top Pages Summary</h2></caption>
	            <tr>
	            	<th>&nbsp;</th>
	                <th>Title</th>
	                <th width="10%">Pageviews</th>
	            </tr>
	            <cfloop from="1" to="#ArrayLen(session.topPagesArray)#" index="num">
	            <tr>
	           		<td>#num#</td>
	                <td>#HTMLEditFormat(session.topPagesArray[num].pageTitle)#</td>
	                <td class="align-right">#NumberFormat(session.topPagesArray[num].pageviews,",")#</td>
	            </tr>
	            </cfloop>
            </table>
           </div>       
       </div>		 
</div>


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
    <label for="profileId">Select Site</label>
    <select name="profileId" id="profileId">
    <cfloop array="#session.profilesArray#" index="profile">
    	<option value="#profile.profileId#,#profile.title#">#profile.title#</option>
    </cfloop>
    </select>
    </form>
</div>
</cfoutput>
</body>
</html>