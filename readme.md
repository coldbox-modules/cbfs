# CB FS (File Storage :disk:)

The `cbfs` module will enable you to abstract ANY filesystem within your ColdBox applications.  You can configure as many disks which represent file systems in your application.  Each disk is backed by a storage provider and configure within your ColdBox application.

## Storage Providers

The available storage providers are:

* `FileProvider` - A local file system storage provider
* `MockProvider` - A mock storage provider that just logs operations to a LogBox logger object
* `S3Provider` - An Amazon S3, Rackspace, Digital Ocean or Google Cloud Storage provider.

## Configuration

In your `config/ColdBox.cfc` create a `cbfs` structure within the `moduleSettings` key.  Here you will define your storage disks and global settings for the `cbfs` storage services.

> **Note**: Please note that each provider has its own configuration properties. So please check out the docs for each provider.

```js
moduleSettings = {
	cbfs = {
		disks = {
			"public" = {
				provider = "FileProvider",
				properties = {
					root = "File root",
					baseUrl = "The base Url for the storage",
					visibility = "public or private"
				}
			}

		}
	}
}
```

********************************************************************************
Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************
#### HONOR GOES TO GOD ABOVE ALL
Because of His grace, this project exists. If you don't like this, then don't read it, its not for you.

>"Therefore being justified by faith, we have peace with God through our Lord Jesus Christ:
By whom also we have access by faith into this grace wherein we stand, and rejoice in hope of the glory of God.
And not only so, but we glory in tribulations also: knowing that tribulation worketh patience;
And patience, experience; and experience, hope:
And hope maketh not ashamed; because the love of God is shed abroad in our hearts by the 
Holy Ghost which is given unto us. ." Romans 5:5

### THE DAILY BREAD
 > "I am the way, and the truth, and the life; no one comes to the Father, but by me (JESUS)" Jn 14:1-12
