/* bender-tags: exportpdf,feature,1 */
/* bender-ckeditor-plugins: toolbar,wysiwygarea */
/* bender-include: _helpers/tools.js */
/* global exportPdfUtils */

( function() {
	'use strict';

	bender.loadExternalPlugin( 'exportpdf', '/apps/plugin/' );

	CKEDITOR.plugins.load( 'exportpdf', function() {
		bender.test( {
			setUp: function() {
				bender.tools.ignoreUnsupportedEnvironment( 'exportpdf' );
			},

			'test data is correct at read and send stages': function() {
				bender.editorBot.create( {
					name: 'editor1',
					config: exportPdfUtils.getDefaultConfig( 'unit' )
				}, function( bot ) {
					var editor = bot.editor;
					bot.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

					editor.once( 'exportPdf', function( evt ) {
						assert.areEqual( evt.data.html, editor.getData(), 'Data from editor is incorrect.' );
						assert.isTrue( CKEDITOR.tools.isEmpty( evt.data.options), '`options` object should be initially empty.' );
					} );

					editor.once( 'exportPdf', function( evt ) {
						evt.cancel();
						assert.areEqual( '<div class="cke_editable cke_contents_ltr">' + editor.getData() + '</div>',
							evt.data.html, 'Preprocessed data sent to endpoint is incorrect.' );
						assert.isNotNull( evt.data.css, 'CSS should be attached.' );
					}, null, null, 16 );

					editor.execCommand( 'exportPdf' );
				} );
			},

			'test options provided via config': function() {
				bender.editorBot.create( {
					name: 'editor2',
					config: exportPdfUtils.getDefaultConfig( 'unit', {
						exportPdf_options: {
							format: 'A6'
						}
					} )
				}, function( bot ) {
					var editor = bot.editor;
					bot.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

					editor.once( 'exportPdf', function( evt ) {
						evt.cancel();
						assert.areEqual( evt.data.options.format, 'A6' );
					} );

					editor.execCommand( 'exportPdf' );
				} );
			},

			'test html changed via event': function() {
				bender.editorBot.create( {
					name: 'editor3',
					config: exportPdfUtils.getDefaultConfig( 'unit' )
				}, function( bot ) {
					var editor = bot.editor;
					bot.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

					editor.once( 'exportPdf', function( evt ) {
						evt.cancel();
						assert.areEqual( evt.data.html, '' );
					} );

					editor.once( 'exportPdf', function( evt ) {
						assert.areNotEqual( evt.data.html, '' );
						evt.data.html = '';
					}, null, null, 1 );

					editor.execCommand( 'exportPdf' );
				} );
			},

			'test options changed via event': function() {
				bender.editorBot.create( {
					name: 'editor4',
					config: exportPdfUtils.getDefaultConfig( 'unit' )
				}, function( bot ) {
					var editor = bot.editor;
					bot.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

					editor.once( 'exportPdf', function( evt ) {
						evt.cancel();
						assert.areEqual( evt.data.options.format, 'A5' );
					} );

					editor.once( 'exportPdf', function( evt ) {
						evt.data.options.format = 'A5';
					}, null, null, 1 );

					editor.execCommand( 'exportPdf' );
				} );
			},

			'test html changed via event asynchronously': function() {
				bender.editorBot.create( {
					name: 'editor5',
					config: exportPdfUtils.getDefaultConfig( 'unit' )
				}, function( bot ) {
					var editor = bot.editor;

					bot.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

					editor.on( 'exportPdf', function( evt ) {
						evt.cancel();
						if ( evt.data.asyncDone ) {
							resume();
							assert.areEqual( evt.data.html, '<p>Content filtered!</p>' );
							delete evt.data.asyncDone;
							assert.isUndefined( evt.data.asyncDone );
						}
					} );

					editor.on( 'exportPdf', function( evt ) {
						if ( !evt.data.asyncDone ) {
							setTimeout( function() {
								evt.data.html = '<p>Content filtered!</p>';
								evt.data.asyncDone = true;
								editor.fire( 'exportPdf', evt.data );
							}, 1000 );
						}
					}, null, null, 1 );

					editor.execCommand( 'exportPdf' );
					wait();
				} );
			},

			'test options changed via event asynchronously': function() {
				bender.editorBot.create( {
					name: 'editor6',
					config: exportPdfUtils.getDefaultConfig( 'unit', {
						exportPdf_options: {
							format: 'A5'
						}
					} )
				}, function( bot ) {
					var editor = bot.editor;

					bot.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

					editor.on( 'exportPdf', function( evt ) {
						evt.cancel();
						if ( evt.data.asyncDone ) {
							resume();
							assert.areEqual( evt.data.options.format, 'A4' );
							delete evt.data.asyncDone;
							assert.isUndefined( evt.data.asyncDone );
						}
					} );

					editor.on( 'exportPdf', function( evt ) {
						if ( !evt.data.asyncDone ) {
							setTimeout( function() {
								evt.data.options.format = 'A4';
								evt.data.asyncDone = true;
								editor.fire( 'exportPdf', evt.data );
							}, 1000 );
						}
					}, null, null, 1 );

					editor.execCommand( 'exportPdf' );
					wait();
				} );
			},

			'test default CKEditor config': function() {
				bender.editorBot.create( {
					name: 'editor7',
					config: exportPdfUtils.getDefaultConfig( 'unit' )
				}, function( bot ) {
					if ( CKEDITOR.config.exportPdf_isDev ) {
						assert.areEqual( bot.editor.config.exportPdf_service, 'https://pdf-converter.cke-cs-staging.com/v1/convert',
							'Default dev endpoint is incorrect.' );
					} else {
						assert.areEqual( bot.editor.config.exportPdf_service, 'https://pdf-converter.cke-cs.com/v1/convert',
							'Default prod endpoint is incorrect.' );
					}

					assert.areEqual( bot.editor.config.exportPdf_fileName, 'ckeditor4-export-pdf.pdf',
						'Default file name is incorrect.' );
				} );
			},

			// (#62)
			'test inaccessible stylesheets are handled correctly': function() {
				bender.editorBot.create( {
					name: 'editor8',
					config: exportPdfUtils.getDefaultConfig( 'unit', {
						contentsCss: 'https://cdn.ckeditor.com/4.16.0/full-all/samples/css/samples.css'
					} )
				}, function( bot ) {
					var editor = bot.editor,
						warnThrown = false,
						listener = CKEDITOR.on( 'log', function( evt ) {
							if ( evt.data.errorCode === 'exportpdf-stylesheets-inaccessible' ) {
								evt.cancel();
								CKEDITOR.removeListener( 'log', listener );

								warnThrown = true;
							}
						} );

					bot.setHtmlWithSelection( '<p id="test">Hello, World!</p>^' );

					editor.once( 'exportPdf', function( evt ) {
						evt.cancel();

						resume( function () {
							warnThrown ? assert.pass() : assert.fail( 'No errors thrown while accessing stylesheets rules.' );
						} );
					}, null, null, 19 );

					// (#98)
					CKEDITOR.tools.setTimeout( function () {
						editor.execCommand( 'exportPdf' );
					}, 1000 );

					wait();
				} );
			}
		} );
	} );
} )();
