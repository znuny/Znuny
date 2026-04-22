// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/* global Env:writable */

Env = {};

/**
 * Default options
 *
 * @type object
 */
Env.Config = {
    resourcePath: '/resources',
    applicationUrl: '/'
};

(function (jQuery) {
    Env.Application = function (config) {
        this.modules = [];
        this.plugins = [];
        this.ctx = false;
        this.config = jQuery.extend(true, Env.Config, config);
        this.sandbox = new Env.Sandbox(this);

        return jQuery.extend(this, {

            /**
             * registers all modules
             *
             * @param {object} context - The DOM context to search for modules
             * @returns {Array} Array of module IDs
             */
            registerModules: function (context) {
                var that = this;
                var moduleIds = [];
                var i, moduleName, moduleId;
                if (this.ctx === false) {
                    this.ctx = context;
                }
                jQuery('.mod', context).each(function () {
                    var classes = jQuery(this).attr('class').split(' ');

                    if (classes.length > 1) {
                        moduleName = '';

                        for (i in classes) {
                            if (classes[i].length > 3 && classes[i].indexOf('mod') === 0) {
                                moduleName = classes[1].substr(3);
                            }
                        }

                        // CSS only modules have no object so instanciate only JS modules
                        if (moduleName.length > 0 && Env.Application[moduleName]) {
                            moduleId = that.registerModule(this, moduleName);
                            moduleIds.push(moduleId);
                        }
                    }
                });

                return moduleIds;
            },

            /**
             * starts a module
             *
             * @param {number} moduleId - The ID of the module to start
             */
            start: function (moduleId) {
                this.modules[moduleId].start();
            },

            /**
             * stops a module
             *
             * @param {number} moduleId - The ID of the module to stop
             */
            stop: function (moduleId) {
                this.modules[moduleId].stop();
                this.modules[moduleId] = null;
            },

            /**
             * Starts the application, registers all modules in body and starts them
             */
            run: function () {
                var id;
                var modules = this.registerModules(jQuery('body'));

                for (id in modules) {
                    this.start(modules[id]);
                }
            },

            /**
             * register a module autoload module if module class is not available
             *
             * @param {object} domNode - DOM node of the module container
             * @param {string} moduleName - Name of the module
             * @returns {number} The module ID
             */
            registerModule: function (domNode, moduleName) {
                var moduleId = parseInt(this.modules.length, 10) + 1;

                this.modules[moduleId] = new Env.Application[moduleName](domNode, this.sandbox, moduleId);
                this.applyErrorHandler(moduleName, this.modules[moduleId]);

                this.modules[moduleId].init();

                return moduleId;
            },

            /**
             * check all existing module ids and get the id for the next, new module
             *
             * @returns {[]}
             */
            getModuleIds: function () {
                var moduleIds = [];
                jQuery('.mod').each(function () {
                    var moduleId = jQuery(this).attr('data-moduleid');
                    if (moduleId) {
                        moduleIds.push(parseInt(moduleId, 10));
                    }
                });
                return moduleIds;
            },

            /**
             * register an module in the existing application
             *
             * @param {object} domNode - DOM node of the module container
             * @param {string} moduleName - Name of the module
             * @param {object} app - Application instance
             * @returns {number} The module ID
             */
            addModule: function (domNode, moduleName, app) {
                var moduleId = (Math.max.apply(Math, this.getModuleIds())) + 1;
                var dom = jQuery('.mod', domNode);
                app.modules[moduleId] = new Env.Application[moduleName](dom, app.sandbox, moduleId);
                app.modules[moduleId].init();
                app.modules[moduleId].start();
                return moduleId;
            },

            /**
             * add more than one module in context
             *
             * @param {object} domNode - DOM node containing the modules
             * @param {string} moduleName - Name of the module
             * @param {object} app - Application instance
             * @returns {Array} Array of module IDs
             */
            addModules: function (domNode, moduleName, app) {
                var dom = jQuery('.mod', domNode);
                var that = this;
                var moduleIds = [];
                dom.each(function () {
                    var moduleId = (Math.max.apply(Math, that.getModuleIds())) + 1;
                    app.modules[moduleId] = new Env.Application[moduleName](this, app.sandbox, moduleId);
                    app.modules[moduleId].init();
                    app.modules[moduleId].start();
                    moduleIds.push(moduleId);
                });
                return moduleIds;
            },


            getPlugin: function (plugin) {
                var domNode;

                if (!this.plugins[plugin]) {
                    domNode = null;

                    this.plugins[plugin] = new Env.Application[plugin](domNode, this.sandbox);
                    this.applyErrorHandler(plugin, this.plugins[plugin]);

                    try {
                        this.plugins[plugin].init();
                    } catch (e) {
                        if (window.console && window.console.error) {
                            console.error(e);
                        }
                    }
                }
                return this.plugins[plugin];
            },

            /**
             * stop all modules
             */
            stopAll: function () {
                var id;

                for (id in this.modules) {
                    this.stop(id);
                }
            },

            /**
             * wrap all module methods with a anonymous function that catches errors
             * and channels the error messages
             *
             * @param {string} moduleName - Name of the module
             * @param {object} module - Module instance
             */
            applyErrorHandler: function (moduleName, module) {
                var that = this;
                var property, method;

                for (property in module) {
                    method = module[property];

                    if (jQuery.isFunction(method)) {
                        module[property] = function (moduleName, property, method) {
                            return function () {
                                try {
                                    return method.apply(this, arguments);
                                } catch (ex) {
                                    if (window.console && window.console.error) {
                                        console.error('Error in ' + moduleName + '.' + property + '()'); // eslint-disable-line no-unused-vars
                                        console.error(ex.message); // eslint-disable-line no-unused-vars
                                        console.error(ex.fileName + ' in line ' + ex.lineNumber); // eslint-disable-line no-unused-vars
                                    }

                                    if (that.config.supressErrors == false) {
                                        throw ex;
                                    }
                                }
                            };
                        }(moduleName, property, method);
                    }
                }
            }
        });
    };
})(jQuery);

/**
 * The sandbox, observer and registry
 *
 *@param the application
 */
(function (jQuery) {
    Env.Sandbox = function (application) {
        /**
         * the application
         */
        this.application = application;

        /**
         * list of objects that are listening
         */
        this.listeners = [];

        /**
         * list of methods to call on the listening objects
         */
        this.listenerMethods = [];

        return jQuery.extend(this, {
            /**
             * returns parameter from config
             *
             * @param {string} name - Name of the parameter
             * @returns {*} The configuration value
             */
            get: function (name) {
                return this.application.config[name];
            },

            /**
             * notify modules. calls the listening method in the context of the listening
             * object. so this inside a listening method points to the listening module.
             *
             * @param {string} name - Name of the listener
             * @param {*} variable - Amount of parameters to pass thru to the listening method
             */
            notify: function (name) {
                var args = [];
                var i, method;

                for (i = 1; i < arguments.length; i++) {
                    args.push(arguments[i]);
                }

                try {
                    method = this.listeners[name][this.listenerMethods[name]];
                    method.apply(this.listeners[name], args);
                } catch (e) {
                    if (window.console && window.console.error) {
                        console.error('no listener found for ' + name);
                        console.error(e); // eslint-disable-line no-unused-vars
                    }
                }
            },

            /**
             * stores a listening module
             *
             * @param {string} name - Name of the listener
             * @param {object} object - Object that is listening
             * @param {string} method - Method that is called when the object is notified
             */
            listen: function (name, object, method) {
                this.listeners[name] = object;
                this.listenerMethods[name] = method;
            },

            /**
             * returns a plugin from the application
             *
             * @param {string} plugin - Name of the plugin
             * @param {*} additional - Optional parameters
             * @returns {object} Plugin instance
             */
            getPlugin: function (plugin) {
                var args = [];
                var i;

                for (i = 1; i < arguments.length; i++) {
                    args.push(arguments[i]);
                }

                return this.application.getPlugin(plugin, args);
            },

            /**
             * adds a module to the existing application
             *
             * @param {object} domNode - DOM node of the module container
             * @param {string} moduleName - Name of the module
             */
            addModule: function (domNode, moduleName) {
                this.application.addModule(domNode, moduleName, this.application);
            },

            /**
             * add modules to the existing application
             *
             * @param {object} domNode - DOM node containing the modules
             * @param {string} moduleName - Name of the module
             */
            addModules: function (domNode, moduleName) {
                this.application.addModules(domNode, moduleName, this.application);
            },

            /**
             * returns a module by its module id (module ID ist stored as data-moduleId on the modules DOM-Node
             *
             * @param {number} moduleId - ID of the module
             * @returns {object} Module instance
             */
            getModule: function (moduleId) {
                if (this.application.modules[moduleId]) {
                    return this.application.modules[moduleId];
                } else {
                    throw {
                        name: "Error",
                        message: "no module registered for id: " + moduleId,
                        toString: function () {
                            return this.name + ": " + this.message;
                        }
                    };
                }
            }
        });
    };
})(jQuery);

/**
 * abstract class for all modules
 *
 *@param domNode of the module container
 *@param sandbox
 */
(function (jQuery) {
    Env.Module = function (domNode, sandbox, moduleId) {
        if (arguments.length > 0) {

            /**
             * module container
             */
            this.ctx = domNode;

            /**
             * the sandbox
             */
            this.sandbox = sandbox;

            /**
             * id of this module
             */
            this.moduleId = moduleId;

            return jQuery.extend(this, {
                /**
                 * the init event chain, calls dependencies() and onInit() of the
                 * module
                 */
                init: function () {
                    var onInit = this.onInit;
                    jQuery(this.ctx).attr('data-moduleId', this.moduleId);
                    if (jQuery.isFunction(onInit)) {
                        this.onInit();
                    }
                },

                /**
                 * the start event chain, calls onStart of the module
                 */
                start: function () {
                    var onStart = this.onStart;
                    if (jQuery.isFunction(onStart)) {
                        this.onStart();
                    }
                },

                /**
                 * the stop event chain, calls onStop of the module
                 */
                stop: function () {
                    var onStop = this.onStop;
                    if (jQuery.isFunction(onStop)) {
                        this.onStop();
                    }
                }
            });
        }
    }
})(jQuery);
