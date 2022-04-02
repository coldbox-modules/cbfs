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
				expect( service.getDiskRegistry() ).toBeEmpty();
			} );

			it( "can be shutdown", function(){
				service.shutdown();
				expect( service.getDisks() ).toBeEmpty();
			} );

			it( "can register disks from the ColdBox application", function(){
			} );

			story( "I want to retrieve disks", function(){
				given( "a disk that has not been created yet", function(){
					then( "it should build it, register it and return it", function(){
						expect( service.getDisks().keyExists( "Unit" ) ).toBeFalse();
						service.get()
					} );
				} );

				given( "a previously registered disk", function(){
					then( "it should return the same disk", function(){
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

			story( "I want to be able to build disks", function(){
				given( "given valid disk arguments", function(){
					when( "the override is false and the disk name is available", function(){
						then( "it should build, register and return the disk", function(){
							var disk = service.build(
								name      : "UnitTest",
								provider  : "Local",
								properties: { path : expandPath( "/tests/resources/storage" ) }
							);
							expect( service.has( "UnitTest" ) ).toBeTrue( "Disk should be registered" );
							expect( disk.getName() ).toBe( "UnitTest" );
							expect( disk.getProperties().path ).toInclude( "/tests/resources/storage" );
							expect( disk.hasStarted() ).toBeTrue( "Should be started" );
						} );
					} );
					when( "the override is false and the disk name is already in use", function(){
						then( "it should throw a DiskAlreadyExistsException", function(){
							service.getDisks().append( { "local" : createStub() } );
							expect( function(){
								service.build( "local", "Local", {} );
							} ).toThrow( "DiskAlreadyExistsException" );
						} );
					} );
					when( "the override is true", function(){
						then( "it should build, register, override and return the disk", function(){
							var disk = service.build(
								name      : "UnitTest",
								provider  : "Local",
								properties: { path : expandPath( "/tests/resources/storage" ) }
							);
							expect( service.has( "UnitTest" ) ).toBeTrue( "Disk should be registered" );
							expect( disk.getName() ).toBe( "UnitTest" );

							var disk = service.build(
								name      : "UnitTest",
								provider  : "Local",
								properties: { path : expandPath( "/tests/resources/" ) },
								override  : true
							);
							expect( service.has( "UnitTest" ) ).toBeTrue( "Disk should be registered" );
							expect( disk.getName() ).toBe( "UnitTest" );
							expect( disk.getProperties().path ).notToInclude( "storage" );
						} );
					} );
				} );
				given( "a custom provider path", function(){
					then( "it should create and register the custom provider", function(){
						var oDisk = service.build( name: "Custom", provider: "tests.resources.CustomProvider" );
						expect( service.has( "Custom" ) ).toBeTrue( "Disk should be registered" );
						expect( oDisk.getName() ).toBe( "Custom" );
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
					} )
				} );
				given( "valid disk properties", function(){
					when( "override is false and a disk with the name MockProvider is already registered", function(){
						then( "the service will ignore the registration", function(){
							expect( service.has( "mockProvider" ) ).toBeFalse();
							service.register( name: "MockProvider", provider: "Mock" );
							expect( service.has( "mockProvider" ) ).toBeTrue();
							service.register( name: "MockProvider", provider: "Local" );
							expect( service.has( "mockProvider" ) ).toBeTrue();
							var registry = service.getDiskRegistry();
							expect( registry[ "mockProvider" ].provider ).toBe( "Mock" );
						} );
					} )
				} );
				given( "valid disk properties", function(){
					when( "override is true and a disk with the name MockProvider is already registered", function(){
						then( "the service will re-register the disk", function(){
							expect( service.has( "mockProvider" ) ).toBeFalse();
							service.register( name: "MockProvider", provider: "Mock" );
							expect( service.has( "mockProvider" ) ).toBeTrue();
							service.register(
								name    : "MockProvider",
								provider: "Local",
								override: true
							);
							expect( service.has( "mockProvider" ) ).toBeTrue();
							var registry = service.getDiskRegistry();
							expect( registry[ "mockProvider" ].provider ).toBe( "Local" );
						} );
					} )
				} );
			} );

			story( "I want to be able to unregister disks", function(){
				given( "a valid disk name and the disk has been built", function(){
					then( "the disk should be shutdown and unregistered", function(){
						service
							.getDiskRegistry()
							.append( { "local" : { provider : "LocalWeb", properties : {} } } );
						var mockProvider = createStub().$( "shutdown" );
						service.getDisks().append( { "local" : mockProvider } );
						service.unregister( "local" );
						expect( mockProvider.$callLog().shutdown ).toHaveLength( 1 );
						expect( service.has( "local" ) ).toBeFalse();
					} );
				} );
				given( "a valid disk name and the disk has NOT been built", function(){
					then( "the disk will be unregistered", function(){
						service
							.getDiskRegistry()
							.append( { "local" : { provider : "LocalWeb", properties : {} } } );
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
						service
							.getDiskRegistry()
							.append( { "local" : { provider : "LocalWeb", properties : {} } } );
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
						service
							.getDiskRegistry()
							.append( { "local" : { provider : "LocalWeb", properties : {} } } );
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
						service
							.getDiskRegistry()
							.append( { "local" : { provider : "LocalWeb", properties : {} } } );
						expect( service.count() ).toBeGT( 0 );
					} );
				} );
			} );
		} );
	}

}
