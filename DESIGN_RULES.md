# Design Rules

## UI Patterns

### Bottom Sheet Buttons
**Rule**: Buttons that open bottom sheets should use downward arrows (e.g., `Icons.arrow_drop_down_rounded`) instead of chevrons or other directional icons.

**Rationale**: Downward arrows clearly indicate that tapping will reveal content below, which aligns with Material Design guidelines for expandable content.

**Examples**:
- Branch selector button → `Icons.arrow_drop_down_rounded`
- Dropdown menus → `Icons.arrow_drop_down_rounded`
- Any button that opens `BottomSheetPagination` → `Icons.arrow_drop_down_rounded`

**Implementation**:
```dart
Icon(
  Icons.arrow_drop_down_rounded,
  size: 20,
  color: context.colorScheme.onSurfaceVariant.withOpacity(0.6),
)
```

