component extends="tests.resources.AbstractDiskSpec" {

    this.loadColdbox = true;

    function getDisk( string name = "test", struct properties = { "path": "/tests/resources/storage" } ) {
        var disk = prepareMock( new cbfs.models.providers.LocalProvider() );
        getWirebox().autowire( disk );
        disk.configure( arguments.name, arguments.properties );
        makePublic( disk, "buildPath", "buildPath" );
        return disk;
    }

    function getNonWritablePathForTest( disk, path ) {
        disk.chmod( arguments.path, "004" );
        return arguments.path;
    }

    function getNonReadablePathForTest( disk, path ) {
        disk.chmod( arguments.path, "000" );
        return arguments.path;
    }

    function run() {
        super.run();

        // Tests which are only applicable to local disks
        describe( "touch on local disk", function() {
            it( "updates the last modified date if the file already exists", function() {
                var disk = getDisk();
                var path = "test_file.txt";
                disk.delete( path );
                disk.create( path = path, contents = "my contents", overwrite = true );
                var originalLastModified = disk.lastModified( path );
                sleep( 1010 );
                disk.touch( path );
                expect( disk.exists( path ) ).toBeTrue( "[#path#] should exist" );
                expect( disk.get( path ) ).toBe( "my contents" );
                var newLastModified = disk.lastModified( path );
                expect( newLastModified ).toBeGT( originalLastModified );
            } );
        } );
    }

}
