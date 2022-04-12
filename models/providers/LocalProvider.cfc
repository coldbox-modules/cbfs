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

		// Verify the disk storage exists, else create it
		if ( !directoryExists( variables.properties.path ) ) {
			directoryCreate( variables.properties.path );
		}

		variables.started = true;
		return this;
	}

	/**
	 * Create a file in the disk
	 *
	 * @path       The file path to use for storage
	 * @contents   The contents of the file to store
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 * @metadata   Struct of metadata to store with the file
	 * @overwrite  If we should overwrite the files or not at the destination if they exist, defaults to true
	 *
	 * @return LocalProvider
	 */
	function create(
		required path,
		required contents,
		visibility        = "",
		struct metadata   = {},
		boolean overwrite = false
	){
		if ( !arguments.overwrite && this.exists( arguments.path ) ) {
			throw(
				type    = "cbfs.FileOverrideException",
				message = "Cannot create file. File already exists [#arguments.path#]"
			);
		}
		// filewrite throws error if directory not exists
		ensureDirectoryExists( arguments.path );
		try {
			fileWrite( buildPath( arguments.path ), arguments.contents );
		} catch ( any e ) {
			throw(
				type    = "cbfs.FileNotFoundException",
				message = "Cannot create file. File already exists [#arguments.path#]"
			);
		}
		if ( len( arguments.visibility ) ) {
			this.setVisibility( arguments.path, arguments.visibility );
		}
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
		boolean overwrite = false
	){
		return this.create(
			path      = arguments.destination,
			contents  = this.get( arguments.source ),
			overwrite = arguments.overwrite
		);
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
		boolean overwrite = false
	){
		this.create(
			path      = arguments.destination,
			contents  = this.get( arguments.source ),
			overwrite = arguments.overwrite
		);
		return this.delete( arguments.source );
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
	 * Get the contents of a file
	 *
	 * @path The file path to retrieve
	 *
	 * @return The contents of the file
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function get( required path ){
		ensureFileExists( arguments.path );
		return fileRead( buildPath( arguments.path ) );
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
		ensureFileExists( arguments.path );
		return fileReadBinary( buildPath( arguments.path ) );
	};

	/**
	 * Validate if a file/directory exists
	 *
	 * @path The file/directory path to verify
	 */
	boolean function exists( required string path ){
		if ( isDirectory( arguments.path ) ) {
			return directoryExists( buildPath( arguments.path ) );
		}
		try {
			return fileExists( buildPath( arguments.path ) );
		} catch ( any e ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
	}

	/**
	 * Deletes a file
	 *
	 * @path
	 * @throwOnMissing When true an error will be thrown if the file does not exist
	 */
	public boolean function delete( required any path, boolean throwOnMissing = false ){
		if ( isSimpleValue( arguments.path ) ) arguments.path = listToArray( arguments.path );
		for ( var file in arguments.path ) {
			if ( !throwOnMissing ) {
				if ( !this.exists( file ) ) {
					return false;
				}
			}
			if ( isDirectory( file ) ) {
				deleteDirectory( file, true );
			} else {
				fileDelete( buildPath( file ) );
			}
		}
		return true;
	}

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
	 * Determines whether a provided path is a directory or not
	 *
	 * @path The path to be checked
	 */
	private function buildPath( required string path ){
		// remove all relative dots
		arguments.path = reReplace( arguments.path, "\.\.\/+", "", "ALL" );
		return expandPath( getProperties().path & "/" & arguments.path );
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
	 * Ensures a directory exists - will create the directory if it does not exist
	 *
	 * @path The path to be checked for existence
	 */
	private function ensureDirectoryExists( required path ){
		var p             = buildPath( arguments.path );
		var directoryPath = replaceNoCase( p, getFileFromPath( p ), "" );

		if ( !directoryExists( directoryPath ) ) {
			directoryCreate( directoryPath );
		}
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
	 * Ensures a directory exists - will create the directory if it does not exist
	 *
	 * @path The path to be checked for existence
	 */
	private function ensureDirectoryExists( required path ){
		var p             = buildPath( arguments.path );
		var directoryPath = replaceNoCase( p, getFileFromPath( p ), "" );

		if ( !directoryExists( directoryPath ) ) {
			directoryCreate( directoryPath );
		}
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
	 * Expands the full path of the requested provider route
	 *
	 * @path The path to be expanded
	 */
	private function buildPath( required string path ){
		return expandPath( getProperties().path & "/" & arguments.path );
	}

	/**
	 * Ensures a file exists
	 *
	 * @path The path to be checked for existence
	 *
	 * @throws cbfs.FileNotFoundException Throws if the file does not exist
	 */
	private function ensureFileExists( required path ){
		if ( !this.exists( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
	}

}
