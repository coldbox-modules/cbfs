﻿component{

	// Configure ColdBox Application
	function configure(){

		// coldbox directives
		coldbox = {
			//Application Setup
			appName 				= "Module Tester",

			//Development Settings
			reinitPassword			= "",
			handlersIndexAutoReload = true,
			modulesExternalLocation = [],

			//Implicit Events
			defaultEvent			= "",
			requestStartHandler		= "",
			requestEndHandler		= "",
			applicationStartHandler = "",
			applicationEndHandler	= "",
			sessionStartHandler 	= "",
			sessionEndHandler		= "",
			missingTemplateHandler	= "",

			//Error/Exception Handling
			exceptionHandler		= "",
			onInvalidEvent			= "",
			customErrorTemplate 	= "/coldbox/system/includes/BugReport.cfm",

			//Application Aspects
			handlerCaching 			= false,
			eventCaching			= false
        };

        moduleSettings = {
            "cbfs": {
                "disks": {
                    "local": {
                        "provider": "LocalProvider@cbfs",
                        "properties": {
                            "path": expandPath( "/root/tests/storage" )
                        }
                    },
					"s3": {
                        "provider": "S3Provider@cbfs",
                        "properties": {
                            "path": "/tests/storage"
                        }
                    }
                }
            },
			s3sdk = {
				// Your amazon, digital ocean access key
				accessKey = getSystemSetting( "aws_access_key_id", "" ),
				secretKey = getSystemSetting( "aws_secret_access_key", "" ),
				awsregion = "us-east-1",
				defaultBucketName = getSystemSetting( "aws_default_bucket", "cbfs-test" ),
				debug = true,
				signature = "V4"
			}
        };

		// environment settings, create a detectEnvironment() method to detect it yourself.
		// create a function with the name of the environment so it can be executed if that environment is detected
		// the value of the environment is a list of regex patterns to match the cgi.http_host.
		environments = {
			development = "localhost,127\.0\.0\.1"
		};

		// Module Directives
		modules = {
			// An array of modules names to load, empty means all of them
			include = [],
			// An array of modules names to NOT load, empty means none
			exclude = []
		};

		//Register interceptors as an array, we need order
		interceptors = [];

		//LogBox DSL
		logBox = {
			// Define Appenders
			appenders = {
				files={class="coldbox.system.logging.appenders.RollingFileAppender",
					properties = {
						filename = "tester", filePath="/#appMapping#/logs"
					}
				}
			},
			// Root Logger
			root = { levelmax="DEBUG", appenders="*" },
			// Implicit Level Categories
			info = [ "coldbox.system" ]
		};

	}

	/**
	 * Load the Module you are testing
	 */
	function afterAspectsLoad( event, interceptData, rc, prc ){
        controller.getModuleService()
            .registerAndActivateModule(
                moduleName 		= request.MODULE_NAME,
                invocationPath 	= "moduleroot"
			);
	}

}
