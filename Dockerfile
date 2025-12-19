# 1. Use a lightweight, modern base (Debian 11 Bullseye)
# This removes the "Double GHC" issue and the need for EOL hacks.
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# 2. Install dependencies
# We combine everything into one RUN command to reduce image layers.
RUN apt-get update && apt-get install -y \
    zsh \
    curl \
    git \
    sudo \
    build-essential \
    libffi-dev \
    libgmp-dev \
    libncurses-dev \
    libtinfo-dev \
    zlib1g-dev \
    libssl-dev \
    # Cleanup apt cache immediately
    && rm -rf /var/lib/apt/lists/*

# 3. Create 'vscode' user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME -s /bin/zsh \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# 4. Install Starship & Just
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y \
    && curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# 5. Switch to user
USER $USERNAME
WORKDIR /home/$USERNAME

# 6. Install GHCup, GHC, Stack, and HLS
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
ENV BOOTSTRAP_HASKELL_GHC_VERSION=9.4.8
ENV BOOTSTRAP_HASKELL_INSTALL_STACK=1
ENV BOOTSTRAP_HASKELL_INSTALL_HLS=1
ENV PATH="/home/vscode/.ghcup/bin:$PATH"

# OPTIMIZATION: We chain the install with the cleanup commands
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh \
    # Remove the massive download cache (~1-2GB saved)
    && ghcup gc --cache \
    # Manually remove any leftover temp files
    && rm -rf /home/vscode/.ghcup/cache/* \
    && rm -rf /home/vscode/.ghcup/tmp/*

# 7. Configure Zsh
RUN echo 'eval "$(starship init zsh)"' >> ~/.zshrc \
    && git clone https://github.com/zsh-users/zsh-autosuggestions /home/vscode/.oh-my-zsh/custom/plugins/zsh-autosuggestions 2>/dev/null || true \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/vscode/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting 2>/dev/null || true
