component extends="coldbox.system.testing.BaseTestCase" {

    function run() {
        describe( "abstract disk spec", function() {
            it( "can be created", function() {
                expect( getDisk() ).toBeComponent();
            } );

            describe( "get", function() {
                it( "can get the contents of a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.create( path = path, contents = "my contents", overwrite = true );
                    expect( disk.get( path ) ).toBe( "my contents" );
                } );
            } );

            it( "throws an exception when trying to create a file that already exists without the overwrite flag", function() {
                var disk = getDisk();
                var path = "test_file.txt";
                disk.delete( path );
                expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
                disk.create( path, "my contents" );
                expect( function() {
                    disk.create( path, "does not matter" );
                } ).toThrow( "cbfs.FileOverrideException" );
            } );

            it( "does not throw an exception when trying to create a file that already exists with the overwrite flag", function() {
                var disk = getDisk();
                var path = "test_file.txt";
                disk.delete( path );
                expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
                disk.create( path, "my contents" );
                expect( function() {
                    disk.create( path = path, contents = "new content", overwrite = true );
                } ).notToThrow( "cbfs.FileOverrideException" );
                expect( disk.get( path ) ).toBe( "new content" );
            } );

            describe( "exists", function() {
                it( "can create a file and verify it exists", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.delete( path );
                    expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
                    disk.create( path, "my contents" );
                    expect( disk.exists( path ) ).toBeTrue( "#path# should exist" );
                } );

                it( "can verify a directory exists", function() {
                    var disk = getDisk();
                    var filePath = "/one/two/test_file.txt";
                    var directoryPath = "/one/two/";
                    disk.deleteDirectory( "/one/" );
                    expect( disk.exists( directoryPath ) ).toBeFalse( "#directoryPath# should not exist" );
                    disk.create( filePath, "my contents" );
                    expect( disk.exists( directoryPath ) ).toBeTrue( "#directoryPath# should exist" );
                } );
            } );

            it( "can delete a file", function() {
                var disk = getDisk();
                var path = "test_file.txt";
                disk.delete( path );
                expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
                disk.create( path, "my contents" );
                disk.delete( path );
                expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
            } );

            describe( "prepend", function() {
                it( "can prepend contents to the beginning of a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.create( path = path, contents = "my contents", overwrite = true );
                    disk.prepend( path, "these are " );
                    expect( disk.get( path ) ).toBe( "these are my contents" );
                } );

                it( "creates a new file if the file does not already exist", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.delete( path );
                    disk.prepend( path, "prepended contents" );
                    expect( disk.get( path ) ).toBe( "prepended contents" );
                } );

                it( "throws an error if the file does not already exist and the throwOnMissing flag is set", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.delete( path );
                    expect( function() {
                        disk.prepend( path = path, contents = "does not matter", throwOnMissing = true );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "append", function() {
                it( "can append contents to the beginning of a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.create( path = path, contents = "my contents", overwrite = true );
                    disk.append( path, " are awesome" );
                    expect( disk.get( path ) ).toBe( "my contents are awesome" );
                } );

                it( "creates a new file if the file does not already exist", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.delete( path );
                    disk.append( path, "appended contents" );
                    expect( disk.get( path ) ).toBe( "appended contents" );
                } );

                it( "throws an exception if the file does not already exist and the throwOnMissing flag is set", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.delete( path );
                    expect( function() {
                        disk.append( path = path, contents = "does not matter", throwOnMissing = true );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "copy", function() {
                it( "can copy a file from one location to another", function() {
                    var disk = getDisk();
                    var oldPath = "test_file.txt";
                    var newPath = "test_file_two.txt";
                    disk.delete( oldPath );
                    disk.delete( newPath );
                    disk.create( path = oldPath, contents = "my contents", overwrite = true );
                    disk.copy( oldPath, newPath );
                    expect( disk.get( newPath ) ).toBe( disk.get( oldPath ) );
                } );

                it( "throws an exception if the source file does not exist", function() {
                    var disk = getDisk();
                    var nonExistantPath = "test_file.txt";
                    var newPath = "test_file_two.txt";
                    disk.delete( nonExistantPath );
                    disk.delete( newPath );
                    expect( function() {
                        disk.copy( nonExistantPath, newPath );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "move", function() {
                it( "can move a file from one location to another", function() {
                    var disk = getDisk();
                    var oldPath = "test_file.txt";
                    disk.create( path = oldPath, contents = "my contents", overwrite = true );
                    var newPath = "test_file_two.txt";
                    disk.move( oldPath, newPath );
                    expect( disk.get( newPath ) ).toBe( "my contents" );
                    expect( disk.exists( oldPath ) ).toBeFalse( "Source path [#oldPath#] should no longer exist." );
                } );

                it( "throws an exception if the source file does not exist", function() {
                    var disk = getDisk();
                    var nonExistantPath = "test_file.txt";
                    var newPath = "test_file_two.txt";
                    disk.delete( nonExistantPath );
                    disk.delete( newPath );
                    expect( function() {
                        disk.move( nonExistantPath, newPath );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "rename", function() {
                it( "can rename a file", function() {
                    var disk = getDisk();
                    var oldPath = "test_file.txt";
                    var newPath = "test_file_two.txt";
                    disk.delete( oldPath );
                    disk.delete( newPath );
                    disk.create( path = oldPath, contents = "my contents", overwrite = true );
                    disk.rename( oldPath, newPath );
                    expect( disk.get( newPath ) ).toBe( "my contents" );
                    expect( disk.exists( oldPath ) ).toBeFalse( "Source path [#oldPath#] should no longer exist." );
                } );

                it( "throws an exception if the source file does not exist", function() {
                    var disk = getDisk();
                    var nonExistantPath = "test_file.txt";
                    var newPath = "test_file_two.txt";
                    disk.delete( nonExistantPath );
                    disk.delete( newPath );
                    expect( function() {
                        disk.rename( nonExistantPath, newPath );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "url", function() {
                it( "can retrieve the url for a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.create( path = path, contents = "my contents", overwrite = true );
                    testURLExpectation( disk, path );
                } );

                it( "throws an exception if the file does not exist", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.delete( path );
                    expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist." );
                    expect( function() {
                        disk.url( path );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "temporaryURL", function() {
                it( "can retrieve the temporary url for a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.create( path = path, contents = "my contents", overwrite = true );
                    testTemporaryURLExpectation( disk, path );
                } );

                it( "throws an exception if the file does not exist", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.delete( path );
                    expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist." );
                    expect( function() {
                        disk.temporaryURL( path );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "size", function() {
                it( "can retrieve the size of a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    var contents = "my contents";
                    disk.create( path = path, contents = contents, overwrite = true );
                    expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist." );
                    expect( disk.size( path ) ).toBe( retireveSizeForTest( path, contents ) );
                } );

                it( "throws an exception if the file does not exist", function() {
                    var disk = getDisk();
                    var path = "does_not_exist.txt";
                    expect( function() {
                        disk.size( path );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "lastModified", function() {
                it( "can retrieve the last modified date of a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    var contents = "my contents";
                    var before = getEpochTimeFromLocal();
                    disk.create( path = path, contents = contents, overwrite = true );
                    var after = getEpochTimeFromLocal();
                    expect( getEpochTimeFromLocal( disk.lastModified( path ) ) ).toBeGTE( before );
                    // Skip this test for remote providers as latency and timezone offsets can make the results inconsistent
                    if ( !isInstanceOf( disk, "S3Provider" ) ) {
                        expect( getEpochTimeFromLocal( disk.lastModified( path ) ) ).toBeLTE( after );
                    }
                } );

                it( "throws an exception if the file does not exist", function() {
                    var disk = getDisk();
                    var path = "does_not_exist.txt";
                    expect( function() {
                        disk.lastModified( path );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "mimeType", function() {
                it( "can retrieve the mime type of a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.create( path = path, contents = "my contents", overwrite = true );
                    expect( disk.mimeType( path ) ).toBe( "text/plain" );
                } );

                it( "throws an exception if the file does not exist", function() {
                    var disk = getDisk();
                    var path = "does_not_exist.txt";
                    expect( function() {
                        disk.lastModified( path );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "touch", function() {
                it( "can create an empty file using touch", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.delete( path );
                    expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist" );
                    disk.touch( path );
                    expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
                    expect( disk.get( path ) ).toBe( "" );
                    expect( disk.size( path ) ).toBe( 0 );
                } );

                it( "creates nested directories by default", function() {
                    var disk = getDisk();
                    var path = "/one/two/test_file.txt";
                    disk.delete( path );
                    expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist" );
                    disk.touch( path );
                    expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
                    expect( disk.get( path ) ).toBe( "" );
                    expect( disk.size( path ) ).toBe( 0 );
                } );

                it( "throws an exception if nested directories do not exist and `createPath` is false", function() {
                    var disk = getDisk();
                    var path = "/one/two/test_file.txt";
                    disk.delete( "/one/two" );
                    expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist" );
                    expect( function() {
                        disk.touch( path = path, createPath = false );
                    } ).toThrow( "cbfs.PathNotFoundException" );
                } );
            } );

            describe( "info", function() {
                it( "can retrieve the info about a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    disk.create( path = path, contents = "my contents", overwrite = true );
                    var info = disk.info( path );
                    expect( info ).toHaveKey( "lastModified" );
                    expect( info ).toHaveKey( "size" );
                    expect( info ).toHaveKey( "path" );
                    expect( info ).toHaveKey( "name" );
                    expect( info ).toHaveKey( "type" );
                    expect( info ).toHaveKey( "canWrite" );
                    expect( info ).toHaveKey( "canRead" );
                    expect( info ).toHaveKey( "isHidden" );
                } );

                it( "throws an exception if the file does not exist", function() {
                    var disk = getDisk();
                    var path = "does_not_exist.txt";
                    expect( function() {
                        disk.info( path );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "checksum", function() {
                it( "can generate the checksum for a file", function() {
                    var disk = getDisk();
                    var path = "test_file.txt";
                    var contents = "my contents";
                    disk.create( path = path, contents = contents, overwrite = true );
                    expect( disk.checksum( path ) ).toBe( hash( contents, "MD5" ) );
                    expect( disk.checksum( path, "SHA-256" ) ).toBe( hash( contents, "SHA-256" ) );
                } );

                it( "throws an exception if the file does not exist", function() {
                    var disk = getDisk();
                    var path = "does_not_exist.txt";
                    expect( function() {
                        disk.checksum( path );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "name", function() {
                it( "can get the name of a file", function() {
                    var disk = getDisk();
                    var path = "/one/two/test_file.txt";
                    expect( disk.name( path ) ).toBe( "test_file.txt" );
                } );
            } );

            describe( "extension", function() {
                it( "can get the extension of a file", function() {
                    var disk = getDisk();
                    var path = "/one/two/test_file.txt";
                    expect( disk.extension( path ) ).toBe( "txt" );
                } );
            } );

            describe( "isFile", function() {
                it( "can check if a path is a file", function() {
                    var disk = getDisk();
                    var directoryPath = "/one/two";
                    var filePath = "#directoryPath#/test_file.txt";
                    disk.create( path = filePath, contents = "my contents", overwrite = true );
                    expect( disk.isFile( directoryPath ) ).toBeFalse();
                    expect( disk.isFile( filePath ) ).toBeTrue();
                } );

                it( "throws an exception if the path does not exist", function() {
                    var disk = getDisk();
                    var path = "does_not_exist.txt";
                    expect( disk.exists( path ) ).toBeFalse( "File should not exist" );
                    expect( function() {
                        disk.isFile( path );
                    } ).toThrow( "cbfs.FileNotFoundException" );
                } );
            } );

            describe( "isWritable", function() {
                it( "it returns true for a writable path", function() {
                    var disk = getDisk();
                    if ( isInstanceOf( disk, "MockProvider" ) ) return;
                    var path = "/one/two/writeable.txt";
                    disk.delete( path );
                    disk.create(
                        path = path,
                        contents = "my contents",
                        visibility = "public",
                        overwrite = true
                    );
                    expect( disk.isWritable( path ) ).toBeTrue( "Path should be writable." );
                } );

                it( "returns false for a non-writable path", function() {
                    var disk = getDisk();
                    if ( isInstanceOf( disk, "MockProvider" ) ) return;
                    var path = "/one/two/non-writeable.txt";
                    disk.delete( path );
                    disk.create(
                        path = path,
                        contents = "my contents",
                        visibility = "private",
                        overwrite = true
                    );
                    expect( disk.isWritable( path ) ).toBeFalse( "Path should not be writable." );
                } );
            } );

            describe( "isReadable", function() {
                it( "it returns true for a readble path", function() {
                    var disk = getDisk();
                    if ( isInstanceOf( disk, "MockProvider" ) ) return;
                    var path = "/one/two/readable.txt";
                    disk.delete( path );
                    disk.create(
                        path = path,
                        contents = "my contents",
                        visiblity = "public",
                        overwrite = true
                    );
                    expect( disk.isReadable( path ) ).toBeTrue( "Path should be readable." );
                } );

                it( "returns false for a non-readble path", function() {
                    var disk = getDisk();
                    if ( isInstanceOf( disk, "MockProvider" ) ) return;
                    var path = "/one/two/non-readble.txt";
                    disk.delete( path );
                    disk.create(
                        path = path,
                        contents = "my contents",
                        visibility = "private",
                        overwrite = true
                    );
                    expect( disk.isReadable( path ) ).toBeFalse( "Path should not be readable." );
                } );
            } );
        } );
    }

    function getDisk() {
        throw( "`getDisk` must be implemented in a subclass" );
    }

    function testURLExpectation( required any disk, required string path ) {
        expect( disk.url( path ) ).toBe( retrieveUrlForTest( path ) );
    }

    function testTemporaryURLExpectation( required any disk, required string path ) {
        expect( disk.temporaryURL( path ) ).toBe( retrieveTemporaryUrlForTest( path ) );
    }

    function retrieveUrlForTest( required string path ) {
        return arguments.path;
    }

    function retrieveTemporaryUrlForTest( required string path ) {
        return arguments.path;
    }

    function retireveSizeForTest( required string path, required content ) {
        return len( arguments.content );
    }

    /**
     * Returns the number of seconds since January 1, 1970, 00:00:00 (Epoch time).
     *
     * @param DateTime      Date/time object you want converted to Epoch time. (Required)
     * @return Returns a numeric value.
     * @author Rob Brooks-Bilson (rbils@amkor.com)
     * @version 1, June 21, 2002
     */
    function getEpochTimeFromLocal( datetime = now() ) {
        return dateDiff( "s", dateConvert( "utc2Local", "January 1 1970 00:00" ), datetime );
    }

}
