<h3>Upload Functionality Acceptance Testing</h3>
<form action="" method="post" enctype="multipart/form-data">
	<cfif event.getHTTPMethod() == "POST">
		<p class="alert alert-success">Congratulations!  Upload tests have passed for all registered disks.</p>
	</cfif>
	<p>
		<input type="file" name="uploadField"/>
	</p>
	<p>
		<input type="submit" name="submit" value="Test Upload Functionality for All Disks"/>
	</p>
</form>