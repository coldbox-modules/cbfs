component extends="tests.resources.AbstractDiskSpec" {

    this.loadColdbox = true;
    variables.testDirectoryName = "tests/" & createUUID();

    function getDisk( string name = "test", struct properties = { "path": variables.testDirectoryName } ) {
        var disk = prepareMock( new cbfs.models.providers.S3Provider() );
        getWirebox().autowire( disk );
        disk.configure( arguments.name, arguments.properties );
        makePublic( disk, "buildPath", "buildPath" );
        return disk;
    }

    function testURLExpectation( required any disk, required string path ) {
        expect( findNoCase( path, disk.url( path ) ) ).toBeTrue();
    }

    function testTemporaryURLExpectation( required any disk, required string path ) {
        expect( findNoCase( path, disk.url( path ) ) ).toBeTrue();
    }

    function retrieveUrlForTest( required string path ) {
        return arguments.path;
    }

    function retrieveTemporaryUrlForTest( required string path ) {
        return arguments.path;
    }

}
