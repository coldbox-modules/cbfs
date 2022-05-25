/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This provider is an in-memory provider that stores the file system in memory
 *
 * TODO: Move to concurrent hash maps
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component
	accessors="true"
	extends  ="cbfs.models.AbstractDiskProvider"
	singleton
{

	/**
	 * Ram container
	 */
	property name="files" type="struct";

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
	 * @mode       Applies to *nix systems. If passed, it overrides the visbility argument and uses these octal values instead
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileOverrideException - When a file exists and no override has been provided
	 */
	function create(
		required path,
		required contents,
		string visibility = "public",
		struct metadata   = {},
		boolean overwrite = true,
		string mode
	){
		// Normalize slashes
		arguments.path = replace( arguments.path, "\", "/", "all" );

		if ( !arguments.overwrite && this.exists( arguments.path ) ) {
			throw(
				type    = "cbfs.FileOverrideException",
				message = "Cannot create file. File already exists [#arguments.path#]"
			);
		}

		// Default mode if not passed using visibility
		if ( isNull( arguments.mode ) ) {
			arguments.mode = variables.PERMISSIONS.file[ arguments.visibility ];
		}

		var fileName                      = this.name( arguments.path );
		variables.files[ arguments.path ] = {
			"path"         : arguments.path,
			"contents"     : arguments.contents,
			"checksum"     : hash( arguments.contents ),
			"visibility"   : arguments.visibility,
			"lastModified" : now(),
			"size"         : len( arguments.contents ),
			"name"         : fileName,
			"mimetype"     : getMimeType( fileName ),
			"type"         : "File",
			"write"        : true,
			"read"         : true,
			"execute"      : true,
			"hidden"       : false,
			"metadata"     : arguments.metadata,
			"mode"         : arguments.mode,
			"symbolicLink" : false
		};

		// Do we need to create directory entries?
		if ( find( "/", arguments.path ) ) {
			createDirectory( getDirectoryFromPath( arguments.path ) );
		}

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
	 * Get the contents of a file
	 *
	 * @path The file path to retrieve
	 *
	 * @return The contents of the file
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function get( required path ){
		return ensureRecordExists( arguments.path ).contents;
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
		arguments.path = normalizePath( arguments.path );
		for ( var existingPath in variables.files.keyArray() ) {
			if ( find( arguments.path, existingPath ) == 1 ) {
				return true;
			}
		}
		return false;
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

	/**************************************** UTILITY METHODS ****************************************/

	/**
	 * Get the uri for the given file
	 *
	 * @path The file path to build the uri for
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function uri( required string path ){
		return ensureRecordExists( arguments.path ).path;
	}

	/**
	 * Get a temporary uri for the given file
	 *
	 * @path       The file path to build the uri for
	 * @expiration The number of minutes this uri should be valid for.
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function temporaryUri( required path, numeric expiration ){
		return this.uri( arguments.path ) & "?expiration=#arguments.expiration#";
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
		return ensureRecordExists( arguments.path ).lastModified;
	}

	/**
	 * Retrieve the file's mimetype
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function mimeType( required path ){
		return getMimeType( ensureRecordExists( arguments.path ).path );
	}

	/**
	 * Return information about the file.  Will contain keys such as lastModified, size, path, name, type, canWrite, canRead, isHidden and more
	 * depending on the provider used
	 *
	 * @path The file path
	 *
	 * @return A struct of file metadata according to provider
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	struct function info( required path ){
		return ensureRecordExists( arguments.path );
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
		return hash( ensureRecordExists( arguments.path ).contents, arguments.algorithm );
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
	 * Sets the access attributes of the file on Unix based disks
	 *
	 * @path The file path
	 * @mode Access mode, the same attributes you use for the Linux command `chmod`
	 *
	 * @return cbfs.models.IDisk
	 */
	function chmod( required string path, required string mode ){
		ensureRecordExists( arguments.path ).mode = arguments.mode;
		return this;
	}

	/**
	 * Create a symbolic link in the system if it supports it.
	 *
	 * The target parameter is the target of the link. It may be an absolute or relative path and may not exist. When the target is a relative path then file system operations on the resulting link are relative to the path of the link.
	 *
	 * @link   The path of the symbolic link to create
	 * @target The target of the symbolic link
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException    - if the target does not exist
	 * @throws UnsupportedOperationException - if the implementation does not support symbolic links
	 */
	function createSymbolicLink( required link, required target ){
		variables.files[ arguments.link ] = ensureRecordExists( arguments.target )
			.duplicate()
			.append( { symbolicLink : true } );
		return this;
	}

	/**************************************** VERIFICATION METHODS ****************************************/

	/**
	 * Verifies if the passed path is an existent file
	 *
	 * @path The file path
	 */
	boolean function isFile( required path ){
		arguments.path = normalizePath( arguments.path );
		return missing( arguments.path ) ? false : variables.files[ arguments.path ].type == "File";
	}

	/**
	 * Is the path writable or not
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	boolean function isWritable( required path ){
		return ensureRecordExists( arguments.path ).visibility == "public";
	}

	/**
	 * Is the path readable or not
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	boolean function isReadable( required path ){
		return isWritable( arguments.path ) || ensureRecordExists( arguments.path ).visibility == "readonly";
	}

	/**
	 * Is the file executable or not
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	boolean function isExecutable( required path ){
		return true;
	}

	/**
	 * Is the file is hidden or not
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	boolean function isHidden( required path ){
		return ensureRecordExists( arguments.path ).visibility == "private";
	}

	/**
	 * Is the file is a symbolic link
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	boolean function isSymbolicLink( required path ){
		return ensureRecordExists( arguments.path ).symbolicLink;
	}

	/**************************************** DIRECTORY METHODS ****************************************/

	/**
	 * Is the path a directory or not
	 *
	 * @path The directory path
	 */
	boolean function isDirectory( required path ){
		arguments.path = normalizePath( arguments.path );
		return missing( arguments.path ) ? false : variables.files[ arguments.path ].type == "Directory";
	}

	/**
	 * Create a new directory
	 *
	 * @directory    The directory path to be created
	 * @createPath   Create parent directory paths when they do not exist. The default is true
	 * @ignoreExists If false, it will throw an error if the directory already exists, else it ignores it if it exists. This should default to true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.DirectoryExistsException - If the directory you are trying to create already exists and <code>ignoreExists</code> is false
	 */
	function createDirectory(
		required directory,
		boolean createPath   = true,
		boolean ignoreExists = true
	){
		// Cleanup directory name
		arguments.directory = normalizePath( arguments.directory );

		if ( this.exists( arguments.directory ) && !arguments.ignoreExists ) {
			throw(
				type    = "cbfs.DirectoryExistsException",
				message = "Cannot create directory. The directory already exists [#arguments.directory#]"
			);
		}

		variables.files[ arguments.directory ] = {
			"path"         : arguments.directory,
			"contents"     : "",
			"checksum"     : "",
			"visibility"   : "public",
			"lastModified" : now(),
			"size"         : 0,
			"name"         : listLast( arguments.directory, "/\" ),
			"mimetype"     : "",
			"type"         : "Directory",
			"write"        : true,
			"read"         : true,
			"execute"      : false,
			"hidden"       : false,
			"metadata"     : {},
			"mode"         : "777",
			"symbolicLink" : false
		};
		return this;
	}

	/**
	 * Copies a directory to a destination
	 *
	 * The `filter` argument can be a closure and lambda with the following format
	 * <pre>
	 * boolean:function( path )
	 * </pre>
	 *
	 * @source      The source directory
	 * @destination The destination directory
	 * @recurse     If true, copies all subdirectories, otherwise only files in the source directory. Default is false.
	 * @filter      A string file extension filter to apply like *.jpg or server-*.json or a lambda/closure that receives the file path and should return true to copy it.
	 * @createPath  If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.DirectoryNotFoundException - When the old path does not exist
	 */
	function copyDirectory(
		required source,
		required destination,
		boolean recurse = false,
		any filter,
		boolean createPath = true
	){
		arguments.source      = normalizePath( arguments.source );
		arguments.destination = normalizePath( arguments.destination );
		try {
			var sourceRecord = ensureRecordExists( arguments.source );
		} catch ( "cbfs.FileNotFoundException" e ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "Directory [#arguments.source#] not found."
			);
		}

		// Copy directory record
		variables.files[ arguments.destination ] = duplicate( sourceRecord ).append( {
			path : arguments.destination,
			name : listLast( arguments.destination, "/\" )
		} );

		// Now copy all the embedded files/directories
		variables.files
			// Get all directory contents
			.keyArray()
			// Filter out the source
			.filter( function( item ){
				return item != source;
			} )
			// Passed String Filter
			.filter( function( item ){
				return isNull( filter ) || !isSimpleValue( filter ) || !len( filter ) ? true : reFindNoCase(
					"#filter.replace( "*.", ".*\." )#",
					item
				);
			} )
			// Passed Closure Filter
			.filter( function( item ){
				return ( !isNull( filter ) && isClosure( filter ) ? filter( item ) : true );
			} )
			// Copy all recursively
			.filter( function( item ){
				return item.lcase().startsWith( source.lcase() );
			} )
			// If recursive is off, filter those first level files ONLY!
			.filter( function( item ){
				return ( !recurse ? reFindNoCase( "#source#(\/|\\)[^\\//]*$", item ) : true );
			} )
			// Copy to new location
			.each( function( item ){
				var newKey                = arguments.item.replaceNoCase( source, destination );
				variables.files[ newKey ] = duplicate( variables.files[ item ] );
				// Update pointers
				variables.files[ newKey ].path = newKey;
			} );

		return this;
	}

	/**
	 * Move a directory
	 *
	 * @source      The source directory
	 * @destination The destination directory
	 * @createPath  If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.DirectoryNotFoundException - When the old path does not exist
	 */
	function moveDirectory(
		required source,
		required destination,
		boolean createPath = true
	){
		arguments.source      = normalizePath( arguments.source );
		arguments.destination = normalizePath( arguments.destination );
		try {
			var oldRecord = ensureRecordExists( arguments.source );
		} catch ( "cbfs.FileNotFoundException" e ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "Directory [#arguments.source#] not found."
			);
		}

		// Store new record with the previous data and new name/path
		oldRecord.path                           = arguments.destination;
		oldRecord.name                           = listLast( arguments.destination, "/\" );
		variables.files[ arguments.destination ] = duplicate( oldRecord );
		// wipe out the old one
		variables.files.delete( arguments.source );
		// Now move all the records from the previous old path to the new path
		variables.files
			// Get all directory contents
			.keyArray()
			.filter( function( item ){
				return item.lcase().startsWith( source );
			} )
			// Move old to new location
			.each( function( oldItemPath ){
				var newKey                = arguments.oldItemPath.replaceNoCase( source, destination );
				variables.files[ newKey ] = duplicate( variables.files[ oldItemPath ] );
				// Update pointers
				variables.files[ newKey ].path = newKey;
				variables.files.delete( arguments.oldItemPath );
			} );

		return this;
	}

	/**
	 * Delete 1 or more directory locations
	 *
	 * @directory      The directory or an array of directories
	 * @recurse        Recurse the deletion or not, defaults to true
	 * @throwOnMissing Throws an exception if the directory does not exist, defaults to false
	 *
	 * @return A boolean value or a struct of booleans determining if the directory paths got deleted or not.
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	boolean function deleteDirectory(
		required string directory,
		boolean recurse        = true,
		boolean throwOnMissing = false
	){
		arguments.directory = normalizePath( arguments.directory );
		try {
			var dirRecord = ensureRecordExists( arguments.directory );
		} catch ( "cbfs.FileNotFoundException" e ) {
			if ( arguments.throwOnMissing ) {
				throw(
					type    = "cbfs.DirectoryNotFoundException",
					message = "Directory [#arguments.directory#] not found."
				);
			}
			return false;
		}

		// Discover the directories in memory that start with this directory path and wipe them
		var aDeleted = variables.files
			.keyArray()
			.filter( function( filePath ){
				return arguments.filePath.startsWith( directory );
			} )
			.each( function( filePath ){
				variables.files.delete( arguments.filepath );
			} );

		return isNull( aDeleted ) ? true : aDeleted.len() > 0 ? true : false;
	}

	/**
	 * Empty the specified directory of all files and folders.
	 *
	 * @directory      The directory
	 * @throwOnMissing Throws an exception if the directory does not exist, defaults to false
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	function cleanDirectory( required directory, boolean throwOnMissing = false ){
		arguments.directory = normalizePath( arguments.directory );
		try {
			var dirRecord = ensureRecordExists( arguments.directory );
		} catch ( "cbfs.FileNotFoundException" e ) {
			if ( arguments.throwOnMissing ) {
				throw(
					type    = "cbfs.DirectoryNotFoundException",
					message = "Directory [#arguments.directory#] not found."
				);
			}
			return false;
		}

		variables.files
			.keyArray()
			// exclude yourself
			.filter( function( filepath ){
				return filepath != directory;
			} )
			// wipe out
			.filter( function( filePath ){
				return arguments.filePath.startsWith( directory );
			} )
			.each( function( filePath ){
				variables.files.delete( arguments.filepath );
			} );
	}

	/**
	 * Get an array listing of all files and directories in a directory.
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 * @type      Filter the result to only include files, directories, or both. ('file|files', 'dir|directory', 'all'). Default is 'all'
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function contents(
		required directory,
		any filter,
		sort,
		boolean recurse = false,
		type            = "all"
	){
		// Verify Directory
		arguments.directory = normalizePath( arguments.directory );
		try {
			var dirRecord = ensureRecordExists( arguments.directory );
		} catch ( "cbfs.FileNotFoundException" e ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "Directory [#arguments.directory#] not found."
			);
			return false;
		}

		// Return results
		return variables.files
			.keyArray()
			// Filter out the source
			.filter( function( item ){
				return item != directory;
			} )
			// the target directory to list out
			.filter( function( item ){
				return item.startsWith( directory );
			} )
			// Passed String Filter
			.filter( function( item ){
				return isNull( filter ) || !isSimpleValue( filter ) || !len( filter ) ? true : reFindNoCase(
					"#filter.replace( "*.", ".*\." )#",
					item
				);
			} )
			// Passed Closure Filter
			.filter( function( item ){
				return ( !isNull( filter ) && isClosure( filter ) ? filter( item ) : true );
			} )
			// If recursive is off, filter those first level files ONLY!
			.filter( function( item ){
				return ( !recurse ? reFindNoCase( "#directory#(\/|\\)[^\\//]*$", item ) : true );
			} )
			// File Type Filter
			.filter( function( item ){
				if ( type == "all" ) {
					return true;
				} else if ( listFindNoCase( "file,files", type ) && variables.files[ item ].type == "file" ) {
					return true;
				} else if ( listFindNoCase( "dir,directory", type ) && variables.files[ item ].type == "Directory" ) {
					return true;
				}
				return false;
			} );
	}

	/**
	 * Get an array listing of all files and directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @type      Filter the result to only include files, directories, or both. ('file|files', 'dir|directory', 'all'). Default is 'all'
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function allContents(
		required directory,
		any filter,
		sort,
		type = "all"
	){
		arguments.recurse = true;
		return contents( argumentCollection = arguments );
	}

	/**
	 * Get an array of all files in a directory.
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function files(
		required directory,
		any filter,
		sort,
		boolean recurse = false
	){
		arguments.type = "file";
		return contents( argumentCollection = arguments );
	}

	/**
	 * Get an array of all directories in a directory.
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function directories(
		required directory,
		any filter,
		sort,
		boolean recurse = false
	){
		arguments.type = "Dir";
		return contents( argumentCollection = arguments );
	}

	/**
	 * Get an array of all files in a directory using recursion, this is a shortcut to the `files()` with recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function allFiles( required directory, any filter, sort ){
		arguments.type    = "File";
		arguments.recurse = true;
		return contents( argumentCollection = arguments );
	}

	/**
	 * Get an array of all directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function allDirectories( required directory, any filter, sort ){
		arguments.type    = "Dir";
		arguments.recurse = true;
		return contents( argumentCollection = arguments );
	}

	/**
	 * Get an array of structs of all files in a directory and their appropriate information map:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 * - etc
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function filesMap(
		required directory,
		any filter,
		sort,
		boolean recurse = false
	){
		// Verify Directory
		arguments.directory = normalizePath( arguments.directory );
		try {
			var dirRecord = ensureRecordExists( arguments.directory );
		} catch ( "cbfs.FileNotFoundException" e ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "Directory [#arguments.directory#] not found."
			);
			return false;
		}

		// Return results
		return variables.files
			.keyArray()
			// Filter out the source
			.filter( function( item ){
				return item != directory;
			} )
			// the target directory to list out
			.filter( function( item ){
				return item.startsWith( directory );
			} )
			// Filter out only files in the directory
			.filter( function( item ){
				return variables.files[ item ].type == "file";
			} )
			// Passed String Filter
			.filter( function( item ){
				return isNull( filter ) || !isSimpleValue( filter ) || !len( filter ) ? true : reFindNoCase(
					"#filter.replace( "*.", ".*\." )#",
					item
				);
			} )
			// Passed Closure Filter
			.filter( function( item ){
				return ( !isNull( filter ) && isClosure( filter ) ? filter( item ) : true );
			} )
			// If recursive is off, filter those first level files ONLY!
			.filter( function( item ){
				return ( !recurse ? reFindNoCase( "#directory#(\/|\\)[^\\//]*$", item ) : true );
			} )
			.map( function( item ){
				return variables.files[ item ];
			} );
	}

	/**
	 * Get an array of structs of all files in a directory with recursion and their appropriate information map:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 * - etc
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function allFilesMap( required directory, any filter, sort ){
		arguments.recurse = true;
		return filesMap( argumentCollection = arguments );
	}

	/**
	 * Get an array of content from all the files from a specific directory
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function contentsMap(
		required directory,
		any filter,
		sort,
		boolean recurse = false
	){
		// Verify Directory
		arguments.directory = normalizePath( arguments.directory );
		try {
			var dirRecord = ensureRecordExists( arguments.directory );
		} catch ( "cbfs.FileNotFoundException" e ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "Directory [#arguments.directory#] not found."
			);
			return false;
		}

		// Return results
		return variables.files
			.keyArray()
			// Filter out the source
			.filter( function( item ){
				return item != directory;
			} )
			// the target directory to list out
			.filter( function( item ){
				return item.startsWith( directory );
			} )
			// Filter out only files in the directory
			.filter( function( item ){
				return variables.files[ item ].type == "file";
			} )
			// Passed String Filter
			.filter( function( item ){
				return isNull( filter ) || !isSimpleValue( filter ) || !len( filter ) ? true : reFindNoCase(
					"#filter.replace( "*.", ".*\." )#",
					item
				);
			} )
			// Passed Closure Filter
			.filter( function( item ){
				return ( !isNull( filter ) && isClosure( filter ) ? filter( item ) : true );
			} )
			// If recursive is off, filter those first level files ONLY!
			.filter( function( item ){
				return ( !recurse ? reFindNoCase( "#directory#(\/|\\)[^\\//]*$", item ) : true );
			} )
			.map( function( item ){
				return {
					"contents" : variables.files[ item ].contents,
					"path"     : item,
					"size"     : variables.files[ item ].size
				};
			} );
	}

	/**
	 * Get an array of content from all the files from a specific directory with recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function allContentsMap( required directory, any filter, sort ){
		arguments.recurse = true;
		return contentsMap( argumentCollection = arguments );
	}

	/**
	 * Find path names matching a given globbing pattern
	 *
	 * @pattern The globbing pattern to match
	 */
	array function glob( required pattern ){
		// Not implemented yet. HELP!!
	}


	/********************* PRIVATE METHODS **********************/

	/**
	 * This checks if the file path is missing. If it does, it throws an exception, else continues operation.
	 *
	 * @path The path to check
	 *
	 * @return The file structure
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	private struct function ensureRecordExists( required path ){
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		return variables.files[ arguments.path ];
	}

}