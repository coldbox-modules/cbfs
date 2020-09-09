component accessors="true" extends="cbfs.models.AbstractDiskProvider" implements="cbfs.models.IDisk" {

    this.permissions = {
        'file' = {
            'public' = 0644,
            'private' = 0600,
        },
        'dir' = {
            'public' = 0755,
            'private' = 0700,
        },
    };

	function create(
		required path,
		required contents,
		visibility,
		struct metadata,
		boolean overwrite
	) {
        if ( ! len(arguments.overwrite) && this.exists( arguments.path ) ) {
            throw(
                type = "cbfs.FileOverrideException",
                message = "Cannot create file. File already exists [#arguments.path#]"
            );
        }
        // filewrite throws error if directory not exists
        ensureDirectoryExists( arguments.path );
        try{
            fileWrite( buildPath( arguments.path ), arguments.contents );
        }catch( any e ){
            throw(
                type = "cbfs.FileNotFoundException",
                message = "Cannot create file. File already exists [#arguments.path#]"
            );
        }
        if( len( arguments.visibility ) ){
            this.setVisibility( arguments.path, arguments.visibility );
        }
        return this;
    }

    function setVisibility( required path, required visibility ){
        var system = createObject("java", "java.lang.System");
        if( isWindows() ){
            FileSetAttribute( buildPath( arguments.path ), arguments.visibility );
            return this;
        }
        FileSetAccessMode( buildPath( arguments.path ), arguments.visibility );
        return this;
    };

    function visibility( required path ){
        var file = getFileInfo( arguments.path );
        if( ! file.canRead ){
            return "private";
        }
        if( file.canWrite ){
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
        if ( ! this.exists( arguments.path ) ) {
            if ( arguments.throwOnMissing ) {
                throw(
                    type = "cbfs.FileNotFoundException",
                    message = "File [#arguments.path#] not found."
                );
            }
            return this.create(
                path = arguments.path,
                contents = arguments.contents,
                metadata = arguments.metadata
            );
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
        if ( ! this.exists( arguments.path ) ) {
            if ( arguments.throwOnMissing ) {
                throw(
                    type = "cbfs.FileNotFoundException",
                    message = "File [#arguments.path#] not found."
                );
            }
            return this.create(
                path = arguments.path,
                contents = arguments.contents,
                metadata = arguments.metadata
            );
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

    any function getAsBinary( required path ){
        ensureFileExists( arguments.path );
        return fileReadBinary( buildPath( arguments.path ) );
    };

    boolean function exists( required string path ) {
    	if( isDirectoryPath( arguments.path ) ){
        	return directoryExists( buildPath( arguments.path ) );
    	}
    	try{
        	return fileExists( buildPath( arguments.path ) );
    	}catch( any e ){
            throw(
                type = "cbfs.FileNotFoundException",
                message = "File [#arguments.path#] not found."
            );
    	}
    }

	function delete( required path, boolean throwOnMissing = false ) {
        if( isSimpleValue( arguments.path ) ){
            if ( ! throwOnMissing ) {
                if ( ! this.exists( arguments.path ) ) {
                    return this;
                }
            }
            fileDelete( buildPath( arguments.path ) );
            return this;
        }
        for( file in arguments.path ){
            if ( ! throwOnMissing ) {
                if ( ! this.exists( file ) ) {
                    return this;
                }
            }
            fileDelete( buildPath( file ) );
        }
        return this;
    }

	function lastModified( required path ) {
        ensureFileExists( arguments.path );
        return getFileInfo( buildPath( arguments.path ) ).lastModified;
    }

    boolean function isFile( required path ) {
        if( isDirectory( arguments.path ) ){
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

    function createDirectory( required directory, boolean createPath, boolean ignoreExists = false ){
        if( !arguments.ignoreExists AND directoryExists( buildPath( arguments.directory ) ) ){
            throw( "Directory Exists" );
        }
        if( ! directoryExists( buildPath( arguments.directory ) ) ){
            directoryCreate( buildPath( arguments.directory ) );
        }
    };

    function renameDirectory(
        required oldPath,
        required newPath,
        boolean createPath
    ){
        directoryRename( buildPath( arguments.oldPath ), buildPath( arguments.newPath ) );
        return this;
    };

    any function deleteDirectory( required directory, boolean recurse = true ){
        if( isSimpleValue( directory ) ){
            directoryDelete( buildPath( arguments.directory ), arguments.recurse );
            return this;
        }
        for( dir in arguments.directory ){
            directoryDelete( buildPath( dir ), arguments.recurse );
        }
    };

    array function contents( required directory, any filter, sort, boolean recurse = false ){

        var result = [];
        arguments.type = structKeyExists( arguments, "type" ) ? arguments.type : javacast( "null", "" );
        var qDir = DirectoryList( 
            buildPath( arguments.directory ), 
            arguments.recurse, 
            "query", 
            arguments.filter,
            arguments.sort,
            arguments.type 
        );      
        if( isNull( arguments.map ) ){
            return ValueArray( qDir, "name" );
        }
        for( v in qDir ){
            v["path"] = getRelativePath( v );
            arrayAppend( result, v )
        }
        return result;
    }

    /************************* PRIVATE METHODS ****************************/

    private function buildPath( required string path ) {
        // remove all relative dots
        var path = reReplace( arguments.path, "\.\.\/+", "", "ALL");
        return expandPath( getProperties().path & "/" & path );
    }

    private function getRelativePath( required obj ) {
        var path = replace( obj.directory, getProperties().path, "" ) & "/" & obj.name;
        path = replace( path, "\", "/", "ALL" );
        path = ( left( path, 1 ) EQ "/" ) ? removeChars( path, 1, 1 ) : path;

        return path;
    }

    private function ensureDirectoryExists( required path ) {
    	var p = buildPath( arguments.path );
		var directoryPath = replaceNoCase( p, GetFileFromPath( p ), "" );

        if ( ! directoryExists( directoryPath ) ) {
        	directoryCreate( directoryPath );
        }
    }

    private function isDirectoryPath( required path ) {

    	if( ! len( GetFileFromPath( buildPath( arguments.path ) ) ) ){
    		return true;
    	}
    	return false;

    }

}
