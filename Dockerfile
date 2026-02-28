# -----------------------------
# Base Image - Ubuntu
# -----------------------------
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# -----------------------------
# Install LaTeX + Tools
# -----------------------------
RUN apt-get update && apt-get install -y \
        texlive-latex-base \
        texlive-latex-recommended \
        texlive-latex-extra \
        texlive-fonts-recommended \
        texlive-fonts-extra \
        texlive-pictures \
        texlive-science \
        texlive-bibtex-extra \
        biber \
        latexmk \
        git \
        bash \
        ca-certificates \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Create User and Workspace
# -----------------------------
RUN useradd -m -s /bin/bash texuser && \
    mkdir -p /workspace && \
    chown -R texuser:texuser /workspace

USER texuser
WORKDIR /workspace