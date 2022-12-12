component extends="cbfs.models.testing.AbstractDiskSpec" {

	// The name of the provider in the test-harness we want to test
	variables.providerName = "Ram";
	// Which features does this disk support for testing
	variables.testFeatures = { symbolicLink : true };

	function run(){
		super.run();

		// Localized Suites
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

	/**
	 * This method should validate the creation of a temporary uri to a file via the "url()" method.
	 * This implementation is a basic in and out.
	 *
	 * @path The target path
	 * @disk The disk used
	 */
	function validateTemporaryUrl( required string path, required any disk ){
		expect( disk.temporaryUrl( arguments.path, 60 ) )
			.toInclude( disk.normalizePath( arguments.path ) )
			.toInclude( "expiration=60" );
	}

}
