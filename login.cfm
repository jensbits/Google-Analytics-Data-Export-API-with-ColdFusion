<cfif isDefined("URL.logout") and URL.logout EQ "true">
	<!--- delete session vars on logout to start fresh --->
    <cflock scope="session" type="exclusive" timeout="5">
    	<cfset StructDelete(session,"ga_loginAuth") />
        <cfset StructDelete(session,"authSubLogin") />
        <cfset StructDelete(session,"startdate") />
        <cfset StructDelete(session,"enddate") />
        <cfset StructDelete(session,"profilesArray") />
        <cfset StructDelete(session,"tableId") />
        <cfset StructDelete(session,"site") />
        <cfset StructDelete(session,"getNewData") />
    </cflock>
	<cflocation url="login.cfm" addtoken="no" /> 
</cfif>
<!--- default value for profile array --->
<cflock scope="session" type="exclusive" timeout="5">
	<cfset session.profilesArray = ArrayNew(1) />
</cflock> 


<cfif isDefined("form.Email")>
	<!---deleting session ga_loginAuth prevents re-authentication on page refresh--->
	 <cflock scope="session" type="exclusive" timeout="5">
    	<cfset StructDelete(session,"ga_loginAuth") />
     </cflock>
     
 	<cfinvoke component="ga" method="googleLogin">
        <cfinvokeargument name="email" value="#form.Email#" />
        <cfinvokeargument name="password" value="#form.password#" />
    </cfinvoke>
</cfif>

<!--- for AuthSub login --->
<cfif isDefined("URL.token")> 
	<cfinvoke component="ga" method="googleAuthSubLogin">
        <cfinvokeargument name="urlToken" value="#URL.token#" />
    </cfinvoke>
</cfif>

<cfif isDefined("session.ga_loginAuth") AND session.ga_loginAuth NEQ "Authorization Failed">
	<cfinvoke component="ga" method="parseProfiles" returnvariable="profilesArray" />
    
 	<cflock scope="session" type="exclusive" timeout="5">
		 <cfset session.profilesArray = profilesArray />
	</cflock>

</cfif>

<!DOCTYPE html>
<html>
<head>

<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title><cfif ArrayLen(session.profilesArray) GT 1>Profile Select: Google Analytics Web Stats<cfelse>Login: Google Analytics Web Stats</cfif></title>
<script language="javascript" type="text/javascript" src="js/jquery-1.4.2.min.js"></script>
<script language="javascript" type="text/javascript" src="js/jquery-ui-1.8.custom.min.js"></script>

<link rel="stylesheet" type="text/css" href="css/960.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/redmond/jquery-ui-1.8.custom.css" media="screen" />
<link rel="stylesheet" type="text/css" href="css/style.css" media="screen" />
<script type="text/javascript">
$().ready(function() {
	$('button#submitSite').click(function(){
		$('#loading_dialog').dialog('open');
		
	});
});

$(function(){				
	// jQuery UI Dialog						
	$('#loading_dialog').dialog({
		autoOpen: false,
		width: 400,
		modal: true,
		resizable: false,
		closeOnEscape: false,
   		open: function(event, ui) { $('.ui-dialog-titlebar-close').hide();}
	});
});
</script>
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-4945154-2']);
  _gaq.push(['_setDomainName', 'none']);
  _gaq.push(['_setAllowLinker', true]);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ga);
  })();

</script>
</head>
<body>
<cfoutput><div id="wrapper">
	
	<div id="header" class="container_16">
		<h1><span>Google Analytics</span> Web Stats</h1>
	</div>
    
<div id="content-wrap" class="container_16">

<cfif  ArrayLen(session.profilesArray) GT 1>
	<div id="logout"><a href="login.cfm?logout=true">Logout</a></div> 
</cfif> 

    <div class="grid_8 prefix_4 suffix_4"> 
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
    <cfelseif  ArrayLen(session.profilesArray) GT 1>
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
	
	<!--- Failed login error message --->
	<cfif isDefined("session.ga_loginAuth") AND session.ga_loginAuth EQ "Authorization Failed">
		<div class='errorMessage'>Authorization failed. Your email and/or password was entered incorrectly.</div>
	</cfif>
	
        <div id="formWrap">
        <form name="loginForm" action="login.cfm" method="post">
            <label for="email">Gmail:</label>
            <input id="email" type="text" name="Email" />
            <label for="password">Password:</label>
            <input type="password" name="password" id="password"/>
            <br /><br />
            <button type="submit" id="submitLogin">Submit</button>
        </form>
        
        <p><a class="button" onClick="_gaq.push(['_trackEvent', 'AuthSub', 'Click', 'http://cf-jensbits.com/ga/login.cfm' ]);" href="https://www.google.com/accounts/AuthSubRequest?next=http://cf-jensbits.com/ga/login.cfm&scope=https://www.google.com/analytics/feeds/
&secure=0&session=1">Or, authenticate using AuthSub through Google</a></p>
        </div>
    </cfif>
    <p><a href='http://www.jensbits.com/2009/12/19/coldfusion-and-google-analytics-getting-out-what-you-put-in/'>return to post on jensbits.com</a></p>    
    </div> 
    
</div>       
</div>

</cfoutput>
<!---loading dialog--->
<div id="loading_dialog" title="Loading...">
<div class='successMessage'>Loading new data. Please wait.</div>
</div>
</body>
</html>
