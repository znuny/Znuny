# Agent Interface SCSS Framework

This directory contains the SCSS files for the Znuny Agent interface default skin. The architecture follows a modular approach with clear separation of concerns.

## Directory Structure

```
scss/
├── layouts/         # Layout-specific styles (grid systems, page structure)
├── mixins/          # Reusable SCSS mixins and functions
├── modules/         # Component-specific styles
└── utilities/       # Utility classes and helper mixins
```

## Naming Conventions

### File Naming
- **Layouts**: `Layout.{Name}.scss` (e.g., `Layout.ContentSidebar.scss`)
- **Mixins**: `_Mixin.{Name}.scss` (e.g., `_Mixin.Buttons.scss`)
- **Modules**: `Module.{Name}.scss` (e.g., `Module.Alert.scss`)
- **Utilities**: `_Utility.{Name}.scss` (e.g., `_Utility.Clear.scss`)

### CSS Class Naming
- **Layout classes**: `.layout{Name}` (e.g., `.layoutContentSidebar`)
- **Module classes**: `.mod{Name}` (e.g., `.modAlert`)
- **Section classes**: `.section{Name}` (e.g., `.sectionContent`, `.sectionSidebar`)

## Architecture Overview

### Layouts (`layouts/`)

Define the overall page structure and grid systems. Layout classes always start with `.layout` and contain sections that start with `.section`.

**Example:**
```scss
.layoutContentSidebar {
  display: grid;
  grid-template-columns: 1fr auto;
  // ...

  .sectionContent { }
  .sectionSidebar { }
}
```

### Mixins (`mixins/`)

Reusable style patterns that can be included in other SCSS files using `@include`.

**Example:**
```scss
@mixin button() {
  font-size: 12px;
  font-weight: 600;
  border-radius: var(--border-radius-sm);
}

@mixin buttonPrimary() {
  @include buttonColor(var(--primary-color), var(--btn-primary-text), ...);
}
```

### Modules (`modules/`)

Component-specific styles for UI elements like alerts, cards, forms, etc. Module classes start with `.mod`.

**Example:**
```scss
.modAlert {
  .alert {
    background-color: rgba(#D7E6F5, 0.95);

    &.alertTypeSuccess { }
    &.alertTypeWarning { }
    &.alertTypeError { }
  }
}
```

### Utilities (`utilities/`)

Helper mixins and utility classes for common styling patterns.

**Example:**
```scss
@mixin clear($float: left) {
  float: $float;
  width: 100%;
  display: inline-block;
}
```

## Usage Guidelines

### Importing Files
Always import dependencies at the top of your SCSS files:

```scss
@import './../mixins/Mixin.Buttons';
@import './../utilities/Utility.Clear';
```

### Using Mixins
Include mixins to apply predefined styling:

```scss
.myButton {
  @include button;
  @include buttonPrimary;
}

.clearfix {
  @include clear();
}
```

### CSS Variables
Use CSS custom properties for theming:

```scss
.element {
  background-color: var(--primary-color);
  border-color: var(--border-color);
}
```

## File Headers

All SCSS files should include the standard Znuny license header:

```scss
/*
Copyright (C) 2021 Znuny GmbH, https://znuny.org/

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
*/
```

## Best Practices

1. **Modular Design**: Keep styles organized by component/module
2. **Consistent Naming**: Follow the established naming conventions
3. **Reusability**: Use mixins for repeated style patterns
4. **Responsive Design**: Utilize media query utilities for responsive behavior
5. **CSS Variables**: Leverage CSS custom properties for theming and consistency
6. **Import Order**: Import utilities and mixins before using them
