component {

	// Configure ColdBox Application
	function configure(){
		// coldbox directives
		variables.coldbox = {
			// Application Setup
			appName                 : "Module Tester",
			// Development Settings
			reinitPassword          : "",
			handlersIndexAutoReload : true,
			modulesExternalLocation : [],
			// Implicit Events
			defaultEvent            : "",
			requestStartHandler     : "",
			requestEndHandler       : "",
			applicationStartHandler : "",
			applicationEndHandler   : "",
			sessionStartHandler     : "",
			sessionEndHandler       : "",
			missingTemplateHandler  : "",
			// Error/Exception Handling
			exceptionHandler        : "",
			onInvalidEvent          : "",
			customErrorTemplate     : "/coldbox/system/exceptions/Whoops.cfm",
			// Application Aspects
			handlerCaching          : false,
			eventCaching            : false
		};

		variables.moduleSettings = {
			"cbfs" : {
				"disks" : {
					"local" : {
						"provider"   : "Local",
						"properties" : {
							"path"  : expandPath( "/root/tests/storage" ),
							diskUrl : "http://localhost:60299/tests/storage/"
						}
					},
					"ram" : { "provider" : "Ram" },
					"S3"  : {
						"provider"   : "S3",
						"properties" : {
							"visibility"        : "private", // can be 'public' or 'private'
							"path"              : "",
							"defaultACL"        : getSystemSetting( "AWS_S3_DEFAULT_ACL", "private" ),
							"ssl"               : getSystemSetting( "AWS_S3_SSL", true ),
							"accessKey"         : getSystemSetting( "AWS_S3_ACCESS_KEY", "" ),
							"secretKey"         : getSystemSetting( "AWS_S3_SECRET_KEY", "" ),
							"awsDomain"         : getSystemSetting( "AWS_S3_DOMAIN", "amazonaws.com" ),
							"awsRegion"         : getSystemSetting( "AWS_S3_REGION", "us-east-1" ),
							"defaultBucketName" : getSystemSetting(
								"AWS_S3_BUCKET_NAME",
								"ortus-cbfs-testing-disk"
							),
							"signatureType" : getSystemSetting( "AWS_S3_SIGNATURE_TYPE", "v4" )
						}
					}
				}
			}
		};

		if ( len( getSystemSetting( "AWS_S3_PUBLIC_DOMAIN", "" ) ) ) {
			moduleSettings.cbfs.disks.S3.properties[ "publicDomain" ] = getSystemSetting( "AWS_S3_PUBLIC_DOMAIN" );
		}

		// Register interceptors as an array, we need order
		variables.interceptors = [];

		// LogBox DSL
		variables.logBox = {
			// Define Appenders
			appenders : {
				myConsole : { class : "ConsoleAppender" },
				files     : {
					class      : "RollingFileAppender",
					properties : { filename : "tester", filePath : "/#appMapping#/logs" }
				}
			},
			// Root Logger
			root : { levelmax : "DEBUG", appenders : "*" },
			// Implicit Level Categories
			info : [ "coldbox.system" ]
		};
	}

	/**
	 * Load the Module you are testing
	 *
	 * Note: We can't rely on `request.MODULE_NAME` here because ColdBox's test harness
	 * clears/bypasses the `request` scope between virtual-app reinits (BaseTestCase's
	 * reset()/beforeTests()), so that key set in Application.cfc's pseudo-constructor
	 * may no longer exist by the time this interceptor fires on a reinit.
	 */
	function cbLoadInterceptorHelpers( event, interceptData, rc, prc ){
		controller.getModuleService().registerAndActivateModule( moduleName = "cbfs", invocationPath = "moduleroot" );
	}

}
