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
	// The concrete test must activate these in order for the tests to execute according to their disk features
	variables.testFeatures = { symbolicLink : false };

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

			/********************************************************/
			/** FILE Operations **/
			/********************************************************/

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

			story( "The disk can delete files", function(){
				given( "a file exists", function(){
					then( "it should delete it", function(){
						var path = "test_file.txt";
						disk.delete( path );
						expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );

						disk.create( path, "my contents" );
						expect( disk.delete( path ) ).toBeTrue( "delete() should return true" );
						expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
					} );
				} );
				given( "a file doesn't exist and throwOnMissing is false", function(){
					then( "it should ignore it and return false", function(){
						var path = "test_file.txt";
						// Make sure it doesn't exist
						disk.delete( path );
						expect( disk.delete( path ) ).toBeFalse( "delete() should ignore it" );
					} );
				} );
				given( "a file doesn't exist and throwOnMissing is true", function(){
					then( "it should throw a FileNotFoundException", function(){
						var path = "test_file.txt";
						// Make sure it doesn't exist
						disk.delete( path );
						expect( function(){
							disk.delete( path, true );
						} ).toThrow( "cbfs.FileNotFoundException" );
					} );
				} );
			} );

			story( "The disk can touch files", function(){
				given( "a file that doesn't exist", function(){
					then( "it should touch it", function(){
						var path = "test_file.txt";
						disk.delete( path );
						disk.touch( path );
						expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
						expect( disk.get( path ) ).toBe( "" );
					} );
				} );
				given( "a file that does exist", function(){
					then( "it should touch it by modified the lastmodified timestamp", function(){
						var path = "test_file.txt";
						disk.delete( path );
						disk.create( path, "hello" );
						var before = disk.lastModified( path );
						sleep( 1000 );
						var after = disk.touch( path ).lastModified( path );
						expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
						expect( disk.get( path ) ).toBe( "hello" );
						expect( before ).toBeLT( after );
					} );
				} );
				given( "a file that doesn't exist and it has a nested path", function(){
					then( "it should create the nested directories and create it", function(){
						var path = "/one/two/test_file.txt";
						disk.delete( path );
						disk.touch( path );
						expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
						expect( disk.get( path ) ).toBe( "" );
					} );
				} );
				given( "A file that doesn't exist and `createPath` is false", function(){
					then( "It should throw a `cbfs.PathNotFoundException`", function(){
						var path = "/one/two/test_file.txt";
						disk.deleteDirectory( "/one/two" );
						expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist" );
						expect( function(){
							disk.touch( path = path, createPath = false );
						} ).toThrow( "cbfs.PathNotFoundException" );
					} );
				} );
			} );

			/********************************************************/
			/** Utility Methods **/
			/********************************************************/

			story( "The disk can get a URI for the given file", function(){
				given( "a valid file", function(){
					then( "it can retrieve the uri for a file", function(){
						var path = "/dir/test_file.txt";
						disk.create(
							path      = path,
							contents  = "my contents",
							overwrite = true
						);
						validateUri( path, disk );
					} );
				} );
				it( "throws an exception if the file does not exist", function(){
					var path = "test_file.txt";
					disk.delete( path );
					expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist." );
					expect( function(){
						disk.uri( path );
					} ).toThrow( "cbfs.FileNotFoundException" );
				} );
			} );
			story( "The disk can get temporary uris for a given file", function(){
				it( "can retrieve the temporary uri for a file", function(){
					var path = "/dir/test_file.txt";
					disk.create(
						path      = path,
						contents  = "my contents",
						overwrite = true
					);
					validateTemporaryUri( path, disk );
				} );

				it( "throws an exception if the file does not exist", function(){
					var path = "test_file.txt";
					disk.delete( path );
					expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist." );
					expect( function(){
						disk.temporaryUri( path );
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

			story( "The disk can get the lastModified property of a file", function(){
				it( "can retrieve the last modified date of a file", function(){
					var path   = "test_file.txt";
					var before = getEpochTimeFromLocal();
					sleep( 500 );
					disk.create(
						path      = path,
						contents  = "hola amigo",
						overwrite = true
					);
					expect( disk.lastModified( path ) ).toBeDate();
					expect( getEpochTimeFromLocal( disk.lastModified( path ) ) ).toBeGTE( before );
				} );
			} );

			story( "The disk can get the mime type property of a file", function(){
				it( "can retrieve the mimetype of a file", function(){
					var path = "test_file.txt";
					disk.create(
						path      = path,
						contents  = "hola amigo",
						overwrite = true
					);
					expect( disk.mimeType( path ) ).toBe( "text/plain" );
				} );
			} );

			story( "The disk can return file information", function(){
				it( "can retrieve an info struct about a file", function(){
					var path = "test_file.txt";
					disk.create(
						path      = path,
						contents  = "my contents",
						overwrite = true
					);
					var info = disk.info( path );
					expect( info ).toBeStruct();
					validateInfoStruct( info, disk );
				} );
			} );

			story( "The disk can create file checksums", function(){
				it( "can generate the checksum for a file", function(){
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
			} );

			story( "The disk can get the name of a file", function(){
				it( "can get the name of a file", function(){
					var path = "/one/two/test_file.txt";
					expect( disk.name( path ) ).toBe( "test_file.txt" );
				} );
			} );

			story( "The disk can get the extension of a file", function(){
				it( "can get the extension of a file", function(){
					var path = "/one/two/test_file.txt";
					expect( disk.extension( path ) ).toBe( "txt" );
				} );
			} );

			story( "The disk can set the permissions of a file via chmod", function(){
				it( "can set the permissions of a file via chmod", function(){
					var path = "/one/two/test_file.txt";
					disk.create(
						path      = path,
						contents  = "Hello",
						overwrite = true
					);
					expect( disk.chmod( path, "777" ).info( path ).mode ).toBe( "777" );
				} );
			} );

			story(
				story: "The disk can create symbolic links",
				skip : !hasFeature( "symbolicLink" ),
				body : function(){
					it( "can create symbolic links", function(){
						var path = "test_file.txt";
						disk.create(
							path      = path,
							contents  = "I love symbolic links",
							overwrite = true
						);
						disk.createSymbolicLink( "link_file.txt", path );
						expect( disk.isSymbolicLink( "link_file.txt" ) ).toBeTrue();
					} );
				}
			);

			/********************************************************/
			/** Verification Methods **/
			/********************************************************/

			story( "The disk can verify if a path is a file", function(){
				given( "A file exists", function(){
					then( "it will verify it", function(){
						var directoryPath = "/one/two";
						var filePath      = "#directoryPath#/test_file.txt";
						disk.create(
							path      = filePath,
							contents  = "my contents",
							overwrite = true
						);
						expect( disk.isFile( directoryPath ) ).toBeFalse( "Directory should not be a file" );
						expect( disk.isFile( filePath ) ).toBeTrue( "#filePath# should be a file" );
					} );
				} );
				given( "A directory", function(){
					then( "it will verify that it's not a file", function(){
						var directoryPath = "/one/two";
						var filePath      = "#directoryPath#/test_file.txt";
						disk.create(
							path      = filePath,
							contents  = "my contents",
							overwrite = true
						);
						expect( disk.isFile( directoryPath ) ).toBeFalse();
					} );
				} );
				given( "a non-existent file", function(){
					then( "it will throw a `cbfs.FileNotFoundException`", function(){
						var path = "does_not_exist.txt";
						disk.delete( path );
						expect( disk.exists( path ) ).toBeFalse( "File should not exist" );
						expect( function(){
							disk.isFile( path );
						} ).toThrow( "cbfs.FileNotFoundException" );
					} );
				} );
			} );

			story( "The disk can verify if a file is writable", function(){
				it( "it returns true for a writable path", function(){
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

			story( "The disk can verify if a file is readable", function(){
				given( "a public file", function(){
					it( "should returns as readable", function(){
						var path = "/one/two/readable.txt";
						disk.delete( path );
						disk.create(
							path       = path,
							contents   = "my contents",
							visibility = "public",
							overwrite  = true
						);
						expect( disk.isReadable( path ) ).toBeTrue( "Path should be readable." );
					} );
				} );
				given( "a readonly file", function(){
					it( "should returns as readable", function(){
						var path = "/one/two/readable.txt";
						disk.delete( path );
						disk.create(
							path       = path,
							contents   = "my contents",
							visibility = "readonly",
							overwrite  = true
						);
						expect( disk.isReadable( path ) ).toBeTrue( "Path should be readable." );
					} );
				} );
				given( "a private file", function(){
					it( "should return false as readable", function(){
						var path = "/one/two/non-writeable.txt";
						disk.delete( path );
						disk.create(
							path       = path,
							contents   = "my contents",
							visibility = "private",
							overwrite  = true
						);
						expect( disk.isWritable( path ) ).toBeFalse( "Path should not be readable." );
					} );
				} );
			} );

			story( "The disk can verify if a file is hidden", function(){
				given( "a public file", function(){
					it( "should returns false as hidden", function(){
						var path = "/one/two/readable.txt";
						disk.delete( path );
						disk.create(
							path       = path,
							contents   = "my contents",
							visibility = "public",
							overwrite  = true
						);
						expect( disk.isHidden( path ) ).toBeFalse( "Path should be hidden." );
					} );
				} );
				given( "a readonly file", function(){
					it( "should return false as hidden", function(){
						var path = "/one/two/readable.txt";
						disk.delete( path );
						disk.create(
							path       = path,
							contents   = "my contents",
							visibility = "readonly",
							overwrite  = true
						);
						expect( disk.isHidden( path ) ).toBeFalse( "Path should be hidden." );
					} );
				} );
				given( "a private file", function(){
					it( "should return true as true", function(){
						var path = "/one/two/non-writeable.txt";
						disk.delete( path );
						disk.create(
							path       = path,
							contents   = "my contents",
							visibility = "private",
							overwrite  = true
						);
						expect( disk.isHidden( path ) ).toBeTrue( "Path should be hidden." );
					} );
				} );
			} );

			/********************************************************/
			/** Directory Methods **/
			/********************************************************/

			story( "The disk can create and verify directories", function(){
				given( "a non-existent directory", function(){
					then( "it should create the directory", function(){
						var path = "bddtests";
						disk.deleteDirectory( path )
						disk.createDirectory( path );

						expect( disk.exists( path ) ).toBeTrue( "#path# should exist" );
						expect( disk.isDirectory( path ) ).toBeTrue( "#path# should be a directory" );
					} );
				} );
				given( "an existent directory and ignoreExists = true", function(){
					then( "it should ignore the creation", function(){
						var path = "bddtests";
						disk.deleteDirectory( path )
						disk.createDirectory( path );

						expect( function(){
							disk.createDirectory( directory = path, ignoreExists = true );
						} ).notToThrow();
					} );
				} );
				given( "an existent directory and ignoreExists = false", function(){
					then( "it should throw a cbfs.DirectoryExistsException ", function(){
						var path = "bddtests";
						disk.deleteDirectory( path )
						disk.createDirectory( path );

						expect( function(){
							disk.createDirectory( directory = path, ignoreExists = false );
						} ).toThrow( "cbfs.DirectoryExistsException" );
					} );
				} );
			} );

			story( "The disk can delete directories", function(){
				given( "a valid directory and recurse = true", function(){
					then( "it should delete all the directories and recurse", function(){
						var path = "deleteTests";
						disk.createDirectory( path );
						disk.create(
							path      = path & "/test.txt",
							contents  = "my contents",
							overwrite = true
						);
						disk.createDirectory( path & "/embedded" );
						disk.create(
							path      = path & "/embedded/test.txt",
							contents  = "my contents",
							overwrite = true
						);

						expect( disk.deleteDirectory( path ) ).toBeTrue();
						expect( disk.exists( path ) ).toBeFalse();
						expect( disk.exists( path & "/test.txt" ) ).toBeFalse();
						expect( disk.exists( path & "/embedded" ) ).toBeFalse();
						expect( disk.exists( path & "/embedded/test.txt" ) ).toBeFalse();
					} );
				} );
				given( "a valid directory and recurse = false", function(){
					then( "it should delete only the top level files", function(){
						var path = "deleteTests";
						disk.createDirectory( path );
						disk.create(
							path      = path & "/test.txt",
							contents  = "my contents",
							overwrite = true
						);
						disk.createDirectory( path & "/embedded" );
						disk.create(
							path      = path & "/embedded/test.txt",
							contents  = "my contents",
							overwrite = true
						);

						expect( disk.deleteDirectory( path ) ).toBeTrue();
						expect( disk.exists( path ) ).toBeFalse();
						expect( disk.exists( path & "/test.txt" ) ).toBeFalse();
						expect( disk.exists( path & "/embedded" ) ).toBeFalse();
						expect( disk.exists( path & "/embedded/test.txt" ) ).toBeFalse();
					} );
				} );
				given( "an non existent directory and throwOnMissing = false", function(){
					then( "it should ignore the deletion ", function(){
						var path = "bogus";
						expect( disk.deleteDirectory( path ) ).toBeFalse();
					} );
				} );
				given( "an non existent directory and throwOnMissing = true", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException", function(){
						var path = "bogus";

						expect( function(){
							disk.deleteDirectory( directory = path, throwOnMissing = true );
						} ).toThrow( "cbfs.DirectoryNotFoundException" );
					} );
				} );
			} );

			story( "The disk can move directories", function(){
				given( "a valid old path", function(){
					then( "it should move the directory", function(){
						var dirPath = "bddtests";
						disk.deleteDirectory( dirPath );
						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );

						expect( disk.exists( dirPath ) ).toBeTrue( "#dirPath# should exist" );
						disk.moveDirectory( dirPath, "tddtests" );

						expect( disk.exists( dirPath ) ).toBeFalse( "#dirPath# should not exist" );
						expect( disk.exists( "tddtests" ) ).toBeTrue( "tddtests should exist" );
						expect( disk.exists( "tddtests/luis.txt" ) ).toBeTrue( "tddtests/luis.txt should exist" );
					} );
				} );
				given( "an invalid old path", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException", function(){
						var dirPath = "bddtests";
						disk.deleteDirectory( dirPath );

						expect( function(){
							disk.moveDirectory( dirPath, "oldTests" );
						} ).toThrow( "cbfs.DirectoryNotFoundException" );
					} );
				} );
			} );

			story( "The disk can copy directories", function(){
				beforeEach( function( currentSpec ){
					sourcePath      = "bddtests";
					destinationPath = "tddtests";
					disk.deleteDirectory( sourcePath );
					disk.deleteDirectory( destinationPath );
				} );

				given( "a valid source and destination with no recurse and no filter", function(){
					then( "it should copy the directory", function(){
						disk.createDirectory( sourcePath );
						disk.create( sourcePath & "/luis.txt", "hello mi amigo" );
						disk.create( sourcePath & "/embedded/luis.txt", "hola" );

						expect( disk.exists( destinationPath ) ).toBeFalse( "#destinationPath# should not exist" );
						expect( disk.exists( sourcePath ) ).toBeTrue( "#sourcePath# should exist" );
						disk.copyDirectory( sourcePath, destinationPath );

						expect( disk.exists( sourcePath ) ).toBeTrue( "#sourcePath# should still exist" );
						expect( disk.exists( destinationPath ) ).toBeTrue( "#destinationPath# should exist" );
						expect( disk.exists( "#destinationPath#/luis.txt" ) ).toBeTrue( " first level file should exist" );
						expect( disk.exists( "#destinationPath#/embedded/luis.txt" ) ).toBeFalse( "embedded should have been skipped" );
					} );
				} );

				given( "a valid source and destination with recurse and no filter", function(){
					then( "it should copy the directory recursively", function(){
						disk.createDirectory( sourcePath );
						disk.create( sourcePath & "/luis.txt", "hello mi amigo" );
						disk.create( sourcePath & "/embedded/luis.txt", "hola" );

						expect( disk.exists( destinationPath ) ).toBeFalse( "#destinationPath# should not exist" );
						expect( disk.exists( sourcePath ) ).toBeTrue( "#sourcePath# should exist" );
						disk.copyDirectory(
							source      = sourcePath,
							destination = destinationPath,
							recurse     = true
						);

						expect( disk.exists( sourcePath ) ).toBeTrue( "#sourcePath# should still exist" );
						expect( disk.exists( destinationPath ) ).toBeTrue( "#destinationPath# should exist" );
						expect( disk.exists( "#destinationPath#/luis.txt" ) ).toBeTrue( " first level file should exist" );
						expect( disk.exists( "#destinationPath#/embedded/luis.txt" ) ).toBeTrue( "embedded should exist" );
					} );
				} );

				given( "a valid source and destination with recurse and a string filter", function(){
					then( "it should copy the directory with the string filter", function(){
						disk.createDirectory( sourcePath );
						disk.create( sourcePath & "/luis.cfc", "component{}" );
						disk.create( sourcePath & "/embedded/luis.txt", "hola" );

						expect( disk.exists( destinationPath ) ).toBeFalse( "#destinationPath# should not exist" );
						expect( disk.exists( sourcePath ) ).toBeTrue( "#sourcePath# should exist" );
						disk.copyDirectory(
							source      = sourcePath,
							destination = destinationPath,
							recurse     = true,
							filter      = "*.cfc"
						);

						expect( disk.exists( sourcePath ) ).toBeTrue( "#sourcePath# should still exist" );
						expect( disk.exists( destinationPath ) ).toBeTrue( "#destinationPath# should exist" );
						expect( disk.exists( "#destinationPath#/luis.cfc" ) ).toBeTrue( "non-filtered file should exist" );
						expect( disk.exists( "#destinationPath#/embedded/luis.txt" ) ).toBeFalse( "filtered file should NOT exist" );
					} );
				} );

				given( "a valid source and destination with recurse and a closure filter", function(){
					then( "it should copy the directory with the closure filter", function(){
						disk.createDirectory( sourcePath );
						disk.create( sourcePath & "/luis.cfc", "component{}" );
						disk.create( sourcePath & "/embedded/luis.txt", "hola" );

						expect( disk.exists( destinationPath ) ).toBeFalse( "#destinationPath# should not exist" );
						expect( disk.exists( sourcePath ) ).toBeTrue( "#sourcePath# should exist" );
						disk.copyDirectory(
							source      = sourcePath,
							destination = destinationPath,
							recurse     = true,
							filter      = function( path ){
								return findNoCase( "luis.cfc", path );
							}
						);

						expect( disk.exists( sourcePath ) ).toBeTrue( "#sourcePath# should still exist" );
						expect( disk.exists( destinationPath ) ).toBeTrue( "#destinationPath# should exist" );
						expect( disk.exists( "#destinationPath#/luis.cfc" ) ).toBeTrue( "non-filtered file should exist" );
						expect( disk.exists( "#destinationPath#/embedded/luis.txt" ) ).toBeFalse( "filtered file should NOT exist" );
					} );
				} );

				given( "an invalid source", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException", function(){
						var dirPath = "bddtests";
						disk.deleteDirectory( dirPath );
						expect( function(){
							disk.moveDirectory( dirPath, "oldTests" );
						} ).toThrow( "cbfs.DirectoryNotFoundException" );
					} );
				} );
			} );

			story( "The disk can clean directories", function(){
				given( "a valid directory", function(){
					then( "it will clean the directory", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						disk.cleanDirectory( dirPath );

						expect( disk.exists( dirPath ) ).toBeTrue( "directory should remain" );
						expect( disk.exists( dirPath & "/luis.txt" ) ).toBeFalse();
						expect( disk.exists( dirPath & "/embedded/luis.txt" ) ).toBeFalse();
					} );
				} );
				given( "an invalid directory", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException", function(){
						var dirPath = "boguspath";
						expect( function(){
							disk.cleanDirectory( dirPath );
						} ).toThrow( "cbfs.DirectoryNotFoundException" );
					} );
				} );
			} );

			story( "The disk can get the contents of a directory", function(){
				beforeEach( function( currentSpec ){
					disk.deleteDirectory( "bddtests" );
				} );
				given( "a valid directory", function(){
					then( "it will list the directory", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contents( dirPath );
						expect( results.len() ).toBe( 2 );
					} );
				} );
				given( "a valid directory and recurse = true", function(){
					then( "it will list the directory recursively", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contents( directory = dirPath, recurse = true );
						expect( results ).toInclude( "bddtests/embedded/luis.txt" );
					} );
				} );
				given( "a valid directory using allContents()", function(){
					then( "it will list the directory recursively", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.allContents( dirPath );
						expect( results ).toInclude( "bddtests/embedded/luis.txt" );
					} );
				} );
				given( "a valid directory with type of 'file'", function(){
					then( "it will list the directory for files only", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contents( directory = dirPath, type = "file" );
						expect( results.len() ).toBe( 1 );
					} );
				} );
				given( "a valid directory with a files() call", function(){
					then( "it will list the directory for files only", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.files( dirPath );
						expect( results.len() ).toBe( 1 );
					} );
				} );
				given( "a valid directory with type of 'dir'", function(){
					then( "it will list the directory for directories only", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contents( directory = dirPath, type = "dir" );
						expect( results.len() ).toBe( 1 );
					} );
				} );
				given( "a valid directory with a directories() call", function(){
					then( "it will list the directory for directories only", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.directories( dirPath );
						expect( results.len() ).toBe( 1 );
					} );
				} );
				given( "an invalid directory", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException", function(){
						var dirPath = "boguspath";
						expect( function(){
							disk.contents( dirPath );
						} ).toThrow( "cbfs.DirectoryNotFoundException" );
					} );
				} );
			} );

			story( "The disk can get file information maps", function(){
				beforeEach( function( currentSpec ){
					disk.deleteDirectory( "bddtests" );
				} );
				given( "a valid directory", function(){
					then( "it can get a file map structure", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/Test.cfc", "component{}" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.filesMap( dirPath );
						expect( results.len() ).toBe( 2 );
					} );
				} );
				given( "a valid directory with recurse = true", function(){
					then( "it can get a recursive file map structure", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/Test.cfc", "component{}" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.allFilesMap( dirPath );
						expect( results.len() ).toBe( 3 );
					} );
				} );
			} );

			fstory( "The disk can get multiple file content maps", function(){
				beforeEach( function( currentSpec ){
					disk.deleteDirectory( "bddtests" );
				} );
				given( "a valid directory", function(){
					then( "it can get a file content map structure", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/Test.cfc", "component{}" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contentsMap( dirPath );
						expect( results.len() ).toBe( 2 );
						debug( results );
						expect( results[ 1 ].contents ).notToBeEmpty();
						expect( results[ 1 ].path ).notToBeEmpty();
						expect( results[ 1 ].size ).notToBeEmpty();
					} );
				} );
				given( "a valid directory with recurse = true", function(){
					then( "it can get a recursive file content map structure", function(){
						var dirPath = "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/Test.cfc", "component{}" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.allContentsMap( dirPath );
						expect( results.len() ).toBe( 3 );
						expect( results[ 1 ].contents ).notToBeEmpty();
						expect( results[ 1 ].path ).notToBeEmpty();
						expect( results[ 1 ].size ).notToBeEmpty();
					} );
				} );
			} );
		} ); // end suite
	}

	/**
	 * ------------------------------------------------------------
	 * Concrete Expectations that can be implemented by each provider
	 * ------------------------------------------------------------
	 */

	/**
	 * This method should validate the info struct coming out of the disk from an "info()" call
	 */
	function validateInfoStruct( required info, required disk ){
	}
	/**
	 * This method should validate the creation of a uri to a file via the "uri()" method.
	 * This implementation is a basic in and out.
	 *
	 * @path The target path
	 * @disk The disk used
	 */
	function validateUri( required string path, required any disk ){
		expect( disk.uri( arguments.path ) ).toBe( arguments.path );
	}

	/**
	 * This method should validate the creation of a temporary uri to a file via the "uri()" method.
	 * This implementation is a basic in and out.
	 *
	 * @path The target path
	 * @disk The disk used
	 */
	function validateTemporaryUri( required string path, required any disk ){
		expect( disk.temporaryUri( arguments.path ) ).toInclude( arguments.path );
	}

	/**
	 * ------------------------------------------------------------
	 * Test Helpers
	 * ------------------------------------------------------------
	 */

	function getDisk(){
		return getInstance( "DiskService@cbfs" ).get( variables.providerName );
	}

	/**
	 * This should be implemented by a concrete provider test. This implementation is a basic one.
	 *
	 * @path    The path of the file
	 * @content The contents of the file
	 */
	private function retrieveSizeForTest( required string path, required content ){
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
	private function getEpochTimeFromLocal( datetime = now() ){
		return dateDiff(
			"s",
			dateConvert( "utc2Local", "January 1 1970 00:00" ),
			datetime
		);
	}

	private boolean function hasFeature( required feature ){
		return variables.testFeatures[ arguments.feature ];
	}

}
