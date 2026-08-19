# Millennium chicken wingholes v5 generation prompt

Mode: built-in imagegen precise-object edit from the existing fitted chicken
millennium sprite.

> Correct only the two black-and-gold circular armholes. They are empty while
> the natural orange wings pass outside them. Re-route each existing wing root
> through the centre of its nearest opening. Orange feathers remain visible in
> the centre; the rear/upper gold rim passes behind the wing and the front/lower
> rim overlaps only its top feathers. Preserve one uninterrupted natural wing
> from that opening to its original tip, along with the chicken, face, pose,
> feet, navy/gold coat, medallion and embroidery. Use a flat `#ff00ff`
> chroma-key background.

The built-in result is saved as
`streak_1000_outfit_millennium_chicken_wingholes_v5_chroma.png`. Its background
was converted to alpha in the matching `_transparent.png` file with the
imagegen skill's `remove_chroma_key.py` helper using border auto-key, soft
matte, thresholds 12/220 and despill. `DRESSED_PET_OVERRIDES` selects this
single source so the ten approved grid cells are not regenerated.
