# `promptkit-os` (npm)

The **courier**, not the product. PromptKit OS itself is pure markdown with no runtime, no daemon, and no model lock-in — it lives at [lowqualityloey/promptkit-os](https://github.com/lowqualityloey/promptkit-os).

This package does one thing: fetch the GitHub release tarball that matches its own version, extract it into `./.promptkit/`, and run the canonical `init.sh` (POSIX) or `init.ps1` (Windows). All installation logic stays in the fetched repository; nothing is reimplemented here.

## Install

```bash
npx promptkit-os@latest                 # interactive picker when in a TTY
npx promptkit-os@latest --balanced      # explicit profile
npx promptkit-os@latest --lite
npx promptkit-os@latest --turbo --experimental
npx promptkit-os@latest /path/to/project
```

Pass-through flags: `--lite`, `--balanced`, `--turbo`, `--experimental`, `--host=`, `--target=`, `--tracking=`, `--reconfigure`.

Requires Node 18+ (the courier runs on Node; the installed product does not). On Windows it also requires **PowerShell 7 (`pwsh`)**, which is what `init.ps1` targets — stock Windows PowerShell 5.1 is not supported.

## Updating an existing install

If `.promptkit/` already exists and is not empty, the courier **refuses to overlay it** — a tarball merge can leave stale files behind and mix delivery doors. The right update path depends on how it was installed:

```bash
# git-submodule install
git submodule update --remote --merge .promptkit && bash .promptkit/init.sh

# courier install (tarball is pinned per version — replace it)
rm -rf .promptkit
npx promptkit-os@latest --balanced
```

The courier detects which case applies (a submodule install has `.promptkit/.git`) and prints the matching command. `--force` overlays anyway, but it is not recommended.

## Version pinning

`npx promptkit-os@X.Y.Z` fetches release tag `vX.Y.Z` and never a moving ref, so a given install is reproducible forever.

## Removal

Delete `.promptkit/` — plus the generated `PROMPTKIT.md` and `docs/STATE.md` if you don't want them. No daemon, no cache, no registration, nothing left behind.

## Which path should I use?

The git submodule flow remains canonical and is documented first in the [README](https://github.com/lowqualityloey/promptkit-os#readme) and [QUICKSTART](https://github.com/lowqualityloey/promptkit-os/blob/main/QUICKSTART.md). Use npm when you want a one-command install without submodule ceremony; the resulting `.promptkit/` tree is identical either way.

## License

MIT. Not affiliated with `microsoft/PromptKit` or `erikgeiser/promptkit`.
