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
	variables.testFeatures = { symbolicLink : false, chmod : true };

	function beforeAll(){
		// Load ColdBox
		super.beforeAll();
		// Setup a request for testing.
		setup();
	}

	function run(){
		param variables.pathPrefix = "";
		describe( "#variables.providerName# Abstract Specs", function(){
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
				given( "a binary file", function(){
					then( "it should create the file", function(){
						var path           = variables.pathPrefix & "space_ninja.png";
						var binaryContents = fileReadBinary(
							expandPath( "/tests/resources/assets/binary_file.png" )
						);
						disk.create(
							path     : path,
							contents : binaryContents,
							metadata : {},
							overwrite: true
						);
						var blob = disk.get( path );
						expect( isBinary( blob ) ).toBeTrue();
					} );
				} );
				given( "a new file content", function(){
					then( "it should create the file", function(){
						var path = variables.pathPrefix & "test.txt";
						disk.create(
							path     : path,
							contents : "hola amigo!",
							metadata : {},
							overwrite: true
						);
						expect( disk.get( path ) ).toBe( "hola amigo!" );
					} );
				} );
				when( "overwrite is false and the file exists", function(){
					then( "it should throw a FileOverrideException", function(){
						var disk = getDisk();

						// Make sure file doesn't exist
						var path = variables.pathPrefix & "test_file.txt";
						disk.delete( path );

						// Create it
						disk.create(
							path      = path,
							contents  = "my contents",
							overwrite = true
						);
						// Test the scenario
						expect( function(){
							disk.create(
								path      = path,
								contents  = "whatever dude!",
								overwrite = false
							);
						} ).toThrow( "cbfs.FileOverrideException" );
					} );
				} );
			} );

			story( "The disk can create files from an existing file", function(){
				given( "given a existing file path", function(){
					then( "it should create the file", function(){
						var path   = variables.pathPrefix & "space_ninja2.png";
						var source = expandPath( "/tests/resources/assets/binary_file.png" );

						disk.createFromFile(
							source   : source,
							directory: getDirectoryFromPath( path ),
							name     : disk.name( path )
						);

						var blob = disk.get( path );
						expect( isBinary( blob ) ).toBeTrue();
					} );
				} );

				when( "deleteSource is true", function(){
					then( "the source file should no longer exist", function(){
						var path     = variables.pathPrefix & "space_ninja2.png";
						var original = expandPath( "/tests/resources/assets/binary_file.png" );
						var clone    = expandPath( "/tests/resources/assets/#createUUID()#.png" );

						if ( fileExists( clone ) ) {
							fileDelete( clone );
						}

						fileCopy( original, clone );

						disk.createFromFile(
							source      : clone,
							directory   : getDirectoryFromPath( path ),
							name        : disk.name( path ),
							deleteSource: true
						);

						var blob = disk.get( path );
						expect( isBinary( blob ) ).toBeTrue();
						expect( fileExists( clone ) ).toBeFalse();
					} );
				} );

				when( "overwrite is false and the file exists", function(){
					then( "it should throw a FileOverrideException", function(){
						var disk = getDisk();

						// Make sure file doesn't exist
						var path   = variables.pathPrefix & "space_ninja2.png";
						var source = expandPath( "/tests/resources/assets/binary_file.png" );
						disk.delete( path );

						// Create it
						disk.createFromFile(
							source   : source,
							directory: getDirectoryFromPath( path ),
							name     : disk.name( path )
						);

						// Test the scenario
						expect( function(){
							disk.createFromFile(
								source   : source,
								directory: getDirectoryFromPath( path ),
								name     : disk.name( path ),
								overwrite: false
							);
						} ).toThrow( "cbfs.FileOverrideException" );
					} );
				} );
			} );



			story( "Ensures the disk has an upload method", function(){
				it( "has an upload method present", function(){
					expect( disk ).toHaveKey( "upload" );
				} );
			} );

			story( "The disk should prepend contents for files", function(){
				when( "the target file to prepend already exists", function(){
					then( "it will prepend contents to the beginning of the file", function(){
						var path = variables.pathPrefix & "test_file.txt";
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
						var path = variables.pathPrefix & "test_file.txt";
						disk.delete( path );
						disk.prepend( path, "prepended contents" );
						expect( disk.get( path ) ).toBe( "prepended contents" );
					} );
				} );
				when( "the target file doesn't exist and throwOnMissing is true", function(){
					then( "it should throw a FileNotFoundException exception ", function(){
						var path = variables.pathPrefix & "test_file.txt";
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
						var path = variables.pathPrefix & "test_file.txt";
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
						var path = variables.pathPrefix & "test_file.txt";
						disk.delete( path );
						disk.append( path, "appended contents" );
						expect( disk.get( path ) ).toBe( "appended contents" );
					} );
				} );
				when( "the target file doesn't exist and throwOnMissing is true", function(){
					then( "it should throw a FileNotFoundException exception ", function(){
						var path = variables.pathPrefix & "test_file.txt";
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
					sourcePath  = variables.pathPrefix & "test_file.txt";
					destination = variables.pathPrefix & "test_file_two.txt";
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
						disk.copy(
							source      = sourcePath,
							destination = destination,
							overwrite   = true
						);
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
							disk.copy(
								source      = sourcePath,
								destination = destination,
								overwrite   = true
							);
							expect( disk.exists( destination ) ).toBeTrue();
							expect( disk.exists( sourcePath ) ).toBeTrue();
							expect( disk.get( destination ) ).toBe( disk.get( sourcePath ) );
						} );
					} );
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
								disk.copy(
									source      = sourcePath,
									destination = destination,
									overwrite   = false
								);
							} ).toThrow( "cbfs.FileOverrideException" );
						} );
					} );
				} );
				given( "A non-existent source", function(){
					it( "it should throw an FileNotFoundException", function(){
						expect( function(){
							disk.copy( source = sourcePath, destination = destination );
						} ).toThrow( "cbfs.FileNotFoundException" );
					} );
				} );
			} );

			story( "The disk can move files", function(){
				beforeEach( function( currentSpec ){
					sourcePath  = variables.pathPrefix & "test_file.txt";
					destination = variables.pathPrefix & "test_file_two.txt";
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
							disk.move(
								source      = sourcePath,
								destination = destination,
								overwrite   = true
							);
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

			story( "The disk can check for existence", function(){
				given( "a file that exists", function(){
					it( "it can verify it", function(){
						var path = variables.pathPrefix & "test_file.txt";
						disk.delete( path );
						expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
						disk.create( path, "my contents" );
						expect( disk.exists( path ) ).toBeTrue( "#path# should exist" );
					} );
				} );
				given( "a directory that exists", function(){
					it( "it can verify it", function(){
						var filePath      = variables.pathPrefix & "one/test_file.txt";
						var directoryPath = variables.pathPrefix & "one";
						disk.deleteDirectory( directory = "one", recurse = true );
						expect( disk.directoryExists( directoryPath ) ).toBeFalse(
							"#directoryPath# should not exist"
						);
						disk.createDirectory( directoryPath );
						disk.create( filePath, "my contents" );
						expect( disk.directoryExists( directoryPath ) ).toBeTrue( "#directoryPath# should exist" );
					} );
				} );
			} );

			story( "The disk can delete files", function(){
				given( "a file exists", function(){
					then( "it should delete it", function(){
						var path = variables.pathPrefix & "test_file.txt";
						disk.create(
							path      = path,
							contents  = "test",
							overwrite = true
						);
						expect( disk.exists( path ) ).toBeTrue();
						disk.delete( path );
						expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );

						disk.create( path, "my contents" );
						expect( disk.delete( path ) ).toBeTrue( "delete() should return true" );
						expect( disk.exists( path ) ).toBeFalse( "#path# should not exist" );
					} );
				} );
				given( "a file doesn't exist and throwOnMissing is false", function(){
					then( "it should ignore it and return false", function(){
						var path = variables.pathPrefix & "test_file.txt";
						// Make sure it doesn't exist
						expect( disk.delete( path ) ).toBeFalse( "delete() should ignore it" );
					} );
				} );
				given( "a file doesn't exist and throwOnMissing is true", function(){
					then( "it should throw a FileNotFoundException", function(){
						var path = variables.pathPrefix & "test_file.txt";
						// Make sure it doesn't exist
						disk.delete( path );
						expect( function(){
							disk.delete( path, true );
						} ).toThrow( "cbfs.FileNotFoundException" );
					} );
				} );
			} );

			story( "The disk can download files", function(){
				given( "a request for download", function(){
					then( "it should deliver the file to the browser", function(){
						var downloadTestEndpoint = getRequestContext().buildLink( "Main.testDownload", { "disk" : disk.getName() } );
							"Main.testDownload",
							{ "disk" : disk.getName() }
						try{
							if ( server.keyExists( "lucee" ) ) {
								var req  = new http( method = "GET", url = downloadTestEndpoint );
								var resp = req.send().getPrefix();
							} else {
								cfhttp(
									method = "GET",
									url    = downloadTestEndpoint,
									result = "local.resp"
								) {
								}
							}
						} catch( any e ){
							fail( "The endpoint #downloadTestEndpoint# was not reachable" );
						}

						expect( resp.statusCode ).toBe( "200 OK" );

						if ( server.keyExists( "lucee" ) ) {
							expect( isBinary( resp.fileContent ) ).toBeTrue();
						} else {
							expect( resp.fileContent ).toBeInstanceOf( "java.io.ByteArrayOutputStream" );
						}
					} );
				} );
			} );

			story( "The disk can touch files", function(){
				given( "a file that doesn't exist", function(){
					then( "it should touch it", function(){
						var path = variables.pathPrefix & "test_file.txt";
						disk.delete( path );
						disk.touch( path );
						expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
						expect( disk.get( path ) ).toBe( "" );
					} );
				} );
				// Skipping on windows, as the delay of 1000 is not enough and we don't want to add
				// more delays to the test. There is a delay in windows to update the metadata of a file
				given(
					given: "a file that does exist",
					skip : isWindows(),
					body : function(){
						then( "it should touch it by modified the lastmodified timestamp", function(){
							var path = variables.pathPrefix & "test_file.txt";
							disk.delete( path );
							disk.create( path, "hello" );
							var before = disk.lastModified( path );
							sleep( 1000 );

							var after = disk.touch( path ).lastModified( path );
							expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
							expect( disk.get( path ) ).toBe( "hello" );
							expect( before ).toBeLT( after );
						} );
					}
				);
				given( "a file that doesn't exist and it has a nested path", function(){
					then( "it should create the nested directories and create it", function(){
						var path = variables.pathPrefix & "/one/two/test_file.txt";
						disk.delete( path );
						disk.touch( path );
						expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
						expect( disk.get( path ) ).toBe( "" );
					} );
				} );
				given( "A file that doesn't exist and `createPath` is false", function(){
					then( "It should throw a `cbfs.PathNotFoundException`", function(){
						var path = variables.pathPrefix & "/one/two/test_file.txt";
						disk.deleteDirectory( variables.pathPrefix & "/one/two" );
						expect( disk.exists( path ) ).toBeFalse( "[#path#] should not exist" );
						expect( function(){
							disk.touch( path = path, createPath = false );
						} ).toThrow( "cbfs.PathNotFoundException" );
					} );
				} );
			} );

			// /********************************************************/
			// /** Utility Methods **/
			// /********************************************************/

			story( "The disk can get a url for the given file", function(){
				given( "a valid file", function(){
					then( "it can retrieve the url for a file", function(){
						var path = variables.pathPrefix & "/dir/test_file.txt";
						disk.create(
							path      = path,
							contents  = "my contents",
							overwrite = true
						);
						validateUrl( path, disk );
					} );
					then( "it can retrieve the full url for a file", function(){
						var path = variables.pathPrefix & "dir/test_file.txt";
						disk.create(
							path      = path,
							contents  = "my contents",
							overwrite = true
						);
						validateURL( path, disk );
					} );
				} );
			} );

			story( "The disk can get temporary urls for a given file", function(){
				it( "can retrieve the temporary url for a file", function(){
					var path = variables.pathPrefix & "/dir/test_file.txt";
					disk.create(
						path      = path,
						contents  = "my contents",
						overwrite = true
					);
					validateTemporaryUrl( path, disk );
				} );
			} );

			story( "The disk can get file sizes in bytes", function(){
				it( "can retrieve the size of a file", function(){
					var path     = variables.pathPrefix & "test_file.txt";
					var contents = variables.pathPrefix & "my contents";
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
					var path = variables.pathPrefix & "test_file.txt";
					disk.create(
						path      = path,
						contents  = "hola amigo",
						overwrite = true
					);
					expect( disk.lastModified( path ) ).toBeDate();
				} );
			} );

			story( "The disk can get the mime type property of a file", function(){
				it( "can retrieve the mimetype of a file", function(){
					var path = variables.pathPrefix & "test_file.txt";
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
					var path = variables.pathPrefix & "test_file.txt";
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
					var path     = variables.pathPrefix & "test_file.txt";
					var contents = variables.pathPrefix & "my contents";
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
					var path = variables.pathPrefix & "/one/two/test_file.txt";
					expect( disk.name( path ) ).toBe( "test_file.txt" );
				} );
			} );

			story( "The disk can get the extension of a file", function(){
				it( "can get the extension of a file", function(){
					var path = variables.pathPrefix & "/one/two/test_file.txt";
					expect( disk.extension( path ) ).toBe( "txt" );
				} );
			} );

			story(
				story: "The disk can set the permissions of a file via chmod",
				skip : !hasFeature( "chmod" ),
				body : function(){
					it( "can set the permissions of a file via chmod", function(){
						var path = variables.pathPrefix & "/one/two/test_file.txt";
						disk.create(
							path      = path,
							contents  = "Hello",
							overwrite = true
						);
						disk.chmod( path, "777" );
						expect( disk.isWritable( path ) ).toBeTrue();
					} );
				}
			);
			// We skip also in windows, due to their amazing privilige system which makes it throw
			// a Require privilege is not held by the client. :poop:
			story(
				story: "The disk can create symbolic links",
				skip : !hasFeature( "symbolicLink" ) || isWindows(),
				body : function(){
					it( "can create symbolic links", function(){
						var path = variables.pathPrefix & "test_file.txt";
						disk.create(
							path      = path,
							contents  = "I love symbolic links",
							overwrite = true
						);
						var test = disk.createSymbolicLink( "link_file.txt", path );
						expect( disk.isSymbolicLink( "link_file.txt" ) ).toBeTrue();
					} );
				}
			);

			// /********************************************************/
			// /** Verification Methods **/
			// /********************************************************/

			story( "The disk can verify if a path is a file", function(){
				given( "A file exists", function(){
					then( "it will verify it", function(){
						var directoryPath = variables.pathPrefix & "/one/two";
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
						var directoryPath = variables.pathPrefix & "/one/two";
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
						var path = variables.pathPrefix & "does_not_exist.txt";

						expect( function(){
							disk.delete( path = path, throwOnMissing = true );
						} ).toThrow( "cbfs.FileNotFoundException" );

						expect( disk.exists( path ) ).toBeFalse( "File should not exist" );
						expect( disk.isFile( path ) ).toBeFalse();
					} );
				} );
			} );

			story(
				story: "The disk can verify if a file is writable",
				skip : !hasFeature( "chmod" ),
				body : function(){
					it( "it returns true for a writable path", function(){
						var path = variables.pathPrefix & "/one/two/writeable.txt";
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
						var path = variables.pathPrefix & "/one/two/non-writeable.txt";
						disk.delete( path );
						disk.create(
							path       = path,
							contents   = "my contents",
							visibility = "readonly",
							overwrite  = true
						);
						expect( disk.isWritable( path ) ).toBeFalse( "Path should not be writable." );
					} );
				}
			);

			story(
				story: "The disk can verify if a file is readable",
				skip : !hasFeature( "chmod" ),
				body : function(){
					given( "a public file", function(){
						it( "should returns as readable", function(){
							var path = variables.pathPrefix & "/one/two/readable.txt";
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
							var path = variables.pathPrefix & "/one/two/readable.txt";
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
						it( "should return true as hidden", function(){
							var path = variables.pathPrefix & "/one/two/.hidden-file.txt";
							disk.delete( path );
							disk.create(
								path       = path,
								contents   = "my contents",
								visibility = "private",
								overwrite  = true
							);
							expect( disk.isHidden( path ) ).toBeTrue( "Path should not be visible." );
						} );
					} );
				}
			);

			story(
				story = "The disk can verify if a file is hidden",
				skip  = isWindows() || !hasFeature( "chmod" ),
				body  = function(){
					given( "a public file", function(){
						it( "should returns false as hidden", function(){
							var path = variables.pathPrefix & "/one/two/readable.txt";
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
							var path = variables.pathPrefix & "/one/two/readable.txt";
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
					// There is no unified way to make files hidden using Java. Hidden has different meanings for different operating systems.
					given( "a private file", function(){
						it( "should return true as hidden", function(){
							// Simply renaming the files to have a dot (“.”) as a first character of the file name will make the file hidden in Unix systems.
							var path = variables.pathPrefix & "/one/two/.iam-hidden.txt";
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
				}
			);

			// /********************************************************/
			// /** Directory Methods **/
			// /********************************************************/

			story( "The disk can create and verify directories", function(){
				given( "a non-existent directory", function(){
					then( "it should create the directory", function(){
						var path = variables.pathPrefix & "bddtests";
						disk.deleteDirectory( path );
						disk.createDirectory( path );
						expect( disk.directoryExists( path ) ).toBeTrue( "#path# should exist" );
						expect( disk.isDirectory( path ) ).toBeTrue( "#path# should be a directory" );
					} );
				} );
				given( "an existent directory and ignoreExists = true", function(){
					then( "it should ignore the creation", function(){
						var path = variables.pathPrefix & "bddtests";
						disk.deleteDirectory( path );
						disk.createDirectory( path );

						expect( function(){
							disk.createDirectory( directory = path, ignoreExists = true );
						} ).notToThrow();
					} );
				} );
				given( "an existent directory and ignoreExists = false", function(){
					then( "it should throw a cbfs.DirectoryExistsException ", function(){
						var path = variables.pathPrefix & "bddtests";
						disk.deleteDirectory( path );
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
						var path = variables.pathPrefix & "deleteTests";
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
						expect( disk.directoryExists( path ) ).toBeFalse( "#path# should not exist" );
						expect( disk.exists( path & "/test.txt" ) ).toBeFalse( "test.txt should not exist" );
						expect( disk.directoryExists( path & "/embedded" ) ).toBeFalse(
							"embedded directory should not exist"
						);
						expect( disk.exists( path & "/embedded/test.txt" ) ).toBeFalse(
							"embedded test.txt should not exist"
						);
					} );
				} );
				given( "a valid directory and recurse = false", function(){
					then( "it should delete only the top level files", function(){
						var path = variables.pathPrefix & "deleteTests";
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

						expect( disk.deleteDirectory( directory = path, recurse = false ) ).toBeFalse();
						expect( disk.directoryExists( path ) ).toBeTrue();
						expect( disk.exists( path & "/test.txt" ) ).toBeFalse();
						expect( disk.directoryExists( path & "/embedded" ) ).toBeTrue();
						expect( disk.exists( path & "/embedded/test.txt" ) ).toBeTrue();
					} );
				} );
				given( "an non existent directory and throwOnMissing = false", function(){
					then( "it should ignore the deletion ", function(){
						var path = variables.pathPrefix & "bogus";
						expect( disk.deleteDirectory( path ) ).toBeFalse();
					} );
				} );
				given( "an non existent directory and throwOnMissing = true", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException", function(){
						var path = variables.pathPrefix & "bogus";
						expect( function(){
							disk.deleteDirectory( directory = path, throwOnMissing = true );
						} ).toThrow( "cbfs.DirectoryNotFoundException" );
					} );
				} );
			} );

			story( "The disk can move directories", function(){
				given( "a valid old path", function(){
					then( "it should move the directory", function(){
						var dirPath = variables.pathPrefix & "bddtests";
						disk.deleteDirectory( dirPath );
						disk.createDirectory( dirPath );
						expect( disk.directoryExists( dirPath ) ).toBeTrue( "#dirPath# should exist" );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.moveDirectory( dirPath, "tddtests" );
						expect( disk.directoryExists( dirPath ) ).toBeFalse( "#dirPath# should not exist" );
						expect( disk.directoryExists( "tddtests" ) ).toBeTrue( "tddtests should exist" );
						expect( disk.exists( "tddtests/luis.txt" ) ).toBeTrue( "tddtests/luis.txt should exist" );
					} );
				} );
				given( "an invalid old path", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException", function(){
						var dirPath = variables.pathPrefix & "bddtests";
						disk.deleteDirectory( dirPath );

						expect( function(){
							disk.moveDirectory( dirPath, "oldTests" );
						} ).toThrow( "cbfs.DirectoryNotFoundException" );
					} );
				} );
			} );

			story( "The disk can copy directories", function(){
				beforeEach( function( currentSpec ){
					sourcePath      = variables.pathPrefix & "bddtests";
					destinationPath = variables.pathPrefix & "tddtests";
					disk.deleteDirectory( sourcePath );
					disk.deleteDirectory( destinationPath );
				} );

				given( "a valid source and destination with no recurse and no filter", function(){
					then( "it should copy the directory", function(){
						disk.createDirectory( sourcePath );
						disk.create( sourcePath & "/luis.txt", "hello mi amigo" );
						disk.create( sourcePath & "/embedded/luis.txt", "hola" );
						expect( disk.directoryExists( destinationPath ) ).toBeFalse(
							"#destinationPath# should not exist"
						);
						expect( disk.directoryExists( sourcePath ) ).toBeTrue( "#sourcePath# should exist" );
						disk.copyDirectory( sourcePath, destinationPath );
						expect( disk.directoryExists( sourcePath ) ).toBeTrue( "#sourcePath# should still exist" );
						expect( disk.directoryExists( destinationPath ) ).toBeTrue(
							"#destinationPath# should exist"
						);
						expect( disk.exists( "#destinationPath#/luis.txt" ) ).toBeTrue(
							" first level file should exist"
						);
						expect( disk.exists( "#destinationPath#/embedded/luis.txt" ) ).toBeFalse(
							"embedded should have been skipped"
						);
					} );
				} );

				given( "a valid source and destination with recurse and no filter", function(){
					then( "it should copy the directory recursively", function(){
						disk.createDirectory( sourcePath );
						disk.create( sourcePath & "/luis.txt", "hello mi amigo" );
						disk.create( sourcePath & "/embedded/luis.txt", "hola" );
						expect( disk.directoryExists( destinationPath ) ).toBeFalse(
							"#destinationPath# should not exist"
						);
						expect( disk.directoryExists( sourcePath ) ).toBeTrue( "#sourcePath# should exist" );
						disk.copyDirectory(
							source      = sourcePath,
							destination = destinationPath,
							recurse     = true
						);

						expect( disk.directoryExists( sourcePath ) ).toBeTrue( "#sourcePath# should still exist" );
						expect( disk.directoryExists( destinationPath ) ).toBeTrue(
							"#destinationPath# should exist"
						);
						expect( disk.exists( "#destinationPath#/luis.txt" ) ).toBeTrue(
							" first level file should exist"
						);
						expect( disk.exists( "#destinationPath#/embedded/luis.txt" ) ).toBeTrue(
							"embedded should exist"
						);
					} );
				} );

				given( "a valid source and destination with recurse and a string filter", function(){
					then( "it should copy the directory with the string filter", function(){
						disk.createDirectory( sourcePath );
						disk.create( sourcePath & "/luis.cfc", "component{}" );
						disk.create( sourcePath & "/embedded/luis.txt", "hola" );

						expect( disk.directoryExists( destinationPath ) ).toBeFalse(
							"#destinationPath# should not exist"
						);
						expect( disk.directoryExists( sourcePath ) ).toBeTrue( "#sourcePath# should exist" );
						disk.copyDirectory(
							source      = sourcePath,
							destination = destinationPath,
							recurse     = true,
							filter      = "*.cfc"
						);

						expect( disk.directoryExists( sourcePath ) ).toBeTrue( "#sourcePath# should still exist" );
						expect( disk.directoryExists( destinationPath ) ).toBeTrue(
							"#destinationPath# should exist"
						);
						expect( disk.exists( "#destinationPath#/luis.cfc" ) ).toBeTrue(
							"non-filtered file should exist"
						);
						expect( disk.exists( "#destinationPath#/embedded/luis.txt" ) ).toBeFalse(
							"filtered file should NOT exist"
						);
					} );
				} );

				given(
					given = "a valid source and destination with recurse and a closure filter on Lucee ONLY",
					skip  = !server.keyExists( "lucee" ),
					body  = function(){
						then( "it should copy the directory with the closure filter", function(){
							disk.createDirectory( sourcePath );
							disk.create( sourcePath & "/luis.cfc", "component{}" );
							disk.create( sourcePath & "/embedded/luis.txt", "hola" );

							expect( disk.directoryExists( destinationPath ) ).toBeFalse(
								"#destinationPath# should not exist"
							);
							expect( disk.directoryExists( sourcePath ) ).toBeTrue( "#sourcePath# should exist" );

							disk.copyDirectory(
								source      = sourcePath,
								destination = destinationPath,
								recurse     = true,
								filter      = function( path ){
									return findNoCase( "luis.cfc", arguments.path ) > 1 ? true : 0;
								}
							);

							expect( disk.directoryExists( sourcePath ) ).toBeTrue(
								"#sourcePath# should still exist"
							);
							expect( disk.directoryExists( destinationPath ) ).toBeTrue(
								"#destinationPath# should exist"
							);
							expect( disk.exists( "#destinationPath#/luis.cfc" ) ).toBeTrue(
								"non-filtered file should exist"
							);
							expect( disk.exists( "#destinationPath#/embedded/luis.txt" ) ).toBeFalse(
								"filtered file should NOT exist"
							);
						} );
					}
				);

				given( "an invalid source", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException", function(){
						var dirPath = variables.pathPrefix & "bddtests";
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
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						disk.cleanDirectory( dirPath );

						expect( disk.directoryExists( dirPath ) ).toBeTrue( "directory should remain" );
						expect( disk.exists( dirPath & "/luis.txt" ) ).toBeFalse();
						expect( disk.exists( dirPath & "/embedded/luis.txt" ) ).toBeFalse();
					} );
				} );
				given( "an invalid directory", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException duh", function(){
						var dirPath = variables.pathPrefix & "boguspath";
						expect( function(){
							disk.cleanDirectory( directory = dirPath, throwOnMissing = true );
						} ).toThrow( "cbfs.DirectoryNotFoundException" );
					} );
				} );
			} );

			story( "The disk can get the contents of a directory", function(){
				beforeEach( function( currentSpec ){
					disk.deleteDirectory( variables.pathPrefix & "bddtests" );
				} );
				given( "a valid directory", function(){
					then( "it will list the directory", function(){
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contents( dirPath & "/" );

						expect( results.len() ).toBe( 2 );
					} );
				} );
				given( "a valid directory and recurse = true", function(){
					then( "it will list the directory recursively", function(){
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contents( directory = dirPath, recurse = true );
						expect( results.toList().reReplace( "\\", "/", "all" ) ).toInclude(
							"bddtests/embedded/luis.txt"
						);
					} );
				} );
				given( "a valid directory using allContents()", function(){
					then( "it will list the directory recursively", function(){
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.allContents( dirPath );
						expect( results.toList().reReplace( "\\", "/", "all" ) ).toInclude(
							"bddtests/embedded/luis.txt"
						);
					} );
				} );
				given( "a valid directory with type of 'file'", function(){
					then( "it will list the directory for files only", function(){
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contents( directory = dirPath, type = "file" );
						expect( results.len() ).toBe( 1 );
					} );
				} );
				given( "a root directory with a files() call", function(){
					then( "it will list the files in the root folder", function(){
						var path = createUUID() & ".txt";
						disk.create( path, "hola mi amigo" );
						expect( disk.exists( path ) ).toBeTrue();

						var matched = disk
							.files()
							.reduce( function( agg, file ){
								if (
									( isStruct( file ) && file.key == path ) ||
									( !isStruct( file ) && file == path )
								) {
									agg = true;
								}
								return agg;
							}, false );

						expect( matched ).toBeTrue();

						disk.delete( path );
					} );
				} );
				given( "a valid directory with a files() call", function(){
					then( "it will list the directory for files only", function(){
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.files( dirPath );
						expect( results.len() ).toBe( 1 );
					} );
				} );
				given( "a valid directory with type of 'dir'", function(){
					then( "it will list the directory for directories only", function(){
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contents( directory = dirPath, type = "dir" );
						expect( results.len() ).toBe( 1 );
					} );
				} );
				given( "a valid directory with a directories() call", function(){
					then( "it will list the directory for directories only", function(){
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.directories( dirPath );
						expect( results.len() ).toBe( 1 );
					} );
				} );
				given( "an invalid directory", function(){
					then( "it should throw a cbfs.DirectoryNotFoundException sdfsadfsd", function(){
						var dirPath = variables.pathPrefix & "boguspath";
						expect( function(){
							disk.contents( dirPath );
						} ).toThrow( "cbfs.DirectoryNotFoundException" );
					} );
				} );
			} );

			story( "The disk can get file information maps", function(){
				beforeEach( function( currentSpec ){
					disk.deleteDirectory( variables.pathPrefix & "bddtests" );
				} );
				given( "a valid directory", function(){
					then( "it can get a file map structure", function(){
						var dirPath = variables.pathPrefix & "bddtests";

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
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/Test.cfc", "component{}" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.allFilesMap( dirPath );
						expect( results.len() ).toBe( 3 );
					} );
				} );
			} );

			story( "The disk can get multiple file content maps", function(){
				beforeEach( function( currentSpec ){
					disk.deleteDirectory( variables.pathPrefix & "bddtests" );
				} );
				given( "a valid directory", function(){
					then( "it can get a file content map structure", function(){
						var dirPath = variables.pathPrefix & "bddtests";

						disk.createDirectory( dirPath );
						disk.create( dirPath & "/luis.txt", "hello mi amigo" );
						disk.create( dirPath & "/Test.cfc", "component{}" );
						disk.create( dirPath & "/embedded/luis.txt", "hello mi amigo" );

						var results = disk.contentsMap( dirPath );
						expect( results.len() ).toBe( 2 );
						expect( results[ 1 ].contents ).notToBeEmpty();
						expect( results[ 1 ].path ).notToBeEmpty();
						expect( results[ 1 ].size ).notToBeEmpty();
					} );
				} );
				given( "a valid directory with recurse = true", function(){
					then( "it can get a recursive file content map structure", function(){
						var dirPath = variables.pathPrefix & "bddtests/";
						disk.createDirectory( dirPath );
						disk.create(
							path      = dirPath & "luis.txt",
							contents  = "hello mi amigo",
							overwrite = true
						);
						disk.create(
							path      = dirPath & "Test.cfc",
							contents  = "component{}",
							overwrite = true
						);
						disk.create(
							path      = dirPath & "embedded/luis.txt",
							contents  = "hello mi amigo",
							overwrite = true
						);
						var start   = getTickCount();
						var results = disk.allContentsMap( dirPath );
						expect( results.len() ).toBe( 3 );
						expect( results[ 1 ].contents ).notToBeEmpty();
						expect( results[ 1 ].path ).notToBeEmpty();
						expect( results[ 1 ].size ).notToBeEmpty();
					} );
				} );
			} );

			// /********************************************************/
			// /** Additional verfications **/
			// /********************************************************/
			story( "The disk can work with binary and non-binary files", function(){
				beforeEach( function( currentSpec ){
					disk.deleteDirectory( variables.pathPrefix & "bddtests" );
				} );
				given( "we have a json file", function(){
					then( "it should determine the file is not binary", function(){
						var dirPath  = variables.pathPrefix & "bddtests/";
						var filePath = dirPath & "supermario.json";
						var jsonData = { "game" : "Super Mario Bros" };

						disk.create(
							path      = filePath,
							contents  = serializeJSON( jsonData ),
							overwrite = true
						);

						expect( disk.isBinaryFile( filePath ) ).toBeFalse(
							"Binary mimetype detected on JSON file.  The detected mimetype of the file is #disk.getMimeType( filePath )#"
						);
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
	 * This method should validate the creation of a url to a file via the "url()" method.
	 * This implementation is a basic in and out.
	 *
	 * @path The target path
	 * @disk The disk used
	 */
	function validateURL( required string path, required any disk ){
		if ( findNoCase( "RamProvider", getMetadata( disk ).name ) ) return;
		var fileURL = disk.url( arguments.path );
		expect( fileURL ).toInclude( disk.normalizePath( arguments.path ) ).toInclude( "http" );
	}

	/**
	 * This method should validate the creation of a temporary url to a file via the "url()" method.
	 * This implementation is a basic in and out.
	 *
	 * @path The target path
	 * @disk The disk used
	 */
	function validateTemporaryUrl( required string path, required any disk ){
		expect( disk.temporaryUrl( arguments.path ) ).toInclude( disk.normalizePath( arguments.path ) );
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
		return !variables.testFeatures.keyExists( feature ) || variables.testFeatures[ arguments.feature ];
	}

	/**
	 * Check if is Windows
	 */
	function isWindows(){
		return reFindNoCase( "Windows", createObject( "java", "java.lang.System" ).getProperties()[ "os.name" ] );
	}

	/**
	 * Check if is Linux
	 */
	function isLinux(){
		return reFindNoCase( "Linux", createObject( "java", "java.lang.System" ).getProperties()[ "os.name" ] );
	}

	/**
	 * Check if is Mac
	 */
	function isMac(){
		return reFindNoCase( "Mac", createObject( "java", "java.lang.System" ).getProperties()[ "os.name" ] );
	}

}
