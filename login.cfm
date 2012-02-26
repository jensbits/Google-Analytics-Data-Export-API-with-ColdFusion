<cfif (isDefined("URL.logout") and URL.logout EQ "true") OR (isDefined("session.ga_accessTokenExpiry") AND DateCompare(session.ga_accessTokenExpiry,Now()) LT 0)>
	<cfinvoke component="ga" method="logout" />
</cfif>
<!--- get access token if code returned and access token not issued --->
<cfif isDefined("URL.code") AND URL.code NEQ "access_denied">
	<cfinvoke component="ga" method="googleOauth2Login">
        <cfinvokeargument name="code" value="#URL.code#" />
    </cfinvoke>
</cfif>

<!---if they picked a pofile from DD, send to stats page --->
<cfif isDefined("form.profileId")>
    <cflock scope="session" type="exclusive" timeout="5">
		<cfset session.profileId = ListGetAt(form.profileId, 1) />
        <cfset session.site = ListGetAt(form.profileId, 2) />
    </cflock>
	<cflocation url="index.cfm" addtoken="no"/>
</cfif>

<!--- get profiles assoc with account --->
<cfif isDefined("session.ga_accessToken") AND session.ga_accessToken DOES NOT CONTAIN "Authorization Failed">
	<cfinvoke component="ga" method="parseProfiles" />  
</cfif>

<!--- create login url --->
<cfset loginURL = "https://accounts.google.com/o/oauth2/auth?scope=" & request.oauthSettings["scope"] 
                   & "&redirect_uri=" & request.oauthSettings["redirect_uri"]
                   & "&response_type=code&client_id=" & request.oauthSettings["client_id"]
                   & "&access_type=online" />
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Web Stats</title>
<link rel="stylesheet" href="//jensbits.com/demos/bootstrap/css/bootstrap.min.css" />
<style>body {padding-top: 60px;}.float_right{float:right}</style>
<link rel="stylesheet" href="//jensbits.com/demos/bootstrap/css/bootstrap-responsive.min.css" />
</head>
<body>
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
	<h1>Web Stats</h1>
	<p>Google Analytics OAuth2 with ColdFusion and ColdFusion Charts</p>
   	<!--- else have them pick the profile they want stats for --->
    <cfif isDefined("session.profilesArray")>
        <p class="float_right"><a class="btn btn-danger" href="index.cfm?logout=true">Logout</a></p>
         <cfoutput>
    		<form class="form-horizontal" name="siteSelect" method="post" action="login.cfm">
    		 <div class="control-group">
                <label class="control-label" for="profileId">Select Site</label>
                <div class="controls">
                <select name="profileId" id="profileId">
                	<cfloop array="#session.profilesArray#" index="profile">
                    	<option value="#profile.profileId#,#profile.title#">#profile.title#</option>
                     </cfloop>
                </select>
                </div>
              </div>
              <div class="form-actions">
         		<button class="btn btn-primary" type="submit" id="submitSite">Submit</button>
         	  </div>
    		</form>
    </cfoutput>
	<!---else no profiles and they need to log in --->
	<cfelse>
         <cfif isDefined("URL.code") AND URL.code EQ "access_denied">
		 	<p class='alert alert-error'>Google authorization failed.</p>
        <cfelseif isDefined("session.ga_accessToken") AND session.ga_accessToken CONTAINS "Authorization Failed">
			<div class='alert alert-error'><cfoutput><p><strong>#session.ga_accessToken#</strong></p></cfoutput><p>Google authorization failed.</p></div>
		</cfif>
        <p><a class="btn btn-primary" href="<cfoutput>#loginURL#</cfoutput>">Login with Google account that has access to analytics</a></p>
  </cfif> 
</div>       
</div>
</body>
</html>