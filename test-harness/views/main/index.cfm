<cfoutput>
<div class="alert alert-dark">
	<h2>Disk Registry</h2>
</div>
<table class="table">
	<thead>
		<th>Disk Name</th>
		<th>Provider</th>
		<th>Properties</th>
	</thead>
	<tbody>
		<cfloop array="#prc.diskService.names()#" index="thisDisk">
		<cfset disk = prc.diskService.get( thisDisk )>
		<cfset diskRecord = prc.diskService.getDiskRecord( thisDisk )>
		<tr>
			<td>
				<span class="badge bg-info">#thisDisk#</span>
			</td>
			<td>
				<span class="badge bg-danger">#diskRecord.provider#</span>
			</td>
			<td>
				<cfdump var="#diskRecord.properties#" expand="false">
			</td>
		</tr>
		</cfloop>
	</tbody>
</table>
</cfoutput>
