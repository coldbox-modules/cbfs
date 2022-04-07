/**
 * Copyright 2013 Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Welcome to the world of file abstractions
 */
component {

	// Module Properties
	this.title          = "CB FileSystem";
	this.author         = "Ortus Solutions, Corp";
	this.webURL         = "https://github.com/ortus-solutions/cbfs";
	this.description    = "A powerfule filesystem abstraction module for ColdBox applications";
	// CF Mapping
	this.cfmapping      = "cbfs";
	this.modelNamespace = "cbfs";
	// Module Dependencies That Must Be Loaded First, use internal names or aliases
	this.dependencies   = [ "cbstreams" ];

	/**
	 * Configure this module
	 */
	function configure(){
		variables.DEFAULTS = {
			// The default disk with a reserved name of 'default'
			"defaultDisk" : "default",
			// Register the disks on the system
			"disks"       : {
				// Your default application storage
				"default" : {
					provider   : "LocalWeb",
					properties : { path : "#appMapping#/.cbfs", autoExpand : true }
				},
				// A disk that points to the CFML Engine's temp directory
				"temp" : {
					provider   : "LocalWeb",
					properties : { path : getTempDirectory() }
				}
			}
		};
		// Setup the defaults
		settings = structCopy( defaults );
		// Register custom DSL
		wirebox.registerDSL( "cbfs", "#moduleMapping#.dsl.cbfsDSL" );
	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad(){
		// Incorporate default disks
		settings.disks.append( variables.DEFAULTS.disks );
		// Register all app disks
		wirebox.getInstance( "DiskService@cbfs" ).registerAppDisks();
	}

	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload(){
	}

}
