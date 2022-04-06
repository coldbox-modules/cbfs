/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This service manages all the disks in your ColdBox application.
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
	 * Struct that stores disk registration and instance data. Each disk will have the following entry:
	 * <pre>
	 * {
	 *     	provider : name or class,
	 * 		properties : struct of properties
	 * 		disk : null or the lazy loaded disk instance
	 * }
	 * </pre>
	 */
	property name="disks" type="struct";

	/**
	 * Constructor
	 */
	function init(){
		// Init the disks
		variables.disks = {};
		return this;
	}

	/**
	 * Called by the ModuleConfig to register all the ColdBox app disks defined
	 */
	function registerAppDisks(){
		writeDump( var = variables.moduleSettings.disks, top = 5 );
		abort;
		variables.moduleSettings.disks.each( function( diskName, diskDefinition ){
			this.register(
				name      : arguments.diskName,
				provider  : arguments.diskDefinition.provider,
				properties: arguments.diskDefinition.properties
			);
		} );
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
	 * Get a registered disk instance by name
	 *
	 * @name The name of the disk
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws InvalidDiskException - When the disk name is not registered
	 */
	function get( required name ){
		var diskRecord = getDiskRecord( arguments.name );

		// Lazy load the disk instance
		if ( isNull( diskRecord.disk ) ) {
			lock name="cbfs-create-#arguments.name#" type="exclusive" timeout="10" throwOnTimeout="true" {
				if ( isNull( diskRecord.disk ) ) {
					diskRecord.disk = buildDisk( provider: diskRecord.provider ).startup(
						name      : arguments.name,
						properties: diskRecord.properties
					);
				}
			}
		}

		return diskRecord.disk;
	}

	/**
	 * Get a registered disk record by name
	 *
	 * @name The name of the disk
	 *
	 * @return struct of { provider:string, properties:struct, disk:cbfs.models.IDisk }
	 *
	 * @throws InvalidDiskException - When the disk name is not registered
	 */
	struct function getDiskRecord( required name ){
		// Check if the disk is registered, else throw exception
		if ( missing( arguments.name ) ) {
			throw(
				message: "The disk you requested (#arguments.name#) has not been registered",
				detail : "Registered disks are: #names().toList()#",
				type   : "InvalidDiskException"
			)
		}
		return variables.disks[ arguments.name ];
	}

	/**
	 * Register a new disk blueprint with the service
	 *
	 * @name       The unique name to register the disk
	 * @provider   The core provider name or a provider class path or WireBox ID
	 * @properties The properties struct to startup the disk with
	 * @override   If true, if a disk with the same name is registered, we will override it. Else, we ignore the registration.
	 */
	DiskService function register(
		required name,
		required provider,
		struct properties = {},
		boolean override  = false
	){
		// If it doesn't exist or we are overriding, register it
		if ( !variables.disks.keyExists( arguments.name ) || arguments.override ) {
			variables.disks[ arguments.name ] = {
				"provider"   : arguments.provider,
				"properties" : arguments.properties,
				"disk"       : javacast( "null", "" )
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
		if ( !isNull( variables.disks[ arguments.name ].disk ) ) {
			variables.disks[ arguments.name ].disk.shutdown();
		}

		// Unregister it
		variables.disks.delete( arguments.name );
		return this;
	}

	/**
	 * Has the passed disk name been registered in this service
	 *
	 * @name The name of the disk
	 */
	boolean function has( required name ){
		return variables.disks.keyExists( arguments.name );
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
		return variables.disks.keyArray();
	}

	/**
	 * Count all the registered disks
	 */
	numeric function count(){
		return variables.disks.count();
	}

	/**
	 * Get the default disk according to your module setting <pre>defaultDisk</pre>
	 */
	function getDefaultDisk(){
		return this.get( variables.moduleSettings.defaultDisk );
	}

	/**
	 * Get the temp disk using the key <pre>temp</pre>
	 */
	function getTempDisk(){
		return this.get( "temp" );
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
