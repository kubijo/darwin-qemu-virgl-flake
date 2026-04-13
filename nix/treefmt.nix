# treefmt-nix configuration. Covers every file type this repo actually contains:
#   - .nix      via nixfmt
#   - .yaml/.yml via Google's yamlfmt
#   - .md       via mdformat with GFM, frontmatter, and soft-break plugins
{ ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    nixfmt.enable = true;
    yamlfmt.enable = true;

    mdformat = {
      enable = true;
      # GFM tables/strikethrough/autolinks/task-lists + frontmatter +
      # soft-break passthrough. Plugins auto-activate their extensions when
      # loaded — no `--extensions=` flag needed.
      plugins = p: [
        p.mdformat-gfm
        p.mdformat-frontmatter
        p.mdformat-simple-breaks
      ];
    };
  };

  settings = {
    global.excludes = [
      "*.lock"
      "*.patch"
      "LICENSE"
      ".gitignore"
      "result"
      "result-*"
    ];

    formatter.mdformat.options = [
      "--number"
      "--wrap=120"
    ];
  };
}
