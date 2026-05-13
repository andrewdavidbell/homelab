# Kokoro TTS (Text-to-Speech)

Fast, high-quality text-to-speech using the Kokoro-82M model with 67 voices across multiple languages.

## Access

- **Web Interface**: `https://kokoro.home.arpa/web` - FastKoko UI
- **API Documentation**: `https://kokoro.home.arpa/docs` - Interactive Swagger UI
- **API Endpoint**: `https://kokoro.home.arpa/v1` (external) or `http://kokoro-tts:8880/v1` (internal)

## Features

- **Beautiful Web Interface**: FastKoko UI with waveform visualisation
- **67 Voices**: Multiple languages including English, Mandarin, Hindi, Japanese, French, German
- **Adjustable Speed**: 0.1x to 4.0x playback speed
- **OpenAI-Compatible API**: Drop-in replacement for OpenAI TTS
- **Audio Download**: Save generated speech as MP3, WAV, OPUS, or FLAC
- **CPU Optimised**: Lightweight 82M parameter model runs efficiently on CPU

## FastKoko Web Interface

The web UI at `/web` provides the easiest way to use Kokoro:

### Getting Started

1. Open `https://kokoro.home.arpa/web`
2. Type or paste your text into the editor
3. Search and select a voice (or use the default `af_heart`)
4. Click **Play** to generate and hear the speech
5. Download the audio if needed

### Features

- **Text Editor**: Enter any text for synthesis
- **Voice Search**: Filter through 67 voices by name or characteristics
- **Waveform Visualisation**: See audio as it plays
- **Speed Control**: Adjust playback speed (0.1x - 4.0x)
- **Language Selection**: Auto-detect or manually specify language
- **Audio Player**: Play, pause, seek, and adjust volume
- **Download**: Save audio in multiple formats

## Available Voices

### Popular English Voices

**American Female**:
- `af_heart` - Natural, warm (default, recommended)
- `af_bella` - Warm and friendly
- `af_sarah` - Professional
- `af_jessica` - Clear
- `af_nicole` - Expressive
- `af_sky` - Bright

**American Male**:
- `am_adam` - Authoritative
- `am_michael` - Friendly
- `am_eric` - Clear
- `am_onyx` - Deep

**British Female**:
- `bf_emma` - Clear RP accent
- `bf_alice` - Refined
- `bf_lily` - Gentle

**British Male**:
- `bm_george` - Sophisticated
- `bm_lewis` - Professional
- `bm_daniel` - Authoritative

### Other Languages

- **Mandarin**: `zf_xiaobei`, `zf_xiaoni`, `zf_xiaoxiao`, `zf_xiaoyi`, `zm_*`
- **Hindi**: `hf_alpha`, `hf_beta`, `hm_omega`, `hm_psi`
- **Japanese**: `jf_alpha`, `jf_gongitsune`, `jm_kumo`
- **French**: `ff_siwis`
- **Spanish**: `ef_dora`
- **Italian**: `if_sara`, `im_nicola`
- **Polish**: `pf_dora`, `pm_alex`

**Full list**: [View all 67 voices](https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md)

## API Usage

### List Available Voices

```bash
curl -sk https://kokoro.home.arpa/v1/audio/voices | jq -r '.voices'
```

### Generate Speech

```bash
curl -sk -X POST https://kokoro.home.arpa/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kokoro",
    "input": "Hello, this is Kokoro text-to-speech.",
    "voice": "af_heart",
    "response_format": "mp3",
    "speed": 1.0
  }' \
  --output speech.mp3
```

### Supported Formats

- `mp3` - Most compatible
- `wav` - Uncompressed, highest quality
- `opus` - Efficient compression
- `flac` - Lossless compression

### Speed Control

- `0.1` to `4.0` - Adjust playback speed
- `1.0` - Normal speed (default)
- `<1.0` - Slower (e.g., 0.75 for clearer speech)
- `>1.0` - Faster (e.g., 1.5 for quick summaries)

## OpenWebUI Integration

Configure Kokoro as the TTS engine for OpenWebUI:

### 1. Configure TTS Settings

1. Navigate to `https://openwebui.home.arpa`
2. Go to **Settings** → **Audio**
3. Configure TTS:
   - **TTS Engine**: OpenAI
   - **API Base URL**: `http://kokoro-tts:8880/v1`
   - **API Key**: `dummy-key` (not validated by Kokoro)
   - **TTS Model**: `kokoro`
   - **TTS Voice**: Select your preferred voice (e.g., `af_heart`)

### 2. Use in Chats

Once configured, OpenWebUI will use Kokoro to:
- Read AI responses aloud
- Convert any message to speech
- Provide natural-sounding voice output

**Important**: OpenWebUI communicates with Kokoro internally via HTTP (`http://kokoro-tts:8880/v1`), but when accessing the Kokoro web interface from your browser, use HTTPS (`https://kokoro.home.arpa/web`).

## Data Persistence

Voice models are cached in:
```
./data/kokoro/
```

The container pre-includes all voice models (~5GB image size), so first-time usage is immediate.

## Troubleshooting

### Can't Access Web Interface

1. **Check container is running**:
   ```bash
   docker compose ps kokoro-tts
   docker logs kokoro-tts --tail 50
   ```

2. **Test the web interface** (note: use HTTPS):
   ```bash
   open https://kokoro.home.arpa/web
   ```

3. **Verify hosts file**:
   ```bash
   grep kokoro /etc/hosts
   ```

### Certificate Errors

Kokoro uses HTTPS via Caddy's internal certificates:

- **Solution 1**: Trust the Caddy CA certificate (see [Networking Guide](../setup/networking.md))
- **Solution 2**: Accept the security exception in your browser
- **For curl**: Use `-k` flag to skip verification: `curl -sk https://...`

### OpenWebUI Can't Connect to Kokoro

1. **Verify Kokoro is running**:
   ```bash
   docker compose ps kokoro-tts
   ```

2. **Test API endpoint**:
   ```bash
   curl -sk https://kokoro.home.arpa/v1/audio/voices
   ```

3. **Check OpenWebUI settings**:
   - API Base URL must be `http://kokoro-tts:8880/v1` (internal container communication)
   - NOT `localhost`, NOT `https`
   - TTS Engine: "OpenAI"
   - TTS Model: "kokoro"

4. **Test connectivity from OpenWebUI container**:
   ```bash
   docker exec openwebui curl -s http://kokoro-tts:8880/v1/audio/voices
   ```

### Audio Quality Issues

- **Speech too fast**: Reduce speed to 0.75 or 0.8
- **Unclear pronunciation**: Try a different voice (some handle accents better)
- **Unnatural pauses**: Kokoro processes text intelligently but may struggle with unusual formatting

### Performance Issues

Kokoro is CPU-optimised but may be slower for long texts:

- **Long texts**: Break into smaller chunks
- **Real-time streaming**: Kokoro doesn't support streaming; full audio is generated first
- **Consider GPU version**: If you have NVIDIA GPU, use `ghcr.io/remsky/kokoro-fastapi-gpu:latest` for faster generation

## API Documentation

Interactive API documentation is available at:
```
https://kokoro.home.arpa/docs
```

This Swagger UI allows you to:
- View all endpoints
- Test API calls interactively
- See request/response schemas
- Explore voice options

## Advanced Usage

### Batch Processing

Generate multiple audio files:

```bash
#!/bin/bash
voices=("af_bella" "am_michael" "bf_emma")

for voice in "${voices[@]}"; do
  curl -sk -X POST https://kokoro.home.arpa/v1/audio/speech \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"kokoro\",\"input\":\"Hello world\",\"voice\":\"$voice\"}" \
    --output "${voice}.mp3"
done
```

### Language-Specific Synthesis

Kokoro auto-detects language but you can specify:

```json
{
  "model": "kokoro",
  "input": "你好世界",
  "voice": "zf_xiaobei",
  "language": "zh"
}
```

### Integration with Other Tools

Kokoro's OpenAI-compatible API works with:
- LangChain
- LlamaIndex
- Custom scripts expecting OpenAI TTS format

## Related Documentation

- [OpenWebUI Configuration](openwebui.md)
- [Initial Setup Guide](../setup/initial-setup.md)
- [Troubleshooting Guide](../troubleshooting.md)
