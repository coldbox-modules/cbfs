﻿component {

	// Configure ColdBox Application
	function configure(){
		// coldbox directives
		coldbox = {
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

		moduleSettings = {
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
							"visibility"        : "public", // can be 'public' or 'private'
							"path"              : "",
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

		// environment settings, create a detectEnvironment() method to detect it yourself.
		// create a function with the name of the environment so it can be executed if that environment is detected
		// the value of the environment is a list of regex patterns to match the cgi.http_host.
		environments = { development : "localhost,127\.0\.0\.1" };

		// Module Directives
		modules = {
			// An array of modules names to load, empty means all of them
			include : [],
			// An array of modules names to NOT load, empty means none
			exclude : []
		};

		// Register interceptors as an array, we need order
		interceptors = [];

		// LogBox DSL
		logBox = {
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
	 */
	function cbLoadInterceptorHelpers( event, interceptData, rc, prc ){
		controller
			.getModuleService()
			.registerAndActivateModule( moduleName = request.MODULE_NAME, invocationPath = "moduleroot" );
	}

}
