/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This is the DSL for WireBox to produce objects from cbfs
 *
 * cbfs => DiskService
 * cbfs:disks => The disk registry struct
 * cbfs:disks:{name} => The specified disk name
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component accessors="true" {

	property name="injector";

	/**
	 * Configure the DSL Builder for operation and returns itself
	 *
	 * @injector             The linked WireBox Injector
	 * @injector.doc_generic coldbox.system.ioc.Injector
	 *
	 * @return coldbox.system.ioc.dsl.IDSLBuilder
	 */
	function init( required any injector ){
		variables.injector = arguments.injector;
		return this;
	}

	/**
	 * Process an incoming DSL definition and produce an object with it
	 *
	 * @definition   The injection dsl definition structure to process. Keys: name, dsl
	 * @targetObject The target object we are building the DSL dependency for. If empty, means we are just requesting building
	 * @targetID     The target ID we are building this dependency for
	 *
	 * @return any
	 */
	function process( required definition, targetObject, targetID ){
		var dslSegments = listToArray( arguments.definition.dsl, ":" );
		var diskService = variables.injector.getInstance( "DiskService@cbfs" );

		switch ( arrayLen( dslSegments ) ) {
			// cbfs
			case 1:
				return diskService;
			// cbfs:disks
			case 2:
				return diskService.getDisks();
			// cbfs:disks:{name}
			case 3:
				return diskService.get( dslSegments[ 3 ] );
			default:
				throw(
					type    = "cbfs.IncorrectDslException",
					message = "No dsl available for [#arguments.definition.dsl#]."
				);
		}
	}

}
