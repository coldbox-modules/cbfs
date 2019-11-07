component accessors="true" {

    property name="name" type="string";
    property name="properties" type="struct";

    /**
	 * Configure the provider. Usually called at startup.
	 *
	 * @properties A struct of configuration data for this provider, usually coming from the configuration file
	 *
	 * @return IDiskProvider
	 */
    function configure( required string name, struct properties = {} ) {
        setName( arguments.name );
        setProperties( arguments.properties );
        return this;
    }

    /**
	 * Create a file in the disk
	 *
	 * @path The file path to use for storage
	 * @contents The contents of the file to store
	 * @visibility The storage visibility of the file, available options are `public, private, readonly` or a custom data type the implemented driver can interpret
	 * @metadata Struct of metadata to store with the file
	 * @overwrite If we should overwrite the files or not at the destination if they exist, defaults to true
	 *
	 * @return IDiskProvider
	 */
	function create(
		required path,
		required contents,
		visibility,
		struct metadata,
		boolean overwrite
	) {
        fileWrite( buildPath( arguments.path ), arguments.contents );
        return this;
    }

    /**
	 * Validate if a file/directory exists
	 *
	 * @path The file/directory path to verify
	 */
    boolean function exists( required string path ) {
        return fileExists( buildPath( arguments.path ) );
    }

    /**
	 * Delete a file or an array of file paths. If a file does not exist a `false` will be
	 * shown for it's return.
	 *
	 * @path A single file path or an array of file paths
     * @throwOnMissing Boolean to throw an exception if the file is missing.
	 *
	 * @return boolean or struct report of deletion
	 */
	function delete( required string path, boolean throwOnMissing = false ) {
        if ( ! throwOnMissing ) {
            if ( ! this.exists( arguments.path ) ) {
                return this;
            }
        }
        fileDelete( buildPath( arguments.path ) );
        return this;
    }

    private function buildPath( required string path ) {
        return expandPath( getProperties().path & "/" & arguments.path );
    }

}
