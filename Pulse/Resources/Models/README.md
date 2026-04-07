# LLM Models

This directory contains the GGUF model files required for on-device AI features (Daily Digest and Article Summarization).

## Required Model

**Gemma 4 E2B Instruct (Q4_K_M quantization)**

- **Filename**: `gemma-4-E2B-it-Q4_K_M.gguf`
- **Size**: ~3.1 GB
- **Source**: [Hugging Face](https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF)

## Download

```bash
huggingface-cli download unsloth/gemma-4-E2B-it-GGUF \
  --include "gemma-4-E2B-it-Q4_K_M.gguf" \
  --local-dir Pulse/Resources/Models/
```

Or download manually from the Hugging Face link above and place the file in this directory.

## Why Not Committed?

Model files are excluded from version control (`.gitignore`) due to their large size. Each developer must download the model locally.

## Verification

After downloading, verify the file exists:

```bash
ls -lh Pulse/Resources/Models/*.gguf
```

The app will show an error if the model is missing when accessing AI features.
