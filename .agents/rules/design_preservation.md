# UI Design Preservation Rule

## Core Directives

1. **Preserve Existing UI & Styling**:
   - When making functional changes, bug fixes, state management updates, or API integrations, **do not modify existing UI designs, colors, themes, typography, or component layouts**.
   - Keep all visual styles (e.g. `Theme.of(context)`, colors, borders, paddings, fonts, card structures) consistent with the current implementation.

2. **No Unsolicited Redesigns**:
   - Only alter visual designs, color schemes, or page layouts if the user **explicitly asks for a redesign** or aesthetic changes.
   - Refactoring code (e.g., extracting BLoCs, fixing logic, handling state) must keep the exact same widget tree visual appearance.

3. **Strict Scoping**:
   - Keep UI edits minimal, surgical, and scoped strictly to what is requested.
