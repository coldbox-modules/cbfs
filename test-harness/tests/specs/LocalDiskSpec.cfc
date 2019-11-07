component extends="tests.resources.AbstractDiskSpec" {

    function getDisk( string name = "test", struct properties = { "path": "/tests/resources/storage" } ) {
        var disk = new cbfs.models.providers.LocalProvider();
        disk.configure( arguments.name, arguments.properties );
        return disk;
    }

}
