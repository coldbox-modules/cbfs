component extends="tests.resources.AbstractDiskSpec" {

    function getDisk() {
        var disk = new cbfs.models.providers.MockProvider();
        disk.configure( "test" );
        return disk;
    }

    function retrieveUrlForTest( required string path ) {
        return arguments.path;
    }

    function retrieveTemporaryUrlForTest( required string path ) {
        return arguments.path;
    }

    function retireveSizeForTest( required string path, required content ) {
        return len( arguments.content );
    }

    function getWritablePathForTest( path ) {
        return arguments.path;
    }

    function getNonWritablePathForTest( disk, path ) {
        arguments.disk.nonWritablePaths[ arguments.path ] = true;
        return arguments.path;
    }

    function getReadablePathForTest( disk, path ) {
        return arguments.path;
    }

    function getNonReadablePathForTest( disk, path ) {
        arguments.disk.nonReadablePaths[ arguments.path ] = true;
        return arguments.path;
    }

}
