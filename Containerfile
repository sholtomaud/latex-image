# -----------------------------
# Base Image - Ubuntu
# -----------------------------
FROM ubuntu:24.04

# The article glosses over *why* their images took this long to build/were this large. It sounds like:
# 1. Lack of layer caching at build time
# 2. No slim images (alpine or otherwise depending on workload)
# 3. Unoptimized docker build process leading to build artifacts/wheel/sources being left on final image (I cut a client's python docker container by ~75% last month with very simple changes. Same applies for nodejs images)


ENV DEBIAN_FRONTEND=noninteractive

# -----------------------------
# Install LaTeX + Tools
# -----------------------------
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
        texlive-extra-utils \
        texlive-xetex \
        pandoc \
        libyaml-tiny-perl \
        libfile-homedir-perl \
        libunicode-linebreak-perl \
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