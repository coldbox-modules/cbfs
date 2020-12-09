component extends="tests.resources.AbstractDiskSpec" {

    function getDisk( string name = "test", struct properties = { "path": "/tests/resources/storage" } ) {
        var disk = new cbfs.models.providers.LocalProvider();
        disk.configure( arguments.name, arguments.properties );
        return disk;
    }

    function getNonWritablePathForTest( disk, path ) {
        disk.chmod( path, "004" );
        return arguments.path;
    }

    function getNonReadablePathForTest( disk, path ) {
        disk.chmod( path, "000" );
        return arguments.path;
    }

}
