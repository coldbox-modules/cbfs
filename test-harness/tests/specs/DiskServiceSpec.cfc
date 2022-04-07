/**
 * Disk Service Spec
 */
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
					when( "override is false and no disk with the name MockProvider exists", function(){
						then( "the disk should be registered", function(){
							expect( service.has( "mockProvider" ) ).toBeFalse();
							service.register( name: "MockProvider", provider: "Mock" );
							expect( service.has( "mockProvider" ) ).toBeTrue();
						} );
					} );
				} );
				given( "valid disk properties", function(){
					when( "override is false and a disk with the name MockProvider is already registered", function(){
						then( "the service will ignore the registration", function(){
							expect( service.has( "mockProvider" ) ).toBeFalse();
							service.register( name: "MockProvider", provider: "Mock" );
							expect( service.has( "mockProvider" ) ).toBeTrue();

							// Try to register it again with a different provider
							service.register( name: "MockProvider", provider: "Local" );
							expect( service.has( "mockProvider" ) ).toBeTrue();
							expect( service.getDiskRecord( "MockProvider" ).provider ).toBe( "Mock" );
						} );
					} );
				} );
				given( "valid disk properties", function(){
					when( "override is true and a disk with the name MockProvider is already registered", function(){
						then( "the service will re-register the disk", function(){
							expect( service.has( "mockProvider" ) ).toBeFalse();
							service.register( name: "MockProvider", provider: "Mock" );
							expect( service.has( "mockProvider" ) ).toBeTrue();

							// Register it again
							service.register(
								name    : "MockProvider",
								provider: "Local",
								override: true
							);
							expect( service.has( "mockProvider" ) ).toBeTrue();
							expect( service.getDiskRecord( "MockProvider" ).provider ).toBe( "Local" );
						} );
					} );
				} );
			} );

			story( "I want to be able to unregister disks", function(){
				given( "a valid disk name and the disk has been built", function(){
					then( "the disk should be shutdown and unregistered", function(){
						var mockProvider = createStub().$( "shutdown" );
						service
							.getDisks()
							.append( {
								"local" : {
									provider   : "LocalWeb",
									properties : {},
									disk       : mockProvider
								}
							} );

						service.unregister( "local" );
						expect( mockProvider.$callLog().shutdown ).toHaveLength( 1 );
						expect( service.has( "local" ) ).toBeFalse();
					} );
				} );
				given( "a valid disk name and the disk has NOT been built", function(){
					then( "the disk will be unregistered", function(){
						service.register( name: "local", provider: "Mock" );
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
						service.register( name: "local", provider: "Mock" );
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
						service.register( name: "local", provider: "Mock" );
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
						service.register( name: "local", provider: "Mock" );
						expect( service.count() ).toBeGT( 0 );
					} );
				} );
			} );


			story( "I want to retrieve the temp disk via the shortcut method: getTempDisk()", function(){
				it( "can retrieve the temp disk", function(){
					service.register( name: "temp", provider: "Mock" );
					expect( service.getTempDisk().getName() ).toBe( "temp" );
				} );
			} );
			story( "I want to retrieve the default disk via the shortcut method: getDefaultDisk()", function(){
				it( "can retrieve the default disk", function(){
					service.register( name: "default", provider: "Mock" );
					expect( service.getDefaultDisk().getName() ).toBe( "default" );
				} );
			} );
		} );
	}

}
