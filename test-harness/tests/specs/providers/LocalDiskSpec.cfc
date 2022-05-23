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

	/**
	 * ------------------------------------------------------------
	 * Concrete Expectations that can be implemented by each provider
	 * ------------------------------------------------------------
	 */
	function validateInfoStruct( required info, required disk ){
		expect( info ).toHaveKey(
			"path,contents,checksum,visibility,lastModified,size,name,mimetype,type,write,read,execute,hidden,metadata,mode,symbolicLink"
		);
	}

}
