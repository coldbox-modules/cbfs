component extends="tests.resources.AbstractDiskSpec" {

	// The name of the provider in the test-harness we want to test
	variables.providerName = "Mock";
	// Which features does this disk support for testing
	variables.testFeatures = { symbolicLink : true };

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
	 * This method should validate the creation of a temporary uri to a file via the "uri()" method.
	 * This implementation is a basic in and out.
	 *
	 * @uri  The built uri via the uri() method
	 * @path The original path used
	 * @disk The disk used
	 */
	function validateTemporaryUri(
		required string uri,
		required string path,
		required numeric expiration,
		required any disk
	){
		expect( arguments.uri ).toInclude( arguments.path ).toInclude( "expiration=#arguments.expiration#" );
	}

}
