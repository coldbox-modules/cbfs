/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This is an abstraction of how all disks should behave or at least give
 * basic behavior.
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component accessors="true" extends="cbfs.models.AbstractDiskProvider" {

	// DI
	property name="wirebox" inject="wirebox";

	// static lookups
	variables.defaults    = { path : "", autoExpand : false };
	// Java Helpers
	// @see https://docs.oracle.com/javase/8/docs/api/java/nio/file/Paths.html#get-java.lang.String-java.lang.String...-
	// @see https://docs.oracle.com/javase/8/docs/api/java/nio/file/Files.html
	variables.jPaths      = createObject( "java", "java.nio.file.Paths" );
	variables.jFiles      = createObject( "java", "java.nio.file.Files" );
	variables.jLinkOption = createObject( "java", "java.nio.file.LinkOption" );
	variables.jCopyOption = createObject( "java", "java.nio.file.StandardCopyOption" );
	variables.jOpenOption = createObject( "java", "java.nio.file.StandardOpenOption" );

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
		variables.properties.jPath = getJavaPath( arguments.properties.path );

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
		boolean overwrite = true,
		string mode
	){
		// Verify the path
		if ( !arguments.overwrite && exists( arguments.path ) ) {
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
		if ( containerDirectory != variables.properties.path ) {
			ensureDirectoryExists( containerDirectory );
		}

		// Use native method if binary, as it's less verbose than creating an input stream and getting the bytes
		if ( isBinary( arguments.contents ) ) {
			fileWrite( arguments.path, arguments.contents );
		} else {
			variables.jFiles.write(
				buildJavaDiskPath( arguments.path ),
				arguments.contents.getBytes(),
				[]
			);
		}

		// Set visibility or mode
		if ( isWindows() ) {
			fileSetAttribute( arguments.path, variables.VISIBILITY_ATTRIBUTE[ arguments.visibility ] );
		} else {
			fileSetAccessMode( arguments.path, arguments.mode );
		}

		return this;
	}

	/**
	 * Uploads a file in to the disk
	 *
	 * @fieldName   The file field name
	 * @directory the directory on disk to upload to
	 * @overload  We can overload the default because we can go directly to the disk with the file
	 */
	function upload( required fieldName, required directory ){

		fileUpload(
			buildDiskPath( arguments.directory ),
			arguments.fieldName,
			variables.properties.keyExists( "uploadMimeAccept" ) ? variables.properties.uploadMimeAccept : "*",
			"error"
		);

		return this;
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
		// Windows vs Others
		if ( isWindows() ) {
			fileSetAttribute(
				buildDiskPath( arguments.path ),
				variables.VISIBILITY_ATTRIBUTE[ arguments.visibility ]
			);
			return this;
		}
		// Others
		fileSetAccessMode( buildDiskPath( arguments.path ), variables.PERMISSIONS.file[ arguments.visibility ] );
		return this;
	};

	/**
	 * Get the storage visibility of a file, the return format can be a string of `public, private, readonly` or a custom data type the implemented driver can interpret.
	 *
	 * @path The target file
	 */
	public string function visibility( required string path ){
		// Public
		if ( isWritable( arguments.path ) && isReadable( arguments.path ) ) {
			return "public";
		}
		// Hidden
		if ( isHidden( arguments.path ) ) {
			return "private";
		}
		// Private
		if ( !isReadable( arguments.path ) ) {
			return "private";
		}
		// Read only then
		return "readonly";
	};

	/**
	 * Prepend contents to the beginning of a file. This is a very expensive operation for local disk storage.
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
		return create(
			path      = arguments.path,
			contents  = arguments.contents & get( arguments.path ),
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

		variables.jFiles.write(
			buildJavaDiskPath( arguments.path ),
			arguments.contents.getBytes(),
			[ variables.jOpenOption.APPEND ]
		);

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
	 * @throws cbfs.FileNotFoundException - When the source doesn't exist
	 * @throws cbfs.FileOverrideException - When the destination exists and no override has been provided
	 */
	function copy(
		required source,
		required destination,
		boolean overwrite = true
	){
		// If source is missing, blow up!
		if ( missing( arguments.source ) ) {
			throw(
				type    = "cbfs.FileNotFoundException",
				message = "Cannot copy file. Source file doesn't exist [#arguments.source#]"
			);
		}

		// Overwrite checks for destination
		if ( !arguments.overwrite && exists( arguments.destination ) ) {
			throw(
				type    = "cbfs.FileOverrideException",
				message = "Cannot copy file. Destination already exists [#arguments.destination#] and overwrite is false"
			);
		}

		// Copy files
		variables.jFiles.copy(
			buildJavaDiskPath( arguments.source ),
			buildJavaDiskPath( arguments.destination ),
			[
				variables.jCopyOption.REPLACE_EXISTING,
				variables.jCopyOption.COPY_ATTRIBUTES
			]
		);

		return this;
	}

	/**
	 * Move a file from one destination to another
	 *
	 * @source      The source file path
	 * @destination The end destination path
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException - When the source doesn't exist
	 * @throws cbfs.FileOverrideException - When the destination exists and no override has been provided
	 */
	function move(
		required source,
		required destination,
		boolean overwrite = true
	){
		// If source is missing, blow up!
		if ( missing( arguments.source ) ) {
			throw(
				type    = "cbfs.FileNotFoundException",
				message = "Cannot move file. Source file doesn't exist [#arguments.source#]"
			);
		}

		// Overwrite checks for destination
		if ( !arguments.overwrite && exists( arguments.destination ) ) {
			throw(
				type    = "cbfs.FileOverrideException",
				message = "Cannot move file. Destination already exists [#arguments.destination#] and overwrite is false"
			);
		}

		// Move files
		variables.jFiles.move(
			buildJavaDiskPath( arguments.source ),
			buildJavaDiskPath( arguments.destination ),
			[
				variables.jCopyOption.REPLACE_EXISTING,
				variables.jCopyOption.ATOMIC_MOVE
			]
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
		return listFirst( getMimeType( arguments.path ), "/" ) == "text"
		 ? variables.jFiles.readString( getJavaPath( ensureFileExists( arguments.path ) ) )
		 : fileReadBinary( buildDiskPath( ensureFileExists( arguments.path ) ) );
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
		return variables.jFiles.readAllBytes( getJavaPath( ensureFileExists( arguments.path ) ) );
	};

	/**
	 * Validate if a file exists
	 *
	 * @path The file path to verify
	 */
	boolean function exists( required string path ){
		return variables.jFiles.exists( buildJavaDiskPath( arguments.path ), [] );
	}

	/**
	 * Validate if a directory exists
	 *
	 * @path The directory path to verify
	 */
	boolean function directoryExists( required string path ){
		return variables.jFiles.exists( buildJavaDiskPath( arguments.path ), [] );
	}

	/**
	 * Delete a file or an array of file paths. If a file does not exist a `false` will be shown for it's return.
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
		variables.jFiles.delete( buildJavaDiskPath( arguments.path ) );

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
			if ( directoryMissing( getDirectoryFromPath( arguments.path ) ) ) {
				throw(
					type    = "cbfs.PathNotFoundException",
					message = "Directory does not already exist and the `createPath` flag is set to false"
				);
			}
		}

		return create( path = arguments.path, contents = "" );
	}

	/**************************************** UTILITY METHODS ****************************************/

	/**
	 * Build a Java Path object from the built disk path. It's like calling getJavaPath( buildDiskPath () )
	 *
	 * @see  https://docs.oracle.com/javase/8/docs/api/java/nio/file/Path.html#toAbsolutePath--
	 * @path The path on the disk to build
	 *
	 * @return java.nio.file.Path
	 */
	function buildJavaDiskPath( required string path ){
		return getJavaPath( buildDiskPath( arguments.path ) );
	}

	/**
	 * Get a Java Path of the passed in stringed path. It does not calculate a full disk path.
	 *
	 * @see  https://docs.oracle.com/javase/8/docs/api/java/nio/file/Path.html#toAbsolutePath--
	 * @path The string path to convert into a Java Path
	 *
	 * @return java.nio.file.Path
	 */
	function getJavaPath( required path ){
		return variables.jPaths.get( javacast( "String", arguments.path ), javacast( "java.lang.String[]", [] ) );
	}

	/**
	 * Get the uri for the given file
	 *
	 * @path The file path to build the uri for
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function uri( required string path ){
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		return buildDiskPath( arguments.path );
	}

	/**
	 * Get the full url for the given file
	 *
	 * @path The file path to build the uri for
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function url( required string path ){
		var baseUrl = variables.wirebox
			.getInstance( "RequestService@coldbox" )
			.getContext()
			.getHTMLBaseURL();
		return baseURL
		& listToArray(
			arguments.properties.visibility == "public"
			 ? uri( argumentCollection = arguments )
			 : temporaryUri( argumentCollection = arguments ),
			"/"
		).toList( "/" );
	}

	/**
	 * Get a temporary uri for the given file
	 *
	 * @path       The file path to build the uri for
	 * @expiration The number of minutes this uri should be valid for. Defaults to 60 minutes
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function temporaryUri( required path, numeric expiration = 60 ){
		return uri( arguments.path ) & "?expiration=#arguments.expiration#";
	}

	/**
	 * Returns the size of a file (in bytes). The size may differ from the actual size on the file system due to compression, support for sparse files, or other reasons.
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	numeric function size( required path ){
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		return variables.jFiles.size( buildJavaDiskPath( arguments.path ) );
	}

	/**
	 * Retrieve the file's last modified timestamp
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function lastModified( required path ){
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		var inMillis = variables.jFiles
			.getLastModifiedTime( getJavaPath( ensureFileExists( arguments.path ) ), [] )
			.toMillis();
		// Calculate adjustments fot timezone and daylightsavindtime
		var offset = ( ( getTimezoneInfo().utcHourOffset ) + 1 ) * -3600;
		// Date is returned as number of seconds since 1-1-1970
		return dateAdd(
			"s",
			( round( inMillis / 1000 ) ) + offset,
			createDateTime( 1970, 1, 1, 0, 0, 0 )
		);
	}

	/**
	 * Retrieve the file's mimetype
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function mimeType( required path ){
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		return getMimeType( buildDiskPath( arguments.path ) );
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
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		var fileInfo           = getFileInfo( buildDiskPath( arguments.path ) );
		fileInfo[ "diskPath" ] = arguments.path;
		return fileInfo;
	}

	/**
	 * This returns the extended info from a file by reading it's posix attributes
	 *
	 * @path The file path
	 *
	 * @return The struct of extended information about a file
	 */
	struct function extendedInfo( required path ){
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}

		var infoMap = variables.jFiles.readAttributes(
			buildJavaDiskPath( arguments.path ),
			"posix:*",
			[]
		);

		infoMap = structMap( infoMap, function( key, value ){
			switch ( arguments.key ) {
				case "permissions": {
					return createObject( "java", "java.nio.file.attribute.PosixFilePermissions" ).toString(
						arguments.value
					);
				}
				default:
					return arguments.value.toString();
			}
		} );
		infoMap[ "diskPath" ] = arguments.path;
		return infoMap;
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
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		return hash( getAsBinary( arguments.path ), arguments.algorithm );
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
	 */
	function chmod( required string path, required string mode ){
		if ( missing( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		fileSetAccessMode( buildDiskPath( arguments.path ), arguments.mode );
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
		return variables.jFiles.createSymbolicLink(
			buildJavaDiskPath( arguments.link ),
			buildJavaDiskPath( arguments.target ),
			[]
		);
	}

	/**************************************** VERIFICATION METHODS ****************************************/

	/**
	 * Is the path a file or not
	 *
	 * @path The file path
	 *
	 * @return true if the file is a regular file; false if the file does not exist, is not a regular file, or it cannot be determined if the file is a regular file or not.
	 */
	boolean function isFile( required path ){
		return variables.jFiles.isRegularFile( buildJavaDiskPath( arguments.path ), [] );
	}

	/**
	 * Is the path writable or not
	 *
	 * @path The file path
	 */
	boolean function isWritable( required path ){
		return variables.jFiles.isWritable( buildJavaDiskPath( arguments.path ) );
	}

	/**
	 * Is the path readable or not
	 *
	 * @path The file path
	 */
	boolean function isReadable( required path ){
		return variables.jFiles.isReadable( buildJavaDiskPath( arguments.path ) );
	}

	/**
	 * Is the file executable or not
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	boolean function isExecutable( required path ){
		return variables.jFiles.isExecutable( buildJavaDiskPath( arguments.path ) );
	}

	/**
	 * Is the file is hidden or not
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	boolean function isHidden( required path ){
		return variables.jFiles.isHidden( buildJavaDiskPath( arguments.path ) );
	}

	/**
	 * Is the file is a symbolic link
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	boolean function isSymbolicLink( required path ){
		return variables.jFiles.isSymbolicLink( buildJavaDiskPath( arguments.path ) );
	}

	/**************************************** DIRECTORY METHODS ****************************************/

	/**
	 * Is the path a directory or not
	 *
	 * @path The directory path
	 *
	 * @return true if the file is a directory; false if the file does not exist, is not a directory, or it cannot be determined if the file is a directory or not.
	 */
	boolean function isDirectory( required path ){
		return variables.jFiles.isDirectory( buildJavaDiskPath( arguments.path ), [] );
	};

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
		// If not ignoring and directory exists, then throw exception
		if ( !arguments.ignoreExists AND this.directoryExists( arguments.directory ) ) {
			throw(
				type    = "cbfs.DirectoryExistsException",
				message = "Cannot create directory. The directory already exists [#arguments.directory#]"
			);
		}
		ensureDirectoryExists( buildJavaDiskPath( arguments.directory ) );
		return this;
	};

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
	 * @throws cbfs.DirectoryNotFoundException - When the source directory does not exist
	 */
	function copyDirectory(
		required source,
		required destination,
		boolean recurse = false,
		any filter,
		boolean createPath = true
	){
		// If source is missing, blow up!
		if ( directoryMissing( arguments.source ) ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "Cannot move directory. Source directory doesn't exist [#arguments.source#]"
			);
		}

		directoryCopy(
			buildDiskPath( arguments.source ),
			buildDiskPath( arguments.destination ),
			arguments.recurse,
			isNull( arguments.filter ) ? "" : arguments.filter
		);

		return this;
	}

	/**
	 * Move or rename a directory
	 *
	 * @source      The source directory
	 * @destination The destination directory
	 * @createPath  If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.DirectoryNotFoundException          - When the source does not exist
	 * @throws java.nio.file.DirectoryNotEmptyException - When the destination exists and is not empty
	 */
	function moveDirectory(
		required source,
		required destination,
		boolean createPath = true
	){
		// If source is missing, blow up!
		if ( directoryMissing( arguments.source ) ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "Cannot move directory. Source directory doesn't exist [#arguments.source#]"
			);
		}

		// Move directory
		variables.jFiles.move(
			buildJavaDiskPath( arguments.source ),
			buildJavaDiskPath( arguments.destination ),
			[
				variables.jCopyOption.REPLACE_EXISTING,
				variables.jCopyOption.ATOMIC_MOVE
			]
		);

		return this;
	};

	/**
	 * Delete one or more directory locations
	 *
	 * @directory      The directory or an array of directories
	 * @recurse        Recurse the deletion or not, defaults to true
	 * @throwOnMissing Throws an exception if the directory does not exist, defaults to false
	 *
	 * @return A boolean value or a struct of booleans determining if the directory paths got deleted or not.
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	public boolean function deleteDirectory(
		required string directory,
		boolean recurse        = true,
		boolean throwOnMissing = false
	){
		// If missing throw or ignore
		if ( directoryMissing( arguments.directory ) ) {
			if ( arguments.throwOnMissing ) {
				throw(
					type    = "cbfs.DirectoryNotFoundException",
					message = "Directory [#arguments.directory#] not found."
				);
			}
			return false;
		}

		// Wipe it out baby!
		if ( arguments.recurse ) {
			variables.jFiles.walkFileTree(
				buildJavaDiskPath( arguments.directory ), // start path
				createDynamicProxy(
					wirebox.getInstance( "DeleteAllVisitor@cbfs" ),
					[ "java.nio.file.FileVisitor" ]
				) // visitor
			);
		} else {
			// Proxy it and delete like an egyptian!
			variables.jFiles.walkFileTree(
				buildJavaDiskPath( arguments.directory ), // start path
				createObject( "java", "java.util.HashSet" ).init(), // options
				javacast( "int", 1 ), // maxDepth
				createDynamicProxy(
					wirebox.getInstance( "DeleteFileVisitor@cbfs" ),
					[ "java.nio.file.FileVisitor" ]
				) // visitor
			);

			return !this.directoryExists( arguments.directory );
		}

		return true;
	};

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
		// If missing throw or ignore
		if ( directoryMissing( arguments.directory ) ) {
			if ( arguments.throwOnMissing ) {
				throw(
					type    = "cbfs.DirectoryNotFoundException",
					message = "Directory [#arguments.directory#] not found."
				);
			}
			return false;
		}

		// Proxy it and delete like an egyptian!
		variables.jFiles.walkFileTree(
			buildJavaDiskPath( arguments.directory ),
			createDynamicProxy(
				wirebox
					.getInstance( "DeleteAllVisitor@cbfs" )
					.setExcludeRoot( buildDiskPath( arguments.directory ) ),
				[ "java.nio.file.FileVisitor" ]
			)
		);

		return this;
	}

	/**
	 * Get an array listing of all files and directories in a directory.
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 * @type      Filter the result to only include files, directories, or both. ('file|files', 'dir|directory', 'all'). Default is 'all'
	 * @absolute  Local provider only: We return relative disk paths by default. If true, we return absolute paths
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function contents(
		required directory,
		any filter,
		sort,
		boolean recurse  = false,
		type             = "all",
		boolean absolute = false
	){
		// If missing throw or ignore
		if ( directoryMissing( arguments.directory ) ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "Directory [#arguments.directory#] not found."
			);
		}

		// Move to nio later
		return directoryList(
			buildDiskPath( arguments.directory ), // path
			arguments.recurse, // recurse
			"path", // listinfo
			isNull( arguments.filter ) ? "" : arguments.filter, // filter
			isNull( arguments.sort ) ? "" : arguments.sort, // sort
			arguments.type // type
		).map( function( item ){
			return absolute ? arguments.item : arguments.item.replace( variables.properties.path, "" );
		} );
	}

	/**
	 * Get an array listing of all files and directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @type      Filter the result to only include files, directories, or both. ('file|files', 'dir|directory', 'all'). Default is 'all'
	 * @absolute  Local provider only: We return relative disk paths by default. If true, we return absolute paths
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function allContents(
		required directory,
		any filter,
		sort,
		type             = "all",
		boolean absolute = false
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
	 * @absolute  Local provider only: We return relative disk paths by default. If true, we return absolute paths
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function files(
		required directory,
		any filter,
		sort,
		boolean recurse  = false,
		boolean absolute = false
	){
		arguments.type = "file";
		return contents( argumentCollection = arguments );
	};

	/**
	 * Get an array of all directories in a directory.
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 * @absolute  Local provider only: We return relative disk paths by default. If true, we return absolute paths
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function directories(
		required directory,
		any filter,
		sort,
		boolean recurse  = false,
		boolean absolute = false
	){
		arguments.type = "Dir";
		return contents( argumentCollection = arguments );
	};

	/**
	 * Get an array of all files in a directory using recursion, this is a shortcut to the `files()` with recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @absolute  Local provider only: We return relative disk paths by default. If true, we return absolute paths
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function allFiles(
		required directory,
		any filter,
		sort,
		boolean absolute = false
	){
		arguments.type    = "File";
		arguments.recurse = true;
		return contents( argumentCollection = arguments );
	};

	/**
	 * Get an array of all directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @absolute  Local provider only: We return relative disk paths by default. If true, we return absolute paths
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function allDirectories(
		required directory,
		any filter,
		sort,
		boolean absolute = false
	){
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
	 * - Name
	 * - Size
	 * - etc
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 * @extended  Default of false produces basic file info, true, produces posix extended info.
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function filesMap(
		required directory,
		any filter,
		sort,
		boolean recurse  = false,
		boolean extended = false
	){
		return files( argumentCollection = arguments ).map( function( item ){
			return extended ? extendedInfo( arguments.item ) : info( arguments.item );
		} );
	};

	/**
	 * Get an array of structs of all recursive files in a directory and their appropriate information map:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Name
	 * - Size
	 * - etc
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @extended  Default of false produces basic file info, true, produces posix extended info.
	 *
	 * @throws cbfs.DirectoryNotFoundException
	 */
	array function allFilesMap(
		required directory,
		any filter,
		sort,
		boolean extended = false
	){
		arguments.recurse = true;
		return filesMap( argumentCollection = arguments );
	};

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
		return files( argumentCollection = arguments ).map( function( item ){
			return {
				"path"     : arguments.item,
				"contents" : get( arguments.item ),
				"size"     : size( arguments.item )
			};
		} );
	};

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
	};

	/**
	 * This function builds the path on the provided disk from it's root + incoming path
	 * with normalization, cleanup and canonicalization.
	 *
	 * @path The path on the disk to build
	 *
	 * @return The canonical path on the disk
	 */
	function buildDiskPath( required string path ){
		var pathTarget = normalizePath( arguments.path );
		return pathTarget.startsWith( variables.properties.path ) ? pathTarget : getCanonicalPath(
			variables.properties.path & "/#pathTarget#"
		).reReplace( "\/$", "" );
	}

	/**************************************** STREAM METHODS ****************************************/

	/**
	 * Return a Java stream of the file using non-blocking IO classes. The stream will represent every line in the file so you can navigate through it.
	 * This method leverages the `cbstreams` library used accordingly by implementations (https://www.forgebox.io/view/cbstreams)
	 *
	 * @path The path to read all the files with
	 *
	 * @return Stream object: See https://apidocs.ortussolutions.com/coldbox-modules/cbstreams/1.1.0/index.html
	 */
	function stream( required path ){
		return wirebox
			.getInstance( "StreamBuilder@cbstreams" )
			.new()
			.ofFile( buildDiskPath( arguments.path ) );
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
		return wirebox.getInstance( "StreamBuilder@cbstreams" ).new( arguments.target );
	}

	/**
	 * Find path names matching a given globbing pattern
	 *
	 * @pattern The globbing pattern to match
	 */
	array function glob( required pattern ){
		// Look at find() in the nio package
		throw( "Not Implemented Yet" );
	}

	/**************************************** PRIVATE HELPER METHODS ****************************************/

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
		return variables.jFiles.createDirectories( getJavaPath( arguments.path ), [] );
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
		if ( !exists( arguments.path ) ) {
			throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
		}
		return arguments.path;
	}

	/**
	 * Converts a CF Binary object in to its numeric bit representation
	 *
	 * @input the binary object to parse
	 */
	function binaryValues( required binary input ){
		var byteBuffer = createObject( "java", "java.nio.ByteBuffer" ).allocate( javacast( "int", 4 ) );

		byteBuffer.put(
			arguments.input,
			javacast( "int", 0 ),
			javacast( "int", 4 )
		);

		return ( byteBuffer.getInt( javacast( "int", 0 ) ) );
	}

}
