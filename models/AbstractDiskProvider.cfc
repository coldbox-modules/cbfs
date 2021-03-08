component accessors="true" {

    property name="name" type="string";
    property name="properties" type="struct";

    property name="streamBuilder" inject="StreamBuilder@cbstreams";

    /**
     * Configure the provider. Usually called at startup.
     *
     * @properties A struct of configuration data for this provider, usually coming from the configuration file
     *
     * @return IDiskProvider
     */
    public IDisk function configure( required string name, struct properties = {} ) {
        setName( arguments.name );
        setProperties( arguments.properties );
        return this;
    }

    /**
     * Called before the cbfs module is unloaded, or via reinits. This can be implemented
     * as you see fit to gracefully shutdown connections, sockets, etc.
     */
    public IDisk function shutdown() {
        return this;
    }

    /**
     * Create a file in the disk
     *
     * @path The file path to use for storage
     * @contents The contents of the file to store
     * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
     * @metadata Struct of metadata to store with the file
     * @overwrite If we should overwrite the files or not at the destination if they exist, defaults to true
     *
     * @return IDiskProvider
     */
    function create(
        required path,
        required contents,
        visibility,
        struct metadata,
        boolean overwrite
    ) {
        if ( !len( arguments.overwrite ) && this.exists( arguments.path ) ) {
            throw(
                type = "cbfs.FileOverrideException",
                message = "Cannot create file. File already exists [#arguments.path#]"
            );
        }
        ensureDirectoryExists( arguments.path );
        fileWrite( buildPath( arguments.path ), arguments.contents );

        return this;
    }

    /**
     * Set the storage visibility of a file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
     *
     * @path The target file
     * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
     *
     * @return IDiskProvider
     */
    public IDisk function setVisibility( required string path, required string visibility ) {
        return this;
    }

    /**
     * Get the storage visibility of a file, the return format can be a string of `public, private, readonly` or a custom data type the implemented driver can interpret.
     *
     * @path The target file
     */
    public string function visibility( required string path ) {
        return "public";
    }

    /**
     * Prepend contents to the beginning of a file
     *
     * @path The file path to use for storage
     * @contents The contents of the file to prepend
     * @metadata Struct of metadata to store with the file
     * @throwOnMissing Boolean flag to throw if the file is missing. Otherwise it will be created if missing.
     *
     * @throws cbfs.FileNotFoundException
     *
     * @return IDiskProvider
     */
    function prepend(
        required string path,
        required contents,
        struct metadata = {},
        boolean throwOnMissing = false
    ) {
        if ( !this.exists( arguments.path ) ) {
            if ( arguments.throwOnMissing ) {
                throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
            }
            return this.create( path = arguments.path, contents = arguments.contents, metadata = arguments.metadata );
        }
        return this.create(
            path = arguments.path,
            contents = arguments.contents & this.get( arguments.path ),
            overwrite = true
        );
    }

    /**
     * Append contents to the end of a file
     *
     * @path The file path to use for storage
     * @contents The contents of the file to append
     * @metadata Struct of metadata to store with the file
     * @throwOnMissing Boolean flag to throw if the file is missing. Otherwise it will be created if missing.
     *
     * @throws cbfs.FileNotFoundException
     *
     * @return IDiskProvider
     */
    function append(
        required string path,
        required contents,
        struct metadata = {},
        boolean throwOnMissing = false
    ) {
        if ( !this.exists( arguments.path ) ) {
            if ( arguments.throwOnMissing ) {
                throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
            }
            return this.create( path = arguments.path, contents = arguments.contents, metadata = arguments.metadata );
        }
        return this.create(
            path = arguments.path,
            contents = this.get( arguments.path ) & arguments.contents,
            overwrite = true
        );
    }

    /**
     * Copy a file from one destination to another
     *
     * @source The source file path
     * @destination The end destination path
     * @overwrite Flag to overwrite the file at the destination, if it exists. Defaults to true.
     *
     * @throws cbfs.FileNotFoundException
     *
     * @return IDiskProvider
     */
    function copy( required source, required destination, boolean overwrite = false ) {
        return this.create(
            path = arguments.destination,
            contents = this.get( arguments.source ),
            overwrite = arguments.overwrite
        );
    }

    /**
     * Move a file from one destination to another
     *
     * @source The source file path
     * @destination The end destination path
     *
     * @throws cbfs.FileNotFoundException
     *
     * @return IDiskProvider
     */
    function move( required source, required destination, boolean overwrite = false ) {
        this.create(
            path = arguments.destination,
            contents = this.get( arguments.source ),
            overwrite = arguments.overwrite
        );
        return this.delete( arguments.source );
    }

    /**
     * Rename a file from one destination to another. Shortcut to the `move()` command
     *
     * @source The source file path
     * @destination The end destination path
     *
     * @throws cbfs.FileNotFoundException
     *
     * @return IDiskProvider
     */
    function rename( required source, required destination, boolean overwrite = false ) {
        return this.move( argumentCollection = arguments );
    }

    /**
     * Get the contents of a file
     *
     * @path The file path to retrieve
     *
     * @throws cbfs.FileNotFoundException
     *
     * @return The contents of the file
     */
    any function get( required path ) {
        ensureFileExists( arguments.path );
        return fileRead( buildPath( arguments.path ) );
    }

    /**
     * Get the contents of a file as binary, such as an executable or image
     *
     * @path The file path to retrieve
     *
     * @throws cbfs.FileNotFoundException
     *
     * @return A binary representation of the file
     */
    public any function getAsBinary( required path ) {
        return toBinary( this.get( arguments.path ) );
    }

    /**
     * Validate if a file/directory exists
     *
     * @path The file/directory path to verify
     */
    boolean function exists( required string path ) {
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
     * Get the URL for the given file
     *
     * @throws cbfs.FileNotFoundException
     *
     * @path The file path to build the URL for
     */
    public string function url( required string path ) {
        ensureFileExists( arguments.path );
        return arguments.path;
    }

    /**
     * Get a temporary URL for the given file
     *
     * @path The file path to build the URL for
     * @expiration The number of minutes this URL should be valid for.
     *
     * @throws cbfs.FileNotFoundException
     */
    string function temporaryURL( required path, numeric expiration ) {
        return this.url( arguments.path );
    }

    /**
     * Retrieve the size of the file in bytes
     *
     * @path The file path location
     *
     * @throws cbfs.FileNotFoundException
     */
    numeric function size( required path ) {
        return this.info( arguments.path ).size;
    }

    /**
     * Retrieve the file's last modified timestamp
     *
     * @path The file path location
     *
     * @throws cbfs.FileNotFoundException
     */
    function lastModified( required path ) {
        return this.info( buildPath( arguments.path ) ).lastModified;
    }

    function mimeType( required path ) {
        ensureFileExists( arguments.path );
        return createObject( "java", "java.net.URLConnection" ).guessContentTypeFromName( arguments.path );
    }

    public boolean function delete( required string path, boolean throwOnMissing = false ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Create a new empty file if it does not exist
     *
     * @path The file path
     * @createPath if set to false, expects all parent directories to exist, true will generate necessary directories. Defaults to true.
     *
     * @throws cbfs.PathNotFoundException
     *
     * @return IDiskProvider
     */
    function touch( required path, boolean createPath = true ) {
        if ( this.exists( arguments.path ) ) {
            var fileContent = this.get( arguments.path );
            this.create( path = arguments.path, contents = fileContent, overwrite = true );
            return this;
        }
        if ( !createPath ) {
            var pathParts = path.listToArray( "/" );
            var directoryPath = "/" & pathParts.slice( 1, pathParts.len() - 1 ).toList( "/" );
            if ( !this.exists( directoryPath ) ) {
                throw(
                    type = "cbfs.PathNotFoundException",
                    message = "Directory does not already exist and the `createPath` flag is set to false"
                );
            }
        }
        return this.create( arguments.path, "" );
    }

    struct function info( required path ) {
        ensureFileExists( arguments.path );
        return getFileInfo( buildPath( arguments.path ) );
    }

    /**
     * Generate checksum for a file in different hashing algorithms
     *
     * @path The file path
     * @algorithm Default is MD5, but SHA-1, SHA-256, and SHA-512 can also be used.
     *
     * @throws cbfs.FileNotFoundException
     */
    string function checksum( required path, algorithm = "MD5" ) {
        ensureFileExists( arguments.path );
        return hash( this.get( arguments.path ), arguments.algorithm );
    }

    /**
     * Extract the file name from a file path
     *
     * @path The file path
     */
    string function name( required path ) {
        return listLast( arguments.path, "/" );
    }

    /**
     * Extract the extension from the file path
     *
     * @path The file path
     */
    string function extension( required path ) {
        return listLast( this.name( arguments.path ), "." );
    }

    /**
     * Is the path a file or not
     *
     * @path The file path
     *
     * @throws cbfs.FileNotFoundException
     */
    public boolean function isFile( required path ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Is the path writable or not
     *
     * @path The file path
     */
    boolean function isWritable( required path ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Is the path readable or not
     *
     * @path The file path
     */
    boolean function isReadable( required path ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Find path names matching a given globbing pattern
     *
     * @pattern The globbing pattern to match
     */
    array function glob( required pattern ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Sets the access attributes of the file on Unix based disks
     *
     * @path The file path
     * @mode Access mode, the same attributes you use for the Linux command `chmod`
     */
    public IDisk function chmod( required string path, required string mode ) {
        throw( "Implement in a subclass" );
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
    function stream( required path ) {
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
    function streamOf( required array target ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Is the path a directory or not
     *
     * @path The directory path
     */
    boolean function isDirectory( required path ) {
        try {
            return getFileInfo( buildPath( arguments.path ) ).type == "directory";
        } catch ( any e ) {
            return false;
        }
    };

    /**
     * Create a new directory
     *
     * @directory The directory path
     * @createPath Create parent directory paths when they do not exist
     * @ignoreExists If false, it will throw an error if the directory already exists, else it ignores it if it exists. This should default to true.
     *
     * @return IDiskProvider
     */
    function createDirectory( required directory, boolean createPath, boolean ignoreExists ) {
        throw( "Implement in a subclass" );
    }

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
     * @return IDiskProvider
     */
    function copyDirectory(
        required source,
        required destination,
        boolean recurse,
        any filter,
        boolean createPath
    ) {
        throw( "Implement in a subclass" );
    };

    /**
     * Move a directory
     *
     * @oldPath The source directory
     * @newPath The destination directory
     * @createPath If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
     *
     * @return IDiskProvider
     */
    function moveDirectory( required oldPath, required newPath, boolean createPath ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Rename a directory, facade to `moveDirectory()`
     *
     * @oldPath The source directory
     * @newPath The destination directory
     * @createPath If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
     *
     * @return IDiskProvider
     */
    function renameDirectory( required oldPath, required newPath, boolean createPath ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Delete 1 or more directory locations
     *
     * @directory The directory or an array of directories
     * @recurse Recurse the deletion or not, defaults to true
     * @throwOnMissing Throws an exception if the directory does not exist
     *
     * @return A boolean value or a struct of booleans determining if the directory paths got deleted or not.
     */
    public boolean function deleteDirectory(
        required string directory,
        boolean recurse = true,
        boolean throwOnMissing = false
    ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Empty the specified directory of all files and folders.
     *
     * @directory The directory
     *
     * @return IDiskProvider
     */
    function cleanDirectory( required directory ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Get an array listing of all files and directories in a directory.
     *
     * @directory The directory
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     * @recurse Recurse into subdirectories, default is false
     */
    array function contents(
        required directory,
        any filter,
        sort,
        boolean recurse
    ) {
        throw( "Implement in a subclass" );
    }

    /**
     * Get an array listing of all files and directories in a directory using recursion
     *
     * @directory The directory
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     * @recurse Recurse into subdirectories, default is false
     */
    array function allContents( required directory, any filter, sort ) {
        arguments.recurse = true;
        arguments.map = false;
        return this.contents( argumentCollection = arguments );
    }

    /**
     * Get an array of all files in a directory.
     *
     * @directory The directory
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     * @recurse Recurse into subdirectories, default is false
     */
    array function files(
        required directory,
        any filter,
        sort,
        boolean recurse
    ) {
        arguments.type = "file";
        arguments.map = false;
        return this.contents( argumentCollection = arguments );
    };

    /**
     * Get an array of all directories in a directory.
     *
     * @directory The directory
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     * @recurse Recurse into subdirectories, default is false
     */
    array function directories(
        required directory,
        any filter,
        sort,
        boolean recurse
    ) {
        arguments.type = "directory";
        arguments.map = false;
        return this.contents( argumentCollection = arguments );
    };

    /**
     * Get an array of all files in a directory using recursion, this is a shortcut to the `files()` with recursion
     *
     * @directory The directory
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     */
    array function allFiles( required directory, any filter, sort ) {
        arguments.recurse = true;
        arguments.map = false;
        this.files( argumentCollection = arguments );
    };

    /**
     * Get an array of all directories in a directory using recursion
     *
     * @directory The directory
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     */
    array function allDirectories( required directory, any filter, sort ) {
        arguments.recurse = true;
        arguments.map = false;
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
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     * @recurse Recurse into subdirectories, default is false
     */
    array function filesMap(
        required directory,
        any filter,
        sort,
        boolean recurse
    ) {
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
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     */
    array function allFilesMap( required directory, any filter, sort ) {
        arguments.map = true;
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
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     * @recurse Recurse into subdirectories, default is false
     */
    array function directoriesMap(
        required directory,
        any filter,
        sort,
        boolean recurse
    ) {
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
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     */
    array function allDirectoriesMap( required directory, any filter, sort ) {
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
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     * @recurse Recurse into subdirectories, default is false
     */
    array function contentsMap(
        required directory,
        any filter,
        sort,
        boolean recurse
    ) {
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
     * @filter A string wildcard or a lambda/closure that receives the file path and should return true to include it in the returned array or not.
     * @sort Columns by which to sort. e.g. Directory, Size DESC, DateLastModified.
     */
    array function allContentsMap( required directory, any filter, sort ) {
        arguments.recurse = true;
        this.contentsMap( argumentCollection = arguments );
    };

    /************************* PRIVATE METHODS *******************************/

    private function buildPath( required string path ) {
        return expandPath( getProperties().path & "/" & arguments.path );
    }

    private function ensureFileExists( required path ) {
        if ( !this.exists( arguments.path ) ) {
            throw( type = "cbfs.FileNotFoundException", message = "File [#arguments.path#] not found." );
        }
    }

    private function ensureDirectoryExists( required path ) {
        var p = buildPath( arguments.path );
        var directoryPath = replaceNoCase( p, getFileFromPath( p ), "" );

        if ( !directoryExists( directoryPath ) ) {
            directoryCreate( directoryPath );
        }
    }

    /**
     * Check if is Windows
     */
    private function isWindows() {
        var system = createObject( "java", "java.lang.System" );
        return reFindNoCase( "Windows", system.getProperties()[ "os.name" ] );
    }

}
