component extends="cbfs.models.testing.AbstractDiskSpec" {

	// The target provider name to test
	variables.providerName = "S3";
	// The concrete test must activate these in order for the tests to execute according to their disk features
	variables.publicDomain = createObject( "java", "java.lang.System" ).getEnv( "AWS_S3_PUBLIC_DOMAIN" );
	if ( isNull( variables.publicDomain ) ) {
		variables.publicDomain = createObject( "java", "java.lang.System" ).getProperty( "AWS_S3_PUBLIC_DOMAIN" );
	}

	variables.testFeatures = {
		symbolicLink : false,
		chmod        : isNull( publicDomain ) || !findNoCase( ":9090", publicDomain )
	};

	// Path prefix for handling concurrency during workflow engine tests
	variables.pathPrefix = createUUID() & "/";

	function run(){
		super.run();

		describe( "#variables.providerName# Provider Extended Specs", function(){
			beforeEach( function( currentSpec ){
				disk                   = getDisk();
				variables.publicDomain = disk.getProperties()[ "publicDomain" ];
			} );

			afterEach( function( currentSpec ){
				structAppend(
					disk.getProperties(),
					{ "publicDomain" : variables.publicDomain },
					true
				);
			} );

			// /********************************************************/
			// /** S3 Disk Custom Methods **/
			// /********************************************************/
			story( "Test S3Disk custom methods", function(){
				it( "Can provide a url using a custom public domain", function(){
					disk.getProperties()[ "publicDomain" ] = "cdn.cbfs-s3.com";
					var path = "test.txt";
					disk.create(
						path     : path,
						contents : "hola amigo!",
						metadata : {},
						overwrite: true
					);
					disk.getProperties()[ "publicDomain" ] = "cdn.cbfs-s3.com";
					expect( find( disk.getProperties().publicDomain, disk.url( path ) ) ).toBeTrue();
				} );
			} )
		} ); // end suite
	}

}
