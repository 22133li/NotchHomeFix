# NotchHome 0.5.0 Hook / ABI Inventory

Target: arm64e dylib from the attached deb. This is static analysis, not recovered original source. Evidence is limited to strings, constructed registration descriptors, Objective-C runtime checks, and disassembly. `Method type` is stated as confirmed only when the binary descriptor or encoding comparison establishes it; otherwise it is marked unknown.

## Main icon zoom modifier

Class: `SBFullScreenToHomeIconZoomSwitcherModifier`

The registration routine builds seven method descriptors. The arm64e descriptor table materializes `frameFor` and `scaleFor` as selector prefixes, pairs them with `Index:`, and stores the expected return encodings (CGRect and `d`). The same table includes the other five selectors shown below. Before installing each hook, it resolves the class and selector, checks method existence, checks return type and argument count, then compares each explicit argument type. Mismatch or missing method skips that hook rather than installing it blindly. The registration descriptors do not by themselves identify each replacement IMP body; that mapping remains unresolved.

| Selector | Registration evidence | Return / argument evidence | Function |
|---|---|---|---|
| `_isEffectivelyHome` | Literal selector in descriptor array | Expected return encoding `B`; zero explicit arguments | Home-state eligibility gate |
| `_isIndexZoomAppLayout:` | Literal selector in descriptor array | Expected return encoding `B`; one explicit argument, exact argument encoding not yet recovered | Layout eligibility gate |
| `frameForIndex:` | Registered via dynamically composed `frameFor` + `Index:` descriptor; HookSlot global at `0x19000+0x4f0` | Expected return CGRect (`{CGRect={CGPoint=dd}{CGSize=dd}}`); one explicit argument, encoding still unknown. Replacement calls saved original IMP and writes 32-byte CGRect to output. It compares against per-instance cached bounds and may recompute/update cache. | Target frame geometry with bounds cache |
| `scaleForIndex:` | Registered via dynamically composed `scaleFor` + `Index:` descriptor; HookSlot global at `0x19000+0x4f8` | Expected return `d`; one explicit argument, encoding still unknown. Replacement calls saved original IMP and writes one double to output, followed by numeric validity/range checks. | Target scale with numeric normalization/validation |
| `cornerRadiiForIndex:` | Literal selector in descriptor setup | Expected return `{UIRectCornerRadii=dddd}`; exact index encoding not yet fully recovered | Corner geometry |
| `transitionWillBegin` | Literal selector in descriptor setup | Expected return `v`, zero explicit arguments | Start transition bookkeeping |
| `transitionDidEnd` | Literal selector in descriptor setup | Expected return `v`, zero explicit arguments | Finish transition bookkeeping |

The routine separately looks up and validates ivars `_homeScreenIconFrame` and `_homeScreenIconCornerRadius`; these are not selectors and are not counted among the seven method hooks. It checks their encodings and offsets/object size before enabling dependent associated layout state. This is ABI/layout validation, not evidence that the values are read for the corner calculation. `cornerRadiiForIndex:` has a separate HookSlot at `0x19000+0x500`; its wrapper invokes the replacement closure stored in that slot and returns four doubles to the caller. The closure's full body/IMP mapping is not yet confirmed, so do not assert that it uses the shared frame helper. Searches for `_homeScreenIconCornerRadius` references found only the metadata/type/offset validation path; no direct value load was located. Its relationship to returned radii remains unknown. `interruptAndEndTransition` is registered through a separate descriptor path.

## Frame bounds cache behavior

- The frame getter obtains `containerViewBounds` through a dynamically resolved selector. It validates the returned CGRect type; if the getter cannot be resolved or a valid CGRect cannot be produced, it returns a zero CGRect marked invalid.
- The per-modifier cache stores the CGRect bounds, a validity/mutation flag, and a weak target-window reference.
- A cached frame result is reused only when the cached bounds pass `CGRectEqualToRect` against the current `containerViewBounds` and the weak target window is still alive.
- If bounds differ, the cache is marked invalid, the target window is cleared, and target selection/frame calculation is repeated. The new bounds and target are written back after recomputation.
- If recomputation cannot produce a valid result, the output is zero CGRect and the result flag is invalid; no stale cached target is treated as current.
- Recompute obtains the shared `UIApplication`, reads connected scenes, filters scenes to `UIWindowScene`, then reads each scene's `windows` collection. It does not begin from a process-wide arbitrary window list.
- Window candidates are filtered by class name to `SBMainSwitcherWindow` or `SBHomeScreenWindow` and accumulated in enumeration order. A subsequent first-match lookup selects the first candidate satisfying geometry predicates; no key-window or z-order sorting was observed.
- Candidate bounds must be finite and width and height each in the inclusive range 12...180 pt (below 12 or above 180 rejects).
- Candidate center must lie within the container bounds expanded by 30 pt on all sides: `candidate.midX >= container.minX - 30`, `candidate.midX <= container.maxX + 30`, `candidate.midY >= container.minY - 30`, and `candidate.midY <= container.maxY + 30`. Equality passes the observed conditional branches.
- The candidate's root view controller child list is inspected; a child qualifies only when its window bounds width and height each differ from candidate bounds by less than 1 pt (absolute difference `>= 1` rejects).
- The first passing candidate is returned in scene/window enumeration order. If no candidate satisfies the predicate or required UIKit objects/selectors are unavailable, recomputation yields an invalid zero CGRect.
- The candidate helper's returned window/bounds is consumed by later logic; it is not proven to be the final icon frame. The main modifier subsequently reads frame and corner-related values from the selected target, then invokes a separate CGRect adjustment helper with two CGRect operands and one scalar.
- The adjustment helper preserves the source CGRect size and centers it on the target midpoint. At the callsite, register/stack marshalling confirms the two rectangles and scalar, but the exact mapping of each rectangle to `_homeScreenIconFrame`, candidate bounds, or container bounds remains unproven.
- Therefore distinguish container bounds, selected candidate window bounds, source layout frame, and final icon frame. Do not substitute one for another without runtime evidence.

## Frame transform helper

- A CGRect helper validates both input rectangles: all dimensions must be finite and positive. One rectangle is constrained to width 300...500 pt, height 600...1100 pt, portrait aspect (height greater than width), and center within a 30 pt margin around the other rectangle.
- When valid, the output preserves the first rectangle's width/height and centers it on the second rectangle's midpoint:
  - `out.origin.x = target.midX - source.width / 2`
  - `out.origin.y = target.midY - source.height / 2`
  - `out.size = source.size`
- Invalid input yields a zero CGRect and invalid-result flag. Callers additionally reject/fallback when the helper reports invalid.
- The call-site argument provenance (which of app frame, target window bounds, or icon frame is passed as source vs target for each animation path) is not fully mapped yet; treat the formula as confirmed but its per-path use as unconfirmed.

## Other confirmed targets

| Class | Selector(s) found in registration code | Current evidence / unknowns |
|---|---|---|
| `SBFullScreenToHomeIconZoomSwitcherModifier` | `opacityForIndex:`, `opacityForLayoutRole:inAppLayout:atIndex:`, `shouldMatchMoveToIconView` | Separate hook-slot constructors exist. Full return/argument encodings and replacement behavior still need mapping. |
| `SBFluidSwitcherViewController` | `_performModifierIconViewVisibilityUpdateAction:`, `_performModifierIconViewVisibilityUpdateResponse:`, `_performModifierIconOverlayVisibilityUpdateAction:`, `_performModifierIconOverlayVisibilityUpdateResponse:`, `_performModifierMatchMoveToIconViewAction:`, `_performModifierMatchMoveToIconViewResponse:` | Hook slots are separately constructed. They operate on visibility, overlay, and match-move event/action/response paths. Exact method encodings and callback ordering remain to be decoded. |
| `SBFullScreenToHomeIconZoomSwitcherModifier` | `animationAttributesForLayoutElement:` | Separate registration slot. Return object/argument encoding must be verified from descriptor. |
| `SBGestureInitiatedIconZoomAnimationAttributesSwitcherModifier` | `animationAttributesForLayoutElement:` | Separate registration slot for gesture-originated animations. Exact behavior and ABI remain to be mapped. |
| `SBSwitcherAnimationAttributes` / `SBFFluidBehaviorSettings` | `mutableCopyWithZone:`, `setDampingRatio:`, `setScaleSettings:`, `setPositionSettings:`, `setScaleUpdateMode:`, `setPositionUpdateMode:` | Present as runtime-resolved selectors in the animation reconstruction path. Need trace whether each is hooked, invoked, or only dynamically looked up before treating them as public hook contracts. |

## Registration and failure behavior

- The main descriptor builder requires the target class to resolve; if not, it exits without installing its method set.
- For each descriptor it resolves the selector and method, compares the return encoding, compares Objective-C argument count (`explicit arguments + self/_cmd`), and checks each explicit argument encoding.
- Missing method, return mismatch, argument count mismatch, or argument type mismatch skips that method's hook.
- The ivar path separately resolves the ivar, checks its type encoding and offset against instance layout, and uses these checks before enabling dependent hooks.
- This compatibility guard is part of behavior and must be reproduced. A source reimplementation must not install guessed signatures unconditionally.
- After signature validation, the generic installer calls `MSHookMessageEx`, stores the returned original IMP in the HookSlot, and marks the slot installed. HookSlot therefore holds both a replacement closure/thunk and the original IMP used for forwarding.
- The main modifier has five explicitly constructed HookSlots whose selectors are `_isEffectivelyHome`, `cornerRadiiForIndex:`, `transitionWillBegin`, `transitionDidEnd`, and `interruptAndEndTransition`. Two more descriptor entries are assembled from string fragments for `frameForIndex:` and `scaleForIndex:`; their dynamic HookSlot initializer call sites are not yet recovered.
- The installer obtains the replacement IMP from the registered closure/thunk, saves the original IMP returned by `method_getImplementation`/`MSHookMessageEx` in the slot, and uses that original IMP for forwarding. The descriptor and closure collections are assembled dynamically; current static analysis does not establish the per-index replacement mapping. Geometry-looking CGRect functions cannot safely be attributed by shape alone.

## Confidence

- High: target class, seven-entry method descriptor table, composed `frameForIndex:`/`scaleForIndex:` selectors, their expected return encodings, the separate two-ivar validation, and runtime return/argument validation.
- Medium: these methods are hooked to custom replacements; descriptor entries and the installer indicate installation intent, but the exact per-slot IMP mapping is not recovered.
- Low / open: exact index argument encodings, each selector-to-replacement thunk mapping, private event argument classes, callback ordering, original error/log semantics, and iOS 15.4 runtime compatibility.
