/**
 * Disk Service Spec
 */
component extends="coldbox.system.testing.BaseTestCase" {

	// Load and do not unload COldBOx, for performance
	this.loadColdbox   = true;
	this.unLoadColdBox = true;

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

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "Disk Service", function(){
			beforeEach( function( currentSpec ){
				service = getInstance( "DiskService@cbfs" ).init();
			} );

			it( "can be created", function(){
				expect( service ).toBeComponent();
				expect( service.getDisks() ).toBeEmpty();
			} );

			it( "can be shutdown", function(){
				service.shutdown();
				expect( service.getDisks() ).toBeEmpty();
			} );

			story( "I want to get disk records for registered disks", function(){
				given( "a valid disk name", function(){
					then( "I will get the disk record", function(){
						service.register( name: "Unit", provider: "Local" );
						expect( service.getDiskRecord( "Unit" ) ).toBeStruct().toHaveKey( "provider,properties" );
					} );
				} );
				given( "an invalid disk name", function(){
					then( "It will throw an InvalidDiskException ", function(){
						expect( function(){
							service.getDiskRecord( "bogus" );
						} ).toThrow( "InvalidDiskException" );
					} );
				} );
			} );

			story( "I want to retrieve disks via the get() operation", function(){
				given( "a disk that has not been created yet", function(){
					then( "it should build it, register it and return it", function(){
						service.register(
							name      : "Unit",
							provider  : "Local",
							properties: { path : "/tests/resources/storage", autoExpand : true }
						);
						var oDisk = service.get( "Unit" );
						expect( oDisk ).toBeComponent();
						expect( oDisk.getName() ).toBe( "Unit" );
					} );
				} );

				given( "a previously built disk", function(){
					then( "it should return the same disk", function(){
						service.register(
							name      : "Unit",
							provider  : "Local",
							properties: { path : "/tests/resources/storage", autoExpand : true }
						);
						var oDisk = service.get( "Unit" );
						expect( service.get( "Unit" ).getIdentifier() ).toBe( oDisk.getIdentifier() );
					} );
				} );

				given( "an invalid and unregistered disk", function(){
					then( "it should throw a InvalidDiskException", function(){
						expect( function(){
							service.get( "Bogus" );
						} ).toThrow( "InvalidDiskException" );
					} );
				} );
			} );

			story( "I want to be able to register disk blueprints", function(){
				given( "valid disk properties", function(){
					when( "override is false and no disk with the name RamProvider exists", function(){
						then( "the disk should be registered", function(){
							expect( service.has( "RamProvider" ) ).toBeFalse();
							service.register( name: "RamProvider", provider: "Ram" );
							expect( service.has( "RamProvider" ) ).toBeTrue();
						} );
					} );
				} );
				given( "valid disk properties", function(){
					when( "override is false and a disk with the name RamProvider is already registered", function(){
						then( "the service will ignore the registration", function(){
							expect( service.has( "RamProvider" ) ).toBeFalse();
							service.register( name: "RamProvider", provider: "Ram" );
							expect( service.has( "RamProvider" ) ).toBeTrue();

							// Try to register it again with a different provider
							service.register( name: "RamProvider", provider: "Local" );
							expect( service.has( "RamProvider" ) ).toBeTrue();
							expect( service.getDiskRecord( "RamProvider" ).provider ).toBe( "Ram" );
						} );
					} );
				} );
				given( "valid disk properties", function(){
					when( "override is true and a disk with the name RamProvider is already registered", function(){
						then( "the service will re-register the disk", function(){
							expect( service.has( "RamProvider" ) ).toBeFalse();
							service.register( name: "RamProvider", provider: "Ram" );
							expect( service.has( "RamProvider" ) ).toBeTrue();

							// Register it again
							service.register(
								name    : "RamProvider",
								provider: "Local",
								override: true
							);
							expect( service.has( "RamProvider" ) ).toBeTrue();
							expect( service.getDiskRecord( "RamProvider" ).provider ).toBe( "Local" );
						} );
					} );
				} );
			} );

			story( "I want to be able to unregister disks", function(){
				given( "a valid disk name and the disk has been built", function(){
					then( "the disk should be shutdown and unregistered", function(){
						var RamProvider = createStub().$( "shutdown" );
						service
							.getDisks()
							.append( { "local" : { provider : "Local", properties : {}, disk : RamProvider } } );

						service.unregister( "local" );
						expect( RamProvider.$callLog().shutdown ).toHaveLength( 1 );
						expect( service.has( "local" ) ).toBeFalse();
					} );
				} );
				given( "a valid disk name and the disk has NOT been built", function(){
					then( "the disk will be unregistered", function(){
						service.register( name: "local", provider: "Ram" );
						service.unregister( "local" );
						expect( service.has( "local" ) ).toBeFalse();
					} );
				} );
				given( "a invalid disk name", function(){
					then( "then we will throw a InvalidDiskException", function(){
						expect( function(){
							service.unregister( "bogus" );
						} ).toThrow( "InvalidDiskException" );
					} );
				} );
			} );

			story( "I want to check if a disk has been registered or not", function(){
				given( "a valid disk name", function(){
					then( "then it will validate that the disk has been regsitered", function(){
						service.register( name: "local", provider: "Ram" );
						expect( service.has( "local" ) ).toBeTrue();
					} );
				} );
				given( "a invalid disk name", function(){
					then( "then it will tell me it's not registered", function(){
						expect( service.has( "bogus" ) ).toBeFalse();
					} );
				} );
			} );

			story( "I want to be able to get an array of registered disk names", function(){
				given( "no registered disks", function(){
					then( "then the names will be empty", function(){
						expect( service.names() ).toBeEmpty();
					} );
				} );
				given( "a few registered disks", function(){
					then( "then the names will not be empty", function(){
						service.register( name: "local", provider: "Ram" );
						expect( service.names() ).notToBeEmpty();
					} );
				} );
			} );

			story( "I want to be able to count how many disks are registered", function(){
				given( "no registered disks", function(){
					then( "then the count will be zero", function(){
						expect( service.count() ).toBe( 0 );
					} );
				} );
				given( "a few registered disks", function(){
					then( "then the count will be > zero", function(){
						service.register( name: "local", provider: "Ram" );
						expect( service.count() ).toBeGT( 0 );
					} );
				} );
			} );


			story( "I want to retrieve the temp disk via the shortcut method: tempDisk()", function(){
				it( "can retrieve the temp disk", function(){
					service.register( name: "temp", provider: "Ram" );
					expect( service.tempDisk().getName() ).toBe( "temp" );
				} );
			} );
			story( "I want to retrieve the default disk via the shortcut method: defaultDisk()", function(){
				it( "can retrieve the default disk", function(){
					service.register( name: "default", provider: "Ram" );
					expect( service.defaultDisk().getName() ).toBe( "default" );
				} );
			} );
		} );
	}

}
