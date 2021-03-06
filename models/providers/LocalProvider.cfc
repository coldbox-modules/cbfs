component accessors="true" extends="cbfs.models.AbstractDiskProvider" implements="cbfs.models.IDisk" {

    variables.permissions = {
        "file": { "public": "666", "private": "000", "readonly": "444" },
        "dir": { "public": "666", "private": "600", "readonly": "644" }
    };

    /**
     * Create a file in the disk
     *
     * @path The file path to use for storage
     * @contents The contents of the file to store
     * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
     * @metadata Struct of metadata to store with the file
     * @overwrite If we should overwrite the files or not at the destination if they exist, defaults to true
     *
     * @return LocalProvider
     */
    function create(
        required path,
        required contents,
        visibility = "",
        struct metadata = {},
        boolean overwrite = false
    ) {
        if ( !arguments.overwrite && this.exists( arguments.path ) ) {
            throw(
                type = "cbfs.FileOverrideException",
                message = "Cannot create file. File already exists [#arguments.path#]"
            );
        }
        // filewrite throws error if directory not exists
        ensureDirectoryExists( arguments.path );
        try {
            fileWrite( buildPath( arguments.path ), arguments.contents );
        } catch ( any e ) {
            throw(
                type = "cbfs.FileNotFoundException",
                message = "Cannot create file. File already exists [#arguments.path#]"
            );
        }
        if ( len( arguments.visibility ) ) {
            this.setVisibility( arguments.path, arguments.visibility );
        }
        return this;
    }

    /**
     * Set the storage visibility of a file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
     *
     * @path The target file
     * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
     *
     * @return LocalProvider
     */
    public IDisk function setVisibility( required string path, required string visibility ) {
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
    public string function visibility( required string path ) {
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
     * @path The file path to use for storage
     * @contents The contents of the file to prepend
     * @metadata Struct of metadata to store with the file
     * @throwOnMissing Boolean flag to throw if the file is missing. Otherwise it will be created if missing.
     *
     * @throws cbfs.FileNotFoundException
     *
     * @return LocalProvider
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
     * @return LocalProvider
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
    any function getAsBinary( required path ) {
        ensureFileExists( arguments.path );
        return fileReadBinary( buildPath( arguments.path ) );
    };

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
     * Deletes a file
     *
     * @path
     * @throwOnMissing   When true an error will be thrown if the file does not exist
     */
    public boolean function delete( required any path, boolean throwOnMissing = false ) {
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
    function lastModified( required path ) {
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
    boolean function isFile( required path ) {
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
    boolean function isWritable( required path ) {
        return getFileInfo( buildPath( arguments.path ) ).canWrite;
    }

    /**
     * Is the path readable or not
     *
     * @path The file path
     */
    boolean function isReadable( required path ) {
        return getFileInfo( buildPath( arguments.path ) ).canRead;
    }

    /**
     * Create a new directory
     *
     * @directory The directory path
     * @createPath Create parent directory paths when they do not exist
     * @ignoreExists If false, it will throw an error if the directory already exists, else it ignores it if it exists. This should default to true.
     *
     * @return LocalProvider
     */
    function createDirectory( required directory, boolean createPath, boolean ignoreExists = false ) {
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
     * @oldPath The source directory
     * @newPath The destination directory
     * @createPath If false, expects all parent directories to exist, true will generate all necessary directories. Default is true.
     */
    function renameDirectory( required oldPath, required newPath, boolean createPath ) {
        directoryRename( buildPath( arguments.oldPath ), buildPath( arguments.newPath ) );
        return this;
    };

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
        if ( isSimpleValue( directory ) ) {
            if ( !throwOnMissing && !this.exists( arguments.directory ) ) {
                return false;
            }
            directoryDelete( buildPath( arguments.directory ), arguments.recurse );
            return true;
        }

        return arguments.directory.every( function( dir ) {
            return this.deleteDirectory( dir, arguments.recurse, arguments.throwOnMissing );
        } );
    };

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
        boolean recurse = false
    ) {
        var result = [];
        arguments.type = structKeyExists( arguments, "type" ) ? arguments.type : javacast( "null", "" );
        var qDir = directoryList(
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
     * Sets the access attributes of the file on Unix based disks
     *
     * @path The file path
     * @mode Access mode, the same attributes you use for the Linux command `chmod`
     */
    public IDisk function chmod( required string path, required string mode ) {
        fileSetAccessMode( buildPath( path ), arguments.mode );
        return this;
    }

    /************************* PRIVATE METHODS ****************************/
    /**
     * Determines whether a provided path is a directory or not
     *
     * @path  The path to be checked
     */
    private function buildPath( required string path ) {
        // remove all relative dots
        arguments.path = reReplace( arguments.path, "\.\.\/+", "", "ALL" );
        return expandPath( getProperties().path & "/" & arguments.path );
    }

    /**
     * Gets the relative path from a path object
     *
     * @obj the path object
     */
    private function getRelativePath( required obj ) {
        var path = replace( obj.directory, getProperties().path, "" ) & "/" & obj.name;
        path = replace( path, "\", "/", "ALL" );
        path = ( left( path, 1 ) EQ "/" ) ? removeChars( path, 1, 1 ) : path;
        return path;
    }

    /**
     * Ensures a directory exists - will create the directory if it does not exist
     *
     * @path The path to be checked for existence
     */
    private function ensureDirectoryExists( required path ) {
        var p = buildPath( arguments.path );
        var directoryPath = replaceNoCase( p, getFileFromPath( p ), "" );

        if ( !directoryExists( directoryPath ) ) {
            directoryCreate( directoryPath );
        }
    }

}
