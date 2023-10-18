/* bender-tags: exportpdf,feature,6 */
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

				this.paths = {
					relative0: getPath( bender.testDir ),
					relative1: getPath( bender.testDir, 1 ),
					relative3: getPath( bender.testDir, 3 )
				};
			},

			'test absolute image urls are not changed': function() {
				testContentTransformation(
					'<p>Foo <img src="https://ckeditor.com/img/image1.jpg" /><img src="https://ckeditor.com/img/image2.png" /></p>',
					'<p>Foo <img src="https://ckeditor.com/img/image1.jpg" /><img src="https://ckeditor.com/img/image2.png" /></p>'
				);
			},

			'test relative (to root) image urls are changed to absolute': function() {
				testContentTransformation(
					'<p><img src="/img/image1.jpg" /> Bar <img src="/img/big/image2.png" /></p>',
					'<p><img src="' + exportPdfUtils.toAbsoluteUrl( '/img/image1.jpg' ) + '" /> Bar <img src="' + exportPdfUtils.toAbsoluteUrl( '/img/big/image2.png' ) + '" /></p>'
				);
			},

			'test relative (to root) image urls with ".." are changed to absolute': function() {
				testContentTransformation(
					'<p><img src="/../img/image1.jpg" /> Bar <img src="/../../img/big/image2.png" /></p>',
					'<p><img src="' + exportPdfUtils.toAbsoluteUrl( '/img/image1.jpg' ) + '" /> Bar <img src="' + exportPdfUtils.toAbsoluteUrl( '/img/big/image2.png' ) + '" /></p>'
				);
			},

			'test relative (to root) image urls with custom baseHref are changed to absolute': function() {
				testContentTransformation(
					'<p><img src="/img/image1.jpg" /> Bar <img src="/img/big/image2.png" /></p>',
					'<p><img src="' + exportPdfUtils.toAbsoluteUrl( '/img/image1.jpg', 'http://ckeditor.com' ) + '" /> Bar <img src="' + exportPdfUtils.toAbsoluteUrl( '/img/big/image2.png', 'http://ckeditor.com' ) + '" /></p>',
					{
						baseHref: 'http://ckeditor.com/ckeditor4/'
					}
				);
			},

			'test relative (to root) image urls with custom baseHref and ".." are changed to absolute': function() {
				testContentTransformation(
					'<p><img src="/../img/image1.jpg" /> Bar <img src="/../../img/big/image2.png" /></p>',
					'<p><img src="' + exportPdfUtils.toAbsoluteUrl( '/img/image1.jpg', 'http://ckeditor.com' ) + '" /> Bar <img src="' + exportPdfUtils.toAbsoluteUrl( '/img/big/image2.png', 'http://ckeditor.com' ) + '" /></p>',
					{
						baseHref: 'http://ckeditor.com/ckeditor4/'
					}
				);
			},

			'test relative (to current url) image urls are changed to absolute': function() {
				testContentTransformation(
					'<p><img src="img/image1.jpg" /> Bar <img src="img/big/image2.png" /></p>',
					'<p><img src="' + exportPdfUtils.toAbsoluteUrl( this.paths.relative0 + '/img/image1.jpg' ) + '" /> Bar <img src="' + exportPdfUtils.toAbsoluteUrl( this.paths.relative0 + '/img/big/image2.png' ) + '" /></p>'
				);
			},

			'test relative (to current url) image urls with ".." are changed to absolute': function() {
				testContentTransformation(
					'<p><img src="../img/image1.jpg" /> Bar <img src="../../../img/big/image2.png" /></p>',
					'<p><img src="' + exportPdfUtils.toAbsoluteUrl( this.paths.relative1 + '/img/image1.jpg' ) + '" /> Bar <img src="' + exportPdfUtils.toAbsoluteUrl( this.paths.relative3 + '/img/big/image2.png' ) + '" /></p>'
				);
			},

			'test relative (to current url) image urls with custom baseHref are changed to absolute': function() {
				testContentTransformation(
					'<p><img src="img/image1.jpg" /> Bar <img src="img/big/image2.png" /></p>',
					'<p><img src="' + exportPdfUtils.toAbsoluteUrl( 'img/image1.jpg', 'http://ckeditor.com/ckeditor4/' ) + '" /> Bar <img src="' + exportPdfUtils.toAbsoluteUrl( 'img/big/image2.png', 'http://ckeditor.com/ckeditor4/' ) + '" /></p>',
					{
						baseHref: 'http://ckeditor.com/ckeditor4/'
					}
				);
			},

			'test relative (to current url) image urls with custom baseHref and ".." are changed to absolute': function() {
				testContentTransformation(
					'<p><img src="../img/image1.jpg" /> Bar <img src="../../img/big/image2.png" /></p>',
					'<p><img src="' + exportPdfUtils.toAbsoluteUrl( 'img/image1.jpg', 'https://ckeditor.com/ckeditor4/' ) + '" /> Bar <img src="' + exportPdfUtils.toAbsoluteUrl( 'img/big/image2.png', 'https://ckeditor.com/' ) + '" /></p>',
					{
						baseHref: 'https://ckeditor.com/ckeditor4/demo/'
					}
				);
			},
		} );

		function testContentTransformation( initialHtml, expectedHtml, extraConfig ) {
			var config = exportPdfUtils.getDefaultConfig( 'unit', extraConfig || {} );

			bender.editorBot.create( {
				name: 'editor' + Date.now(),
				config: config
			}, function( bot ) {
				var editor = bot.editor;

				bot.setHtmlWithSelection( initialHtml );

				editor.once( 'exportPdf', function( evt ) {
					assert.areEqual( initialHtml, evt.data.html );
				}, null, null, 10 );

				editor.once( 'exportPdf', function( evt ) {
					evt.cancel();

					assert.areEqual( '<div class="cke_editable cke_contents_ltr">' + expectedHtml + '</div>', evt.data.html );
				}, null, null, 16 );

				editor.execCommand( 'exportPdf' );
			} );
		}

		function getPath( path, dirsBack ) {
			path = path.replace( /\/$/g, '' );

			if ( dirsBack && dirsBack > 0 ) {
				path = path.split( '/' ).slice( 0, -dirsBack ).join( '/' );
			}

			return path;
		}
	} );
} )();
