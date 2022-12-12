/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This is a s3 protocol implementation of a cbfs disk based off the S3SDK Module: https://forgebox.io/view/s3sdk
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>, Jon Clausen <jclausen@ortussolutions.com>
 */
component accessors="true" extends="cbfs.models.AbstractDiskProvider" {

	/**
	 * --------------------------------------------------------------------------
	 * Properties
	 * --------------------------------------------------------------------------
	 */
	property name="s3";

	/**
	 * --------------------------------------------------------------------------
	 * DI
	 * --------------------------------------------------------------------------
	 */
	property name="wirebox"       inject="wirebox";
	property name="templateCache" inject="cachebox:template";

	/**
	 * Return if startup has occurred.
	 *
	 * @return Boolean
	 */
	function hasStarted(){
		return !isNull( variables.s3 );
	}

	/**
	 * Configure the provider. Usually called at startup.
	 *
	 * @properties A struct of configuration data for this provider, usually coming from the configuration file
	 *
	 * @return S3Provider
	 */
	function startup( required string name, struct properties = {} ){
		// Param the properties
		param arguments.properties.awsDomain           = "amazonaws.com";
		param arguments.properties.awsRegion           = "us-east-1";
		param arguments.properties.encryptionCharset   = "UTF-8";
		param arguments.properties.signatureType       = "V4";
		param arguments.properties.ssl                 = true;
		param arguments.properties.defaultTimeOut      = 300;
		param arguments.properties.defaultDelimiter    = "/";
		param arguments.properties.defaultBucketName   = "";
		param arguments.properties.defaultCacheControl = "no-store, no-cache, must-revalidate";
		param arguments.properties.defaultStorageClass = "STANDARD";
		param arguments.properties.defaultACL          = "public-read";
		param arguments.properties.throwOnRequestError = true;
		param arguments.properties.retriesOnError      = 3;
		param arguments.properties.autoContentType     = false;
		param arguments.properties.autoMD5             = false;
		param arguments.properties.serviceName         = "s3";
		param arguments.properties.debug               = false;
		param arguments.properties.visibility          = "public";
		param arguments.properties.cacheLookups        = true;

		try {
			variables.s3 = createObject( "component", "s3sdk.models.AmazonS3" ).init(
				argumentCollection = arguments.properties
			);
			variables.wirebox.autowire( variables.s3 );
		} catch ( any e ) {
			throw(
				type    = "cbfs.ProviderConfigurationException",
				message = "The the S3Provider encountered a fatal error during configuration. The message received was #e.message#."
			);
		}

		// More params
		param arguments.properties.bucketName   = variables.s3.getDefaultBucketName();
		param arguments.properties.publicDomain = arguments.properties.bucketName & "." & variables.s3.getURLEndpointHostname();

		setName( arguments.name );
		setProperties( arguments.properties );

		intercept.announce( "cbfsOnDiskStart", { "disk" : this } );

		return this;
	}

	/**
	 * Called before the cbfs module is unloaded, or via reinits. This can be implemented
	 * as you see fit to gracefully shutdown connections, sockets, etc.
	 */
	function shutdown(){
		intercept.announce( "cbfsOnDiskShutdown", { "disk" : this } );
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
	 * @return S3Provider
	 */
	function create(
		required path,
		required contents,
		visibility        = variables.properties.visibility,
		struct metadata   = {},
		boolean overwrite = false
	){
		if ( !arguments.overwrite && exists( arguments.path ) ) {
			throw(
				type    = "cbfs.FileOverrideException",
				message = "Cannot create file. File already exists [Bucket: #variables.properties.bucketName#, Path: #buildPath( arguments.path )#]"
			);
		}

		switch ( arguments.visibility ) {
			case "private": {
				arguments.visibility = variables.s3.ACL_PRIVATE;
				break;
			}
			default: {
				arguments.visibility = variables.s3.ACL_PUBLIC_READ;
				break;
			}
		}

		arguments.path = buildPath( arguments.path );

		variables.s3.putObject(
			bucketName = variables.properties.bucketName,
			uri        = arguments.path,
			data       = arguments.contents,
			acl        = arguments.visibility
		);

		evictFromCache( arguments.path );

		arguments[ "disk" ] = this;
		intercept.announce( "cbfsOnFileCreate", arguments );

		return this;
	}

	/**
	 * Create a file in the disk from a file path
	 *
	 * @source       The file path to use for storage
	 * @directory    The target directory
	 * @name         The destination file name. If not provided it defaults to the file name from the source
	 * @visibility   The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 * @overwrite    Flag to overwrite the file at the destination, if it exists. Defaults to true.
	 * @deleteSource Flag to remove the source file upon creation in the disk.  Defaults to false.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileOverrideException - When a file exists and no override has been provided
	 */
	function createFromFile(
		required source,
		required directory,
		string name,
		string visibility    = variables.properties.visibility,
		boolean overwrite    = true,
		boolean deleteSource = false
	){
		if ( isNull( arguments.name ) ) arguments.name = name( source );

		var filePath = arguments.directory & "/" & arguments.name;
		if ( !arguments.overwrite && exists( filePath ) ) {
			throw(
				type    = "cbfs.FileOverrideException",
				message = "Cannot upload file. Destination already exists [#filePath#] and overwrite is false"
			);
		}

		switch ( arguments.visibility ) {
			case "private": {
				arguments.visibility = variables.s3.ACL_PRIVATE;
				break;
			}
			default: {
				arguments.visibility = variables.s3.ACL_PUBLIC_READ;
				break;
			}
		}

		variables.s3.putObjectFile(
			bucketName = variables.properties.bucketName,
			filePath   = arguments.source,
			uri        = buildPath( filePath ),
			acl        = arguments.visibility
		);

		if ( arguments.deleteSource ) {
			fileDelete( arguments.source );
		}

		return this;
	}


	/**
	 * Set the storage visibility of a file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 *
	 * @path       The target file
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 *
	 * @return S3Provider
	 */
	function setVisibility( required string path, required string visibility ){
		switch ( arguments.visibility ) {
			case "private": {
				arguments.visibility = variables.s3.ACL_PRIVATE;
				break;
			}
			default: {
				arguments.visibility = variables.s3.ACL_PUBLIC_READ;
				break;
			}
		}

		variables.s3.setAccessControlPolicy(
			bucketName = variables.properties.bucketName,
			uri        = buildPath( arguments.path ),
			acl        = arguments.visibility
		);

		return this;
	}

	/**
	 * Get the storage visibility of a file, the return format can be a string of `public, private, readonly` or a custom data type the implemented driver can interpret.
	 *
	 * @path The target file
	 */
	string function visibility( required string path ){
		try {
			var policies = variables.s3
				.getAccessControlPolicy(
					bucketName = variables.properties.bucketName,
					uri        = buildPath( arguments.path )
				)
				.filter( function( acl ){
					return acl.type == "Group" && findNoCase( "/AllUsers", acl.uri );
				} );

			var activePolicy = policies.len() ? policies[ 1 ] : javacast( "null", 0 );

			if ( !isNull( activePolicy ) ) {
				switch ( activePolicy.permission ) {
					case "READ":
						return variables.s3.ACL_PUBLIC_READ;
					case "READ_WRITE":
						return variables.s3.ACL_PUBLIC_READ_WRITE;
					case "AUTH_READ":
						return variables.s3.ACL_AUTH_READ;
					default: {
						return variables.s3.ACL_PRIVATE;
					}
				}
			} else {
				return variables.s3.ACL_PRIVATE;
			}
		} catch ( S3SDKError e ) {
			throw(
				type    = "cbfs.S3Provider.InvalidOperationException",
				message = "An error occurred while attempting to read the ACL permission on the requested object [#buildPath( arguments.path )#]. #e.message#"
			);
		}
	}

	/**
	 * Prepend contents to the beginning of a file
	 *
	 * @path           The file path to use for storage
	 * @contents       The contents of the file to prepend
	 * @metadata       Struct of metadata to store with the file
	 * @throwOnMissing Boolean flag to throw if the file is missing. Otherwise it will be created if missing.
	 *
	 * @return S3Provider
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function prepend(
		required string path,
		required contents,
		struct metadata        = {},
		boolean throwOnMissing = false
	){
		if ( !exists( arguments.path ) ) {
			if ( arguments.throwOnMissing ) {
				throwFileNotFoundException( arguments.path );
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
	 * @return S3Provider
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function append(
		required string path,
		required contents,
		struct metadata        = {},
		boolean throwOnMissing = false
	){
		if ( !exists( arguments.path ) ) {
			if ( arguments.throwOnMissing ) {
				throwFileNotFoundException( arguments.path );
			}
			evictFromCache( arguments.path );
			return create(
				path     = arguments.path,
				contents = arguments.contents,
				metadata = arguments.metadata
			);
		}
		return create(
			path      = arguments.path,
			contents  = get( arguments.path ) & arguments.contents,
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
	 * @return S3Provider
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function copy(
		required source,
		required destination,
		boolean overwrite = false
	){
		var sourceExists      = exists( arguments.source );
		var destinationExists = exists( arguments.destination );
		if ( !arguments.overwrite && destinationExists ) {
			throw(
				type    = "cbfs.FileOverrideException",
				message = "Cannot create file. File already exists [Bucket: #variables.properties.bucketName#, Path: #buildPath( arguments.destination )#]"
			);
		} else {
			if ( !exists( arguments.source ) ) {
				throwFileNotFoundException( arguments.source );
			}
		}

		if ( arguments.overwrite && destinationExists ) {
			delete( arguments.destination );
		}

		variables.s3.copyObject(
			fromBucket = variables.properties.bucketName,
			fromURI    = buildPath( arguments.source ),
			toBucket   = variables.properties.bucketName,
			toURI      = buildPath( arguments.destination ),
			acl        = visibility( arguments.source )
		);

		evictFromCache( buildPath( arguments.destination ) );

		intercept.announce(
			"cbfsOnFileCopy",
			{
				"source"      : arguments.source,
				"destination" : arguments.destination,
				"disk"        : this
			}
		);

		return this;
	}

	/**
	 * Move a file from one destination to another
	 *
	 * @source      The source file path
	 * @destination The end destination path
	 *
	 * @return S3Provider
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function move(
		required source,
		required destination,
		boolean overwrite = false
	){
		if ( !arguments.overwrite && exists( arguments.destination ) ) {
			throw(
				type    = "cbfs.FileOverrideException",
				message = "Cannot create file. File already exists [Bucket: #variables.properties.bucketName#, Path: #buildPath( arguments.destination )#]"
			);
		} else {
			if ( !exists( arguments.source ) ) {
				throwFileNotFoundException( arguments.source );
			}
		}

		arguments.source      = buildPath( arguments.source );
		arguments.destination = buildPath( arguments.destination );

		variables.s3.copyObject(
			fromBucket = variables.properties.bucketName,
			fromURI    = arguments.source,
			toBucket   = variables.properties.bucketName,
			toURI      = arguments.destination,
			acl        = visibility( arguments.source )
		);

		evictFromCache( [ arguments.source, arguments.destination ] );

		intercept.announce(
			"cbfsOnFileMove",
			{
				"source"      : arguments.source,
				"destination" : arguments.destination,
				"disk"        : this
			}
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
		ensureFileExists( arguments.path );
		arguments.path = buildPath( arguments.path );
		// ACF will not allow us to read the file directly via URL
		if ( server.coldfusion.productVersion.listFirst() >= 2018 ) {
			var tempFileName = createUUID() & "." & extension( arguments.path );

			if ( getProperties().keyExists( "tempDirectory" ) ) {
				var tempDir = getProperties().tempDirectory;
				if ( !this.directoryExists( expandPath( tempDir ) ) ) this.directoryCreate( expandPath( tempDir ) );
				var tempFilePath = expandPath( tempDir & "/" & tempFileName );
			} else {
				var tempFilePath = getTempFile( getTempDirectory(), tempFileName );
				// the function above touches a file on ACF so we need to delete it
				if ( fileExists( tempFilePath ) ) fileDelete( tempFilePath );
			}

			variables.s3.downloadObject(
				bucketName = variables.properties.bucketName,
				uri        = arguments.path,
				filepath   = tempFilePath
			);

			var fileContents = !isBinaryFile( arguments.path )
			 ? fileRead( tempFilePath )
			 : fileReadBinary( tempFilePath );
			fileDelete( tempFilePath );
			return fileContents;
		} else {
			return !isBinaryFile( arguments.path )
			 ? fileRead( url( arguments.path ) )
			 : fileReadBinary( url( arguments.path ) );
		}
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
		return toBinary( get( arguments.path ) );
	}

	/**
	 * Validate if a file exists
	 *
	 * @path  The file to verify
	 * @force If true, it will skip any caching of existence checks, defaults to false
	 */
	boolean function exists( required string path, boolean force = false ){
		arguments.path = buildPath( arguments.path );
		var fLookup    = () => variables.s3.objectExists( bucketName = variables.properties.bucketName, uri = path );

		return variables.properties.cacheLookups && !arguments.force ? variables.templateCache.getOrSet(
			"s3fs_path_exists_#hash( arguments.path )#",
			fLookup
		) : fLookup();
	}

	/**
	 * Validate if a directory exists
	 *
	 * @path The directory to verify
	 */
	boolean function directoryExists( required string path ){
		arguments.path = buildDirectoryPath( arguments.path );

		return !!variables.s3
			.getBucket(
				bucketName = variables.properties.bucketName,
				prefix     = path,
				maxKeys    = 1
			)
			.len();
	}

	/**
	 * Get the URL for the given file
	 *
	 * @path The file path to build the URL for
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function url( required string path ){
		return variables.properties.visibility == "public"
		 ? publicUrl( arguments.path )
		 : temporaryURL( arguments.path );
	}

	/**
	 * Get a temporary URL for the given file
	 *
	 * @path       The file path to build the URL for
	 * @expiration The number of minutes this URL should be valid for.
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function temporaryURL( required path, numeric expiration = 1 ){
		return this.url(
			variables.s3.getAuthenticatedURL(
				bucketName   = variables.properties.bucketName,
				uri          = buildPath( arguments.path ),
				minutesValid = arguments.expiration
			)
		);
	}

	/**
	 * Retrieve the size of the file in bytes
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	numeric function size( required path ){
		return info( arguments.path ).size;
	}

	/**
	 * Retrieve the file's last modified timestamp
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function lastModified( required path ){
		return info( arguments.path ).lastModified;
	}

	/**
	 * Returns the mimetype of a file
	 *
	 * @path
	 **/
	function mimeType( required path ){
		return info( arguments.path ).type;
	}

	/**
	 * Deletes a file
	 *
	 * @path          
	 * @throwOnMissing When true an error will be thrown if the file does not exist
	 */
	boolean function delete( required any path, boolean throwOnMissing = false ){
		if ( this.exists( arguments.path ) ) {
			arguments.path = buildPath( arguments.path );
			variables.s3.deleteObject( bucketName = variables.properties.bucketName, uri = arguments.path );
			evictFromCache( arguments.path );
		} else if ( this.directoryExists( arguments.path ) ) {
			arguments.path = buildDirectoryPath( arguments.path );
			variables.s3.deleteObject( bucketName = variables.properties.bucketName, uri = arguments.path );
			evictFromCache( arguments.path );
		} else {
			if ( throwOnMissing ) {
				throwFileNotFoundException( arguments.path );
			}
			return false;
		}

		intercept.announce( "cbfsOnFileDelete", { "path" : normalizePath( arguments.path ), "disk" : this } );

		return true;
	}

	/**
	 * Create a new empty file if it does not exist
	 *
	 * @path       The file path
	 * @createPath if set to false, expects all parent directories to exist, true will generate necessary directories. Defaults to true.
	 *
	 * @return S3Provider
	 *
	 * @throws cbfs.PathNotFoundException
	 */
	function touch( required path, boolean createPath = true ){
		if ( !arguments.createPath && !this.directoryExists( getDirectoryFromPath( arguments.path ) ) ) {
			throw(
				type    = "cbfs.PathNotFoundException",
				message = "Directory does not already exist [#getDirectoryFromPath( arguments.path )#] and the `createPath` flag is set to false"
			);
		}
		evictFromCache( arguments.path );
		return append( arguments.path, "" );
	}

	/**
	 * Returns the information on a file
	 *
	 * @path
	 */
	struct function info( required path ){
		ensureFileExists( arguments.path );
		var filePath = buildPath( arguments.path );
		var s3Info   = variables.s3.getObjectInfo( bucketName = variables.properties.bucketName, uri = filePath );
		var acl      = visibility( arguments.path );
		var info     = {
			"name"         : getFileFromPath( filePath ),
			"lastModified" : s3Info[ "Last-Modified" ],
			"path"         : filePath,
			"parent"       : getDirectoryFromPath( filePath ),
			"size"         : s3Info[ "Content-Length" ],
			"type"         : s3Info[ "Content-Type" ],
			"canRead"      : findNoCase( "public-read", acl ),
			"canWrite"     : findNoCase( "-write", acl ) && acl == "private",
			"isHidden"     : acl == "private"
		};

		intercept.announce( "cbfsOnFileInfoRequest", info );

		return info;
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
		return hash( get( arguments.path ), arguments.algorithm );
	}

	/**
	 * Extract the file name from a file path
	 *
	 * @path The file path
	 */
	string function name( required path ){
		return getFileFromPath( buildPath( arguments.path ) );
	}

	/**
	 * Extract the extension from the file path
	 *
	 * @path The file path
	 */
	string function extension( required path ){
		var fileName = this.name( arguments.path );
		return listLen( fileName, "." ) > 1 ? listLast( fileName, "." ) : "";
	}

	/**
	 * Is the path a file or not
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	boolean function isFile( required path ){
		try {
			var ext = extension( arguments.path );
			ensureFileExists( arguments.path );
			return len( ext );
		} catch ( cbfs.FileNotFoundException e ) {
			return false;
		}
	}

	/**
	 * Is the path writable or not
	 *
	 * @path The file path
	 */
	boolean function isWritable( required path ){
		try {
			ensureFileExists( path );
		} catch ( cbfs.FileNotFoundException e ) {
			return false;
		}
		return visibility( path ) != "private";
	}

	/**
	 * Is the path readable or not
	 *
	 * @path The file path
	 */
	boolean function isReadable( required path ){
		try {
			ensureFileExists( path );
		} catch ( cbfs.FileNotFoundException e ) {
			return false;
		}
		return visibility( path ) != "private";
	}

	/**
	 * Is the file executable or not
	 *
	 * @path The file path
	 */
	boolean function isExecutable( required path ){
		return false;
	}

	/**
	 * Find path names matching a given globbing pattern
	 *
	 * @pattern The globbing pattern to match
	 */
	array function glob( required pattern ){
		throw( "Method not implemented" );
	}

	/**
	 * Sets the access attributes of the file on Unix based disks
	 *
	 * @path The file path
	 * @mode Access mode, the same attributes you use for the Linux command `chmod`
	 */
	function chmod( required string path, required string mode ){
		switch ( right( mode, 1 ) ) {
			case 7: {
				var acl = variables.s3.ACL_PUBLIC_READ_WRITE;
				break;
			}
			case 6:
			case 5: {
				var acl = variables.s3.ACL_PUBLIC_READ;
				break;
			}
			case 4: {
				var acl = variables.s3.ACL_AUTH_READ;
				break;
			}
			default: {
				var acl = variables.s3.ACL_PRIVATE;
			}
		}

		// S3Mock and some other providers do not support modifying the ACL
		try {
			variables.s3.setAccessControlPolicy(
				bucketName = variables.properties.bucketName,
				uri        = buildPath( arguments.path ),
				acl        = acl
			);
		} catch ( any e ) {
			if ( !findNoCase( "400 Bad Request", e.message ) ) {
				rethrow;
			}
		}

		return this;
	}

	/**
	 * Is the path a directory or not
	 *
	 * @path The directory path
	 */
	boolean function isDirectory( required path ){
		var fullPath = buildPath( arguments.path );
		return !!variables.s3
			.getBucket( bucketName = variables.properties.bucketName, prefix = fullPath )
			.filter( function( item ){
				return item.key == fullPath && item.isDirectory;
			} )
			.len();
	};

	/**
	 * Create a new directory
	 *
	 * @directory    The directory path
	 * @createPath   Create parent directory paths when they do not exist
	 * @ignoreExists If false, it will throw an error if the directory already exists, else it ignores it if it exists. This should default to true.
	 *
	 * @return S3Provider
	 */
	function createDirectory(
		required directory,
		boolean createPath   = true,
		boolean ignoreExists = true
	){
		if ( !ignoreExists && this.directoryExists( arguments.directory ) ) {
			throw(
				type    = "cbfs.DirectoryExistsException",
				message = "The destination directory [#arguments.directory#] already exists."
			);
		}

		arguments.directory = buildDirectoryPath( arguments.directory );

		variables.s3.putObjectFolder( bucketName = variables.properties.bucketName, uri = arguments.directory );

		intercept.announce( "cbfsOnDirectoryCreate", { "directory" : arguments.directory, "disk" : this } );

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
	 * @filter      A string wildcard or a lambda/closure that receives the file path and should return true to copy it.
	 * @createPath  If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 *
	 * @return S3Provider
	 */
	function copyDirectory(
		required source,
		required destination,
		boolean recurse    = false,
		any filter         = "",
		boolean createPath = true
	){
		var sourcePath      = buildDirectoryPath( arguments.source );
		var destinationPath = buildDirectoryPath( arguments.destination );

		if ( !arguments.createPath && !this.directoryExists( destinationPath ) ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "The destination directory [#destinationPath#] does not exist and the createPath argument is false."
			);
		}

		var bucketAssets = files(
			directory = sourcePath,
			filter    = arguments.filter,
			recurse   = arguments.recurse
		);

		bucketAssets.each( function( asset ){
			var destinationPath = buildPath( replace( asset.key, source, destination ) );
			variables.s3.copyObject(
				fromBucket = variables.properties.bucketName,
				fromURI    = buildPath( asset.key ),
				toBucket   = variables.properties.bucketName,
				toURI      = destinationPath,
				acl        = visibility( asset.key )
			);
			evictFromCache( destinationPath );
		} );
		evictFromCache( sourcePath );

		intercept.announce(
			"cbfsOnDirectoryCopy",
			{
				"source"      : arguments.source,
				"destination" : arguments.destination,
				"disk"        : this
			}
		);

		return this;
	};

	/**
	 * Move a directory
	 *
	 * @oldPath    The source directory
	 * @newPath    The destination directory
	 * @createPath If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 *
	 * @return S3Provider
	 */
	function moveDirectory(
		required source,
		required destination,
		boolean createPath = true
	){
		copyDirectory(
			source      = arguments.source,
			destination = arguments.destination,
			recurse     = true
		);

		deleteDirectory( source );

		evictFromCache( [ source, destination ] );

		intercept.announce(
			"cbfsOnDirectoryMove",
			{
				"source"      : arguments.source,
				"destination" : arguments.destination,
				"disk"        : this
			}
		);

		return this;
	}

	/**
	 * Delete one or more directory locations
	 *
	 * @directory      The directory or an array of directories
	 * @recurse        Recurse the deletion or not, defaults to true
	 * @throwOnMissing Throws an exception if the directory does not exist
	 *
	 * @return A boolean value or a struct of booleans determining if the directory paths got deleted or not.
	 */
	boolean function deleteDirectory(
		required string directory,
		boolean recurse        = true,
		boolean throwOnMissing = false
	){
		arguments.directory = buildDirectoryPath( arguments.directory );

		var exists = this.directoryExists( directory );

		if ( !exists ) {
			if ( arguments.throwOnMissing ) {
				throw(
					type    = "cbfs.DirectoryNotFoundException",
					message = "Directory [#arguments.directory#] not found."
				);
			}
			return false;
		}

		var results = variables.s3
			.getBucket( bucketName = variables.properties.bucketName, prefix = arguments.directory )
			.filter( function( file ){
				return file.key != directory;
			} );

		var foundDirectory = false;

		results.each( function( file ){
			if ( file.isDirectory ) {
				if ( recurse ) {
					deleteDirectory(
						directory      = file.key,
						recurse        = true,
						throwOnMissing = throwOnMissing
					);
				} else {
					foundDirectory = true;
				}
			} else {
				delete( path = file.key, throwOnMissing = throwOnMissing );
				evictFromCache( file.key );
			}
		} );

		delete( path = arguments.directory, throwOnMissing = arguments.throwOnMissing );

		evictFromCache( arguments.directory );

		intercept.announce( "cbfsOnDirectoryDelete", { "directory" : arguments.directory, "disk" : this } );

		return !foundDirectory ? true : false;
	}

	/**
	 * Empty the specified directory of all files and folders.
	 *
	 * @directory      The directory
	 * @throwOnMissing Throws an exception if the directory does not exist, defaults to false
	 *
	 * @return S3Provider
	 */
	function cleanDirectory( required directory, boolean throwOnMissing = false ){
		if ( this.directoryExists( arguments.directory ) ) {
			deleteDirectory( arguments.directory, true );
			createDirectory( arguments.directory );
			evictFromCache( arguments.directory );
			return this;
		}

		if ( throwOnMissing ) {
			throw(
				type    = "cbfs.DirectoryNotFoundException",
				message = "Directory [#arguments.directory#] not found."
			);
		}
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
	 */
	array function contents(
		required directory,
		any filter       = "",
		sort             = "",
		boolean recurse  = false,
		type             = "all",
		boolean absolute = false
	){
		var sourcePath = arguments.directory;

		if ( !this.directoryExists( sourcePath ) ) {
			throw( type = "cbfs.DirectoryNotFoundException", message = "Directory [#sourcePath#] not found." );
		}

		// Ensure we do a folder search within S3
		sourcePath = buildDirectoryPath( sourcePath );

		var bucketContents = variables.s3
			.getBucket( bucketName = variables.properties.bucketName, prefix = sourcePath )
			.reduce( function( agg, item ){
				if ( type == "dir" && !item.isDirectory ) {
					return agg;
				}

				if ( item.isDirectory ) {
					if ( type != "file" ) {
						agg.append( item );
					}
					if ( recurse && item.key != sourcePath ) {
						agg.append(
							contents(
								directory = item.key,
								filter    = filter,
								sort      = sort,
								recurse   = recurse,
								type      = type,
								absolute  = absolute,
								map       = true
							),
							true
						)
					}
				} else if ( listLen( item.key, "." ) > 1 || val( item.size ) > 0 ) {
					agg.append( item );
				}
				return agg;
			}, [] )
			.filter( function( item ){
				if ( item.key == sourcePath ) {
					return false;
				} else if ( !isNull( filter ) && isClosure( filter ) ) {
					return filter( item.key );
				} else if ( !isNull( filter ) && len( filter ) ) {
					return reFindNoCase( filter.replace( "*.", ".*\." ), item.key );
				} else {
					return true;
				}
			} );

		if ( !structKeyExists( arguments, "map" ) || !arguments.map ) {
			return bucketContents.map( function( item ){
				return len( getProperties().path ) ? replaceNoCase( item.key, getProperties().path, "" ) : item.key;
			} );
		} else {
			return bucketContents;
		}
	}

	/**
	 * Get an array listing of all files and directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @type      Filter the result to only include files, directories, or both. ('file|files', 'dir|directory', 'all'). Default is 'all'
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
	 */
	array function files(
		required directory,
		any filter,
		sort,
		boolean recurse = false
	){
		arguments.map  = true;
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
	 */
	array function directories(
		required directory,
		any filter,
		sort,
		boolean recurse = false
	){
		arguments.type = "directory";
		arguments.map  = true;
		return contents( argumentCollection = arguments )
			.filter( function( item ){
				return item.isDirectory;
			} )
			.map( function( item ){
				return len( getProperties().path ) ? replaceNoCase( item.key, getProperties().path, "" ) : item.key;
			} );
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
		return files( argumentCollection = arguments );
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
		return directories( argumentCollection = arguments );
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
		return contents( argumentCollection = arguments ).filter( function( item ){
			return !item.isDirectory;
		} );
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
		arguments.recurse = true;
		return filesMap( argumentCollection = arguments );
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
		return contents( argumentCollection = arguments ).filter( function( item ){
			return item.isDirectory;
		} );
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
		arguments.recurse = true;
		return directoriesMap( argumentCollection = arguments );
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
		return files( argumentCollection = arguments ).map( function( file ){
			return {
				"path"     : arguments.file.key,
				"contents" : get( arguments.file.key ),
				"size"     : arguments.file.size
			};
		} );
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
		return contentsMap( argumentCollection = arguments );
	};

	/**
	 * Is the file is hidden or not. Here to adhere to interface.
	 *
	 * @path The file path
	 */
	boolean function isHidden( required path ){
		return info( path ).isHidden;
	}

	/**
	 * Is the file is a symbolic link
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException - If the filepath is missing
	 */
	boolean function isSymbolicLink( required path ){
		return false;
	}

	/************************* PRIVATE METHODS *******************************/

	/**
	 * Expands the full path of the requested provider route
	 *
	 * @path The path to be expanded
	 */
	private function buildPath( required string path ){
		arguments.path   = replace( arguments.path, "\", "/", "all" );
		var pathSegments = listToArray( getProperties().path, "/" );
		pathSegments.append( listToArray( arguments.path, "/" ), true );

		return pathSegments.toList( "/" );
	}

	/**
	 * Ensures a file exists
	 *
	 * @path The path to be checked for existence
	 *
	 * @throws cbfs.FileNotFoundException Throws if the file does not exist
	 */
	private function ensureFileExists( required path ){
		if ( !exists( arguments.path ) ) {
			throwFileNotFoundException( arguments.path );
		}
		return this;
	}

	/**
	 * Ensures a directory exists - will create the directory if it does not exist
	 *
	 * @path The path to be checked for existence
	 */
	private function ensureDirectoryExists( required path ){
		var p             = buildPath( arguments.path );
		var directoryPath = len( extension( p ) ) ? replaceNoCase( p, getFileFromPath( p ), "" ) : p;

		if ( !this.directoryExists( directoryPath ) ) {
			variables.s3.putObjectFolder( bucketName = variables.properties.bucketName, uri = directoryPath );
		}
		return this;
	}

	/**
	 * Ensures proper pathing to a directory needed for S3.
	 *
	 * @path
	 *
	 * @return String
	 */
	private function buildDirectoryPath( path ){
		arguments.path = buildPath( arguments.path );

		if ( right( arguments.path, 1 ) != "/" ) {
			arguments.path &= "/";
		}
		return arguments.path;
	}

	/**
	 * Throws file not found exception
	 *
	 * @throw
	 */
	private function throwFileNotFoundException( path ){
		throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
	}

	/**
	 * Cache eviction for existence checks
	 *
	 * @paths an array or string list of paths
	 */
	private function evictFromCache( any paths ){
		if ( isSimpleValue( arguments.paths ) ) {
			arguments.paths = listToArray( arguments.paths );
		}

		arguments.paths.each( ( path ) => variables.templateCache.clear( "s3fs_path_exists_#hash( path )#" ) );

		return this;
	}

	/**
	 * Builds a public URL for the resource
	 */
	private function publicUrl( required string path ){
		var uri         = buildPath( arguments.path );
		var urlEndpoint = replace(
			variables.s3.getUrlEndpoint(),
			variables.s3.getURLEndpointHostname(),
			variables.properties.publicDomain
		) & "/";
		return urlEndpoint & uri;
	}

}
