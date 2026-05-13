# Rolex7exe TikTok Tweak

This repository contains a Theos tweak that targets TikTok's BHTikTok settings UI.

## What it does

- Rebrands `BHTikTok`, `BHTikTok Plus`, and `BHTikTok++` texts to `rolex7exe`.
- Removes or disables developer-area link rows (Telegram, GitHub, X, Buy Me a Coffee, Boosty).
- Blocks outbound URL opens to those developer-link domains as a fallback.

## Build

1. Install Theos on your macOS/iOS build environment.
2. Run:

```bash
make package
```

The generated tweak binary is produced by Theos in the build output (for example under `.theos/obj` and inside the generated `.deb` package).
