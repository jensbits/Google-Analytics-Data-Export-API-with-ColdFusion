$(function() {
	$("#startdate").datepicker({altField: '#start_alternate',altFormat: 'yy-mm-dd',minDate: new Date(2008, 8 - 1, 1),maxDate: -1});
	$("#enddate").datepicker({altField: '#end_alternate',altFormat: 'yy-mm-dd',minDate: new Date(2008, 8 - 1, 2),maxDate: -1});	
	
	$('button#selectDateRange').click(function(){ $('#dialog').dialog('open'); });
	$('button#selectSite').click(function(){ $('#site_dialog').dialog('open'); });
								
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
								$('#message').html("<div class='alert alert-error'>Date range is invalid.</div>"); 
							} else {
								$('#message').html("<div class='alert alert-success'>Loading new data. Please wait.</div>");
								location.reload();
							}
						}
					}); //end ajax
					return false;
				 } //end if
		  	 }
		 } //end buttons
	 }); //end dialog
	
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
						$('#message_site').html("<div class='alert alert-success'>Loading new data. Please wait.</div>");
						$('#siteSelectForm, .ui-dialog-buttonpane, .ui-dialog-titlebar-close').hide();
						$('#site_dialog').dialog({ closeOnEscape: false });
						location.reload();
					}
				}); //end ajax
			return false;
			},
			"Close": function() {
				$(this).dialog("close");
			}
		} //end buttons
	}); //end dialog
});