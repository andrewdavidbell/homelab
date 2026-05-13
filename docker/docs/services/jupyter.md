# Jupyter Notebook

Interactive Python notebook environment for data science and machine learning experimentation.

## Access

- **URL**: `https://jupyter.home.arpa` or `https://jupyter`
- **Authentication**: Token-based (see below)

## Features

- **JupyterLab Interface**: Modern web-based IDE
- **Scientific Python Stack**: Pre-installed NumPy, SciPy, Pandas, Matplotlib
- **Persistent Workspace**: Notebooks saved in `./data/jupyter/`
- **Package Management**: Install additional packages via pip/conda
- **Code Interpreter Backend**: Can be used by OpenWebUI for AI code execution

## Getting Started

### 1. Find Your Token

Your Jupyter token is required for authentication:

```bash
# Method 1: Check logs
docker logs jupyter 2>&1 | grep "token="

# Method 2: Check .env file
cat .env | grep JUPYTER_TOKEN
```

### 2. Access JupyterLab

Open `https://jupyter.home.arpa` and either:
- Enter the token when prompted, or
- Use direct URL: `https://jupyter.home.arpa/?token=YOUR_TOKEN`

### 3. Create Your First Notebook

1. Click **File** → **New** → **Notebook**
2. Select **Python 3** kernel
3. Start coding!

All notebooks are saved in `./data/jupyter/work/` and persist across container restarts.

## Code Interpreter Integration

OpenWebUI's Code Interpreter feature allows AI models to autonomously write and execute Python code. You can configure it to use your Jupyter instance for powerful, persistent code execution.

### Configuration

**1. Configure in OpenWebUI Admin Panel**

1. Navigate to `https://openwebui.home.arpa`
2. Go to **Admin Panel** → **Settings** → **Code Execution**
3. Configure Code Interpreter settings:
   - **Engine**: Select **Jupyter** (instead of Pyodide)
   - **Jupyter Server URL**: `http://jupyter:8888`
   - **Jupyter Token**: Copy from your `.env` file

**2. Enable Per Chat**

In any OpenWeb UI chat:
- Toggle the **Code Interpreter** switch in the chat controls
- AI can now use the `execute_code` tool automatically

### What You Can Do

With Code Interpreter enabled, the AI can:

- **Data Analysis**: Upload CSV/Excel files and ask AI to analyse them
- **Visualisation**: Generate matplotlib, seaborn, or plotly charts
- **File Processing**: Read, transform, and save files
- **Package Installation**: AI can `pip install` required packages
- **Persistent Context**: Variables and imports persist across code blocks in the same chat

### Example Usage

```
You: "I've uploaded sales.csv. Show me the top 5 products by revenue
     with a bar chart."

AI: [Automatically executes code in Jupyter]
    import pandas as pd
    import matplotlib.pyplot as plt

    df = pd.read_csv('sales.csv')
    top_products = df.groupby('product')['revenue'].sum().nlargest(5)

    plt.figure(figsize=(10, 6))
    top_products.plot(kind='bar')
    plt.title('Top 5 Products by Revenue')
    plt.ylabel('Revenue')
    plt.show()
```

The AI writes, executes, and displays the results automatically.

### Jupyter vs Pyodide

Choose the right backend for your needs:

| Feature | Jupyter | Pyodide |
|---------|---------|---------|
| **Execution Location** | Server-side (container) | Browser-side |
| **Context Persistence** | ✅ Variables persist between blocks | ❌ Isolated per execution |
| **Package Support** | ✅ Full Python ecosystem | ⚠️ Limited browser packages |
| **Performance** | ✅ Fast (server CPU/RAM) | ⚠️ Slower (browser limits) |
| **Filesystem Access** | ✅ Full container access | ⚠️ Virtual filesystem only |
| **Multi-user Security** | ❌ Shared instance | ✅ Sandboxed per user |
| **File Uploads** | ✅ Direct access | ⚠️ Limited integration |

**Recommendation**:
- **Jupyter**: Single-user, data science workflows, complex analysis
- **Pyodide**: Multi-user deployments, untrusted queries, simple scripts

### Security Considerations

⚠️ **Important Security Notes**:

- **Full Filesystem Access**: Jupyter gives AI access to the entire container filesystem
- **Shared Instance**: Single Jupyter instance shared across all OpenWebUI users (no isolation)
- **Trusted Models Only**: Only use with models and queries you trust
- **No Sandboxing**: AI-generated code runs with full container permissions

**For Production**: Consider using Pyodide for better isolation in multi-user scenarios.

**Note**: Jupyter is marked as "legacy" in recent OpenWebUI versions, though it remains more powerful for single-user data science work.

## Data Persistence

All Jupyter data is stored in:
```
./data/jupyter/
```

Your notebooks and files in `/home/jovyan/work/` inside the container map to this directory on your host.

## Troubleshooting

### Can't Access Jupyter

1. Check the service is running:
   ```bash
   docker compose ps jupyter
   docker logs jupyter --tail 50
   ```

2. Verify hosts file entry:
   ```bash
   grep jupyter /etc/hosts
   ```

### Token Issues

If you've lost your token:

```bash
# View the token in logs
docker logs jupyter 2>&1 | grep "token="

# Or regenerate by restarting
docker compose restart jupyter
docker logs jupyter 2>&1 | grep "token="
```

Your `.env` file also contains the `JUPYTER_TOKEN`.

### Code Interpreter Not Working

**Symptoms**: AI says it executed code but nothing happens, or "Execution timeout exceeded" errors.

**Solutions**:

1. **Verify Jupyter is running**:
   ```bash
   docker compose ps jupyter
   docker logs jupyter --tail 50
   ```

2. **Check OpenWebUI settings**:
   - Admin Panel → Settings → Code Execution
   - Engine: "Jupyter"
   - URL: `http://jupyter:8888` (not `localhost` or `https`)
   - Token: Must match `.env` file exactly

3. **Enable Code Interpreter in chat**:
   - Toggle the Code Interpreter switch
   - Look for "Analysed" indicators when code executes

4. **Test Jupyter connectivity**:
   ```bash
   # From OpenWebUI container
   docker exec openwebui curl -s http://jupyter:8888/api
   ```

5. **Restart both services**:
   ```bash
   docker compose restart jupyter openwebui
   ```

### Code Not Persisting Between Blocks

This is expected behaviour with **Pyodide** engine. Switch to **Jupyter** engine in Code Execution settings for persistent context (variables and imports remain between code blocks).

### Kernel Crashes

If Jupyter kernel becomes unresponsive:

1. Restart the kernel in JupyterLab: **Kernel** → **Restart Kernel**
2. Or restart the entire service: `docker compose restart jupyter`

### Package Installation

To pre-install packages for all sessions:

```bash
# Enter the container
docker exec -it jupyter bash

# Install packages
pip install package-name

# Or create a requirements.txt and rebuild
```

Alternatively, let the AI install packages as needed (they persist in the container).

## Advanced Usage

### Custom Python Environments

The jupyter/scipy-notebook image comes with conda. You can create custom environments:

```bash
docker exec -it jupyter bash
conda create -n myenv python=3.11
conda activate myenv
pip install your-packages
```

Then select the environment kernel in JupyterLab.

### Extensions

Install JupyterLab extensions:

```bash
docker exec -it jupyter bash
pip install jupyterlab-extension-name
```

### Resource Limits

Add resource limits in `compose.yml`:

```yaml
jupyter:
  # ... existing config
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 4G
```

## Related Documentation

- [OpenWebUI Integration](openwebui.md)
- [Initial Setup Guide](../setup/initial-setup.md)
