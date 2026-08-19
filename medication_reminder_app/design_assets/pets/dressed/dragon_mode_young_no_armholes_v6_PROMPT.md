# Dragon mode v6 generation prompt

Mode: built-in imagegen precise-object edit from the V5 transparent grid.

> For the first ten animals, remove only the large oval armhole rings beside
> their natural front legs. Replace each removed oval with seamless green
> overlapping dragon scales that continue the shoulder vest naturally. Add no
> new hole, ring, cuff, sleeve, artificial claw or paw. Keep every natural
> furry front leg and original paw fully visible, uninterrupted and in front
> of the costume. Keep the chicken unchanged. Preserve the exact 4x3 layout,
> cell order, scale, centering, identities, faces, poses, wings, hoods, horns,
> chest armour, tails, lighting, colours and empty twelfth cell. Use a genuinely
> transparent background with no text, border, shadow or extra object.

The built-in result is saved on a flat chroma background as
`dragon_mode_young_no_armholes_v6_grid_chroma.png`. The imagegen skill's
`remove_chroma_key.py` helper converts it to
`dragon_mode_young_no_armholes_v6_grid_transparent.png` using border auto-key,
soft matte, thresholds 12/220 and despill. The generated chicken cell is
deliberately ignored: the app keeps using the exact approved V5 chicken cell.
