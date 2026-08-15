# Dragon mode young paws V2

Mode: ingebouwde ImageGen, `precise-object-edit` in twee bewerkingsrondes.

## Eerste bewerking

```text
Use case: precise-object-edit. The FIRST supplied image is the target 4x3 Dragon-mode pet sprite grid. The SECOND supplied image is an anatomy-only reference for how animal front legs clearly pass through costume armholes; do not copy its blue clothing. Preserve the FIRST image's exact canvas, flat #ff00ff background, grid layout and order, all eleven animals, young-pet proportions, heads, faces, fur/feather colors, dragon hoods, horns, scales, cream belly panels, shoulder armor, purple wings, tails, jewels, lighting, painterly style, and overall silhouettes. Fix only the limb/armhole construction. For each of the ten mammals, both natural fur-covered front legs must visibly begin inside and emerge through the matching green-and-gold arm opening below the shoulder armor, pass in front of the rear rim, remain visible down the front of the costume, and end in the animal's normal visible paws. The opening's front rim may overlap only the outer edge of the leg, proving that the leg passes through it; costume fabric must never be painted across the paws. Preserve each animal's exact leg fur pattern. For the chicken, both feathered wings must visibly emerge through the two side arm openings with the rims wrapping behind/around the wing roots; preserve its natural feet. Keep the decorative dragon-claw elements as small cuff/boot trim around or behind the natural paws, never replacing or covering them. Do not alter any face, body, hood, wing, tail, color, cell placement, scale, or costume decoration beyond the minimal local overlap edits. No crop, resizing, rearrangement, text, transparency, shadows, props, extra characters, or new decorations.
```

## Gerichte correctie van twee katten

```text
Use case: precise-object-edit. Preserve this exact Dragon-mode 4x3 grid, canvas, flat #ff00ff background, all eleven animals, every cell position, scale, face, hood, horn, jewel, wing, tail, belly panel, costume detail, color, lighting, style, and every already-correct visible limb. Change only two cells: the orange tabby cat in row 1 column 1 and the black cat in row 2 column 1. In each of those two cells, both natural fur-covered front legs are still hidden by green costume material. Redraw both full front legs so they visibly emerge through the two green-and-gold arm openings below the shoulder pieces, remain visibly in front of the costume down their full length, and end in the cat's natural visible paws. Use orange-striped fur and paws for the orange tabby; use black fur and black paws for the black cat. The rear opening rim stays behind the leg and the front rim may overlap only the leg edge. Keep small dragon-claw cuff/boot trim around or behind the natural paws without covering them. Do not alter any other cell or any other part of these two cats. No crop, resize, layout change, text, transparency, shadows, props, extra characters, or new decorations.
```

De chroma-versie is `dragon_mode_young_paws_v2_grid_chroma.png`. De transparante
versie is gemaakt met `remove_chroma_key.py --auto-key border --soft-matte
--transparent-threshold 12 --opaque-threshold 220 --despill --force` en staat in
`dragon_mode_young_paws_v2_grid_transparent.png`.
