/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This service manages all the disks in your ColdBox application.
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component accessors="true" singleton threadsafe {

	/**
	 * --------------------------------------------------------------------------
	 * Dependency Injection
	 * --------------------------------------------------------------------------
	 */
	property name="appModules"     inject="coldbox:setting:modules";
	property name="moduleSettings" inject="coldbox:moduleSettings:cbfs";
	property name="moduleConfig"   inject="coldbox:moduleConfig:cbfs";
	property name="wirebox"        inject="wirebox";
	property name="log"            inject="logbox:logger:{this}";

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
	DiskService function registerAppDisks(){
		return registerDiskMap( diskMap: variables.moduleSettings.disks );
	}

	/**
	 * Registers all disks from the incoming struct according to our rules
	 *
	 * @diskMap   The disk metadata structure to register
	 * @namespace The namespeace to use when registering
	 */
	private function registerDiskMap( required struct diskMap, string namespace = "" ){
		arguments.diskMap.each( function( diskName, diskDefinition ){
			param name="arguments.diskDefinition.properties" default="#structNew()#";
			register(
				name      : arguments.diskName & namespace,
				provider  : arguments.diskDefinition.provider,
				properties: arguments.diskDefinition.properties
			);
		} );
		return this;
	}

	/**
	 * Called by the ModuleConfig to register all the ColdBox module disks defined
	 */
	DiskService function registerModuleDisks(){
		variables.appModules
			// Discover cbfs enabled modules
			.filter( function( module, config ){
				return arguments.config.settings.keyExists( "cbfs" );
			} )
			// Register the disks
			.each( function( module, config ){
				param name="arguments.config.settings.cbfs.disks"       default="#structNew()#";
				param name="arguments.config.settings.cbfs.globalDisks" default="#structNew()#";
				registerDiskMap( diskMap: arguments.config.settings.cbfs.disks, namespace: "@#module#" );
				registerDiskMap( diskMap: arguments.config.settings.cbfs.globalDisks );
			} );
		return this;
	}

	/**
	 * Shutdown all disks that are registered in the service
	 */
	DiskService function shutdown(){
		log.info( "Starting Shutdown for cbfs.DiskService..." );
		names().each( function( diskName ){
			unregister( arguments.diskName );
		} );
		log.info( "Shutdown complete for cbfs.DiskService" );
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
					log.debug( "Disk (#arguments.name#) not built, building it now." );
					diskRecord.disk = buildDisk( provider: diskRecord.provider ).startup(
						name      : arguments.name,
						properties: diskRecord.properties
					);
					diskRecord.createdOn = now();
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
				"name"         : arguments.name,
				"provider"     : arguments.provider,
				"properties"   : arguments.properties,
				"disk"         : javacast( "null", "" ),
				"registeredOn" : now(),
				"createdOn"    : ""
			};
			log.info( "- Registered (#arguments.name#:#arguments.provider#) disk." );
		} else {
			log.warn( "- Ignored registration for (#arguments.name#) disk as it was already registered." );
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
		var diskRecord = getDiskRecord( arguments.name );

		// Shutdown the disk if it was every built
		if ( !isNull( diskRecord.disk ) ) {
			diskRecord.disk.shutdown();
		}

		// Unregister it
		variables.disks.delete( arguments.name );

		log.info( "Disk (#arguments.name#) sucessfully shutdown and unregistered" );
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
		var names = variables.disks.keyArray();
		// Dumb ACF 2016 Member function
		names.sort( "textNocase" );
		return names;
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
	function defaultDisk(){
		return get( variables.moduleSettings.defaultDisk );
	}

	/**
	 * Get the temp disk using the key <pre>temp</pre>
	 */
	function tempDisk(){
		return get( "temp" );
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
			variables.providersPath           = variables.moduleConfig.modelsPhysicalPath & "/providers";
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
