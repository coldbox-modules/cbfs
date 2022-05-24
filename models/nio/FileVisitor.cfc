/**
 * Copyright Since 2005 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This is a CFML implementation of a Java nio FileVisitor class
 *
 * @see    https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/nio/file/FileVisitor.html
 * @see    https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/nio/file/FileVisitResult.html
 * @author Luis Majano <lmajano@ortussolutions.com>, Grant Copley <gcopley@ortussolutions.com>
 */
component accessors="true" {

	/**
	 * The result ENUM
	 * - CONTINUE
	 * - SKIP_SIBLINGS : Continue without visiting the siblings of this file or directory.
	 * - SKIP_SUBTREE : Continue without visiting the entries in this directory.
	 * - TERMINATE
	 */
	variables.jFileVisitResult = createObject( "java", "java.nio.file.FileVisitResult" );
	variables.jFiles           = createObject( "java", "java.nio.file.Files" );

	/**
	 * Constructor
	 */
	function init(){
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
		return variables.jFileVisitResult.CONTINUE;
	}

	/**
	 * Invoked for a directory before entries in the directory are visited.
	 *  If this method returns CONTINUE, then entries in the directory are visited. If this method returns SKIP_SUBTREE or SKIP_SIBLINGS then entries in the directory (and any descendants) will not be visited.
	 *
	 * @dir   A reference to teh directory
	 * @attrs The directory's basic attributes
	 *
	 * @return FileVisitResult - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/nio/file/FileVisitResult.html
	 *
	 * @throws IOException - if an I/O error occurs
	 */
	function preVisitDirectory( dir, attrs ){
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
		return variables.jFileVisitResult.CONTINUE;
	}

	/**
	 * Invoked for a file that could not be visited. This method is invoked if the file's attributes could not be read, the file is a directory that could not be opened, and other reasons.
	 *
	 * @file      A reference to the file
	 * @exception the I/O exception that prevented the file from being visited
	 *
	 * @return FileVisitResult - https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/nio/file/FileVisitResult.html
	 *
	 * @throws IOException - if an I/O error occurs
	 */
	function visitFileFailed( file, exception ){
		return variables.jFileVisitResult.CONTINUE;
	}

}
