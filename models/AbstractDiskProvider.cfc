/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This is an abstraction of how all disks should behave or at least give
 * basic behavior.
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component accessors="true" {

	/**
	 * The unique identifier for this disk. Usually a UUID
	 */
	property name="identifier" type="string";

	/**
	 * The name of the disk
	 */
	property name="name" type="string";

	/**
	 * The properties bound to this disk
	 */
	property name="properties" type="struct";

	/**
	 * This bit is used to tell if the disk has been started or not
	 */
	property
		name   ="started"
		type   ="boolean"
		default="false";

	/**
	 * --------------------------------------------------------------------------
	 * Dependency Injection
	 * --------------------------------------------------------------------------
	 */
	property name="streamBuilder" inject="StreamBuilder@cbstreams";

	/**
	 * Constructor
	 */
	function init(){
		variables.identifier = createUUID();
		variables.started    = false;
		variables.name       = "";
		variables.properties = {};
		return this;
	}

	/**
	 * Check if this disk has been started or not.
	 */
	boolean function hasStarted(){
		return variables.started;
	}

	/**
	 * Called before the cbfs module is unloaded, or via reinits. This can be implemented
	 * as you see fit to gracefully shutdown connections, sockets, etc.
	 *
	 * @return cbfs.models.IDisk
	 */
	function shutdown(){
		variables.started = false;
		return this;
	}

	/**
	 * Generate checksum for a file in different hashing algorithms
	 *
	 * @path      The file path
	 * @algorithm Default is MD5, but SHA-1, SHA-256, and SHA-512 can also be used.
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function checksum( required path, algorithm = "MD5" ){
		ensureFileExists( arguments.path );
		return hash( this.get( arguments.path ), arguments.algorithm );
	}

	/**
	 * Extract the file name from a file path
	 *
	 * @path The file path
	 */
	string function name( required path ){
		return listLast( arguments.path, "/" );
	}

	/**
	 * Extract the extension from the file path
	 *
	 * @path The file path
	 */
	string function extension( required path ){
		if ( listLen( this.name( arguments.path ), "." ) > 1 ) {
			return listLast( this.name( arguments.path ), "." );
		} else {
			return "";
		}
	}

	/************************* PRIVATE METHODS *******************************/

	/**
	 * Check if is Windows
	 */
	private function isWindows(){
		var system = createObject( "java", "java.lang.System" );
		return reFindNoCase( "Windows", system.getProperties()[ "os.name" ] );
	}

}
