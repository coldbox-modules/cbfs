component extends="cbfs.models.testing.AbstractDiskSpec" {

	// The name of the provider in the test-harness we want to test
	variables.providerName = "Local";
	variables.TEST_PATH    = expandPath( "/tests/storage" );
	// Which features does this disk support for testing
	variables.testFeatures = { symbolicLink : true };

	function beforeAll(){
		if ( directoryExists( variables.TEST_PATH ) ) {
			directoryDelete( variables.TEST_PATH, true );
		}
		super.beforeAll();
	}

	function run(){
		super.run();

		// Localized Suites

		describe( "Local Provider Extended Specs", function(){
			beforeEach( function( currentSpec ){
				disk = getDisk();
			} );

			story(
				story: "I want to read the posix attributes of a path",
				skip : isWindows(),
				body : function(){
					given( "a valid path", function(){
						then( "it should read all the posix attributes", function(){
							var path = "localFile.txt";
							disk.create(
								path      = path,
								contents  = "my contents",
								overwrite = true
							);
							var test = disk.extendedInfo( path );
							// writeDump( var = test, top = 5 );
							expect( test ).toHaveKey( "creationTime,owner,permissions,size" );
						} );
					} );
				}
			);

			story( "I want to produce a stream from the content's of a file", function(){
				given( "a valid path", function(){
					then( "it should return a stream of the file contents", function(){
						var path = "localFile.cfc";
						disk.create(
							path      = path,
							contents  = fileRead( expandPath( "/tests/resources/AbstractDiskSpec.cfc" ) ),
							overwrite = true
						);
						var stream = disk.stream( path );
						expect( stream ).toBeInstanceOf( "Stream" );
					} );
				} );
			} );

			story( "We can work with a file object", function(){
				beforeEach( function(){
					var files = [
						variables.pathPrefix & "some_file.txt",
						variables.pathPrefix & "another_file.txt"
					];

					files.each( function( testFile ){
						if ( disk.exists( testFile ) ) {
							disk.delete( testFile );
						}
					} );

					testFile = new cbfs.models.File( disk, variables.pathPrefix & "some_file.txt" ).create(
						"some content"
					);
				} );
				given( "we get a stream", function(){
					then( "it is proxied to the disk", function(){
						expect( testFile.stream() ).toBeInstanceOf( "Stream" );
					} );
				} );
			} );
		} );
	}

	/**
	 * ------------------------------------------------------------
	 * Concrete Expectations that can be implemented by each provider
	 * ------------------------------------------------------------
	 */
	function validateInfoStruct( required info, required disk ){
		expect( info ).toHaveKey( "path,size,name,type,canWrite,canRead,isHidden" );
	}

}
