<cfscript>
/**
 * Helper to get the disk service or a named disk from cbfs
 *
 * @diskName If passed, it will try to get the named disk, else the disk service
 */
function cbfs( diskName ){
	var diskService = getInstance( "DiskService@cbfs" );

	if( isNull( arguments.diskName ) ){
		return diskService;
	}

	return diskService.get( arguments.diskName );

}
</cfscript>
