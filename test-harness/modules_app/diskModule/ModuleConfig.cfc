/**
 * Copyright 2013 Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 */
component {

	/**
	 * Configure this module
	 */
	function configure(){
		settings = {
			// CBFS Module
			cbfs : {
				// Disks that will be namespaced with the module name @diskModule
				disks : {
					"temp" : { provider : "Mock" },
					"nasa" : { provider : "mock" }
				},
				// No namespace in global spacing
				globalDisks : {
					// Should be ignored, you can't override if it exists
					"temp" : { provider : "Mock" },
					"nasa" : { provider : "mock" }
				}
			}
		};
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
