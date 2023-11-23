/**
 * @license Copyright (c) 2003-2022, CKSource Holding sp. z o.o. All rights reserved.
 * For licensing, see LICENSE.md or https://ckeditor.com/legal/ckeditor-oss-license
 */

( function() {
	'use strict';

	window.exportPdfUtils = {
		useXHR: function( editor, callback ) {
			var xhr = sinon.useFakeXMLHttpRequest(),
				request;

			xhr.onCreate = function( requestInstance ) {
				request = requestInstance;
			};

			editor.execCommand( 'exportPdf' );

			if ( callback ) {
				callback( request );
			}

			xhr.restore();
		},

		getDefaultConfig: function( type, extraProps ) {
			return CKEDITOR.tools.object.merge( {
				extraPlugins: 'exportpdf',
				exportPdf_appId: 'cke4-tests-' + type
			}, extraProps );
		},

		initManualTest: function() {
			bender.loadExternalPlugin( 'exportpdf', '/apps/plugin/' );
			bender.tools.ignoreUnsupportedEnvironment( 'exportpdf' );
		},

		toAbsoluteUrl: function( path, origin ) {
			return ( origin ? origin : window.location.origin ) + path;
		}
	};
} )();
