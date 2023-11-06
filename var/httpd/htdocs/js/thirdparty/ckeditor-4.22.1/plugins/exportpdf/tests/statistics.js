/* bender-tags: exportpdf,feature,50 */
/* bender-ckeditor-plugins: toolbar,wysiwygarea */
/* bender-include: _helpers/tools.js */
/* global exportPdfUtils */

( function() {
	'use strict';

	bender.loadExternalPlugin( 'exportpdf', '/apps/plugin/' );

	CKEDITOR.plugins.load( 'exportpdf', function() {
		bender.editors = {
			defaultHeader: {
				config: {
					extraPlugins: 'exportpdf'
				}
			},
			customHeader: {
				config: exportPdfUtils.getDefaultConfig( 'unit' )
			}
		};

		bender.test( {
			setUp: function() {
				bender.tools.ignoreUnsupportedEnvironment( 'exportpdf' );

				// We don't want to download anything on success.
				sinon.stub( CKEDITOR.plugins.exportpdf, 'downloadFile' );
			},

			tearDown: function() {
				CKEDITOR.plugins.exportpdf.downloadFile.restore();
			},

			'test default statistics header': function() {
				var editor = this.editors.defaultHeader;

				this.editorBots.defaultHeader.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

				exportPdfUtils.useXHR( editor, function( xhr ) {
					assert.areEqual( xhr.requestHeaders[ 'x-cs-app-id' ], 'cke4', 'Default stats header is wrong.' );
				} );
			},

			'test custom statistics header': function() {
				var editor = this.editors.customHeader;

				this.editorBots.customHeader.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

				exportPdfUtils.useXHR( editor, function( xhr ) {
					assert.areEqual( xhr.requestHeaders[ 'x-cs-app-id' ], 'cke4-tests-unit', 'Custom stats header was not set properly.' );
				} );
			}
		} );
	} );
} )();
