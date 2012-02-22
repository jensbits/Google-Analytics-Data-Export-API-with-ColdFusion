
<cfif isDefined("URL.code") AND URL.code NEQ "access_denied">
	<cfinvoke component="ga" method="googleOauth2Login">
        <cfinvokeargument name="code" value="#URL.code#" />
        <cfinvokeargument name="client_id" value="1042549107899.apps.googleusercontent.com" />
        <cfinvokeargument name="client_secret" value="dnCU7Pn3MKSA0xCoz0Ua03z7" />
        <cfinvokeargument name="redirect_uri" value="http://www.popcenter.org/ga/login.cfm" />
        <cfinvokeargument name="state" value="#URL.state#" />
    </cfinvoke>
</cfif>

<!---not used as client login is security risk
checking for session loginAuth prevents re-authentication on page refresh
<cfif isDefined("form.Email") AND ((NOT isDefined("session.ga_loginAuth")) OR session.ga_loginAuth EQ "Authorization Failed")>
 	<cfinvoke component="ga" method="googleLogin" returnvariable="loginAuth">
        <cfinvokeargument name="email" value="#form.Email#" />
        <cfinvokeargument name="password" value="#form.password#" />
    </cfinvoke>
</cfif>--->

<cfif isDefined("session.ga_loginAuth") AND session.ga_loginAuth NEQ "Authorization Failed">
	<cfinvoke component="ga" method="parseProfiles" returnvariable="profilesArray">
    	<cfinvokeargument name="authToken" value="#session.ga_loginAuth#" />
    </cfinvoke>
    
    <cflock scope="session" type="exclusive" timeout="5">
		<cfset session.profilesArray = profilesArray />
	</cflock>
    
</cfif>
<!DOCTYPE html>
<html>
<head>

<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Web Stats</title>

<link rel="stylesheet" type="text/css" href="css/reset.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/960.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/text.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/style.css" media="screen" />
</head>
<body>
<div id="wrapper">
	
	<div id="header" class="container_16">
		<h1><span>Web</span> Stats</h1>
	</div>
    
<div id="content-wrap" class="container_16">
   
    <div class="grid_8 prefix_4 suffix_4"> 
    <cfif isDefined("URL.code") AND URL.code EQ "access_denied">
		<div class='errorMessage'>Google authorization failed.</div>
	</cfif>
    
	<cfif isDefined("session.ga_loginAuth") AND session.ga_loginAuth CONTAINS "Authorization Failed">
		<div class='errorMessage'>Google authorization failed. Your email and/or password was entered incorrectly or the Google account you are using does not have access to the analytics data. <cfoutput>ERROR: #session.ga_loginAuth#</cfoutput></div>
	</cfif>
    <cfif ArrayLen(session.profilesArray) GT 1>
		<div id="logout"><a href="login.cfm?logout=true">Logout</a></div>
	</cfif>
 
    <!---if they picked a pofile from DD, send to stats page --->
    <cfif isDefined("form.tableId")>
        <cflock scope="session" type="exclusive" timeout="5">
			<cfset session.tableId = Mid(form.tableId,1,Find("|",form.tableId)-1) />
            <cfset session.site = Mid(form.tableId,Find("|",form.tableId)+1,Len(form.tableId)-Find("|",form.tableId)) />
        </cflock>
		<cflocation url="index.cfm" addtoken="no"/>
	</cfif>

    <!---if they only have 1 profile assoc w/ their login, send them to stats page --->
     <cfif ArrayLen(session.profilesArray) EQ 1>
     	<cflock scope="session" type="exclusive" timeout="5">
			<cfset session.tableId = session.profilesArray[1].tableId />
            <cfset session.site = session.profilesArray[1].title />
		</cflock>
		<cflocation url="index.cfm" addtoken="no"/>

	<!--- else have them pick the profile they want stats for --->
    <cfelseif ArrayLen(session.profilesArray) GT 1>
        <div class="grid_8 prefix_4 suffix_4">
          <div id="formWrap">
         
    		<form name="siteSelect" method="post" action="login.cfm">
                <label for="tableId">Select Site</label>
                <select name="tableId" id="tableId">
                                <cfloop array="#session.profilesArray#" index="profile">
                                    <option value="#profile.tableId#|#profile.title#">#profile.title#</option>
                                </cfloop>
                </select>
    			<br /><br />
         		<button type="submit" id="submitSite">Submit</button>
    		</form>
    
    	</div>
	<!---else no profiles and they need to log in --->
	<cfelse>
        <div id="formWrap">
<!---     No longer used for security reasons   
		<form name="loginForm" action="login.cfm" method="post">
            <label for="email">Email (gmail.com)</label>
            <input id="email" type="text" name="Email" />
            <label for="password">Password:</label>
            <input type="password" name="password" id="password"/>
            <br /><br />
            <button type="submit" id="submitLogin">Submit</button>
        </form>--->
        <p><a href=" https://accounts.google.com/o/oauth2/auth?scope=https://www.googleapis.com/auth/analytics.readonly&redirect_uri=http://www.jensbits.com/demos/analytics_oauth2/index.php&response_type=code&client_id=1083852050270.apps.googleusercontent.com&access_type=online">Login with Google account that has access to CPOP analytics<br /></a></p>
        </div>
    </div> 
  </cfif> 
</div>       
</div>
</body>
</html>
