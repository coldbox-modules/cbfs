component extends="tests.resources.AbstractDiskSpec" {

    function getDisk() {
        var disk = new cbfs.models.providers.MockProvider();
        disk.configure( "test" );
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
