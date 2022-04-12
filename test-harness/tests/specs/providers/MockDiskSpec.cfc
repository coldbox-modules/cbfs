component extends="tests.resources.AbstractDiskSpec" {

	// The name of the provider in the test-harness we want to test
	variables.providerName = "Mock";
	variables.testFeatures = {
		symbolicLink : true
	};

	function getNonWritablePathForTest( disk, path ){
		arguments.disk.nonWritablePaths[ arguments.path ] = true;
		return arguments.path;
	}

	function getNonReadablePathForTest( disk, path ){
		arguments.disk.nonReadablePaths[ arguments.path ] = true;
		return arguments.path;
	}

}
