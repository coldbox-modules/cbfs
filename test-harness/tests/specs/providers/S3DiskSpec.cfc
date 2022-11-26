component extends="tests.resources.AbstractDiskSpec" {

	// Load and do not unload ColdBox, for performance
	this.loadColdbox   = true;
	this.unLoadColdBox = false;

	// The target provider name to test
	variables.providerName = "S3";
	// The concrete test must activate these in order for the tests to execute according to their disk features
	variables.testFeatures = { symbolicLink : false };

	function beforeAll(){
		// Load ColdBox
		super.beforeAll();
		// Setup a request for testing.
		setup();
	}

	function run(){

		describe( "#variables.providerName# Custom Specs", function(){
			beforeEach( function( currentSpec ){
				disk = getDisk();
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
					expect( find( disk.getProperties().publicDomain, disk.url( path ) ) ).toBeTrue();
				});
			})

		} ); // end suite

		super.run();
	}

	/**
	 * ------------------------------------------------------------
	 * Concrete Expectations that can be implemented by each provider
	 * ------------------------------------------------------------
	 */

	/**
	 * This method should validate the info struct coming out of the disk from an "info()" call
	 */
	function validateInfoStruct( required info, required disk ){
	}
	/**
	 * This method should validate the creation of a uri to a file via the "uri()" method.
	 * This implementation is a basic in and out.
	 *
	 * @path The target path
	 * @disk The disk used
	 */
	function validateUri( required string path, required any disk ){
		expect( disk.uri( arguments.path ) ).toInclude( arguments.path );
	}

	/**
	 * This method should validate the creation of a temporary uri to a file via the "uri()" method.
	 * This implementation is a basic in and out.
	 *
	 * @path The target path
	 * @disk The disk used
	 */
	function validateTemporaryUri( required string path, required any disk ){
		expect( disk.temporaryUri( arguments.path ) ).toInclude( arguments.path );
	}

	/**
	 * ------------------------------------------------------------
	 * Test Helpers
	 * ------------------------------------------------------------
	 */

	function getDisk(){
		return getInstance( "DiskService@cbfs" ).get( variables.providerName );
	}

	/**
	 * This should be implemented by a concrete provider test. This implementation is a basic one.
	 *
	 * @path    The path of the file
	 * @content The contents of the file
	 */
	private function retrieveSizeForTest( required string path, required content ){
		return len( arguments.content );
	}

	/**
	 * Returns the number of seconds since January 1, 1970, 00:00:00 (Epoch time).
	 *
	 * @param   DateTime      Date/time object you want converted to Epoch time. (Required)
	 * @author  Rob Brooks-Bilson (rbils@amkor.com)
	 * @version 1, June 21, 2002
	 *
	 * @return Returns a numeric value.
	 */
	private function getEpochTimeFromLocal( datetime = now() ){
		return dateDiff(
			"s",
			dateConvert( "utc2Local", "January 1 1970 00:00" ),
			datetime
		);
	}

	private boolean function hasFeature( required feature ){
		return variables.testFeatures[ arguments.feature ];
	}

	/**
	 * Check if is Windows
	 */
	function isWindows(){
		return reFindNoCase( "Windows", createObject( "java", "java.lang.System" ).getProperties()[ "os.name" ] );
	}

	/**
	 * Check if is Linux
	 */
	function isLinux(){
		return reFindNoCase( "Linux", createObject( "java", "java.lang.System" ).getProperties()[ "os.name" ] );
	}

	/**
	 * Check if is Mac
	 */
	function isMac(){
		return reFindNoCase( "Mac", createObject( "java", "java.lang.System" ).getProperties()[ "os.name" ] );
	}

}
