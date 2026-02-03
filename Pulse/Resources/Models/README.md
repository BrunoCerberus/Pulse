# LLM Models

This directory contains the GGUF model files required for on-device AI features (Daily Digest and Article Summarization).

## Required Model

**Llama 3.2 1B Instruct (Q4_K_M quantization)**

- **Filename**: `Llama-3.2-1B-Instruct-Q4_K_M.gguf`
- **Size**: ~770 MB
- **Source**: [Hugging Face](https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF)

## Download

```bash
curl -L -o Pulse/Resources/Models/Llama-3.2-1B-Instruct-Q4_K_M.gguf \
  "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf"
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
