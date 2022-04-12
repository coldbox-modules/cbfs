/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This is an abstraction of how all disks should behave or at least give basic behavior.
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
	property name="log"           inject="logbox:logger:{this}";

	/**
	 * --------------------------------------------------------------------------
	 * Static Defaults
	 * --------------------------------------------------------------------------
	 */
	variables.PERMISSIONS = {
		"file" : { "public" : "666", "private" : "000", "readonly" : "444" },
		"dir"  : { "public" : "666", "private" : "600", "readonly" : "644" }
	};

	/**
	 * Constructor
	 */
	function init(){
		variables.identifier        = createUUID();
		variables.started           = false;
		variables.name              = "";
		variables.properties        = {};
		variables.javaSystem        = createObject( "java", "java.lang.System" );
		variables.javaUrlConnection = createObject( "java", "java.net.URLConnection" );
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
	 * Extract the file name from a passed file path
	 *
	 * @path The file path
	 */
	string function name( required path ){
		return getFileFromPath( arguments.path );
	}

	/**
	 * Extract the extension from the file path
	 *
	 * @path The file path
	 */
	string function extension( required path ){
		var fileName = this.name( arguments.path );
		return ( listLen( fileName, "." ) ? listLast( fileName, "." ) : "" );
	}

	/**
	 * Validate if a file/directory doesn't exist
	 *
	 * @path The file/directory path to verify
	 */
	boolean function missing( required string path ){
		return !this.exists( arguments.path );
	}

	/************************* PRIVATE METHODS *******************************/

	/**
	 * Check if is Windows
	 */
	private function isWindows(){
		return reFindNoCase( "Windows", variables.javaSystem.getProperties()[ "os.name" ] );
	}

	/**
	 * Check if is Linux
	 */
	private function isLinux(){
		return reFindNoCase( "Linux", variables.javaSystem.getProperties()[ "os.name" ] );
	}

	/**
	 * Check if is Mac
	 */
	private function isMac(){
		return reFindNoCase( "Mac", variables.javaSystem.getProperties()[ "os.name" ] );
	}

	/**
	 * Find out the mime type of a path
	 */
	private function getMimeType( required path ){
		return variables.javaUrlConnection.guessContentTypeFromName( arguments.path );
	}

}
