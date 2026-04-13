_default:
    @just --list

# Build the QEMU binary (default flake output)
build:
    nix build -L

# Run qemu-system-aarch64 with forwarded args
run *args:
    nix run -L . -- {{ args }}

# Run all flake checks (formatting + patch-apply tests)
check:
    nix flake check -L

# Verify the vendored patches still apply against pinned sources
check-patches:
    nix build -L \
      .#checks.aarch64-darwin.patches-apply-qemu-akihikodaki \
      .#checks.aarch64-darwin.patches-apply-qemu-skip-macos-icon \
      .#checks.aarch64-darwin.patches-apply-libepoxy-libgl-path \
      .#checks.aarch64-darwin.patches-apply-libepoxy-akihikodaki \
      --no-link

# Format all files (.nix via nixfmt, .md via mdformat with GFM)
format:
    nix fmt

# Update all pinned flake inputs to their latest revisions
update:
    nix flake update

# Show the current pin for each input
pins:
    @nix flake metadata --json | jq -r '.locks.nodes | to_entries[] | select(.value.locked) | "\(.key): \(.value.locked.rev // .value.locked.url // .value.locked.narHash)"'
