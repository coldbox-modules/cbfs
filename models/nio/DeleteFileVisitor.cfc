/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This file visitor only recursively deletes files
 *
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component extends="FileVisitor" {

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
		if ( variables.jFiles.isRegularFile( arguments.file, [] ) ) {
			variables.jFiles.delete( arguments.file );
		}
		return variables.jFileVisitResult.CONTINUE;
	}

}
