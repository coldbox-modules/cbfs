/**
 * This abstract testing class can take care of testing the basics of each provider.  The following should be tested by the concrete implemetnation
 *
 * - Visibility
 */
component extends="coldbox.system.testing.BaseTestCase" {

	// Load and do not unload COldBOx, for performance
	this.loadColdbox   = true;
	this.unLoadColdBox = false;

	// The target provider name to test: Filled by concrete test clases
	variables.providerName = "";

	function beforeAll(){
		// Load ColdBox
		super.beforeAll();
		// Setup a request for testing.
		setup();
	}

	function run(){
		describe( "#variables.providerName# spec", function(){
			beforeEach( function( currentSpec ){
				disk = getDisk();
			} );

			story( "The disk should be created and started by the service", function(){
				it( "is started by the service", function(){
					expect( disk ).toBeComponent();
					expect( disk.hasStarted() ).toBe( true );
				} );
			} );

			story( "The disk can create files", function(){
				given( "a new file content", function(){
					then( "it should create the file", function(){
						var path = "test.txt";
						disk.create(
							path    : path,
							contents: "hola amigo!",
							metadata: {}
						);
						expect( disk.exists( path ) ).toBeTrue( "File should exist" );
						expect( disk.get( path ) ).toBe( "hola amigo!" );
					} );
				} );
				when( "overwrite is false and the file exists", function(){
					then( "it should throw a FileOverrideException", function(){
						var disk = getDisk();

						// Make sure file doesn't exist
						var path = "test_file.txt";
						disk.delete( path );
						expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );

						// Create it
						disk.create( path, "my contents" );
						// Test the scenario
						expect( function(){
							disk.create( path, "does not matter" );
						} ).toThrow( "cbfs.FileOverrideException" );
					} );
				} );

				when( "overwrite is true and the file exists", function(){
					then( "it should re-create the file", function(){
						var disk = getDisk();

						// Make sure file doesn't exist
						var path = "test_file.txt";
						disk.delete( path );
						expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );

						// Create it
						disk.create( path, "my contents" );
						expect( function(){
							disk.create(
								path      = path,
								contents  = "new content",
								overwrite = true
							);
						} ).notToThrow( "cbfs.FileOverrideException" );
						expect( disk.get( path ) ).toBe( "new content" );
					} );
				} );
			} );

			story( "The disk should prepend contents for files", function(){
				when( "the target file to prepend already exists", function(){
					then( "it will prepend contents to the beginning of the file", function(){
						var path = "test_file.txt";
						disk.create(
							path      = path,
							contents  = "my contents",
							overwrite = true
						);
						disk.prepend( path, "these are " );
						expect( disk.get( path ) ).toBe( "these are my contents" );
					} );
				} );
				when( "the target file doesn't exist and throwOnMissing is false", function(){
					then( "it will create a new file with the contents", function(){
						var path = "test_file.txt";
						disk.delete( path );
						disk.prepend( path, "prepended contents" );
						expect( disk.get( path ) ).toBe( "prepended contents" );
					} );
				} );
				when( "the target file doesn't exist and throwOnMissing is true", function(){
					then( "it should throw a FileNotFoundException exception ", function(){
						var path = "test_file.txt";
						disk.delete( path );
						expect( function(){
							disk.prepend(
								path           = path,
								contents       = "does not matter",
								throwOnMissing = true
							);
						} ).toThrow( "cbfs.FileNotFoundException" );
					} );
				} );
			} );

			story( "The disk should append contents for files", function(){
				when( "the target file to append already exists", function(){
					then( "it will append contents to the end of the file", function(){
						var path = "test_file.txt";
						disk.create(
							path      = path,
							contents  = "my contents",
							overwrite = true
						);
						disk.append( path, " are awesome!" );
						expect( disk.get( path ) ).toBe( "my contents are awesome!" );
					} );
				} );
				when( "the target file doesn't exist and throwOnMissing is false", function(){
					then( "it will create a new file with the contents", function(){
						var path = "test_file.txt";
						disk.delete( path );
						disk.append( path, "appended contents" );
						expect( disk.get( path ) ).toBe( "appended contents" );
					} );
				} );
				when( "the target file doesn't exist and throwOnMissing is true", function(){
					then( "it should throw a FileNotFoundException exception ", function(){
						var path = "test_file.txt";
						disk.delete( path );
						expect( function(){
							disk.append(
								path           = path,
								contents       = "does not matter",
								throwOnMissing = true
							);
						} ).toThrow( "cbfs.FileNotFoundException" );
					} );
				} );
			} );

			story( "The disk can copy files", function(){
				beforeEach( function( currentSpec ){
					sourcePath  = "test_file.txt";
					destination = "test_file_two.txt";
					disk.delete( sourcePath );
					disk.delete( destination );
				} );
				given( "An existing source and a non-existing destination", function(){
					then( "it should copy the source to the destination", function(){
						disk.create(
							path      = sourcePath,
							contents  = "my contents",
							overwrite = true
						);
						disk.copy( sourcePath, destination );
						expect( disk.exists( destination ) ).toBeTrue();
						expect( disk.exists( sourcePath ) ).toBeTrue();
						expect( disk.get( destination ) ).toBe( disk.get( sourcePath ) );
					} );
				} );
				given( "An existing source and a existing destination", function(){
					when( "overwrite is true", function(){
						then( "it should copy the source to the destination", function(){
							disk.create(
								path      = sourcePath,
								contents  = "my contents",
								overwrite = true
							);
							disk.create(
								path      = destination,
								contents  = "old stuff",
								overwrite = true
							);
							disk.copy( sourcePath, destination );
							expect( disk.exists( destination ) ).toBeTrue();
							expect( disk.exists( sourcePath ) ).toBeTrue();
							expect( disk.get( destination ) ).toBe( disk.get( sourcePath ) );
						} );
					} );
				} );
				given( "An existing source and a existing destination", function(){
					when( "overwrite is false", function(){
						then( "it should throw an FileOverrideException", function(){
							disk.create(
								path      = sourcePath,
								contents  = "my contents",
								overwrite = true
							);
							disk.create(
								path      = destination,
								contents  = "old stuff",
								overwrite = true
							);

							expect( function(){
								disk.copy( sourcePath, destination, false );
							} ).toThrow( "cbfs.FileOverrideException" );
						} );
					} );
				} );
				given( "A non-existent source", function(){
					it( "it should throw an FileNotFoundException", function(){
						expect( function(){
							disk.copy( sourcePath, destination );
						} ).toThrow( "cbfs.FileNotFoundException" );
					} );
				} );
			} );

			story( "The disk can move files", function(){
				beforeEach( function( currentSpec ){
					sourcePath  = "test_file.txt";
					destination = "test_file_two.txt";
					disk.delete( sourcePath );
					disk.delete( destination );
				} );
				given( "An existing source and a non-existing destination", function(){
					then( "it should move the source to the destination", function(){
						disk.create(
							path      = sourcePath,
							contents  = "my contents",
							overwrite = true
						);
						disk.move( sourcePath, destination );
						expect( disk.exists( destination ) ).toBeTrue( "destination should exist" );
						expect( disk.missing( sourcePath ) ).toBeTrue( "source should not exist" );
						expect( disk.get( destination ) ).toBe( "my contents" );
					} );
				} );
				given( "An existing source and a existing destination", function(){
					when( "overwrite is true", function(){
						then( "it should move the source to the destination and overwrite it", function(){
							disk.create(
								path      = sourcePath,
								contents  = "my contents",
								overwrite = true
							);
							disk.create(
								path      = destination,
								contents  = "old stuff",
								overwrite = true
							);
							disk.move( sourcePath, destination );
							expect( disk.exists( destination ) ).toBeTrue( "destination should exist" );
							expect( disk.missing( sourcePath ) ).toBeTrue( "source should not exist" );
							expect( disk.get( destination ) ).toBe( "my contents" );
						} );
					} );
				} );
				given( "An existing source and a existing destination", function(){
					when( "overwrite is false", function(){
						then( "it should throw an FileOverrideException", function(){
							disk.create(
								path      = sourcePath,
								contents  = "my contents",
								overwrite = true
							);
							disk.create(
								path      = destination,
								contents  = "old stuff",
								overwrite = true
							);

							expect( function(){
								disk.move( sourcePath, destination, false );
							} ).toThrow( "cbfs.FileOverrideException" );
						} );
					} );
				} );
				given( "A non-existent source", function(){
					it( "it should throw an FileNotFoundException", function(){
						expect( function(){
							disk.move( sourcePath, destination );
						} ).toThrow( "cbfs.FileNotFoundException" );
					} );
				} );
			} );

			story( "The disk can rename files", function(){
				it( "can rename a file", function(){
					var oldPath = "test_file.txt";
					var newPath = "test_file_two.txt";
					disk.delete( oldPath );
					disk.delete( newPath );
					disk.create(
						path      = oldPath,
						contents  = "my contents",
						overwrite = true
					);
					disk.rename( oldPath, newPath );
					expect( disk.get( newPath ) ).toBe( "my contents" );
					expect( disk.exists( oldPath ) ).toBeFalse( "Source path [#oldPath#] should no longer exist." );
				} );
			} );

			story( "The disk can check for existence", function(){
				given( "a file that exists", function(){
					it( "it can verify it", function(){
						var path = "test_file.txt";
						disk.delete( path );
						expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
						disk.create( path, "my contents" );
						expect( disk.exists( path ) ).toBeTrue( "#path# should exist" );
					} );
				} );
				given( "a directory that exists", function(){
					it( "it can verify it", function(){
						var filePath      = "/one/two/test_file.txt";
						var directoryPath = "/one/two/";
						disk.deleteDirectory( "/one/" );
						expect( disk.exists( directoryPath ) ).toBeFalse( "#directoryPath# should not exist" );
						disk.create( filePath, "my contents" );
						expect( disk.exists( directoryPath ) ).toBeTrue( "#directoryPath# should exist" );
					} );
				} );
			} );

			// TODO
			xstory( "The disk can get a url for the given file", function(){
				given( "a valid file", function(){
					then( "it can retrieve the url for a file", function(){
						var path = "test_file.txt";
						disk.create(
							path      = path,
							contents  = "my contents",
							overwrite = true
						);
						testURLExpectation( disk, path );
					} );
				} );

				it( "throws an exception if the file does not exist", function(){
					var disk = getDisk();
					var path = "test_file.txt";
					disk.delete( path );
					expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist." );
					expect( function(){
						disk.url( path );
					} ).toThrow( "cbfs.FileNotFoundException" );
				} );
			} );
			xstory( "The disk can get temporary urls for a given file", function(){
				it( "can retrieve the temporary url for a file", function(){
					var disk = getDisk();
					var path = "test_file.txt";
					disk.create(
						path      = path,
						contents  = "my contents",
						overwrite = true
					);
					testTemporaryURLExpectation( disk, path );
				} );

				it( "throws an exception if the file does not exist", function(){
					var disk = getDisk();
					var path = "test_file.txt";
					disk.delete( path );
					expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist." );
					expect( function(){
						disk.temporaryURL( path );
					} ).toThrow( "cbfs.FileNotFoundException" );
				} );
			} );

			story( "The disk can get file sizes in bytes", function(){
				it( "can retrieve the size of a file", function(){
					var path     = "test_file.txt";
					var contents = "my contents";
					disk.create(
						path      = path,
						contents  = contents,
						overwrite = true
					);
					expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist." );
					expect( disk.size( path ) ).toBe( retrieveSizeForTest( path, contents ) );
				} );
			} );

			fstory( "The disk can get the lastModified property of a file", function(){
				it( "can retrieve the last modified date of a file", function(){
					var disk     = getDisk();
					var path     = "test_file.txt";
					var contents = "my contents";
					var before   = getEpochTimeFromLocal();
					sleep( 1000 );
					disk.create(
						path      = path,
						contents  = contents,
						overwrite = true
					);
					expect( disk.lastModified( path ) ).toBeDate();
					expect( getEpochTimeFromLocal( disk.lastModified( path ) ) ).toBeGTE( before );
				} );
			} );

			it( "can delete a file", function(){
				var disk = getDisk();
				var path = "test_file.txt";
				disk.delete( path );
				expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
				disk.create( path, "my contents" );
				disk.delete( path );
				expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
			} );





			describe( "mimeType", function(){
				it( "can retrieve the mime type of a file", function(){
					var disk = getDisk();
					var path = "test_file.txt";
					disk.create(
						path      = path,
						contents  = "my contents",
						overwrite = true
					);
					expect( disk.mimeType( path ) ).toBe( "text/plain" );
				} );

				it( "throws an exception if the file does not exist", function(){
					var disk = getDisk();
					var path = "does_not_exist.txt";
					expect( function(){
						disk.lastModified( path );
					} ).toThrow( "cbfs.FileNotFoundException" );
				} );
			} );

			describe( "touch", function(){
				it( "can create an empty file using touch", function(){
					var disk = getDisk();
					var path = "test_file.txt";
					disk.delete( path );
					expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist" );
					disk.touch( path );
					expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
					expect( disk.get( path ) ).toBe( "" );
					expect( disk.size( path ) ).toBe( 0 );
				} );

				it( "creates nested directories by default", function(){
					var disk = getDisk();
					var path = "/one/two/test_file.txt";
					disk.delete( path );
					expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist" );
					disk.touch( path );
					expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
					expect( disk.get( path ) ).toBe( "" );
					expect( disk.size( path ) ).toBe( 0 );
				} );

				it( "throws an exception if nested directories do not exist and `createPath` is false", function(){
					var disk = getDisk();
					var path = "/one/two/test_file.txt";
					disk.delete( "/one/two" );
					expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist" );
					expect( function(){
						disk.touch( path = path, createPath = false );
					} ).toThrow( "cbfs.PathNotFoundException" );
				} );
			} );

			describe( "info", function(){
				it( "can retrieve the info about a file", function(){
					var disk = getDisk();
					var path = "test_file.txt";
					disk.create(
						path      = path,
						contents  = "my contents",
						overwrite = true
					);
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

				it( "throws an exception if the file does not exist", function(){
					var disk = getDisk();
					var path = "does_not_exist.txt";
					expect( function(){
						disk.info( path );
					} ).toThrow( "cbfs.FileNotFoundException" );
				} );
			} );

			describe( "checksum", function(){
				it( "can generate the checksum for a file", function(){
					var disk     = getDisk();
					var path     = "test_file.txt";
					var contents = "my contents";
					disk.create(
						path      = path,
						contents  = contents,
						overwrite = true
					);
					expect( disk.checksum( path ) ).toBe( hash( contents, "MD5" ) );
					expect( disk.checksum( path, "SHA-256" ) ).toBe( hash( contents, "SHA-256" ) );
				} );

				it( "throws an exception if the file does not exist", function(){
					var disk = getDisk();
					var path = "does_not_exist.txt";
					expect( function(){
						disk.checksum( path );
					} ).toThrow( "cbfs.FileNotFoundException" );
				} );
			} );

			describe( "name", function(){
				it( "can get the name of a file", function(){
					var disk = getDisk();
					var path = "/one/two/test_file.txt";
					expect( disk.name( path ) ).toBe( "test_file.txt" );
				} );
			} );

			describe( "extension", function(){
				it( "can get the extension of a file", function(){
					var disk = getDisk();
					var path = "/one/two/test_file.txt";
					expect( disk.extension( path ) ).toBe( "txt" );
				} );
			} );

			describe( "isFile", function(){
				it( "can check if a path is a file", function(){
					var disk          = getDisk();
					var directoryPath = "/one/two";
					var filePath      = "#directoryPath#/test_file.txt";
					disk.create(
						path      = filePath,
						contents  = "my contents",
						overwrite = true
					);
					expect( disk.isFile( directoryPath ) ).toBeFalse();
					expect( disk.isFile( filePath ) ).toBeTrue();
				} );

				it( "throws an exception if the path does not exist", function(){
					var disk = getDisk();
					var path = "does_not_exist.txt";
					expect( disk.exists( path ) ).toBeFalse( "File should not exist" );
					expect( function(){
						disk.isFile( path );
					} ).toThrow( "cbfs.FileNotFoundException" );
				} );
			} );

			describe( "isWritable", function(){
				it( "it returns true for a writable path", function(){
					var disk = getDisk();
					if ( isInstanceOf( disk, "MockProvider" ) ) return;
					var path = "/one/two/writeable.txt";
					disk.delete( path );
					disk.create(
						path       = path,
						contents   = "my contents",
						visibility = "public",
						overwrite  = true
					);
					expect( disk.isWritable( path ) ).toBeTrue( "Path should be writable." );
				} );

				it( "returns false for a non-writable path", function(){
					var disk = getDisk();
					if ( isInstanceOf( disk, "MockProvider" ) ) return;
					var path = "/one/two/non-writeable.txt";
					disk.delete( path );
					disk.create(
						path       = path,
						contents   = "my contents",
						visibility = "private",
						overwrite  = true
					);
					expect( disk.isWritable( path ) ).toBeFalse( "Path should not be writable." );
				} );
			} );

			describe( "isReadable", function(){
				it( "it returns true for a readble path", function(){
					var disk = getDisk();
					if ( isInstanceOf( disk, "MockProvider" ) ) return;
					var path = "/one/two/readable.txt";
					disk.delete( path );
					disk.create(
						path      = path,
						contents  = "my contents",
						visiblity = "public",
						overwrite = true
					);
					expect( disk.isReadable( path ) ).toBeTrue( "Path should be readable." );
				} );

				it( "returns false for a non-readble path", function(){
					var disk = getDisk();
					if ( isInstanceOf( disk, "MockProvider" ) ) return;
					var path = "/one/two/non-readble.txt";
					disk.delete( path );
					disk.create(
						path       = path,
						contents   = "my contents",
						visibility = "private",
						overwrite  = true
					);
					expect( disk.isReadable( path ) ).toBeFalse( "Path should not be readable." );
				} );
			} );
		} );
	}

	/**
	 * ------------------------------------------------------------
	 * Test Helpers
	 * ------------------------------------------------------------
	 */

	function getDisk(){
		return getInstance( "DiskService@cbfs" ).get( variables.providerName );
	}

	function testURLExpectation( required any disk, required string path ){
		expect( disk.url( path ) ).toBe( retrieveUrlForTest( path ) );
	}

	function testTemporaryURLExpectation( required any disk, required string path ){
		expect( disk.temporaryURL( path ) ).toBe( retrieveTemporaryUrlForTest( path ) );
	}

	function retrieveUrlForTest( required string path ){
		return arguments.path;
	}

	function retrieveTemporaryUrlForTest( required string path ){
		return arguments.path;
	}

	/**
	 * This should be implemented by a concrete provider test. This implementation is a basic one.
	 *
	 * @path    The path of the file
	 * @content The contents of the file
	 */
	function retrieveSizeForTest( required string path, required content ){
		return len( arguments.content );
	}

	/**
	 * Returns the number of seconds since January 1, 1970, 00:00:00 (Epoch time).
	 *
	 * @param   DateTime      Date/time object you want converted to Epoch time. (Required)
	 * @author  Rob Brooks-Bilson (rbils@amkor.com)
	 * @version 1, June 21, 2002
	 *
	 * @return Returns a numeric value.
	 */
	function getEpochTimeFromLocal( datetime = now() ){
		return dateDiff(
			"s",
			dateConvert( "utc2Local", "January 1 1970 00:00" ),
			datetime
		);
	}

}
