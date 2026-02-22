# -----------------------------
# Base Image - Ubuntu
# -----------------------------
FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# -----------------------------
# 1. Install LaTeX + Tools + Python
# -----------------------------
RUN apt-get update && apt-get install -y \
        texlive-latex-base \
        texlive-latex-recommended \
        texlive-latex-extra \
        texlive-fonts-recommended \
        texlive-pictures \
        texlive-science \
        latexmk \
        git \
        zsh \
        curl \
        bash \
        sudo \
        ca-certificates \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

# -----------------------------
# 2. Install uv CLI
# -----------------------------
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    mv /root/.local/bin/uv* /usr/local/bin/ && \
    chmod +x /usr/local/bin/uv

# -----------------------------
# 3. Create User and Workspace
# -----------------------------
RUN useradd -m -s /bin/zsh texuser && \
    mkdir -p /workspace && \
    chown -R texuser:texuser /workspace

USER texuser
WORKDIR /workspace

# -----------------------------
# 4. Create Python 3.11 venv and Install Packages
# -----------------------------
ENV PATH="/home/texuser/.local/bin:$PATH"

RUN uv venv --python 3.11 && \
    uv pip install matplotlib scipy numpy sympy && \
    echo 'source /workspace/.venv/bin/activate' >> ~/.zshrc

# -----------------------------
# 5. Install Zotero MCP Server
# -----------------------------
RUN uv tool install "git+https://github.com/54yyyu/zotero-mcp.git"

# No CMD needed — stateless, run per-compile
