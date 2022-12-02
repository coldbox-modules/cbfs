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

	function testUpload( event, rc, prc ){
		if ( event.getHTTPMethod() == "POST" ) {
			cbfs()
				.getDisks()
				.keyArray()
				.each( function( disk ){
					var activeDisk    = cbfs().get( disk );
					var fileExtension = activeDisk.extension(
						getPageContext()
							.formScope()
							.getUploadResource( "uploadField" )
							.getName()
					);
					// test direct upload
					activeDisk.upload( "uploadField", createUUID() );
					// test with custom file name
					var overwriteDirectory = createUUID();
					activeDisk.upload(
						"uploadField",
						overwriteDirectory,
						"myFile.#fileExtension#"
					);
					// test with overwrite
					activeDisk.upload(
						"uploadField",
						overwriteDirectory,
						"myFile.#fileExtension#",
						true
					);
					// test the error handling
					try {
						activeDisk.upload(
							"uploadField",
							overwriteDirectory,
							"myFile.#fileExtension#",
							false
						);
					} catch ( cbfs.FileOverrideException e ) {
					}
				} );
		}
	}

	function testDownload( event, rc, prc ){
		param rc.disk = "local";
		var activeDisk = cbfs().get( rc.disk );
		var testFile = expandPath( '/tests/resources/assets/binary_file.png' );
		var directory = createUUID();
		var filename = createUUID() & "." & activeDisk.extension( testFile );
		activeDisk.createFromFile( testFile, directory, filename );
		activeDisk.download( directory & "/" & filename );
	}

}
