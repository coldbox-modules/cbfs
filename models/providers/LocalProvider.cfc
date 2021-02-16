component accessors="true" extends="cbfs.models.AbstractDiskProvider" implements="cbfs.models.IDisk" {

    this.permissions = {
        "file": { "public": "666", "private": "000", "readonly" : "444" },
        "dir": { "public": "666", "private": "600", "readonly" : "644" }
    };

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

    public IDisk function setVisibility( required string path, required string visibility ) {
		if ( isWindows() ) {
			switch( arguments.visibility ){
				case "private":{
					var mode = "system";
					break;
				}
				case "readonly":{
					var mode = arguments.visibility;
					break;
				}
				default:{
					var mode = "normal";
				}
			}
            fileSetAttribute( buildPath( arguments.path ), mode );
            return this;
        }
		switch( arguments.visibility ){
			case "private":{
				var mode = this.permissions.file.private;
				break;
			}
			case "readonly":{
				var mode = this.permissions.file.readonly;
				break;
			}
			default:{
				var mode = this.permissions.file.public;
			}
		}
        fileSetAccessMode( buildPath( arguments.path ), mode );
        return this;
    };

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

    any function get( required path ) {
        ensureFileExists( arguments.path );
        return fileRead( buildPath( arguments.path ) );
    }

    any function getAsBinary( required path ) {
        ensureFileExists( arguments.path );
        return fileReadBinary( buildPath( arguments.path ) );
    };

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

    public boolean function delete( required any path, boolean throwOnMissing = false ) {
        if ( isSimpleValue( arguments.path ) ) {
            if ( !throwOnMissing ) {
                if ( !this.exists( arguments.path ) ) {
                    return false;
                }
            }
			if( isDirectory( arguments.path ) ){
				deleteDirectory( arguments.path, true );
			} else {
				fileDelete( buildPath( arguments.path ) );
			}
            return true;
        }
        for ( var file in arguments.path ) {
            if ( !throwOnMissing ) {
                if ( !this.exists( file ) ) {
                    return false;
                }
            }
			if( isDirectory( file ) ){
				deleteDirectory( file, true );
			} else {
				fileDelete( buildPath( file ) );
			}
        }
        return true;
    }

    function lastModified( required path ) {
        ensureFileExists( arguments.path );
        return getFileInfo( buildPath( arguments.path ) ).lastModified;
    }

    boolean function isFile( required path ) {
        if ( isDirectory( arguments.path ) ) {
            return false;
        }
        ensureFileExists( arguments.path );
        return getFileInfo( buildPath( arguments.path ) ).type EQ "file";
    }

    boolean function isWritable( required path ) {
        return getFileInfo( buildPath( arguments.path ) ).canWrite;
    }

    boolean function isReadable( required path ) {
        return getFileInfo( buildPath( arguments.path ) ).canRead;
    }

    function createDirectory( required directory, boolean createPath, boolean ignoreExists = false ) {
        if ( !arguments.ignoreExists AND directoryExists( buildPath( arguments.directory ) ) ) {
            throw( "Directory Exists" );
        }
        if ( !directoryExists( buildPath( arguments.directory ) ) ) {
            directoryCreate( buildPath( arguments.directory ) );
        }
    };

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

    private function buildPath( required string path ) {
        // remove all relative dots
        arguments.path = reReplace( arguments.path, "\.\.\/+", "", "ALL" );
        return expandPath( getProperties().path & "/" & arguments.path );
    }

    private function getRelativePath( required obj ) {
        var path = replace( obj.directory, getProperties().path, "" ) & "/" & obj.name;
        path = replace( path, "\", "/", "ALL" );
        path = ( left( path, 1 ) EQ "/" ) ? removeChars( path, 1, 1 ) : path;
        return path;
    }

    private function ensureDirectoryExists( required path ) {
        var p = buildPath( arguments.path );
        var directoryPath = replaceNoCase( p, getFileFromPath( p ), "" );

        if ( !directoryExists( directoryPath ) ) {
            directoryCreate( directoryPath );
        }
    }

}
