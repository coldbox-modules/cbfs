/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This file visitor deletes recursively all files and directories it walks
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component extends="FileVisitor" accessors="true" {

	/**
	 * If passed, this contains the root directory that needs to be excluded from deletion
	 */
	property name="excludeRoot";

	/**
	 * Constructor
	 */
	function init(){
		variables.excludeRoot = "";
		return this;
	}

	/**
	 * Invoked for a directory after entries in the directory, and all of their descendants, have been visited.
	 *
	 * @dir       A reference to the directory
	 * @exception null if the iteration of the directory completes without an error; otherwise the I/O exception that caused the iteration of the directory to complete prematurely
	 *
	 * @return FileVisitResult - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/nio/file/FileVisitResult.html
	 *
	 * @throws IOException - if an I/O error occurs
	 */
	function postVisitDirectory( dir, exception ){
		// If we have an exclude root, check it and exclude it.
		if (
			!len( variables.excludeRoot ) ||
			arguments.dir.toString().reReplace( "[\\/]", "", "all" ) != variables.excludeRoot.reReplace(
				"[\\/]",
				"",
				"all"
			)
		) {
			variables.jFiles.delete( arguments.dir );
		}
		return variables.jFileVisitResult.CONTINUE;
	}

	/**
	 * Invoked for a file in a directory.
	 *
	 * @file  A reference to the file
	 * @attrs The file's basic attributes
	 *
	 * @return FileVisitResult - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/nio/file/FileVisitResult.html
	 *
	 * @throws IOException - if an I/O error occurs
	 */
	function visitFile( file, attrs ){
		variables.jFiles.delete( arguments.file );
		return variables.jFileVisitResult.CONTINUE;
	}

}
