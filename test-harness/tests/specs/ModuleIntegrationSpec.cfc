component extends="coldbox.system.testing.BaseTestCase" {

	function run() {
		describe( "cbfs integration", function() {
			it( "can register and activate the module", function(){
                expect( getController().getModuleService().isModuleActive( "cbfs" ) )
                    .toBeTrue( "cbfs should be active" );
            } );

            it( "can inject the disk service", function() {
                var diskService = getWireBox().getInstance( dsl = "cbfs" );
                expect( diskService ).toBeInstanceOf( "DiskService" );
            } );

            it( "can inject the disks struct", function() {
                var disks = getWireBox().getInstance( dsl = "cbfs:disks" );
                expect( disks ).toHaveKey( "local" );
                expect( disks.local ).toHaveKey( "provider" );
                expect( disks.local.provider ).toBe( "LocalProvider@cbfs" );
            } );

            it( "can inject using a custom provider", function() {
                var localDisk = getWireBox().getInstance( dsl = "cbfs:disks:local" );
                expect( localDisk ).toBeInstanceOf( "LocalProvider" );
                expect( localDisk.getName() ).toBe( "local" );
                expect( localDisk.getProperties() ).toHaveKey( "path" );
            } );
		} );
	}

}
