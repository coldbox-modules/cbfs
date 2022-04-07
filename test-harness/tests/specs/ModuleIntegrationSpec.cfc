component extends="coldbox.system.testing.BaseTestCase" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	/**
	 * executes before all suites+specs in the run() method
	 */
	function beforeAll(){
		super.beforeAll();
		setup();
	}

	/**
	 * executes after all suites+specs in the run() method
	 */
	function afterAll(){
		super.afterAll();
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "cbfs integration", function(){
			it( "can register and activate the module", function(){
				expect( getController().getModuleService().isModuleActive( "cbfs" ) ).toBeTrue(
					"cbfs should be active"
				);
			} );

			it( "can register the app disks", function(){
				var diskService = getInstance( dsl = "cbfs" );
				expect( diskService.get( "local" ) ).toBeComponent();
				expect( diskService.get( "mock" ) ).toBeComponent();
				expect( diskService.get( "default" ) ).toBeComponent();
				expect( diskService.get( "temp" ) ).toBeComponent();
			} );

			it( "can register the module disks", function(){
				var diskService = getInstance( dsl = "cbfs" );
				// Module Ones
				expect( diskService.get( "nasa@diskModule" ) ).toBeComponent();
				expect( diskService.get( "temp@diskModule" ) ).toBeComponent();

				// Global Ones
				expect( diskService.get( "nasa" ) ).toBeComponent();
				expect( diskService.get( "local" ) ).toBeComponent();
				expect( diskService.get( "mock" ) ).toBeComponent();
				expect( diskService.get( "default" ) ).toBeComponent();
				expect( diskService.get( "temp" ) ).toBeComponent();
			} );

			it( "can inject the disk service using the cbfs dsl", function(){
				var diskService = getInstance( dsl = "cbfs" );
				expect( diskService ).toBeInstanceOf( "DiskService" );
			} );

			it( "can inject the disks struct using the cbfs dsl", function(){
				var diskService = getInstance( dsl = "cbfs" );
				diskService.register( name: "Mock", provider: "Mock" );

				var disks = getInstance( dsl = "cbfs:disks" );
				expect( disks ).toHaveKey( "Mock" );
				expect( disks.mock.provider ).toBe( "Mock" );
			} );

			it( "can inject using a disk using the cbfs dsl", function(){
				var diskService = getInstance( dsl = "cbfs" );
				diskService.register( name: "Mock", provider: "Mock" );

				var localDisk = getInstance( dsl = "cbfs:disks:Mock" );

				expect( localDisk ).toBeInstanceOf( "MockProvider" );
				expect( localDisk.getName() ).toBe( "Mock" );
			} );
		} );
	}

}
