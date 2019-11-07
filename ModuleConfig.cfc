/**
 * Copyright 2013 Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Welcome to the world of file abstraction
 */
component {

	// Module Properties
	this.title 				= "CB FileSystem";
	this.author 			= "Ortus Solutions, Corp";
	this.webURL 			= "https://github.com/ortus-solutions/cbfs";
	this.description 		= "A powerfule filesystem abstraction module for ColdBox applications";
	// CF Mapping
	this.cfmapping			= "cbfs";
	this.modelNamespace 	= "cbfs";
	// Module Dependencies That Must Be Loaded First, use internal names or aliases
	this.dependencies		= [ "cbstreams" ];

	/**
	* Configure this module
	*/
	function configure() {
        settings = {
            "disks": {}
        };
        binder.getInjector().registerDSL( "cbfs", "#moduleMapping#.models.dsl.cbfsDSL" );
	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
	}

}
