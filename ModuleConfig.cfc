/**
 * Copyright 2013 Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Welcome to the world of file abstractions
 */
component {

	// Module Properties
	this.title             = "CB FileSystem";
	this.author            = "Ortus Solutions, Corp";
	this.webURL            = "https://github.com/ortus-solutions/cbfs";
	this.description       = "A powerful file system abstraction module for ColdBox applications";
	this.version           = "@build.version@+@build.number@";
	// CF Mapping
	this.cfmapping         = "cbfs";
	this.modelNamespace    = "cbfs";
	// Module Dependencies That Must Be Loaded First, use internal names or aliases
	this.dependencies      = [ "cbstreams", "s3sdk" ];
	// Helpers
	this.applicationHelper = [ "helpers/Mixins.cfm" ];

	/**
	 * Configure this module
	 */
	function configure(){
		variables.DEFAULTS = {
			// The default disk with a reserved name of 'default'
			"defaultDisk" : "default",
			// Register the disks on the system
			"disks"       : {
				// Your default application storage : non-web accessible
				"default" : {
					provider   : "Local",
					properties : {
						path : getSystemSetting( "CBFS_DEFAULT_DISK_PATH", "#controller.getAppRootPath()#.cbfs" )
					}
				},
				// A public web-accessible storage located at /includes/public
				"public" : {
					provider   : "Local",
					properties : {
						path : getSystemSetting(
							"CBFS_PUBLIC_DISK_PATH",
							"#controller.getAppRootPath()#includes/public"
						),
						diskUrl : function(){
							return variables.controller
								.getRequestService()
								.getContext()
								.getHtmlBaseUrl() & "includes/public"
						}
					}
				},
				// A disk that points to the CFML Engine's temp directory
				"temp" : {
					provider   : "Local",
					properties : { path : getSystemSetting( "CBFS_TEMP_DISK_PATH", getTempDirectory() ) }
				}
			}
		};

		// Setup the defaults
		settings = structCopy( variables.DEFAULTS );

		// Disk Events
		interceptorSettings = {
			customInterceptionPoints : [
				"cbfsOnDiskStart",
				"cbfsOnDiskShutdown",
				"cbfsOnFileCreate",
				"cbfsOnFileMove",
				"cbfsOnFileCopy",
				"cbfsOnFileDelete",
				"cbfsOnFileInfoRequest",
				"cbfsOnFileMove",
				"cbfsOnDirectoryMove",
				"cbfsOnDirectoryCreate",
				"cbfsOnDirectoryCopy",
				"cbfsOnDirectoryDelete"
			]
		};

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
	 * Listen when modules are activated to load module disks
	 */
	function afterAspectsLoad( event, interceptData, rc, prc, buffer ){
		// Register all module disks
		wirebox.getInstance( "DiskService@cbfs" ).registerModuleDisks();
	}

	/**
	 * Listen when ColdBox Shutds down
	 */
	function onColdBoxShutdown( event, interceptData, rc, prc, buffer ){
		wirebox.getInstance( "DiskService@cbfs" ).shutdown();
	}

	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload(){
	}

}
