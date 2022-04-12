/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This provider is useful for mocking purposes. They all go into a memory array
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component
	accessors="true"
	extends  ="cbfs.models.AbstractDiskProvider"
	singleton
{

	/**
	 * Mocking container
	 */
	property name="files" type="struct";

	this.nonWritablePaths = {};
	this.nonReadablePaths = {};

	/**
	 * Startup the local provider
	 *
	 * @name       The name of the disk
	 * @properties A struct of configuration data for this provider, usually coming from the configuration file
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws InvalidPropertyException - On any configuration property exception
	 */
	function startup( required string name, struct properties = {} ){
		variables.name       = arguments.name;
		variables.properties = arguments.properties;
		variables.started    = true;
		variables.files      = {};
		return this;
	}

	/**
	 * Called before the cbfs module is unloaded, or via reinits. This can be implemented
	 * as you see fit to gracefully shutdown connections, sockets, etc.
	 *
	 * @return cbfs.models.IDisk
	 */
	any function shutdown(){
		variables.files   = {};
		variables.started = false;
		return this;
	}

	/**
	 * Create a file in the disk
	 *
	 * @path       The file path to use for storage
	 * @contents   The contents of the file to store
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 * @metadata   Struct of metadata to store with the file
	 * @overwrite  Flag to overwrite the file at the destination, if it exists. Defaults to true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileOverrideException - When a file exists and no override has been provided
	 */
	function create(
		required path,
		required contents,
		visibility        = "public",
		struct metadata   = {},
		boolean overwrite = false
	){
		if ( !arguments.overwrite && this.exists( arguments.path ) ) {
			throw(
				type    = "cbfs.FileOverrideException",
				message = "Cannot create file. File already exists [#arguments.path#]"
			);
		}
		var fileName                      = this.name( arguments.path );
		variables.files[ arguments.path ] = {
			"path"         : arguments.path,
			"contents"     : arguments.contents,
			"visibility"   : arguments.visibility,
			"lastModified" : now(),
			"size"         : len( arguments.contents ),
			"name"         : fileName,
			"type"         : createObject( "java", "java.net.URLConnection" ).guessContentTypeFromName( fileName ),
			"canWrite"     : true,
			"canRead"      : true,
			"isHidden"     : false,
			"metadata"     : arguments.metadata
		};
		return this;
	}

	/**
	 * Set the storage visibility of a file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 *
	 * @path       The target file
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function setVisibility( required string path, required string visibility ){
		if ( this.exists( arguments.path ) ) {
			variables.files[ arguments.path ].visibility = arguments.visibility;
		} else {
			throw(
				message: "The file requested (#arguments.path#) doesn't exist",
				type   : "cbfs.FileNotFoundException"
			);
		}
		return this;
	};

	/**
	 * Get the storage visibility of a file, the return format can be a string of `public, private, readonly` or a custom data type the implemented driver can interpret.
	 *
	 * @path The target file
	 *
	 * @return The visibility of the requested file
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	public string function visibility( required string path ){
		if ( this.exists( arguments.path ) ) {
			return variables.files[ arguments.path ].visibility;
		} else {
			throw(
				message: "The file requested (#arguments.path#) doesn't exist",
				type   : "cbfs.FileNotFoundException"
			);
		}
	}

	/**
	 * Prepend contents to the beginning of a file. If the file is missing and the throwOnMissing if false
	 * We will create the file with the contents provided.
	 *
	 * @path           The file path to use for storage
	 * @contents       The contents of the file to prepend
	 * @metadata       Struct of metadata to store with the file
	 * @throwOnMissing Boolean flag to throw if the file is missing. Otherwise it will be created if missing.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function prepend(
		required string path,
		required contents,
		struct metadata        = {},
		boolean throwOnMissing = false
	){
		if ( missing( arguments.path ) ) {
			if ( arguments.throwOnMissing ) {
				throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
			}
			return create(
				path     = arguments.path,
				contents = arguments.contents,
				metadata = arguments.metadata
			);
		}
		variables.files[ arguments.path ].contents = arguments.contents & variables.files[ arguments.path ].contents;
		variables.files[ arguments.path ].metadata.append( arguments.metadata, true );
		return this;
	}

	/**
	 * Append contents to the end of a file. If the file is missing and the throwOnMissing if false
	 * We will create the file with the contents provided.
	 *
	 * @path           The file path to use for storage
	 * @contents       The contents of the file to append
	 * @metadata       Struct of metadata to store with the file
	 * @throwOnMissing Boolean flag to throw if the file is missing. Otherwise it will be created if missing.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function append(
		required string path,
		required contents,
		struct metadata        = {},
		boolean throwOnMissing = false
	){
		if ( missing( arguments.path ) ) {
			if ( arguments.throwOnMissing ) {
				throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
			}
			return create(
				path     = arguments.path,
				contents = arguments.contents,
				metadata = arguments.metadata
			);
		}
		variables.files[ arguments.path ].contents = variables.files[ arguments.path ].contents & arguments.contents;
		variables.files[ arguments.path ].metadata.append( arguments.metadata, true );
		return this;
	}

	/**
	 * Copy a file from one destination to another
	 *
	 * @source      The source file path
	 * @destination The end destination path
	 * @overwrite   Flag to overwrite the file at the destination, if it exists. Defaults to true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function copy(
		required source,
		required destination,
		boolean overwrite = true
	){
		return create(
			path      = arguments.destination,
			contents  = get( arguments.source ),
			overwrite = arguments.overwrite
		);
	}

	/**
	 * Move a file from one destination to another
	 *
	 * @source      The source file path
	 * @destination The end destination path
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function move(
		required source,
		required destination,
		boolean overwrite = true
	){
		create(
			path      = arguments.destination,
			contents  = get( arguments.source ),
			overwrite = arguments.overwrite
		);
		return delete( arguments.source );
	}

	/**
	 * Rename a file from one destination to another. Shortcut to the `move()` command
	 *
	 * @source      The source file path
	 * @destination The end destination path
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function rename(
		required source,
		required destination,
		boolean overwrite = false
	){
		return move( argumentCollection = arguments );
	}

	/**
	 * Get the contents of a file
	 *
	 * @path The file path to retrieve
	 *
	 * @return The contents of the file
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function get( required path ){
		return ensureFileExists( arguments.path ).contents;
	}

	/**
	 * Get the contents of a file as binary
	 *
	 * @path The file path to retrieve
	 *
	 * @return A binary representation of the file
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function getAsBinary( required path ){
		return toBinary( toBase64( get( arguments.path ) ) );
	}

	/**
	 * Validate if a file/directory exists
	 *
	 * @path The file/directory path to verify
	 */
	boolean function exists( required string path ){
		for ( var existingPath in variables.files.keyArray() ) {
			if ( find( arguments.path, existingPath ) == 1 ) {
				return true;
			}
		}
		return false;
	}

	/**
	 * Get the URL for the given file
	 *
	 * @path The file path to build the URL for
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function url( required string path ){
		return ensureFileExists( arguments.path ).path;
	}

	/**
	 * Get a temporary URL for the given file
	 *
	 * @path       The file path to build the URL for
	 * @expiration The number of minutes this URL should be valid for.
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function temporaryURL( required path, numeric expiration ){
		return this.url( arguments.path );
	}

	/**
	 * Retrieve the size of the file in bytes
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	numeric function size( required path ){
		return len( get( arguments.path ) );
	}

	/**
	 * Retrieve the file's last modified timestamp
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function lastModified( required path ){
		return ensureFileExists( arguments.path ).lastModified;
	}

	/**
	 * Retrieve the file's mimetype
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function mimeType( required path ){
		return getMimeType( ensureFileExists( arguments.path ).path );
	}

	/**
	 * Delete a file or an array of file paths. If a file does not exist a `false` will be
	 * shown for it's return.
	 *
	 * @path           A single file path or an array of file paths
	 * @throwOnMissing Boolean to throw an exception if the file is missing.
	 *
	 * @return boolean or struct report of deletion
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	public boolean function delete( required any path, boolean throwOnMissing = false ){
		if ( missing( arguments.path ) ) {
			if ( arguments.throwOnMissing ) {
				throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
			}
			return false;
		}
		variables.files.delete( arguments.path );
		return true;
	}

	/**
	 * Create a new empty file if it does not exist
	 *
	 * @path       The file path
	 * @createPath if set to false, expects all parent directories to exist, true will generate necessary directories. Defaults to true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.PathNotFoundException
	 */
	function touch( required path, boolean createPath = true ){
		if ( exists( arguments.path ) ) {
			variables.files[ arguments.path ].lastModified = now();
			return this;
		}
		if ( !arguments.createPath ) {
			if ( !this.exists( getDirectoryFromPath( arguments.path ) ) ) {
				throw(
					type    = "cbfs.PathNotFoundException",
					message = "Directory does not already exist and the `createPath` flag is set to false"
				);
			}
		}
		return create( arguments.path, "" );
	}

	/**
	 * Return information about the file.  Will contain keys such as lastModified, size, path, name, type, canWrite, canRead, isHidden and more
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	struct function info( required path ){
		ensureFileExists( arguments.path );
		return variables.files[ arguments.path ];
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
		return listLast( this.name( arguments.path ), "." );
	}

	/**
	 * Is the path a file or not
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	boolean function isFile( required path ){
		ensureFileExists( arguments.path );
		return variables.files.keyExists( arguments.path );
	}

	/**
	 * Is the path writable or not
	 *
	 * @path The file path
	 */
	boolean function isWritable( required path ){
		return !this.nonWritablePaths.keyExists( arguments.path );
	}

	/**
	 * Is the path readable or not
	 *
	 * @path The file path
	 */
	boolean function isReadable( required path ){
		return !this.nonReadablePaths.keyExists( arguments.path );
	}

	/**
	 * Delete 1 or more directory locations
	 *
	 * @directory      The directory or an array of directories
	 * @recurse        Recurse the deletion or not, defaults to true
	 * @throwOnMissing Throws an exception if the directory does not exist
	 *
	 * @return A boolean value or a struct of booleans determining if the directory paths got deleted or not.
	 */
	public boolean function deleteDirectory(
		required string directory,
		boolean recurse        = true,
		boolean throwOnMissing = false
	){
		for ( var filePath in variables.files ) {
			if ( !find( arguments.directory, filePath ) > 0 ) {
				return false;
			}
			variables.files.delete( filePath );
		}
		return true;
	}

	/**
	 * This checks if the file path is missing. If it does, it throws an exception, else continues operation.
	 *
	 * @path The path to check
	 *
	 * @return The mocked file structure
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	private struct function ensureFileExists( required path ){
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		return variables.files[ arguments.path ];
	}

}
