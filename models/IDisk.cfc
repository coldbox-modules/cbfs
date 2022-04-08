/**
 * The disk interface is used to implement a storage provider backend.
 * Each disk implementation represents a specific provider and location and can contain many more functions a part from the
 * ones defined in this interface.  This is the base abstraction layer to storages.
 *
 * @author Luis Majano
 */
interface {

	/**
	 * Get the unique UUID identifier for this disk
	 */
	string function getIdentifier();

	/**
	 * Returns true if the disk has been started up, false if not.
	 */
	boolean function hasStarted();

	/**
	 * Returns the name of the disk.
	 */
	string function getName();

	/**
	 * Retrieves the settings for the disk.
	 */
	struct function getProperties();

	/**
	 * Startup a disk provider with the instance data it needs to startup. It needs to make sure
	 * that it sets the "started" variable to true in order to operate.
	 *
	 * @name       The name of the disk
	 * @properties A struct of configuration data for this provider, usually coming from the configuration file
	 *
	 * @return cbfs.models.IDisk
	 */
	any function startup( required string name, struct properties = {} );

	/**
	 * Called before the cbfs module is unloaded, or via reinits. This can be implemented
	 * as you see fit to gracefully shutdown connections, sockets, etc.
	 *
	 * @return cbfs.models.IDisk
	 */
	any function shutdown();

	/**
	 * Create a file in the disk
	 *
	 * @path       The file path to use for storage
	 * @contents   The contents of the file to store
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 * @metadata   Struct of metadata to store with the file
	 * @override   Flag to overwrite the file at the destination, if it exists. Defaults to true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileOverrideException - When a file exists and no override has been provided
	 */
	function create(
		required path,
		required contents,
		visibility,
		struct metadata,
		boolean overwrite
	);

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
	any function setVisibility( required string path, required string visibility );

	/**
	 * Get the storage visibility of a file, the return format can be a string of `public, private, readonly` or a custom data type the implemented driver can interpret.
	 *
	 * @path The target file
	 *
	 * @return The visibility of the requested file
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function visibility( required string path );

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
	any function prepend(
		required string path,
		required contents,
		struct metadata,
		boolean throwOnMissing
	);

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
	any function append(
		required string path,
		required contents,
		struct metadata,
		boolean throwOnMissing
	);

	/**
	 * Copy a file from one destination to another
	 *
	 * @source      The source file path
	 * @destination The end destination path
	 * @override    Flag to overwrite the file at the destination, if it exists. Defaults to true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function copy(
		required source,
		required destination,
		boolean overwrite = true
	);

	/**
	 * Move a file from one destination to another
	 *
	 * @source      The source file path
	 * @destination The end destination path
	 * @override    Flag to overwrite the file at the destination, if it exists. Defaults to true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function move(
		required source,
		required destination,
		boolean overwrite
	);

	/**
	 * Rename a file from one destination to another. Shortcut to the `move()` command
	 *
	 * @source      The source file path
	 * @destination The end destination path
	 * @override    Flag to overwrite the file at the destination, if it exists. Defaults to true.
	 *
	 * @return cbfs.models.IDisk
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function rename(
		required source,
		required destination,
		boolean overwrite
	);

	/**
	 * Get the contents of a file
	 *
	 * @path The file path to retrieve
	 *
	 * @return The contents of the file
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function get( required path );

	/**
	 * Get the contents of a file as binary, such as an executable or image
	 *
	 * @path The file path to retrieve
	 *
	 * @return A binary representation of the file
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	any function getAsBinary( required path );

	/**
	 * Validate if a file/directory exists
	 *
	 * @path The file/directory path to verify
	 */
	boolean function exists( required string path );

	/**
	 * Validate if a file/directory doesn't exist
	 *
	 * @path The file/directory path to verify
	 */
	boolean function missing( required string path );

	/**
	 * Get the URL for the given file
	 *
	 * @path The file path to build the URL for
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function url( required string path );

	/**
	 * Get a temporary URL for the given file
	 *
	 * @path       The file path to build the URL for
	 * @expiration The number of minutes this URL should be valid for.
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function temporaryURL( required path, numeric expiration );

	/**
	 * Retrieve the size of the file in bytes
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	numeric function size( required path );

	/**
	 * Retrieve the file's last modified timestamp
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function lastModified( required path );

	/**
	 * Retrieve the file's mimetype
	 *
	 * @path The file path location
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	function mimeType( required path );

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
	boolean function delete( required any path, boolean throwOnMissing );

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
	function touch( required path, boolean createpath );

	/**
	 * Return information about the file.  Will contain keys such as lastModified, size, path, name, type, canWrite, canRead, isHidden and more
	 *
	 * @path The file path
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	struct function info( required path );

	/**
	 * Generate checksum for a file in different hashing algorithms
	 *
	 * @path      The file path
	 * @algorithm Default is MD5, but SHA-1, SHA-256, and SHA-512 can also be used.
	 *
	 * @throws cbfs.FileNotFoundException
	 */
	string function checksum( required path, algorithm );

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
	 *
	 * @throws cbfs.FileNotFoundException
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
	 * Find path names matching a given globbing pattern
	 *
	 * @pattern The globbing pattern to match
	 */
	array function glob( required pattern );

	/**
	 * Sets the access attributes of the file on Unix based disks
	 *
	 * @path The file path
	 * @mode Access mode, the same attributes you use for the Linux command `chmod`
	 */
	IDisk function chmod( required string path, required string mode );

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
	 * @directory    The directory path
	 * @createPath   Create parent directory paths when they do not exist
	 * @ignoreExists If false, it will throw an error if the directory already exists, else it ignores it if it exists. This should default to true.
	 *
	 * @return cbfs.models.IDisk
	 */
	function createDirectory(
		required directory,
		boolean createPath,
		boolean ignoreExists
	);

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
	 * @return cbfs.models.IDisk
	 */
	function copyDirectory(
		required source,
		required destination,
		boolean recurse,
		any filter,
		boolean createPath
	);

	/**
	 * Move a directory
	 *
	 * @oldPath    The source directory
	 * @newPath    The destination directory
	 * @createPath If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 *
	 * @return cbfs.models.IDisk
	 */
	function moveDirectory(
		required oldPath,
		required newPath,
		boolean createPath
	);

	/**
	 * Rename a directory, facade to `moveDirectory()`
	 *
	 * @oldPath    The source directory
	 * @newPath    The destination directory
	 * @createPath If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
	 *
	 * @return cbfs.models.IDisk
	 */
	function renameDirectory(
		required oldPath,
		required newPath,
		boolean createPath
	);

	/**
	 * Delete 1 or more directory locations
	 *
	 * @directory      The directory or an array of directories
	 * @recurse        Recurse the deletion or not, defaults to true
	 * @throwOnMissing Throws an exception if the directory does not exist
	 *
	 * @return A boolean value or a struct of booleans determining if the directory paths got deleted or not.
	 */
	boolean function deleteDirectory(
		required string directory,
		boolean recurse,
		boolean throwOnMissing
	);

	/**
	 * Empty the specified directory of all files and folders.
	 *
	 * @directory The directory
	 *
	 * @return cbfs.models.IDisk
	 */
	function cleanDirectory( required directory );

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
		boolean recurse
	);

	/**
	 * Get an array listing of all files and directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 * @recurse   Recurse into subdirectories, default is false
	 */
	array function allContents( required directory, any filter, sort );

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
	);

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
	);

	/**
	 * Get an array of all files in a directory using recursion, this is a shortcut to the `files()` with recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allFiles( required directory, any filter, sort );

	/**
	 * Get an array of all directories in a directory using recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allDirectories( required directory, any filter, sort );

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
	);

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
	array function allFilesMap( required directory, any filter, sort );

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
	);

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
	array function allDirectoriesMap( required directory, any filter, sort );

	/**
	 * Get an array of content from all the files from a specific directory
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
	);

	/**
	 * Get an array of content from all the files from a specific directory with recursion
	 *
	 * @directory The directory
	 * @filter    A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
	 * @sort      Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
	 */
	array function allContentsMap( required directory, any filter, sort );

}
