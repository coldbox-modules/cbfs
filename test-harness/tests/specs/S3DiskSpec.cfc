component extends="tests.resources.AbstractDiskSpec" {

    function getDisk( string name = "test", struct properties = { "path": "tests/resources/storage" } ) {
        var disk = prepareMock( new cbfs.models.providers.S3Provider() );
        disk.configure( arguments.name, arguments.properties );
		makePublic( disk, "buildPath", "buildPath" );
        return disk;
    }

	function testURLExpectation( required any disk, required string path ){
		expect( findNOCase( path, disk.url( path ) ) ).toBeTrue();
	}

	function testTemporaryURLExpectation( required any disk, required string path ){
		expect( findNOCase( path, disk.url( path ) ) ).toBeTrue();
	}

    function retrieveUrlForTest( required string path ) {
        return arguments.path;
    }

    function retrieveTemporaryUrlForTest( required string path ) {
        return arguments.path;
    }

}
