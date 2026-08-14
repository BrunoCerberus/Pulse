# LLM Models

This directory is reserved for local development copies of the GGUF model used by on-device AI features. The model is not included in the App Store bundle.

## Required Model

**Gemma 3 1B Instruct (Q4_K_M quantization)**

- **Filename**: `gemma-3-1b-it-Q4_K_M.gguf`
- **Size**: ~806 MB (806,058,496 bytes)
- **Source**: [Hugging Face](https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF)

Gemma is provided under and subject to the Gemma Terms of Use found at [ai.google.dev/gemma/terms](https://ai.google.dev/gemma/terms).

## Optional local inspection

```bash
huggingface-cli download bartowski/google_gemma-3-1b-it-GGUF \
  --include "gemma-3-1b-it-Q4_K_M.gguf" \
  --local-dir Pulse/Resources/Models/
```

The app does not read this source directory in production. The command is only for local inspection or checksum verification; no manual model setup is required to run the app.

## Runtime behavior

Production builds exclude this directory from the app target. When a user explicitly starts an AI feature, Pulse downloads the pinned file into Application Support only over Wi-Fi or another unconstrained network. Before downloading, it checks for sufficient free storage. The transfer is resumable, and the completed file is verified against its expected size and SHA-256 before it is used. A small verification record avoids hashing the full 806 MB file on every cold launch. Background preloaders may warm a verified local copy, but never initiate the first-use download.

## Why Not Committed?

Model files are excluded from version control (`.gitignore`) due to their large size. The runtime copy is kept in the app's Application Support directory and excluded from device backups.

## Verification

After downloading, verify the file exists:

```bash
ls -lh Pulse/Resources/Models/*.gguf
```

The app downloads the model when an AI feature is explicitly started. If the download is interrupted, Pulse keeps resume data for a later retry; if the completed file fails verification, it is discarded and the user can retry the feature.
