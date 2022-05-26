# CB FS (File Storage :disk:)

[![cbfs CI](https://github.com/coldbox-modules/cbfs/actions/workflows/ci.yml/badge.svg)](https://github.com/coldbox-modules/cbfs/actions/workflows/ci.yml)

<img src="https://forgebox.io/api/v1/entry/cbfs/badges/version" />

The `cbfs` module will enable you to abstract **ANY** filesystem within your ColdBox applications. You can configure as many disks as you wish which represent file systems in your application. Each disk is backed by a storage provider and configurable within your ColdBox application.

## License

Apache License, Version 2.0.

## System Requirements

- Lucee 5+
- Adobe ColdFusion 2016 (Deprecated)
- Adobe ColdFusion 2018+

## Installation

Use CommandBox CLI to install:

```bash
box install cbfs
```

## Storage Providers

The available storage providers are:

- `Local` - A local file system storage provider.
- `Ram` - An in-memory file storage provider.
- `S3` - An Amazon S3, Rackspace, Digital Ocean or Google Cloud Storage provider. (Beta)
- `CacheBox` - Leverages ANY caching engine as a virtual file system.  If you use a distributed cache like Couchbase, Redis, or Mongo, then you will have a distributed file system. (Coming...)

## Configuration

In your `config/ColdBox.cfc` create a `cbfs` structure within the `moduleSettings` key. Here you will define your storage disks and global settings for the `cbfs` storage services.

> **Note**: Each provider has its own configuration properties. Please review this README for additional information on each provider.

```js
moduleSettings = {
	cbfs: {
		// The default disk with a reserved name of 'default'
		"defaultDisk" : "default",
		// Register the disks on the system
		"disks"       : {
			// Your default application storage
			"default" : {
				provider   : "Local",
				properties : { path : "#controller.getAppRootPath()#.cbfs" }
			},
			// A disk that points to the CFML Engine's temp directory
			"temp" : {
				provider   : "Local",
				properties : { path : getTempDirectory() }
			}
		}
	},
};
```

### Default Disk

You can use the `defaultDisk` setting to point it to a registered disk by name.  Every time you use the default operations, it will be based upon this setting.

### Disks

You can register as many disks as you want in the parent application using this structure.  The `key` will be the name of the disk and the value is a struct of:

- `provider` : The short name of the provider or a WireBox ID or a full CFC path.
- `properties` : A struct of properties that configures each provider.

By default, we register two disks in your ColdBox application.

| Disk         | Provider     | Description |
|--------------|--------------|-------------|
| `default` | `Local`      | By convention it creates a `.cbfs` folder in the root of your application where all files will be stored. |
| `temp`      | `Local`  | Access to the Java temporary folder structure you can use for any type of generation that is not web-accessible and temporary |

----

## Providers

The available providers are listed below with their appropriate properties to configure them.

### Local

The `local` provider has a shortcut of `Local` or it can be fully referenced via it's WireBox ID `LocalProvider@cbfs`.  The available properties are:

| Property         | Type     | Default | Description |
|------------------|----------|---------|-------------|
| `path` 		   | string   | ---     | The relative or absolute path of where to store the file system. |
| `autoExpand`     | boolean  | false   | If true, it will use an `expandPath()` on the `path` property. Else it leaves it as is. |


### Ram

The `ram` provider has a shortcut of `Ram` or it can be fully referenced via it's WireBox ID `RamProvider@cbfs`. It also does not have any configuration properties.


----

## Disk Service

cbfs includes a Disk Service object you can use to register and interact with your disks.

```js
// Via getInstance()
var diskService = getInstance( "DiskService@cbfs" );
// Via cfproperty
property name="diskService" inject="DiskService@cbfs";
```

The full API for the Disk Service can be found in the [API Docs](https://apidocs.ortussolutions.com/#/coldbox-modules/cbfs/).

### Core methods

#### `get( name )`

Returns requested disk instance. Throws 'InvalidDiskException' if disk not registered.

#### `has( name )`

Returns true if disk has been registered with provided name.

#### `register( name, provider, properties, override )`

Registers a new disk. If a disk has already been configured with the same name, then it will not be updated unless you specify override=true.

#### `unregister( name )`

Unregisters a disk. Throws 'InvalidDiskException' if disk not registered.

#### `shutdown()`

Unregisters and shuts down all disks managed by the DiskService.

#### `getDiskRecord( name )`

Returns struct of details for a disk.

#### `names()`

Returns an array of registered disk names.

#### `count()`

Returns the count of registered disks.

#### `defaultDisk()`

Returns the default disk.

#### `tempDisk()`

Returns the temporary disk.

## Injection DSL

The `cbfs` module also registers a WireBox injection DSL that you can use to inject objects from the module:

| DSL         			| Description |
|-----------------------|-------------|
| `cbfs` 		   		| Injects the `DiskService@cbfs` |
| `cbfs:disks`     		| Injects the entire disks record structure |
| `cbfs:disks:{name}`	| Injects the specific disk by `{name}`. Ex: `cbfs:disks:temp` |


## Module Disks

If you want custom modules to register cbfs disks, they can! Just add a `cbfs` key into your module's `ModuleConfig.cfc` `settings` struct. You will have the option to register disks that are namespaced to the module and global disks that are NOT namespaced.

```js
settings = {
	cbfs: {
		// Disks that will be namespaced with the module name @{moduleName}
		disks: {
			temp: { provider: "Ram" },
			nasa: { provider: "Ram" },
		},
		// No namespace in global spacing
		globalDisks: {
			// Should be ignored, you can't override global disks
			temp: { provider: "Ram" },
			nasa: { provider: "Ram" },
		},
	},
};
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
