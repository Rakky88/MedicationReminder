# Dragon mode v5 generation prompt

Mode: two built-in imagegen precise-object edits from the v4 transparent grid.

The first edit removed the detached armhole rings and kept every natural front
leg free. The second edit used that result as its edit target and v4 only as a
material reference:

> Add a small but unmistakable closed armhole rim around the upper end of each
> natural foreleg for the first ten animals. Each green scaled rim must be
> centred directly on the furry leg, with fur visible through its empty centre.
> Show both side rims, a lower/front lip in front of only the upper shoulder
> fur, and an upper/rear lip disappearing behind that fur. This overlap must
> prove the uninterrupted natural leg passes through the opening and continues
> to its original paw. Remove every detached empty oval beside a leg. Preserve
> the 4x3 layout, identities, faces, poses, paws, costume, chicken, empty last
> cell and flat `#ff00ff` background.

The built-in result is saved as
`dragon_mode_young_paws_v5_grid_chroma.png`. Its flat chroma background was
converted to alpha in `dragon_mode_young_paws_v5_grid_transparent.png` with the
imagegen skill's `remove_chroma_key.py` helper using border auto-key, soft
matte, thresholds 12/220 and despill.
