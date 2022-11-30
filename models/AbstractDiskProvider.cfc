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
	variables.VISIBILITY_ATTRIBUTE = {
		"public"   : "normal",
		"private"  : "hidden",
		"readonly" : "readonly"
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
	 * Validate if a file doesn't exist
	 *
	 * @path The file path to verify
	 */
	boolean function missing( required string path ){
		return !exists( arguments.path );
	}

	/**
	 * Validate if a directory doesn't exist
	 *
	 * @path The directory path to verify
	 */
	boolean function directoryExists( required string path ){
		return exists( arguments.path );
	}

	/**
	 * Validate if a directory doesn't exist
	 *
	 * @path The directory path to verify
	 */
	boolean function directoryMissing( required string path ){
		return !this.directoryExists( arguments.path );
	}

	/**
	 * Uploads a file in to the disk
	 *
	 * @fieldName The file field name
	 * @directory the directory on disk to upload to
	 * @fileName  optional file name on the disk
	 * @overwrite whether to overwrite ( defaults to false )
	 */
	function upload(
		required fieldName,
		required directory,
		string fileName,
		string overwrite = false
	){
		var tmpDirectory = getTempDirectory();

		var upload = fileUpload(
			tmpDirectory,
			arguments.fieldName,
			variables.properties.keyExists( "uploadMimeAccept" ) ? variables.properties.uploadMimeAccept : "*",
			"makeunique"
		);

		var tmpFile  = tmpDirectory & upload.serverFile;
		var filePath = arguments.directory & "/" & ( arguments.fileName ?: upload.clientFile );

		try {
			create(
				path     = filePath,
				contents = !isBinaryFile( tmpFile )
				 ? fileRead( tmpFile )
				 : fileReadBinary( tmpFile ),
				overwrite = arguments.overwrite
			);
		} finally {
			fileDelete( tmpFile );
		}

		return this;
	}

	/************************* UTILITY METHODS *******************************/

	/**
	 * Normalize and cleanup file paths for consistency and remove leading slashes
	 *
	 * @path The path to clean
	 */
	function normalizePath( path ){
		return listToArray(
			replace( arguments.path, "\", "/", "all" ).replace( "//", "/", "all" ).reReplace( "\/$", "" )
		).toList( "/" );
	}

	/**
	 * Check if is Windows
	 */
	function isWindows(){
		return reFindNoCase( "Windows", variables.javaSystem.getProperties()[ "os.name" ] );
	}

	/**
	 * Check if is Linux
	 */
	function isLinux(){
		return reFindNoCase( "Linux", variables.javaSystem.getProperties()[ "os.name" ] );
	}

	/**
	 * Check if is Mac
	 */
	function isMac(){
		return reFindNoCase( "Mac", variables.javaSystem.getProperties()[ "os.name" ] );
	}

	/**
	 * Find out the mime type of a path
	 *
	 * @path The file path to check
	 */
	function getMimeType( required path ){
		return variables.javaUrlConnection.guessContentTypeFromName( arguments.path );
	}

	/**
	 * Verify if a file path is binary file or not
	 *
	 * @path The file path to check
	 */
	boolean function isBinaryFile( required path ){
		var type = getMimeType( arguments.path ) ?: "binary";
		return type.listFirst( "/" ).findnocase( "text" ) ? false : true;
	}

}
