component extends="tests.resources.AbstractDiskSpec" {

	variables.providerName = "S3";

	/*
	Number of miliseconds to delay between each test. This is done on the
	the S3Provider to avoid rate limiting errors.
	*/
	this.delaySpecs = "0";

}
