# Znuny JavaScript Module Framework

This directory contains the JavaScript module framework for Znuny's frontend architecture. The framework provides a modular, scalable approach to building interactive UI components with automatic lifecycle management and inter-module communication.

## Framework Architecture

### Core Components

#### 1. Application Core (`application.js`)

The main framework file containing three core classes:

- **`Env.Application`** - Main application controller
- **`Env.Module`** - Base class for all modules
- **`Env.Sandbox`** - Communication layer between modules

#### 2. Module Files (`Module.*.js`)

Individual feature modules that extend the base `Env.Module` class:

- `Module.Alert.js` - Alert display and management
- `Module.Card.js` - Collapsible card functionality
- `Module.CustomerSelector.js` - Customer selection interface
- `Module.Form.js` - Form functionality and field manipulation
- `Module.Messages.js` - Message display system
- `Module.Sidebar.js` - Main sidebar functionality
- `Module.SidebarWidget.js` - Sidebar widget components

## Module Structure

### Base Module Pattern

All modules follow this consistent structure:

```javascript
// --
// Copyright (C) 2021 Znuny GmbH, https://znuny.org/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (AGPL). If you
// did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
// --

/**
 * ModuleName Module
 *
 * Brief description of module functionality.
 */

/* global Env */
(function (jQuery) {
    Env.Application.ModuleName = function (ctx, sandbox, moduleId) {
        Env.Module.call(this, ctx, sandbox, moduleId);
    };
    Env.Application.ModuleName.prototype = new Env.Module();
    Env.Application.ModuleName.prototype.constructor = Env.Application.ModuleName;
    jQuery.extend(Env.Application.ModuleName.prototype, {

        // Module configuration
        name: 'modModuleName',

        // Hook functions
        dependencies: function () {
            // Load module dependencies
        },

        onInit: function () {
            // Initialize module before binding events
        },

        onStart: function () {
            // Start module and bind events
        },

        onStop: function () {
            // Clean up when module stops
        }
    });
})(jQuery);
```

### Module Lifecycle Hooks


1. **`dependencies()`** - Load required dependencies
2. **`onInit()`** - Initialize module state and data
3. **`onStart()`** - Bind events and start functionality
4. **`onStop()`** - Clean up resources when module stops

## Automatic Module Registration

### DOM-Based Registration

Modules are automatically registered based on CSS classes in the DOM (TemplateToolkit files):

```html
<div class="mod modAlert">
    <!-- Alert module content -->
</div>

<div class="mod modCard">
    <!-- Card module content -->
</div>
```

### Registration Process

1. Application scans for elements with `.mod` class
2. Extracts module name from additional class (e.g., `modAlert`)
3. Instantiates corresponding `Env.Application.Alert` class
4. Calls lifecycle hooks: `dependencies()` → `onInit()` → `onStart()`

## Module Communication

### Sandbox System

Modules communicate through the sandbox to maintain loose coupling:

```javascript
// Get another module instance
var messagesModule = this.sandbox.getModule(moduleId);

// Add new modules dynamically
this.sandbox.addModule(domNode, 'Alert');

// Listen for notifications
this.sandbox.listen('eventName', this, 'methodName');

// Send notifications
this.sandbox.notify('eventName', data);
```

### Inter-Module Examples

#### Alert → Messages Communication

```javascript
// Alert module sends generated HTML to Messages module
var messagesModule = this.findMessagesModule();
if (messagesModule) {
    messagesModule.addMessage(html, 'notice', 5);
}
```

## Application Lifecycle

### Initialization

```javascript
// Create application instance
var app = new Env.Application(config);

// Start application (registers and starts all modules)
app.run();
```

### Runtime Module Management

```javascript
// Add new module to running application
app.addModule(domElement, 'Alert');

// Stop specific module
app.stop(moduleId);

// Stop all modules
app.stopAll();
```

## Configuration

### Application Config

```javascript
Env.Config = {
    resourcePath: '/resources',
    applicationUrl: '/',
    supressErrors: false  // Set to true for production
};
```

### Module Configuration

Each module can define its configuration:

```javascript
jQuery.extend(Env.Application.ModuleName.prototype, {
    name: 'modModuleName',
    defaultOptions: {
        animationSpeed: 250,
        autoClose: true
    }
    // ...
});
```

## Error Handling

The framework includes comprehensive error handling:

- **Automatic Error Wrapping** - All module methods are wrapped with try/catch
- **Console Logging** - Errors logged to browser console with module context
- **Graceful Degradation** - Errors don't break other modules
- **Production Mode** - Set `supressErrors: true` to suppress error throwing

## Best Practices

### Module Development

1. **Single Responsibility** - Each module should handle one specific feature
2. **DOM Context** - Use `this.ctx` to limit DOM queries to module scope
3. **Event Binding** - Always bind events in `onStart()` method
4. **Cleanup** - Implement `onStop()` for proper resource cleanup
5. **Error Handling** - Use try/catch for external API calls

### Performance

1. **Lazy Loading** - Modules are only instantiated when found in DOM
2. **Scoped Queries** - Always query within module context (`this.ctx`)
3. **Event Delegation** - Prefer event delegation for dynamic content
4. **Memory Management** - Clean up event listeners and references in `onStop()`

### Communication

1. **Loose Coupling** - Use sandbox for inter-module communication
2. **Event-Driven** - Prefer event notifications over direct method calls
3. **Data Validation** - Always validate data received from other modules

## Integration with Legacy Code

The module framework coexists with existing Znuny JavaScript:

### Core Integration

```javascript
// Access Core functionality from modules
if (Core && Core.UI && Core.UI.Popup) {
    Core.UI.Popup.ClosePopup();
}
```

### Legacy DOM Patterns

```html
<!-- Module-based (new) -->
<div class="mod modAlert">
    <div class="alertData">{"message": "Success!", "type": "success"}</div>
</div>

<!-- Legacy pattern (still supported) -->
<div class="MessageContainer">
    <div class="Message Success">Success message</div>
</div>
```

## Development Workflow

### Creating New Modules

1. **Create Module File**
   ```bash
   touch Module.MyFeature.js
   ```

2. **Implement Module Structure**
   - Copy base pattern from existing module
   - Update class name and prototype
   - Implement required hooks

3. **Add CSS Classes**
   ```html
   <div class="mod modMyFeature">
       <!-- Module content -->
   </div>
   ```

4. **Test Integration**
   - Verify automatic registration
   - Test lifecycle hooks
   - Validate error handling

### Debugging

1. **Console Inspection**
   ```javascript
   // Check registered modules
   console.log(app.modules);

   // Get specific module
   var module = app.sandbox.getModule(moduleId);
   ```

2. **DOM Attributes**
   - Each module container gets `data-moduleid` attribute
   - Use browser dev tools to inspect module IDs

3. **Error Tracking**
   - Framework logs detailed error information
   - Module name and method included in error messages

## File Structure

```
modules/
├── application.js          # Core framework (Env.Application, Env.Module, Env.Sandbox)
├── Module.Alert.js         # Alert display and management
├── Module.Card.js          # Collapsible card functionality
├── Module.CustomerSelector.js  # Customer selection interface
├── Module.Form.js          # Form handling and field manipulation
├── Module.Messages.js      # Message display system
├── Module.Sidebar.js       # Main sidebar functionality
└── Module.SidebarWidget.js # Sidebar widget components
```

## Related Documentation

- **CSS Framework**: `/var/httpd/htdocs/skins/Agent/default/scss/README.md`
- **Core JavaScript**: `/var/httpd/htdocs/js/Core.*.js`
- **Legacy Documentation**: `/var/httpd/htdocs/js/jsdoc-readme.md`