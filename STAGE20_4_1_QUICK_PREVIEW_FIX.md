# ComicPort — Stage 20.4.1 / Mac v1.0.1

Compile hotfix for Quick Preview.

## Xcode error
`Instance member 'navigationTitle' cannot be used on type 'View'`

## Cause
The `navigationTitle` and `toolbar` modifiers were syntactically positioned after
an `if let book` result inside the `NavigationStack` builder. Swift's parser accepts
the source, but semantic type checking can bind the modifier to the conditional
view expression instead of the NavigationStack.

## Fix
- Wrap Quick Preview conditional content in `Group`.
- Move `.navigationTitle` and `.toolbar` onto `NavigationStack`.
- Add a safe unavailable-comic state.
- No Stage 20.4 feature behavior was removed.
- No Xcode project/target/package change.
