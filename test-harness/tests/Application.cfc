/**
********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************
*/
component {

	// UPDATE THE NAME OF THE MODULE IN TESTING BELOW
	request.MODULE_NAME = "cbfs";
	request.MODULE_PATH = "cbfs";

	this.name               = "CBFS Testing Harness" & hash( getCurrentTemplatePath() );
	this.sessionManagement  = true;
	this.setClientCookies   = true;
	this.clientManagement   = true;
	this.sessionTimeout     = createTimespan( 0, 0, 10, 0 );
	this.applicationTimeout = createTimespan( 0, 0, 10, 0 );
	this.timezone           = "UTC";
	this.enableNullSupport  = shouldEnableFullNullSupport();

	// Turn on/off white space management
	this.whiteSpaceManagement = "smart";

	// setup test path
	this.mappings[ "/tests" ] = getDirectoryFromPath( getCurrentTemplatePath() );
	// setup root path
	rootPath                  = reReplaceNoCase( this.mappings[ "/tests" ], "tests(\\|/)", "" );

	this.mappings[ "/root" ] = rootPath;


	// The module root path
	moduleRootPath = reReplaceNoCase(
		rootPath,
		"#request.MODULE_PATH#(\\|/)test-harness(\\|/)",
		""
	);

	this.mappings[ "/moduleroot" ]            = moduleRootPath;
	this.mappings[ "/#request.MODULE_NAME#" ] = moduleRootPath & "#request.MODULE_NAME#";
	this.mappings[ "/s3sdk" ]                 = moduleRootPath & "#request.MODULE_NAME#" & "/modules/s3sdk";

	public boolean function onRequestStart( targetPage ){
		// Set a high timeout for long running tests
		setting requestTimeout   ="9999";
		// New ColdBox Virtual Application Starter
		request.coldBoxVirtualApp= new coldbox.system.testing.VirtualApp();

		// If hitting the runner or specs, prep our virtual app and database
		if ( getBaseTemplatePath().replace( expandPath( "/tests" ), "" ).reFindNoCase( "(runner|specs)" ) ) {
			request.coldBoxVirtualApp.startup();
		}

		// ORM Reload for fresh results
		if ( structKeyExists( url, "fwreinit" ) ) {
			if ( structKeyExists( server, "lucee" ) ) {
				pagePoolClear();
			}
			ormReload();
			request.coldBoxVirtualApp.restart();
		}

		return true;
	}

	public void function onRequestEnd( required targetPage ){
		request.coldBoxVirtualApp.shutdown();
	}

	private boolean function shouldEnableFullNullSupport(){
		var system = createObject( "java", "java.lang.System" );
		var value  = system.getEnv( "FULL_NULL" );
		return isNull( value ) ? false : !!value;
	}

}
