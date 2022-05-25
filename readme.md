# CB FS (File Storage :disk:)

[![cbfs CI](https://github.com/coldbox-modules/cbfs/actions/workflows/ci.yml/badge.svg)](https://github.com/coldbox-modules/cbfs/actions/workflows/ci.yml)

<img src="https://forgebox.io/api/v1/entry/cbfs/badges/version" />

The `cbfs` module will enable you to abstract ANY filesystem within your ColdBox applications. You can configure as many disks as you wish which represent file systems in your application. Each disk is backed by a storage provider and configurable within your ColdBox application.

## License

Apache License, Version 2.0.

## System Requirements

-   Lucee 5+
-   Adobe ColdFusion 2016+

## Installation

Use CommandBox CLI to install:

```bash
box install cbfs
```

## Storage Providers

The available storage providers are:

-   `LocalProvider@cbfs` - A local file system storage provider.
-   `MockProvider@cbfs` - A mock storage provider that just logs operations to a LogBox logger object.
-   `S3Provider@cbfs` - An Amazon S3, Rackspace, Digital Ocean or Google Cloud Storage provider.

## Configuration

In your `config/ColdBox.cfc` create a `cbfs` structure within the `moduleSettings` key. Here you will define your storage disks and global settings for the `cbfs` storage services.

> **Note**: Each provider has its own configuration properties. Please review this README for additional information on each provider.

```js
moduleSettings = {
	cbfs: {
		disks: {
			default: {
				provider: "LocalProvider@cbfs",
			},
		},
	},
};
```

## Default Disk

You can specify a default disk for your application with the `defaultDisk` key in your `config/ColdBox.cfc`.

```js
moduleSettings = {
	cbfs: {
		defaultDisk: "default",
		disks: {
			default: {
				provider: "LocalProvider@cbfs",
			},
		},
	},
};
```

## Module Disks

If you want custom modules to register cbfs disks, they can! Just add a `cbfs` key into your module's `ModuleConfig.cfc` `settings` struct. You will have the option to register disks that are namespaced to the module and global disks that are NOT namespaced.

```js
settings = {
	cbfs: {
		// Disks that will be namespaced with the module name @{moduleName}
		disks: {
			temp: { provider: "Mock" },
			nasa: { provider: "mock" },
		},
		// No namespace in global spacing
		globalDisks: {
			// Should be ignored, you can't override global disks
			temp: { provider: "Mock" },
			nasa: { provider: "mock" },
		},
	},
};
```

## Disk Service

cbfs includes a Disk Service object you can use to interact with your disks.

```bash
var diskService = getInstance( "DiskService@cbfs" );
```

The full API for the Disk Service can be found in the [API Docs](https://apidocs.ortussolutions.com/#/coldbox-modules/cbfs/).

Core service methods:

```
get( providerName ) - Returns a disk instance.
register( name, provider, properties, override) - Register a new disk.
unregister( name ) - Unregister a disk.
shutdown() - Unregister and shutdown all disks.
names() - List of all disk names.
count() - Number of disks.
defaultDisk() - Gets default disk instance.
tempDisk() - Get temp disk instance.

```

---

Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com

---

## HONOR GOES TO GOD ABOVE ALL

Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

> "Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
> By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
> And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
> And patience, experience; and experience, hope:
> And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the
> Holy Ghost which is given unto us. ." Romans 5:5

### THE DAILY BREAD

> "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12
