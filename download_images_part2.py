import urllib.request
import os
import shutil

images = {
    "categories/football.jpg": "https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=400",
    "categories/badminton.jpg": "https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?q=80&w=400",
    "categories/tennis.jpg": "https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=400",
    "categories/pickleball.jpg": "https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?q=80&w=400",
    "categories/basketball.jpg": "https://images.unsplash.com/photo-1519861531473-9200262188bf?q=80&w=400",
    "categories/volleyball.jpg": "https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?q=80&w=400", # reusing pickleball/net sport as fallback
    "community/team-01.jpg": "https://images.unsplash.com/photo-1526232761682-d26e03ac148e?q=80&w=600",
    "app/app-mockup.png": "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?q=80&w=600",
}

base_dir = "/home/nhan/Downloads/V-SPORT/src/main/webapp/assets/images/vsport/"
for path, url in images.items():
    full_path = os.path.join(base_dir, path)
    if not os.path.exists(full_path):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req) as response, open(full_path, "wb") as out_file:
                out_file.write(response.read())
            print(f"Downloaded {path}")
        except Exception as e:
            print(f"Error downloading {path}: {e}")
            # Fallback to a local file if network fails
            fallback = os.path.join(base_dir, "hero/hero-player.jpg")
            if os.path.exists(fallback):
                shutil.copy(fallback, full_path)
