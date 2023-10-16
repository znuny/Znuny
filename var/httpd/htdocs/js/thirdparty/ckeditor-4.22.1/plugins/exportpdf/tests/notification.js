/* bender-tags: exportpdf,feature,4 */
/* bender-ckeditor-plugins: toolbar,wysiwygarea,notification */
/* bender-include: _helpers/tools.js */
/* global exportPdfUtils */

( function() {
	'use strict';

	bender.loadExternalPlugin( 'exportpdf', '/apps/plugin/' );

	CKEDITOR.plugins.load( 'exportpdf', function() {
		var processingDocumentMsg = 'Processing PDF document...';

		bender.editors = {
			successEditor: {
				config: exportPdfUtils.getDefaultConfig( 'unit' )
			},
			errorEditor: {
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

			'test notifications and progress steps are correct in happy path': function() {
				var editor = this.editors.successEditor;

				this.editorBots.successEditor.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

				editor.once( 'exportPdf', function() {
					assertNotifications( editor, { message: processingDocumentMsg, type: 'progress', progress: 0 } );
				} );

				editor.once( 'exportPdf', function() {
					assertNotifications( editor, { message: processingDocumentMsg, type: 'progress', progress: 0.2 } );
				}, null, null, 16 );

				exportPdfUtils.useXHR( editor, function( xhr ) {
					xhr.addEventListener( 'progress', function() {
						assertNotifications( editor, { message: processingDocumentMsg, type: 'progress', progress: 0.8 } );
					} );

					xhr.addEventListener( 'loadend', function() {
						assertNotifications( editor, { message: 'Document is ready!', type: 'success', progress: 1 } );
					} );

					xhr.respond( 200, {}, '' );
				} );
			},

			'test notifications and progress steps are correct in sad path': function() {
				var editor = this.editors.errorEditor;

				this.editorBots.errorEditor.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

				exportPdfUtils.useXHR( editor, function( xhr ) {
					var stubbed = sinon.stub( console, "error", function( arg ) {
						assert.areSame( 'Validation failed.', arg.message, 'Message from endpoint is incorrect.' );
						stubbed.restore();
					} );

					xhr.addEventListener( 'loadend', function() {
						assertNotifications( editor, { message: 'Error occurred.', type: 'warning' } );
					} );

					xhr.respond( 400, {}, '{ "message": "Validation failed." }' );
				} );
			}
		} );

		function assertNotifications( editor, expectedNotification ) {
			var actualNotification = editor._.notificationArea.notifications[ 0 ];

			assert.areSame( expectedNotification.message, actualNotification.message, 'Message should be the same.' );
			assert.areSame( expectedNotification.type, actualNotification.type, 'Type should be the same.' );
			assert.areSame( expectedNotification.progress, actualNotification.progress, 'Progress should be the same.' );
		}
	} );
} )();
