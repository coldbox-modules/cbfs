component extends="coldbox.system.testing.BaseTestCase" {

	// Load and do not unload COldBOx, for performance
	this.loadColdbox   = true;
	this.unLoadColdBox = false;

	/*********************************** LIFE CYCLE Methods ***********************************/

	/**
	 * executes before all suites+specs in the run() method
	 */
	function beforeAll(){
		request.coldBoxVirtualApp.shutdown();
		structDelete( request, "coldBoxVirtualApp" );
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
				expect( diskService.get( "ram" ) ).toBeComponent();
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
				expect( diskService.get( "ram" ) ).toBeComponent();
				expect( diskService.get( "default" ) ).toBeComponent();
				expect( diskService.get( "temp" ) ).toBeComponent();
			} );

			it( "can inject the disk service using the cbfs dsl", function(){
				var diskService = getInstance( dsl = "cbfs" );
				expect( diskService ).toBeInstanceOf( "DiskService" );
			} );

			it( "can inject the disks struct using the cbfs dsl", function(){
				var diskService = getInstance( dsl = "cbfs" );
				diskService.register( name: "Ram", provider: "Ram" );

				var disks = getInstance( dsl = "cbfs:disks" );
				expect( disks ).toHaveKey( "Ram" );
				expect( disks.ram.provider ).toBe( "Ram" );
			} );

			it( "can inject using a disk using the cbfs dsl", function(){
				var diskService = getInstance( dsl = "cbfs" );
				diskService.register( name: "Ram", provider: "Ram" );

				var localDisk = getInstance( dsl = "cbfs:disks:Ram" );

				expect( localDisk ).toBeInstanceOf( "RamProvider" );
				expect( localDisk.getName() ).toBe( "Ram" );
			} );
		} );
	}

}
