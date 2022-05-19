/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This is an abstraction of how all disks should behave or at least give
 * basic behavior.
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component
	accessors="true"
	extends  ="cbfs.models.AbstractDiskProvider"
	singleton
{

	// static lookups
	variables.defaults = { path : "", autoExpand : false };
	// Java Helpers
	// @see https://docs.oracle.com/javase/8/docs/api/java/nio/file/Paths.html#get-java.lang.String-java.lang.String...-
	// @see https://docs.oracle.com/javase/8/docs/api/java/nio/file/Files.html
	variables.jPaths = createObject( "java", "java.nio.file.Paths" );
	variables.jFiles = createObject( "java", "java.nio.file.Files" );

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

		// Append defaults
		structAppend(
			variables.properties,
			variables.defaults,
			false
		);

		// Property Checks
		if ( !len( variables.properties.path ) ) {
			throw(
				message = "The local disk requires a 'path' property to bind to",
				type    = "InvalidPropertyException"
			);
		}


		// Do we need to expand the path
		if ( variables.properties.autoExpand ) {
			variables.properties.path = expandPath( variables.properties.path );
		}

		// Normalize Path
		variables.properties.path = normalizePath( variables.properties.path );

		// Create java nio path
		variables.properties.jPath = variables.jPaths.get( arguments.properties.path, [] );

		// Verify the disk storage exists, else create it
		if ( !directoryExists( variables.properties.path ) ) {
			directoryCreate( variables.properties.path );
		}

		variables.started = true;
		return this;
	}

	/**
	 * Called before the cbfs module is unloaded, or via reinits. This can be implemented
	 * as you see fit to gracefully shutdown connections, sockets, etc.
	 *
	 * @return cbfs.models.IDisk
	 */
	any function shutdown(){
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
		boolean overwrite = false,
		string mode
	){
		// Verify the path
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

		// Normalize and build the path on disk
		arguments.path = buildDiskPath( arguments.path );

		// Make sure if we pass a nested file, that the sub-directories get created
		var containerDirectory = getDirectoryFromPath( arguments.path );
		if( containerDirectory != variables.properties.path ){
			ensureDirectoryExists( containerDirectory );
		}

		// Write it
		fileWrite( arguments.path, arguments.contents, "UTF-8" );

		// Set visibility or mode
		if( isWindows() ){
			fileSetAttribute( arguments.path, variables.VISIBILITY_ATTRIBUTE[ arguments.visibility ] );
		} else {
			fileSetAccessMode( arguments.path, arguments.mode );
		}

		return this;
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
		return this.move( argumentCollection = arguments );
	}

	/**
	 * Set the storage visibility of a file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 *
	 * @path       The target file
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 *
	 * @return LocalProvider
	 */
	function setVisibility( required string path, required string visibility ){
		if ( isWindows() ) {
			switch ( arguments.visibility ) {
				case "private": {
					var mode = "system";
					break;
				}
				case "readonly": {
					var mode = arguments.visibility;
					break;
				}
				default: {
					var mode = "normal";
				}
			}
			fileSetAttribute( buildPath( arguments.path ), mode );
			return this;
		}
		switch ( arguments.visibility ) {
			case "private": {
				var mode = variables.permissions.file.private;
				break;
			}
			case "readonly": {
				var mode = variables.permissions.file.readonly;
				break;
			}
			default: {
				var mode = variables.permissions.file.public;
			}
		}
		fileSetAccessMode( buildPath( arguments.path ), mode );
		return this;
	};

	/**
	 * Get the storage visibility of a file, the return format can be a string of `public, private, readonly` or a custom data type the implemented driver can interpret.
	 *
	 * @path The target file
	 */
	public string function visibility( required string path ){
		var file = getFileInfo( arguments.path );
		if ( !file.canRead ) {
			return "private";
		}
		if ( file.canWrite ) {
			return "public";
		}
		return "public";
	};

	/**
	 * Prepend contents to the beginning of a file
	 *
	 * @path           The file path to use for storage
	 * @contents       The contents of the file to prepend
	 * @metadata       Struct of metadata to store with the file
	 * @throwOnMissing Boolean flag to throw if the file is missing. Otherwise it will be created if missing.
	 *
	 * @return LocalProvider
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function prepend(
		required string path,
		required contents,
		struct metadata        = {},
		boolean throwOnMissing = false
	){
		if ( !this.exists( arguments.path ) ) {
			if ( arguments.throwOnMissing ) {
				throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
			}
			return this.create(
				path     = arguments.path,
				contents = arguments.contents,
				metadata = arguments.metadata
			);
		}
		return this.create(
			path      = arguments.path,
			contents  = arguments.contents & this.get( arguments.path ),
			overwrite = true
		);
	}

	/**
	 * Append contents to the end of a file
	 *
	 * @path           The file path to use for storage
	 * @contents       The contents of the file to append
	 * @metadata       Struct of metadata to store with the file
	 * @throwOnMissing Boolean flag to throw if the file is missing. Otherwise it will be created if missing.
	 *
	 * @return LocalProvider
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function append(
		required string path,
		required contents,
		struct metadata        = {},
		boolean throwOnMissing = false
	){
		if ( !this.exists( arguments.path ) ) {
			if ( arguments.throwOnMissing ) {
				throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
			}
			return this.create(
				path     = arguments.path,
				contents = arguments.contents,
				metadata = arguments.metadata
			);
		}
		return this.create(
			path      = arguments.path,
			contents  = this.get( arguments.path ) & arguments.contents,
			overwrite = true
		);
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
		boolean overwrite = false
	){
		return this.create(
			path      = arguments.destination,
			contents  = this.get( arguments.source ),
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
		if( arguments.overwrite || missing( arguments.destination ) ){
			fileMove( buildDiskPath( arguments.source ), buildDiskPath( arguments.destination ) );
		}
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
		return fileRead( ensureFileExists( arguments.path ), "UTF-8" );
	}

	/**
	 * Get the contents of a file as binary, such as an executable or image
	 *
	 * @path The file path to retrieve
	 *
	 * @return A binary representation of the file
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function getAsBinary( required path ){
		return fileReadBinary( ensureFileExists( arguments.path ), "UTF-8" );
	};

	/**
	 * Validate if a file/directory exists
	 *
	 * @path The file/directory path to verify
	 */
	boolean function exists( required string path ){
		arguments.path = buildDiskPath( arguments.path );
		if ( isDirectory( arguments.path ) ) {
			return directoryExists( arguments.path );
		}
		return fileExists( arguments.path );
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

		fileDelete( buildDiskPath( arguments.path ) );

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
		// If it exists, just touch the timestamp
		if ( exists( arguments.path ) ) {
			fileSetLastModified( buildDiskPath( arguments.path ), now() );
			return this;
		}
		// else touch it baby!
		arguments.path = buildDiskPath( arguments.path );
		if ( !arguments.createPath ) {
			if ( missing( getDirectoryFromPath( arguments.path ) ) ) {
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
	 * Retrieve the file's last modified timestamp
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function lastModified( required path ){
		ensureFileExists( arguments.path );
		return getFileInfo( buildPath( arguments.path ) ).lastModified;
	}

	/**
	 * Is the path a file or not
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	boolean function isFile( required path ){
		if ( isDirectory( arguments.path ) ) {
			return false;
		}
		ensureFileExists( arguments.path );
		return getFileInfo( buildPath( arguments.path ) ).type EQ "file";
	}

	/**
	 * Is the path writable or not
	 *
	 * @path The file path
	 */
	boolean function isWritable( required path ){
		return getFileInfo( buildPath( arguments.path ) ).canWrite;
	}

	/**
	 * Is the path readable or not
	 *
	 * @path The file path
	 */
	boolean function isReadable( required path ){
		return getFileInfo( buildPath( arguments.path ) ).canRead;
	}

	/**
	 * Is the path a directory or not
	 *
	 * @path The directory path
	 */
	boolean function isDirectory( required path ){
		try {
			return getFileInfo( buildPath( arguments.path ) ).type == "directory";
		} catch ( any e ) {
			return isDirectoryPath( arguments.path );
		}
	};

	/**
	 * Create a new directory
	 *
	 * @directory    The directory path
	 * @createPath   Create parent directory paths when they do not exist
	 * @ignoreExists If false, it will throw an error if the directory already exists, else it ignores it if it exists. This should default to true.
	 *
	 * @return LocalProvider
	 */
	function createDirectory(
		required directory,
		boolean createPath,
		boolean ignoreExists = false
	){
		if ( !arguments.ignoreExists AND directoryExists( buildPath( arguments.directory ) ) ) {
			throw( "Directory Exists" );
		}
		if ( !directoryExists( buildPath( arguments.directory ) ) ) {
			directoryCreate( buildPath( arguments.directory ) );
		}
	};

	/**
	 * Renames a directory path
	 *
	 * @oldPath    The source directory
	 * @newPath    The destination directory
	 * @createPath If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 */
	function renameDirectory(
		required oldPath,
		required newPath,
		boolean createPath
	){
		directoryRename( buildPath( arguments.oldPath ), buildPath( arguments.newPath ) );
		return this;
	};

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
		if ( isSimpleValue( directory ) ) {
			if ( !throwOnMissing && !this.exists( arguments.directory ) ) {
				return false;
			}
			directoryDelete( buildPath( arguments.directory ), arguments.recurse );
			return true;
		}

		return arguments.directory.every( function( dir ){
			return this.deleteDirectory(
				dir,
				arguments.recurse,
				arguments.throwOnMissing
			);
		} );
	};

	/**
	 * Get an array listing of all files and directories in a directory.
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 */
	array function contents(
		required directory,
		any filter,
		sort,
		boolean recurse = false
	){
		var result     = [];
		arguments.type = structKeyExists( arguments, "type" ) ? arguments.type : javacast( "null", "" );
		var qDir       = directoryList(
			buildPath( arguments.directory ),
			arguments.recurse,
			"query",
			arguments.filter,
			arguments.sort,
			arguments.type
		);
		if ( isNull( arguments.map ) ) {
			return valueArray( qDir, "name" );
		}
		for ( v in qDir ) {
			v[ "path" ] = getRelativePath( v );
			arrayAppend( result, v );
		}
		return result;
	}

	/**
	 * Get an array of all files in a directory.
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 */
	array function files(
		required directory,
		any filter,
		sort,
		boolean recurse
	){
		arguments.type = "file";
		arguments.map  = false;
		return this.contents( argumentCollection = arguments );
	};

	/**
	 * Get an array of all directories in a directory.
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 */
	array function directories(
		required directory,
		any filter,
		sort,
		boolean recurse
	){
		arguments.type = "directory";
		arguments.map  = false;
		return this.contents( argumentCollection = arguments );
	};

	/**
	 * Get an array of all files in a directory using recursion, this is a shortcut to the `files()` with recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allFiles( required directory, any filter, sort ){
		arguments.recurse = true;
		arguments.map     = false;
		this.files( argumentCollection = arguments );
	};

	/**
	 * Get an array of all directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allDirectories( required directory, any filter, sort ){
		arguments.recurse = true;
		arguments.map     = false;
		this.directories( argumentCollection = arguments );
	};

	/**
	 * Get an array of structs of all files in a directory and their appropriate information map:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 */
	array function filesMap(
		required directory,
		any filter,
		sort,
		boolean recurse
	){
		arguments.map = true;
		this.files( argumentCollection = arguments );
	};

	/**
	 * Get an array of structs of all files in a directory with recursion and their appropriate information map:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allFilesMap( required directory, any filter, sort ){
		arguments.map     = true;
		arguments.recurse = true;
		this.filesMap( argumentCollection = arguments );
	};

	/**
	 * Get an array of structs of all directories in a directory and their appropriate information map:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 */
	array function directoriesMap(
		required directory,
		any filter,
		sort,
		boolean recurse
	){
		arguments.map = true;
		this.directories( argumentCollection = arguments );
	};

	/**
	 * Get an array of structs of all directories in a directory with recursion and their appropriate information map:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allDirectoriesMap( required directory, any filter, sort ){
		arguments.recurse = false;
		this.directoriesMap( argumentCollection = arguments );
	};

	/**
	 * Get an array of structs of all files and directories in a directory and their appropriate information map:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 */
	array function contentsMap(
		required directory,
		any filter,
		sort,
		boolean recurse
	){
		arguments.map = true;
		this.contents( argumentCollection = arguments );
	};

	/**
	 * Get an array of structs of all files in a directory with recursion and their appropriate information map:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allContentsMap( required directory, any filter, sort ){
		arguments.recurse = true;
		this.contentsMap( argumentCollection = arguments );
	};

	/**
	 * Sets the access attributes of the file on Unix based disks
	 *
	 * @path The file path
	 * @mode Access mode, the same attributes you use for the Linux command `chmod`
	 */
	function chmod( required string path, required string mode ){
		fileSetAccessMode( buildPath( path ), arguments.mode );
		return this;
	}

	/************************* PRIVATE METHODS ****************************/

	/**
	 * This function builds the path on the provided disk from it's root + incoming path
	 * with normalization, cleanup and canonicalization.
	 *
	 * @path The path on the disk to build
	 *
	 * @return The canonical path on the disk
	 */
	private function buildDiskPath( required string path ){
		var pathTarget = normalizePath( arguments.path );
		return pathTarget.startsWith( variables.properties.path ) ? pathTarget : variables.properties.path & "/#pathTarget#";
	}

	/**
	 * Gets the relative path from a path object
	 *
	 * @obj the path object
	 */
	private function getRelativePath( required obj ){
		var path = replace( obj.directory, getProperties().path, "" ) & "/" & obj.name;
		path     = replace( path, "\", "/", "ALL" );
		path     = ( left( path, 1 ) EQ "/" ) ? removeChars( path, 1, 1 ) : path;
		return path;
	}

	/**
	 * Get an array listing of all files and directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 */
	array function allContents( required directory, any filter, sort ){
		arguments.recurse = true;
		arguments.map     = false;
		return this.contents( argumentCollection = arguments );
	}

	/**************************************** STREAM METHODS ****************************************/

	/**
	 * Return a Java stream of the file using non-blocking IO classes. The stream will represent every line in the file so you can navigate through it.
	 * This method leverages the `cbstreams` library used accordingly by implementations (https://www.forgebox.io/view/cbstreams)
	 *
	 * @path
	 *
	 * @return Stream object: See https://apidocs.ortussolutions.com/coldbox-modules/cbstreams/1.1.0/index.html
	 */
	function stream( required path ){
		return streamBuilder.new().ofFile( buildPath( arguments.path ) );
	};

	/**
	 * Create a Java stream of the incoming array of files/directories usually called from this driver as well.
	 * <pre>
	 * disk.streamOf( disk.files( "my.path" ) )
	 *  .filter( function( item ){
	 *      return item.startsWith( "a" );
	 *  } )
	 *  .forEach( function( item ){
	 *      writedump( item );
	 *  } );
	 * </pre>
	 *
	 * @target The target array of files/directories to generate a stream of
	 *
	 * @return Stream object: See https://apidocs.ortussolutions.com/coldbox-modules/cbstreams/1.1.0/index.html
	 */
	function streamOf( required array target ){
		throw( "Implement in a subclass" );
	}


	/**
	 * Creates a directory by creating all nonexistent parent directories first.
	 * An exception is not thrown if the directory could not be created because it already exists.
	 *
	 * @path The full disk path, no normalization is done here.
	 *
	 * @return The java Path representing the directory
	 */
	private function ensureDirectoryExists( required path ){
		// Create directories and if they exist, ignore it
		return variables.jFiles.createDirectories(
			arguments.path, javaCast( "null", "" )
		);
	}

	/**
	 * Determines whether a provided path is a directory or not
	 *
	 * @path The path to be checked
	 */
	private function isDirectoryPath( required path ){
		if ( !len( getFileFromPath( buildPath( arguments.path ) ) ) && !!len( extension( arguments.path ) ) ) {
			return true;
		}
		return false;
	}

	/**
	 * Ensures a file exists
	 *
	 * @path The path to be checked for existence
	 *
	 * @throws cbfs.FileNotFoundException Throws if the file does not exist
	 */
	private function ensureFileExists( required path ){
		arguments.path = buildDiskPath( arguments.path );
		if ( fileExists( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		return arguments.path;
	}

}
