/* bender-tags: exportpdf,feature,31 */
/* bender-ckeditor-plugins: toolbar,wysiwygarea,divarea */
/* bender-include: _helpers/tools.js */
/* global exportPdfUtils */

( function() {
	'use strict';

	var inputHtml = '<p id="test">Hello, World!</p>',
		outputHtml = '<div class="cke_editable cke_contents_ltr"><p id="test">Hello, World!</p></div>';

	bender.loadExternalPlugin( 'exportpdf', '/apps/plugin/' );

	CKEDITOR.plugins.load( 'exportpdf', function() {
		bender.test( {
			setUp: function() {
				bender.tools.ignoreUnsupportedEnvironment( 'exportpdf' );
			},

			'test no custom stylesheets attached to divarea editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: outputHtml,
					expectCss: false
				} );
			},

			'test one absolute path custom stylesheet attached to divarea editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="https://ckeditor.com/">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ 'https://ckeditor.com' ]
					}
				} );
			},

			'test two absolute path custom stylesheets attached to divarea editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="https://ckeditor.css/">' +
						'<link type="text/css" rel=stylesheet href="https://cksource.css/">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ 'https://ckeditor.css', 'https://cksource.css' ]
					}
				} );
			},

			'test one relative path custom stylesheet attached to divarea editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/ckeditor.css' ) + '">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ '/css/ckeditor.css' ]
					}
				} );
			},

			'test two relative path custom stylesheets attached to divarea editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/ckeditor.css' ) + '">' +
						'<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/cksource.css' ) + '">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ '/css/ckeditor.css', '/css/cksource.css' ]
					}
				} );
			},

			'test one relative and one absolute path custom stylesheets attached to divarea editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/ckeditor.css' ) + '">' +
						'<link type="text/css" rel=stylesheet href="' + 'https://ckeditor.com/' + '">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ '/css/ckeditor.css', 'https://ckeditor.com' ]
					}
				} );
			},

			'test no custom stylesheets attached to inline editor': function() {
				testAttachingStylesheets( {
					creator: 'inline',
					initialHtml: inputHtml,
					expectedHtml: outputHtml,
					expectCss: false
				} );
			},

			'test one absolute path custom stylesheet attached to inline editor': function() {
				testAttachingStylesheets( {
					creator: 'inline',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="https://ckeditor.com/">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ 'https://ckeditor.com' ]
					}
				} );
			},

			'test two absolute path custom stylesheets attached to inline editor': function() {
				testAttachingStylesheets( {
					creator: 'inline',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="https://ckeditor.css/">' +
						'<link type="text/css" rel=stylesheet href="https://cksource.css/">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ 'https://ckeditor.css', 'https://cksource.css' ]
					}
				} );
			},

			'test one relative path custom stylesheet attached to inline editor': function() {
				testAttachingStylesheets( {
					creator: 'inline',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/ckeditor.css' ) + '">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ '/css/ckeditor.css' ]
					}
				} );
			},

			'test two relative path custom stylesheets attached to inline editor': function() {
				testAttachingStylesheets( {
					creator: 'inline',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/ckeditor.css' ) + '">' +
						'<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/cksource.css' ) + '">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ '/css/ckeditor.css', '/css/cksource.css' ]
					}
				} );
			},

			'test one relative and one absolute path custom stylesheets attached to inline editor': function() {
				testAttachingStylesheets( {
					creator: 'inline',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/ckeditor.css' ) + '">' +
						'<link type="text/css" rel=stylesheet href="' + 'https://ckeditor.com/' + '">' + outputHtml,
					expectCss: false,
					extraConfig: {
						exportPdf_stylesheets: [ '/css/ckeditor.css', 'https://ckeditor.com' ]
					}
				} );
			},

			'test no custom stylesheets attached to classic editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: outputHtml,
					expectCss: true,
					extraConfig: {
						removePlugins: 'divarea'
					}
				} );
			},

			'test one absolute path custom stylesheet attached to classic editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="https://ckeditor.com/">' + outputHtml,
					expectCss: false,
					extraConfig: {
						removePlugins: 'divarea',
						exportPdf_stylesheets: [ 'https://ckeditor.com' ]
					}
				} );
			},

			'test two absolute path custom stylesheets attached to classic editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="https://ckeditor.css/">' +
						'<link type="text/css" rel=stylesheet href="https://cksource.css/">' + outputHtml,
					expectCss: false,
					extraConfig: {
						removePlugins: 'divarea',
						exportPdf_stylesheets: [ 'https://ckeditor.css', 'https://cksource.css' ]
					}
				} );
			},

			'test one relative path custom stylesheet attached to classic editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/ckeditor.css' ) + '">' + outputHtml,
					expectCss: false,
					extraConfig: {
						removePlugins: 'divarea',
						exportPdf_stylesheets: [ '/css/ckeditor.css' ]
					}
				} );
			},

			'test two relative path custom stylesheets attached to classic editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/ckeditor.css' ) + '">' +
						'<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/cksource.css' ) + '">' + outputHtml,
					expectCss: false,
					extraConfig: {
						removePlugins: 'divarea',
						exportPdf_stylesheets: [ '/css/ckeditor.css', '/css/cksource.css' ]
					}
				} );
			},

			'test one relative and one absolute path custom stylesheets attached to classic editor': function() {
				testAttachingStylesheets( {
					creator: 'replace',
					initialHtml: inputHtml,
					expectedHtml: '<link type="text/css" rel=stylesheet href="' + exportPdfUtils.toAbsoluteUrl( '/css/ckeditor.css' ) + '">' +
						'<link type="text/css" rel=stylesheet href="' + 'https://ckeditor.com/' + '">' + outputHtml,
					expectCss: false,
					extraConfig: {
						removePlugins: 'divarea',
						exportPdf_stylesheets: [ '/css/ckeditor.css', 'https://ckeditor.com' ]
					}
				} );
			}
		} );

		function testAttachingStylesheets( options ) {
			var config = exportPdfUtils.getDefaultConfig( 'unit', options.extraConfig || {} );

			bender.editorBot.create( {
				name: 'editor' + Date.now(),
				config: config,
				creator: options.creator
			}, function( bot ) {
				var editor = bot.editor;

				bot.setHtmlWithSelection( options.initialHtml );

				editor.once( 'exportPdf', function( evt ) {
					assert.areEqual( options.initialHtml, evt.data.html );
				}, null, null, 10 );

				editor.once( 'exportPdf', function( evt ) {
					evt.cancel();
					if ( options.expectCss ) {
						assert.isNotUndefined( evt.data.css, 'Some CSS should be sent.' );
					} else {
						assert.isUndefined( evt.data.css, 'No CSS should be sent.' );
					}

					// (#103)
					var actualValue = evt.data.html.replace( /\?t=[a-z0-9]+/gi, '' );
					assert.areEqual( options.expectedHtml, actualValue, 'HTML is incorrect.' );
				}, null, null, 16 );

				editor.execCommand( 'exportPdf' );
			} );
		}
	} );
} )();
