/* bender-tags: exportpdf,feature,77 */
/* bender-ckeditor-plugins: toolbar,wysiwygarea */
/* bender-include: _helpers/tools.js */
/* global exportPdfUtils */

( function() {
	'use strict';

	bender.loadExternalPlugin( 'exportpdf', '/apps/plugin/' );

	CKEDITOR.plugins.load( 'exportpdf', function() {
		var tokenValue = 'sample-token-value',
			xhrServer = createFakeTokenServer(),
			fileDownloadStub;

		bender.test( {
			setUp: function() {
				bender.tools.ignoreUnsupportedEnvironment( 'exportpdf' );
				fileDownloadStub = sinon.stub( CKEDITOR.plugins.exportpdf, 'downloadFile' );
			},

			tearDown: function() {
				fileDownloadStub.restore();
			},

			'test token is fetched if tokenUrl is correct': function() {
				createEditor( { exportPdf_tokenUrl: '/custom-url' }, function( editor ) {
					editor.on( 'exportPdf', function( evt ) {
						assert.areEqual( evt.data.token, tokenValue, 'Token value is incorrect.' );
					}, null, null, 17 );

					xhrServer.respond();
					editor.execCommand( 'exportPdf' );
					xhrServer.respond();
				} );
			},

			'test authentication header is added if token is provided': function() {
				createEditor( { exportPdf_tokenUrl: '/custom-url' }, function( editor ) {
					xhrServer.respond();
					editor.execCommand( 'exportPdf' );
					xhrServer.respond();

					assert.areEqual( tokenValue, xhrServer.requests[ xhrServer.requests.length - 1 ].requestHeaders[ 'Authorization' ], 'Authorization token was not set properly.' );
				} );
			},

			'test console.warn is called if tokenUrl is not provided': function() {
				CKEDITOR.once( 'log', function( evt ) {
					evt.cancel();

					assert.areEqual( 'exportpdf-no-token-url', evt.data.errorCode, 'There should be URL error log.' );
				} );

				createEditor( { exportPdf_tokenUrl: '' } );
			},

			'test console.warn is called on POST request if token is empty': function() {
				var listener = CKEDITOR.on( 'log', function( evt ) {
					if ( evt.data.errorCode !== 'exportpdf-no-token' ) {
						return;
					}

					evt.cancel();
					CKEDITOR.removeListener( 'log', listener );

					assert.areEqual( 'exportpdf-no-token', evt.data.errorCode, '`exportpdf-no-token` should occur.' );
				} );

				createEditor( { exportPdf_tokenUrl: '/empty-token' }, function( editor ) {
					xhrServer.respond();
					editor.execCommand( 'exportPdf' );
					xhrServer.respond();
				} );
			},

			'test console.warn is called on POST request if token was not fetched at all': function() {
				var listener = CKEDITOR.on( 'log', function( evt ) {
					if ( evt.data.errorCode !== 'exportpdf-no-token' ) {
						return;
					}

					evt.cancel();
					CKEDITOR.removeListener( 'log', listener );

					assert.areEqual( 'exportpdf-no-token', evt.data.errorCode, '`exportpdf-no-token` should occur.' );
				} );

				createEditor( { exportPdf_tokenUrl: '/custom-url' }, function( editor ) {
					editor.execCommand( 'exportPdf' );
					xhrServer.respond();
				} );
			},

			'test token refreshes in the declared intervals': function() {
				CKEDITOR.once( 'instanceCreated', function( evt ) {
					evt.editor.exportPdfTokenInterval = 200;
				} );

				createEditor( { exportPdf_tokenUrl: '/incremental_token' }, function( editor ) {
					xhrServer.respond();
					setTimeout( function() {
						resume( function() {
							xhrServer.respond();

							editor.on( 'exportPdf', function( evt ) {
								assert.areNotSame( evt.data.token, tokenValue + '0', 'Token was not refreshed.' );
							}, null, null, 17 );

							editor.execCommand( 'exportPdf' );
							xhrServer.respond();
						} );
					}, 500 );
					wait();
				} );
			},

			'test file is downloaded also without token': function() {
				createEditor( { exportPdf_tokenUrl: '/empty-token' }, function( editor ) {
					xhrServer.respond();
					editor.execCommand( 'exportPdf' );
					xhrServer.respond();

					sinon.assert.calledOnce( fileDownloadStub );
					assert.pass();
				} );
			}
		} );

		function createEditor( extraConfig, callback ) {
			var config = exportPdfUtils.getDefaultConfig( 'unit', extraConfig || {} );

			bender.editorBot.create( {
					name: 'editor' + Date.now(),
					config: config,
					startupData: '<p>Hello World!</p>'
				}, function( bot ) {
					if ( callback ) {
						callback( bot.editor );
					}
				}
			);
		}

		function createFakeTokenServer() {
			var xhrServer = sinon.fakeServer.create(),
				incrementalTokenCount = 0;

			xhrServer.respondWith( function( req ) {
				if ( req.url === '/incremental_token' ) {
					req.respond( 200, {}, tokenValue + incrementalTokenCount );
					incrementalTokenCount += 1;
				} else if ( req.url === '/empty-token' ) {
					req.respond( 200, {}, '' );
				} else {
					req.respond( 200, {}, tokenValue );
				}
			} );

			return xhrServer;
		}
	} );
} )();
