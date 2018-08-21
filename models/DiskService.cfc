/**
 * This service manages all the discs in your system.
 * On load this service should store the disc configuration and lazy load storage discs
 */
component accessors="true"{

	// DI
	property name="moduleSettings" inject="coldbox:moduleSettings:cbfs";

	/**
	 * Struct that stores disk implementations
	 */
	property name="disks" type="struct";

	/**
	 * Constructor
	 */
	function init(){
		variables.disks = {};
		return this;
	}


}