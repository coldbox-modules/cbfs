/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This service manages all the discs in your system.
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component accessors="true" singleton {

	/**
	 * --------------------------------------------------------------------------
	 * Dependency Injection
	 * --------------------------------------------------------------------------
	 */
	property name="moduleSettings" inject="coldbox:moduleSettings:cbfs";
	property name="wirebox"        inject="wirebox";

	/**
	 * Struct that stores disk implementations
	 */
	property name="disks" type="struct";

	/**
	 * A struct containing all the disks registered in the application
	 */
	property name="diskRegistry" type="struct";

	/**
	 * Constructor
	 */
	function init(){
		// Init the disks
		variables.disks        = {};
		variables.diskRegistry = {};
		return this;
	}

	/**
	 * Called by the afterAspectsLoad interception to register all global and module disks
	 */
	function registerDisks(){
	}

	/**
	 * Shutdown all disks that are registered in the service
	 */
	DiskService function shutdown(){
		names().each( function( diskName ){
			unregister( arguments.diskName );
		} );
		return this;
	}

	/**
	 * Get a registered disk instance
	 *
	 * @name The name of the disk
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws InvalidDiskException - When the disk name is not registered
	 */
	function get( required name ){
		// Check if the disk is registered, else throw exception
		if ( missing( arguments.name ) ) {
			throw(
				message: "The disk you requested (#arguments.name#) has not been registered",
				detail : "Registered disks are: #names().toList()#",
				type   : "InvalidDiskException"
			)
		}

		// Check if it's built, else build and return
		if ( variables.disks.keyExists( arguments.name ) ) {
			return variables.disks[ arguments.name ];
		}

		// Else build, startup and return;
		variables.disks[ arguments.name ] = buildDisk( variables.diskRegistry[ arguments.name ].provider ).startup(
			arguments.name,
			variables.diskRegistry[ arguments.name ].properties
		);

		return variables.disks[ arguments.name ];
	}

	/**
	 * Register a new disk blueprint with the service
	 *
	 * @disk     The disk instance to register: cbfs.models.IDisk
	 * @override If true, then we override if it exists, else return the previously registered disk
	 */
	DiskService function register(
		required name,
		required provider,
		struct properties = {},
		boolean override  = false
	){
		// If it doesn't exist or we are overriding, register it
		if ( !variables.diskRegistry.keyExists( arguments.name ) || arguments.override ) {
			variables.diskRegistry[ arguments.name ] = {
				provider   : arguments.provider,
				properties : arguments.properties,
				instance   : javacast( "null", "" )
			};
		}

		return this;
	}

	/**
	 * Unregister a disk by name from the service will shut it down, and remove it
	 *
	 * @name The name of the disk to unregister
	 *
	 * @throws InvalidDiskException - When the name passed is not found in the registry
	 */
	DiskService function unregister( required name ){
		if ( !has( arguments.name ) ) {
			throw(
				message: "The disk (#arguments.name#) has not been registered",
				detail : "Registered disks are: #names().toList()#",
				type   : "InvalidDiskException"
			);
		}

		// Shutdown the disk if it was every built
		if ( variables.disks.keyExists( arguments.name ) ) {
			variables.disks[ arguments.name ].shutdown();
		}
		// Unregister it
		variables.disks.delete( arguments.name );
		variables.diskRegistry.delete( arguments.name );
		return this;
	}

	/**
	 * Has the passed disk name been registered in this service
	 *
	 * @name The name of the disk
	 */
	boolean function has( required name ){
		return variables.diskRegistry.keyExists( arguments.name );
	}

	/**
	 * Verifies if the incoming disk is missing from the registration
	 *
	 * @name The name of the disk
	 */
	boolean function missing( required name ){
		return !this.has( arguments.name );
	}

	/**
	 * Get a listing of all registered disks
	 */
	array function names(){
		return variables.diskRegistry.keyArray();
	}

	/**
	 * Count all the registered disks
	 */
	numeric function count(){
		return variables.diskRegistry.count();
	}

	function getDefaultDisk(){
	}

	function getTempDisk(){
	}

	/**
	 * Build a core or custom disk provider
	 *
	 * @provider The core provider or wirebox id or class path
	 *
	 * @return cbfs.models.IDisk
	 */
	private function buildDisk( required provider ){
		// is this core?
		if ( getRegisteredCoreProviders().keyExists( arguments.provider ) ) {
			arguments.provider = variables.registeredCoreProviders[ arguments.provider ];
		}
		// Build it out
		return variables.wirebox.getInstance( arguments.provider );
	}

	/**
	 * Get's the struct of registered disk providers lazily
	 */
	private function getRegisteredCoreProviders(){
		if ( isNull( variables.registeredCoreProviders ) ) {
			// Providers Path
			variables.providersPath           = getDirectoryFromPath( getMetadata( this ).path ) & "providers";
			// Register core disk providers
			variables.registeredCoreProviders = directoryList(
				variables.providersPath,
				false,
				"name",
				"*.cfc"
			)
				// Purge extension
				.map( function( item ){
					return listFirst( item, "." );
				} )
				// Build out wirebox mapping
				.reduce( function( result, item ){
					arguments.result[ arguments.item.replaceNoCase( "Provider", "" ) ] = "#arguments.item#@cbfs";
					return arguments.result;
				}, {} );
		}

		return variables.registeredCoreProviders;
	}

}
