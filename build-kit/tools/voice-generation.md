# Voice Generation Guide (ElevenLabs)

Reference for generating natural-sounding TTS audio using ElevenLabs. Battle-tested from the Weekly Digest podcast build + deep research on community best practices.

## Quick Reference -- Settings for Natural Speech

| Setting | Default | Podcast/Conversational | Narration | Character/Dramatic |
|---------|---------|----------------------|-----------|-------------------|
| stability | 0.5 | 0.25-0.35 | 0.6-0.8 | 0.3-0.5 |
| similarity_boost | 0.75 | 0.80 | 0.70 | 0.80 |
| style | 0.0 | 0.35-0.40 | 0.2-0.4 | 0.7-1.0 |
| speed | 1.0 | 1.10-1.15 | 1.0 | 1.0 |
| use_speaker_boost | false | true | true | true |
| model | -- | eleven_v3 | eleven_v3 | eleven_v3 |

### What each setting does
- **Stability**: Lower = more expressive variation. Too low causes instability/hallucinations. Too high = monotone robot.
- **Similarity boost**: How close to the original voice. Keep high (0.7-0.9) for consistency.
- **Style**: Amplifies the speaker's natural character. Even 3-5% makes a noticeable difference. Increases latency.
- **Speed**: 0.7-1.3 range. 1.1-1.15 removes the "AI drag" that makes TTS sound slow and deliberate.

### Troubleshooting via settings
- Robotic/monotone: Lower stability to 0.25-0.35, raise style to 0.3+
- Unstable/glitchy: Raise stability to 0.6+, lower style
- Flat delivery: Lower stability, add emotional context in the script text
- Too slow: Increase speed to 1.1-1.15

## Voice Selection

### Always use community voices over premade
Premade voices (the ~22 built-in ones) sound noticeably more robotic than top community voices. The difference is dramatic.

**How to evaluate a community voice:**
- `cloned_by_count` > 10,000 = well-tested
- `usage_character_count_1y` > 100M = production-proven
- Listen to a test line with YOUR content before committing
- Match voice to content style (podcast, narration, conversation)
- Watch for credit multipliers -- some community voices cost 2-3x

### Voice hierarchy (what matters most for quality)
1. Voice selection (biggest impact)
2. Script writing (second biggest -- see below)
3. Model selection (always v3)
4. Voice settings (fine-tuning)

### Voice types
- **Premade**: Reliable, generic, limited personality
- **Community**: Best quality-to-effort ratio. Filter by accent, gender, age, use case
- **Voice Design**: Describe what you want in text, get 3 candidates. Be specific: "Middle-aged Australian male, warm deep voice, calm professional, slight gravelly timbre"
- **Instant Clone**: 1-2 min of clean audio. Works best with v3. Good quality.
- **Professional Clone**: 3+ hours of studio audio. Highest fidelity BUT not fully optimised for v3. Prefer Instant Clones with v3.

### API for searching voices
```
GET https://api.elevenlabs.io/v1/shared-voices?page_size=20&gender=male&language=en&accent=australian&sort=trending
Headers: xi-api-key
```

### Tested voices (as of 2026-03)

| Name | ID | Accent | Style | Notes |
|------|-----|--------|-------|-------|
| Tom | `DYkrAHD8iwork3YSUBbs` | Australian | Easygoing, warm, natural | Podcast host (CHIP). Settings: stability 0.28, style 0.35, speed 1.13. |
| Vivian | `luVEyhT3CocLZaLBps8v` | Australian | Natural, conversational | Podcast co-host (GLITCH). 559M usage/yr. Settings: stability 0.20, style 0.45, speed 1.14. |
| Arabella | `aEO01A4wXwd1O8GPgGlF` | Australian | Young, natural | Tested, not as natural as Vivian. 137k clones. |
| Steve | `aGkVQvWUZi16EH8aZJvT` | Australian | Mid 40s podcaster | Most used Aussie voice (1.2B chars/yr). |
| Hope | `OYTbf65OHHFELVut7v2H` | American | Natural, clear, calm | #1 most used female voice on entire platform. |
| Jessica | `g6xIsTj2HwM6VR4iXFCw` | American | Chatty, friendly | Most cloned female (180k). Very natural. |
| Lucy | `lcMyyd2HUfFzxdCaC4Ta` | British | Fresh, casual | Good for dry/deadpan delivery. |

## Script Writing for TTS

**This is the single biggest lever for natural-sounding output.** Voice settings are fine-tuning. Script writing is the difference between "obviously AI" and "wait, is that a real person?"

### The golden rule
Write for the ear, not the eye. Read every line aloud before generating. If it sounds weird spoken, it'll sound weird from TTS.

### The "listy AI" problem
The #1 reason TTS sounds robotic. LLM-generated text loves lists. TTS reads them with identical cadence per item.

**Bad (listy):**
> "He added 8 skills including an eval framework, productionise, and diagram generation."

**Good (conversational):**
> "Look, he built the eval framework from scratch. Then he just casually dropped productionise and diagram generation like it was nothing."

**The fix pattern:** Pick the headline item, emphasise it, then mention the rest as afterthoughts.

### 10 rules for natural TTS scripts

1. **Short sentences.** Max 15 words. Break long thoughts with periods, not commas.

2. **One idea per sentence.** Don't chain with "and", "while", "which". Split them.

3. **Filler words.** "Look," "Honestly," "I mean," "Right," -- these signal natural speech to the TTS model. Use sparingly but deliberately.

4. **Contractions always.** "He's" not "He is". "Don't" not "Do not". Never use formal expansions.

5. **Emphasise one, gloss the rest.** Don't give three features equal weight. Headline one, mention the others.

6. **Vary sentence length deliberately.** Follow a long sentence with a short one. "He built the entire eval framework from scratch and somehow shipped three more features on top. Unreal." Creates rhythm.

7. **Spell out numbers for speech.** "Over five thousand lines" not "5,340 lines". "Fifty two" not "52". Numbers read robotically.

8. **Fragments are natural.** "Four PRs. Eight skills. The man's on another level." -- TTS handles fragments well.

9. **Questions break monotony.** "And Sam? One PR. One fix." gives TTS a natural inflection point.

10. **Avoid transition words.** Never use "Additionally," "Moreover," "Furthermore," "In conclusion." These are LLM tells. Real people don't talk like that.

### Format numbers and abbreviations
- Write out numbers: "one hundred and twenty three" not "123"
- Write out money: "forty five dollars" not "$45"
- Write out abbreviations: "Doctor" not "Dr."
- Phone numbers: "one two three, four five six"
- Percentages: "ninety five percent" not "95%"
- Acronyms: spell out on first use or they may be mispronounced

### Punctuation as performance markup
TTS engines interpret punctuation as rhythm:
- **Period (.)** -- full stop, natural pause
- **Comma (,)** -- short breathing pause
- **Ellipsis (...)** -- longer pause, hesitation, trailing off. Very effective.
- **Question mark (?)** -- upward inflection
- **Exclamation (!)** -- energy and emphasis
- **Double dash (--)** -- mid-sentence pause, good for asides

## ElevenLabs Audio Tags (v3 only)

Tags go inline in the text. They guide emotional delivery. 1-2 per line max.

### Delivery tags
- `[pause]`, `[short pause]`, `[long pause]` -- timing control
- `[excited]` -- upbeat energy
- `[sarcastic]`, `[deadpan]` -- dry delivery
- `[whispers]`, `[quietly]` -- intimate delivery
- `[rushed]`, `[rapid-fire]` -- faster pacing
- `[slows down]`, `[drawn out]` -- deliberate emphasis
- `[emphasized]`, `[stress on next word]` -- word-level emphasis

### Emotional tags
- `[happy]`, `[sad]`, `[angry]`, `[nervous]`, `[frustrated]`, `[tired]`, `[calm]`
- `[playfully]`, `[annoyed]`, `[flustered]`, `[casual]`, `[flatly]`

### Human reaction tags (realism)
- Laughter: `[laughs]`, `[laughs softly]`, `[giggle]`, `[light chuckle]`
- Sounds: `[sigh]`, `[gulps]`, `[gasps]`, `[clears throat]`
- Volume: `[whispering]`, `[loudly]`, `[shouts]`

### Multi-character dialogue tags
- `[interrupting]`, `[overlapping]`, `[cuts in]`

### Tips
- Place tags at the START of the line for full-line effect
- Mid-sentence placement creates dynamic shifts within the line
- `[pause]` before a sarcastic line creates comedic timing
- `[whispers]` into `[excited]` in the same line = great dynamic range
- Tags work better with community voices than premade
- Tags are v3 exclusive -- other models ignore them
- Professional Voice Clones underperform with tags -- use Instant Clones
- Effects fade over long passages -- reinsert periodically
- Don't stack too many tags in quick succession -- confuses the model

## Multi-Speaker Podcast Production

### Voice pairing
- Contrasting accents work well (Australian + British)
- Contrasting energy works well (warm host + dry co-host)
- Same accent works if voices are tonally different (deep + bright)
- Test the pairing with 2-3 lines before committing to full production

### Natural dialogue techniques
- Write reactions: "Wait, seriously?" / "Exactly!" / "Hmm"
- Write interruptions: one character cuts in (use short/no gap)
- Give each speaker a distinct vocabulary and rhythm
- Include non-verbal cues: `[laughs]`, `[sigh]` between turns
- Avoid clean handoffs -- real conversations overlap

### Silence between speakers (gap timing)
- **Standard turn**: 250-400ms (natural conversation pace)
- **Interruption/reaction**: 50-100ms (creates energy, feels like cutting in)
- **Topic shift**: 400-600ms (gives the listener a beat to process)
- **Dramatic pause**: 600ms+ (use sparingly for emphasis)
- Too short throughout (<200ms) = sounds like they're talking over each other
- Too long throughout (>600ms) = sounds like awkward dead air
- **Vary the gaps** -- uniform gaps sound robotic. Match gap to the moment.

### Sound effects (ElevenLabs Sound Generation API)
```
POST https://api.elevenlabs.io/v1/sound-generation
Headers: xi-api-key, Content-Type: application/json

{"text": "short retro 8-bit video game jingle, upbeat, 3 seconds", "duration_seconds": 3}
```
Returns: MP3 audio bytes. Use for jingles, transitions, comedy beats.

### Concatenation (local ffmpeg)
pydub and ffmpeg are NOT available in the Relevance AI Python runtime. Do concatenation locally.

```bash
# Generate silence files for each gap duration
ffmpeg -y -f lavfi -i anullsrc=r=44100:cl=mono -t 0.3 -q:a 9 silence_300ms.mp3

# Build concat list (interleave audio + gaps)
printf "file 'line_01.mp3'\nfile 'silence_300ms.mp3'\nfile 'line_02.mp3'\n..." > files.txt

# Concatenate
ffmpeg -y -f concat -safe 0 -i files.txt -c:a libmp3lame -q:a 2 output.mp3

# Check duration
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 output.mp3
```

### Post-processing
- **Loudness normalisation**: Target -16 LUFS (stereo) or -19 LUFS (mono)
  ```bash
  ffmpeg -i input.mp3 -af loudnorm=I=-16:TP=-1.5:LRA=11 output.mp3
  ```
- **Normalise each speaker independently** before combining so they have consistent volume
- **Gentle compression** (2:1-4:1 ratio) evens out loud consonants and quiet moments
- **Consistent EQ** across all speakers so they sound like they're in the same room

## API Reference

### Generate speech
```
POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}
Headers: xi-api-key, Content-Type: application/json

{
  "text": "Your text here",
  "model_id": "eleven_v3",
  "speed": 1.12,
  "voice_settings": {
    "stability": 0.28,
    "similarity_boost": 0.8,
    "style": 0.35,
    "use_speaker_boost": true
  }
}
```
Returns: MP3 audio bytes

### Generate sound effects
```
POST https://api.elevenlabs.io/v1/sound-generation
Headers: xi-api-key, Content-Type: application/json

{"text": "description of the sound", "duration_seconds": 3}
```
Returns: MP3 audio bytes

### Search community voices
```
GET https://api.elevenlabs.io/v1/shared-voices?page_size=20&gender=male&language=en&accent=australian&sort=trending
Headers: xi-api-key
```

### List your voices
```
GET https://api.elevenlabs.io/v1/voices
Headers: xi-api-key
```

## Cost

- Credits scale with character count
- ~25-30 credits per short line (under 50 chars)
- ~100-150 credits per longer line (100-150 chars)
- Sound effects: ~50-100 credits per generation
- A 14-19 line podcast with SFX costs roughly 1500-2500 credits
- eleven_v3 costs more per character than v2 but sounds dramatically better
- Some community voices have credit multipliers (2-3x) -- check before committing

## Common Mistakes

1. **Feeding raw LLM output to TTS** -- LLM text is optimised for reading, not listening. Always rewrite for speech.
2. **Lists with identical cadence** -- Convert bullet points to flowing prose.
3. **Uniform sentence length** -- Creates a metronome effect. Vary deliberately.
4. **Ignoring punctuation** -- TTS relies on punctuation for rhythm. Missing commas = breathless delivery.
5. **Wrong voice for content** -- Corporate narrator for casual content sounds immediately wrong.
6. **Skipping post-processing** -- Raw TTS has volume inconsistencies and awkward gaps.
7. **Professional Clones with v3** -- Not fully optimised. Use Instant Clones instead.
8. **Overusing audio tags** -- Too many in quick succession confuses the model.
9. **Not testing iteratively** -- Different voices handle the same text differently. Generate, listen, adjust.
10. **Writing acronyms without expansion** -- "API" may read as "appy". Spell out or use phonetic guidance.

## Gotchas

- Community voices auto-add to your library on first use. First call may be slower.
- Quota is per API key, not per voice. Monitor usage.
- pydub and ffmpeg are NOT available in Relevance AI Python runtime. Concatenate locally.
- Rate limits: Don't fire parallel requests for the same voice. Sequential with 0.3-0.5s delay is safe.
- Temp URLs from Relevance AI expire. Download audio promptly.
- Audio tags are v3 exclusive. Other models silently ignore them.
