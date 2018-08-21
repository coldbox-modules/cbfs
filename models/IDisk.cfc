/**
 * The disk interface is used to implement a storage provider backend.
 * Each disk implementation represents a specific provider and location and can contain many more functions a part from the
 * ones defined in this interface.  This is the base abstraction layer to storages.
 *
 * @author Luis Majano
 */
interface{

	/**
	 * Configure the provider. Usually called at startup.
	 *
	 * @properties A struct of configuration data for this provider, usually coming from the configuration file
	 *
	 * @return IDisk
	 */
	function configure( required struct properties );

	/**
	 * Called before the cbfs module is unloaded, or via reinits. This can be implemented
	 * as you see fit to gracefully shutdown connections, sockets, etc.
	 */
	function shutdown();

	/**
	 * Store a file
	 *
	 * @path The file path to use for storage
	 * @contents The contents of the file to store
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 * @metadata Struct of metadata to store with the file
	 *
	 * @return IDisk
	 */
	function put(
		required path,
		required contents,
		visibility,
		struct metadata
	);

	/**
	 * A nice way to put a file directly from an upload
	 *
	 * @fileField The file field used in the upload
	 * @path The destination to store the file to
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 * @metadata Struct of metadata to store with the file
	 * @overwrite If we should overwrite the files or not at the destination if they exist
	 * @accept Limits the MIME types to accept. Comma-delimited list.
	 */
	function upload(
		required fileField,
		required path,
		required contents,
		visibility,
		struct metadata
	);

	/**
	 * Set the storage visibility of a file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 *
	 * @path The target file
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 *
	 * @return IDisk
	 */
	function setVisibility( required path, required visibility );

	/**
	 * Get the storage visibility of a file, the return format can be a string of `public, private, readonly` or a custom data type the implemented driver can interpret.
	 *
	 * @path The target file
	 */
	any function getVisibility( required path );

	/**
	 * Prepend contents to the beginning of a file
	 *
	 * @path The file path to use for storage
	 * @contents The contents of the file to prepend
	 * @metadata Struct of metadata to store with the file
	 *
	 * @return IDisk
	 */
	function prepend( required path, required contents, struct metadata );

	/**
	 * Append contents to the end of a file
	 *
	 * @path The file path to use for storage
	 * @contents The contents of the file to append
	 * @metadata Struct of metadata to store with the file
	 *
	 * @return IDisk
	 */
	function append( required path, required contents, struct metadata );

	/**
	 * Copy a file from one destination to another
	 *
	 * @source The source file path
	 * @destination The end destination path
	 *
	 * @return IDisk
	 */
	function copy( required source, required destination );

	/**
	 * Move/rename a file from one destination to another
	 *
	 * @source The source file path
	 * @destination The end destination path
	 *
	 * @return IDisk
	 */
	function move( required source, required destination );

	/**
	 * Get the contents of a file
	 *
	 * @path The file path to retrieve
	 *
	 * @throws FileNotFoundException
	 *
	 * @return The contents of the file
	 */
	any function get( required path );

	/**
	 * Get the contents of a file as binary, such as an executable or image
	 *
	 * @path The file path to retrieve
	 *
	 * @throws FileNotFoundException
	 *
	 * @return A binary representation of the file
	 */
	any function getAsBinary( required path );

	/**
	 * Validate if a file/directory exists
	 *
	 * @path The file/directory path to verify
	 */
	boolean function exists( required path );

	/**
	 * Generates a response that forces the user's browser to download the file at the given path
	 *
	 * @path The file path to download
	 * @name The name of the file the user will see when downloading, usually by setting the content header.  If not passed, it should use the filename in the path
	 * @headers Any additional headers to send with the download request
	 * @mimeType Force the mimetype of the download else we deduct it from the file
	 * @disposition The browser content disposition, `attachment` or `inline`
	 * @abortAtEnd Do an abort after content is sent, this should default to false
	 * @deleteFile Remove the file once it has been delivered, this defaults to false
	 *
	 * @return IDisk
	 */
	boolean function download(
		required path,
		name,
		struct headers,
		mimeType,
		disposition,
		boolean abortAtEnd,
		boolean deleteFile
	);

	/**
	 * Get the URL for the given file
	 *
	 * @path The file path to build the URL for
	 */
	string function url( required path );

	/**
	 * Get a temporary URL for the given file
	 *
	 * @path The file path to build the URL for
	 * @expiration The number of minutes this URL should be valid for.
	 */
	string function temporaryURL( required path, numeric expiration );

	/**
	 * Retrieve the size of the file in bytes
	 *
	 * @path The file path location
	 */
	numeric function size( required path );

	/**
	 * Retrieve the file's last modified timestamp
	 *
	 * @path The file path location
	 */
	function lastModified( required path );

	/**
	 * Retrieve the file's mimetype
	 *
	 * @path The file path location
	 */
	function mimeType( required path );

	/**
	 * Delete a file or an array of file pths. If a file does not exist a `false` will be
	 * shown for it's return.
	 *
	 * @path A single file path or an array of file paths
	 *
	 * @return boolean or struct report of deletion
	 */
	function delete( required path );

	/**
	 * Create a new empty file if it does not exist
	 *
	 * @path The file path
	 * @createPath if set to false, expects all parent directories to exist, true will generate necessary directories. Defaults to true.
	 *
	 * @return IDisk
	 */
	function touch( required path, boolean createpath );

	/**
	 * Return information about the file.  Will contain keys such as lastModified, size, path, name, type, canWrite, canRead, isHidden and more
	 *
	 * @path The file path
	 */
	struct function info( required path );

	/**
	 * Get the md5 hash checksum of the file
	 *
	 * @path the file path
	 */
	string function md5( required path );

	/**
	 * Extract the file name from a file path
	 *
	 * @path The file path
	 */
	string function name( required path );

	/**
	 * Extract the extension from the file path
	 *
	 * @path The file path
	 */
	string function extension( required path );

	/**
	 * Is the path a file or not
	 *
	 * @path The file path
	 */
	boolean function isFile( required path );

	/**
	 * Is the path writable or not
	 *
	 * @path The file path
	 */
	boolean function isWritable( required path );

	/**
	 * Is the path readable or not
	 *
	 * @path The file path
	 */
	boolean function isReadable( required path );

	/**
	 * Find path names matching a given pattern
	 *
	 * @pattern
	 */
	array function glob( required pattern );

	/**
	 * Sets the access attributes of the file on Unix based disks
	 *
	 * @path The file path
	 * @mode Access mode, the same attributes you use for the Linux command `chmod`
	 */
	function chmod( required path, required mode );

	/**************************************** STREAM METHODS ****************************************/

	/**
	 * Return a Java stream of the file using non-blocking IO classes. The stream will represent every line in the file so you can navigate through it.
	 * This method leverages the `cbstreams` library used accordingly by implementations (https://www.forgebox.io/view/cbstreams)
	 *
	 * @path
	 *
	 * @return Stream object: See https://apidocs.ortussolutions.com/coldbox-modules/cbstreams/1.1.0/index.html
	 */
	function stream( required path );

	/**
	 * Create a Java stream of the incoming array of files/directories usually called from this driver as well.
	 * <pre>
	 * disk.streamOf( disk.files( "my.path" ) )
	 * 	.filter( function( item ){
	 *		return item.startsWith( "a" );
	 *	} )
	 *	.forEach( function( item ){
	 *		writedump( item );
	 *	} );
	 * </pre>
	 *
	 * @target The target array of files/directories to generate a stream of
	 *
	 * @return Stream object: See https://apidocs.ortussolutions.com/coldbox-modules/cbstreams/1.1.0/index.html
	 */
	function streamOf( required array target );

	/**************************************** DIRECTORY METHODS ****************************************/

	/**
	 * Is the path a directory or not
	 *
	 * @path The directory path
	 */
	boolean function isDirectory( required path );

	/**
	 * Create a new directory
	 *
	 * @directory The directory path
	 * @createPath Create parent directory paths when they do not exist
	 * @ignoreExists If false, it will throw an error if the directory already exists, else it ignores it if it exists. This should default to true.
	 *
	 * @return IDisk
	 */
	function newDirectory( required directory, boolean createPath, boolean ignoreExists );

	/**
	 * Copies a directory to a destination
	 *
	 * The `filter` argument can be a closure and lambda with the following format
	 * <pre>
	 * boolean:function( path )
	 * </pre>
	 *
	 * @source The source directory
	 * @destination The destination directory
	 * @recurse If true, copies all subdirectories, otherwise only files in the source directory. Default is false.
	 * @filter A string wildcard or a lambda/closure that receives the file path and should return true to copy it.
	 * @createPath If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 *
	 * @return IDisk
	 */
	function copyDirectory(
		required source,
		required destination,
		boolean recurse,
		any filter,
		boolean createPath
	);

	/**
	 * Move or Rename a directory
	 *
	 * @oldPath The source directory
	 * @newPath The destination directory
	 * @createPath If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 *
	 * @return IDisk
	 */
	function moveDirectory(
		required oldPath,
		required newPath,
		boolean createPath
	);

	/**
	 * Delete 1 or more directory locations
	 *
	 * @directory The directory or an array of directories
	 * @recurse Recurse the deletion or not, defaults to true
	 *
	 * @return A boolean value or a struct of booleans determining if the directory paths got deleted or not.
	 */
	any function deleteDirectory( required directory, boolean recurse );

	/**
	 * Empty the specified directory of all files and folders.
	 *
	 * @directory The directory
	 *
	 * @return IDisk
	 */
	function cleanDirectory( required directory );

	/**
	 * Get an array of all files in a directory.
	 *
	 * @directory The directory
	 * @recurse Recurse into subdirectories, default is false
	 * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function files( required directory, boolean recurse, any filter, sort );

	/**
	 * Get an array of all directories in a directory.
	 *
	 * @directory The directory
	 * @recurse Recurse into subdirectories, default is false
	 * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function directories( required directory, boolean recurse, any filter, sort );

	/**
	 * Get an array of all files in a directory using recursion, this is a shortcut to the `files()` with recursion
	 *
	 * @directory The directory
	 * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allFiles( required directory, any filter, sort );

	/**
	 * Get an array of all directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allDirectories( required directory, any filter, sort );

	/**
	 * Get a structure of all files in a directory and their appropriate information map including:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 *
	 * @directory The directory
	 * @recurse Recurse into subdirectories, default is false
	 * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	struct function filesMap( required directory, boolean recurse, any filter, sort );

	/**
	 * Get a structure of all files in a directory with recursion and their appropriate information map including:
	 * - Attributes
	 * - DateLastModified
	 * - Directory
	 * - Link
	 * - Mode
	 * - Name
	 * - Size
	 *
	 * @directory The directory
	 * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allFilesMap( required directory, any filter, sort );


}