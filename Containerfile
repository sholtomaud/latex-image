FROM ubuntu:24.04

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

# Keep the machine VM alive. The host user is created automatically by
# container machine; no manual user setup needed.
CMD ["sleep", "infinity"]
