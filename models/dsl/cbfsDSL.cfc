component {

    public any function init( required any injector ) {
        variables.injector = arguments.injector;
        return this;
    }

    public any function process( required definition, targetObject ) {
        var dslSegments = listToArray( arguments.definition.dsl, ":" );
        switch ( arrayLen( dslSegments ) ) {
            case 1:
                return variables.injector.getInstance( dsl = "DiskService@cbfs" );
            case 2:
                return variables.injector.getInstance( dsl = "coldbox:setting:disks@cbfs" );
            case 3:
                var disks = variables.injector.getInstance( dsl = "coldbox:setting:disks@cbfs" );
                var diskName = dslSegments[ 3 ];
                var diskSettings = disks[ diskName ];
                if ( ! diskSettings.keyExists( "provider" ) ) {
                    throw(
                        type = "cbfs.NoProviderException",
                        message = "No provider set for disk [#diskName#]."
                    );
                }
                param diskSettings.properties = {};
                var provider = variables.injector.getInstance( diskSettings.provider );
                provider.configure( diskName, diskSettings.properties );
                return provider;
            default:
                throw(
                    type = "cbfs.IncorrectDslException",
                    message = "No dsl available for [#arguments.definition.dsl#]."
                );
        }
    }

}
