# Pet sound attribution

The app contains 20 distinct, shuffled variants for every pet behaviour:
cat meow/purr, dog bark/pant and chicken crow/cluck. Variants are trimmed,
volume-normalised passages from real animal recordings; no synthetic animal
voice is used. The unmodified source downloads are retained outside the app
bundle in `.source_audio/`.

## CC0 sources

- “Cat purr and meow” by slv1:
  https://soundspool.com/sounds/car-purr-and-meow
- “Cat meow” by philsapphire:
  https://freesound.org/people/philsapphire/sounds/256452/
- “Kitten meows” by Luke100000:
  https://freesound.org/people/Luke100000/sounds/476918/
- “cat purring and meow” by skymary:
  https://freesound.org/people/skymary/sounds/412016/
- “purring.wav” by Snapper4298:
  https://freesound.org/people/Snapper4298/sounds/255588/
- “cat purr.wav” by Walter_Odington:
  https://freesound.org/people/Walter_Odington/sounds/26769/
- “Purring Cat.wav” by Rehanjo:
  https://freesound.org/people/Rehanjo/sounds/593609/
- “Dog Barks.wav” by UnderlinedDesigns:
  https://freesound.org/people/UnderlinedDesigns/sounds/191687/
- “dog panting.wav” by keweldog:
  https://freesound.org/people/keweldog/sounds/181767/
- “Rooster Crowing” by pooky1:
  https://freesound.org/people/pooky1/sounds/556913/
- “Chicken clucking” by Breviceps:
  https://freesound.org/people/Breviceps/sounds/456803/
- "Rooster Crowing_27112016 [Processed]" by cabled_mess:
  https://freesound.org/people/cabled_mess/sounds/391313/
- "chicken.wav" by JhennaSide:
  https://freesound.org/people/JhennaSide/sounds/455905/

## Public-domain sources

- “Medium rooster crowing”:
  https://commons.wikimedia.org/wiki/File:Medium_rooster_crowing.ogg
- “Rooster crowing small”:
  https://commons.wikimedia.org/wiki/File:Rooster_crowing_small.ogv

All hungry sound variants (meow, bark and crow) are also packaged as Android
raw resources so medication notifications can use the adopted pet's voice.

The maintenance scripts replace passages with a poor animal-to-background
ratio, apply conservative noise reduction and verify that every generated file
can be decoded. The clean rooster source above was already explicitly
noise-reduced by its recorder. Source checksums are pinned in
`tool/replace_noisy_pet_sounds.py`.
