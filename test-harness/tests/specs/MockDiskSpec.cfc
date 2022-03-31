component extends="tests.resources.AbstractDiskSpec" {

    function getDisk( string name = "test", struct properties = { "path": "" } ) {
        var disk = prepareMock( new cbfs.models.providers.MockProvider() );
        disk.configure( arguments.name, arguments.properties );
        makePublic( disk, "buildPath", "buildPath" );
        return disk;
    }

    function getNonWritablePathForTest( disk, path ) {
        arguments.disk.nonWritablePaths[ arguments.path ] = true;
        return arguments.path;
    }

    function getNonReadablePathForTest( disk, path ) {
        arguments.disk.nonReadablePaths[ arguments.path ] = true;
        return arguments.path;
    }

}
