# UI/UX & Performance

## Design tokens
- Spacing, radius, typography, and warm palette are defined in `lib/utils/design_tokens.dart`.
- All screens should use these tokens instead of magic numbers.

## Warm minimalism
- One warm ground color, one ink color, one accent.
- No decorative shadows or gradients.
- Equal outer margins; section gaps 120-160px.
- Headlines fit in two lines or fewer.

## Performance checklist
- Use `ref.watch(provider.select(...))` to limit rebuilds.
- Prefer `ListView.builder` / `ListView.separated` for long lists.
- Use `const` widgets and `RepaintBoundary` for heavy subtrees.
- Cache formatters (already static in `DateFormatter` and `CurrencyFormatter`).
- Profile with Flutter DevTools: frame time, rebuild count, memory.

## Profiling targets
- Home screen rebuild count
- History scroll smoothness
- Wallet carousel performance
- Form input responsiveness
