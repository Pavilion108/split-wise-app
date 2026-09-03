# Splitwiser-26 — AI Raster Couch Character Motion (short rect)
# Run in Google Colab: Runtime -> Run all
# Generates 3 images -> converts to motion via Ken Burns + exports as replacement for assets/animations/coffee_character.png sequence

# Cell 1
!pip install -q huggingface_hub Pillow moviepy

# Cell 2
import os, time, numpy as np
from huggingface_hub import InferenceClient
from PIL import Image
from moviepy.editor import ImageClip, CompositeVideoClip, concatenate_videoclips, ColorClip

HF_TOKEN = "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"
OUT = "/content/character_motion"
os.makedirs(OUT, exist_ok=True)
client = InferenceClient(token=HF_TOKEN)

# Three states for the small motion rect
STATES = [
  ("idle", "cute cartoon character developer slouched on couch resting tired about to sleep, eyes half closed, holding empty mug, flat vector, soft pastel, transparent background not needed, 512x512, kawaii", 2.5),
  ("attend", "same cute cartoon character sitting up attentive on couch, looking at viewer, holding mug forward offering, flat vector, bright, 512x512, kawaii", 1.2),
  ("cheers", "same character sipping coffee and cheering with sparkles, happy smile, thumbs up, flat vector, celebration confetti, 512x512, kawaii", 1.8),
]

def gen(prompt, name):
    print(f"Generating {name}...")
    for model in ["black-forest-labs/FLUX.1-schnell", "stabilityai/stable-diffusion-xl-base-1.0"]:
        try:
            img = client.text_to_image(prompt, model=model)
            p = os.path.join(OUT, f"{name}.png")
            img.save(p)
            print(f"  OK {p}")
            return p
        except Exception as e:
            print(f"  {model} failed: {e}")
    # fallback colored
    img = Image.new('RGB', (512,512), (240,240,255))
    p = os.path.join(OUT, f"{name}.png")
    img.save(p)
    return p

paths = []
for name, prompt, dur in STATES:
    paths.append((gen(prompt, name), dur))
    time.sleep(1)

# Cell 3 — Build looping motion rect (small area, 140x140 display)
from moviepy.editor import ImageClip
clips = []
for (p, dur) in paths:
    img = Image.open(p).resize((512,512), Image.LANCZOS)
    arr = np.array(img)
    clip = ImageClip(arr, duration=dur)
    # subtle zoom for motion
    clip = clip.resize(lambda t: 1 + 0.06 * (t/dur))
    clips.append(clip)

# idle loops twice for idle feel
final = concatenate_videoclips([clips[0], clips[1], clips[2], clips[0]], method="compose")
final.write_videofile("/content/coffee_character_motion.mp4", fps=12, codec="libx264", audio=False, preset="ultrafast")
print("Done: /content/coffee_character_motion.mp4 — download and place frames as assets/animations/coffee_character.png sequence or use mp4 via video_player")

from google.colab import files
files.download("/content/coffee_character_motion.mp4")
for p,_ in paths:
    files.download(p)
