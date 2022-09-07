component {

	function index( event, rc, prc ){
		prc.diskService = getInstance( "DiskService@cbfs" );

		prc.defaultDisk = prc.diskService.get( "default" );
		prc.tempDisk    = prc.diskService.get( "temp" );
		prc.localDisk   = prc.diskService.get( "local" );
		prc.ramDisk     = prc.diskService.get( "ram" );

		// writeDump( var = prc.defaultDisk.getProperties(), label = "Default" );
		// writeDump( var = prc.tempDisk.getProperties(), label = "Temp" );
		// writeDump( var = prc.ramDisk.getProperties(), label = "Ram" );
		// writeDump( var = prc.localDisk.getProperties(), label = "Local" );
	}

}
