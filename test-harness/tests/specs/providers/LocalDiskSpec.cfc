component extends="tests.resources.AbstractDiskSpec" {

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

			story( "I want to read the posix attributes of a path", function(){
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
			} );
		} );
	}

	/**
	 * ------------------------------------------------------------
	 * Concrete Expectations that can be implemented by each provider
	 * ------------------------------------------------------------
	 */
	function validateInfoStruct( required info, required disk ){
		expect( info ).toHaveKey(
			"path,size,name,type,canWrite,canRead,isHidden"
		);
	}

}
