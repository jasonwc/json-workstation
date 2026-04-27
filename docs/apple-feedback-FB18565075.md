# Apple Feedback draft — SIGCHLD lost wakeup on macOS 26 (rdar://FB18565075)

Draft writeup and filing instructions for an Apple Feedback Assistant report
about the `sigsuspend(2)` SIGCHLD lost-wakeup bug that hangs interactive zsh
inside tmux on macOS 26 (Tahoe). This is the bug that drove the workarounds
in `modules/home/zsh.nix` (custom starship/direnv hooks, pre-baked zcompdump,
`enableCompletion = !pkgs.stdenv.isDarwin`).

Once Apple ships a fix (or zsh upstreams a `sigtimedwait`/kqueue-based
`signal_suspend`), the Darwin-gated workarounds in this repo can be removed.

---

## Title

`sigsuspend(2) loses SIGCHLD wakeup on macOS 26; zsh $(...) hangs in interactive shells under tmux`

## Description

On macOS 26.4.1 (build 25E253) running on Apple Silicon, an interactive `zsh`
(5.9) running inside `tmux` (3.6a) intermittently hangs whenever the
prompt-rendering path performs a `$(...)` command substitution. The hang
occurs in roughly 1 of every 10–30 prompt redraws. Outside `tmux`, the same
shell with the same configuration does not hang. With `zsh -f -i` (no rc
files) inside `tmux`, it also does not hang — the bug surfaces only under
prompt/precmd workloads that fork frequently for command substitution (e.g.
`compinit`, `eval "$(direnv export zsh)"`, Starship's
`PROMPT='$(starship prompt …)'`).

Diagnosis with `sample(1)` shows the parent shell wedged 100% in
`__sigsuspend`:

```
4392 zsh_main
  4392 loop
    4392 zleentry → zleread → promptexpand → singsub → prefork → getoutput
      4392 waitforpid
        4392 signal_suspend
          4392 pause  (in libsystem_c.dylib)
            4392 __sigsuspend  (in libsystem_kernel.dylib)
```

At the moment the parent is blocked, the forked child has already exited and
has been reaped or is no longer present in `ps`. zsh's `signal_suspend()`
(Src/signals.c) calls a bare `sigsuspend()` with an empty mask, which per
POSIX should atomically unblock all signals and return on delivery of any
unblocked signal. The SIGCHLD wakeup is being lost in the kernel/libsystem
boundary, so the process never returns from `__sigsuspend`.

This appears to be the same defect already on file as **rdar://FB18565075**
(https://openradar.appspot.com/FB18565075), whose reporter attributes it to
the xnu continuation-based sleep model:

> "SIGCHLD causes sigsuspend to return, even when SIGCHLD is blocked or when
> there is no user-space signal handler function for SIGCHLD … the xnu
> kernel's continuation-based model for sleeps … either removing the
> continuation-based sigcontinue or having sigsuspend check the error
> argument to determine whether to re-enter tsleep0."

That radar reproduces it from macOS 15.5 (24F74) through macOS 26.0b8
(25A5349a). The same kernel-side race also has a 2020 precedent in
**rdar://FB7731811** (https://developer.apple.com/forums/thread/134003),
where Apple DTS acknowledged that `fork()`/`alarm()` interactions on macOS
"are less than smooth." A 2020 `zsh $(...)` hang on macOS 11
(https://github.com/Homebrew/homebrew-core/issues/64921) appears to be the
same bug class. Red Hat documents the zsh-side race window at
https://access.redhat.com/solutions/2720181 — but the zsh-side race is
benign on systems where `sigsuspend()` honors POSIX semantics, because a
SIGCHLD that arrives before `sigsuspend()` is entered will still wake it.
On macOS 26 it does not.

Bisection has ruled out `TERM`, locale, `fpath`, Starship, and direnv as
root causes; the hang reproduces with any `$()` expansion in `precmd` once
`tmux` is in the picture. `tmux`'s involvement is suggestive — likely it
changes signal-mask inheritance or job-control PGID layout in a way that
makes the kernel race fire far more often, but the bug itself is in the
libsystem/xnu signal-delivery path, not in `tmux` or `zsh`.

## Steps to Reproduce

1. On macOS 26.4.1 (Apple Silicon), open Terminal.app.
2. Run: `tmux new-session '/bin/zsh -i'`
3. At the zsh prompt, paste:
   ```
   precmd() { x=$(/usr/bin/true); }
   ```
4. Hold Return. Within 30–100 prompt redraws, one Return will hang
   indefinitely.
5. From another terminal: `sample <pid> 5` — observe 100% of samples in
   `__sigsuspend`.
6. Confirm: `ps -o pid,stat,wchan,command -p <pid>` shows no living child;
   the parent is blocked alone.

The hang does not reproduce when step 2 is replaced with `/bin/zsh -i`
directly (no tmux), nor when the `precmd` body is replaced with
`x=$(</etc/hostname)` (zsh's no-fork file read), nor with
`x=$(=(/usr/bin/true))` (process substitution via tempfile).

## Expected

`sigsuspend()` returns when SIGCHLD is delivered (or already pending at
entry). `waitforpid()` reaps the child and the prompt continues.

## Actual

`sigsuspend()` never returns. The process is stuck in `__sigsuspend` until
SIGINT or SIGTERM. The child has already exited and either been reaped or
is no longer accounted for in the process table.

## Workaround

zsh-side mitigations exist — `=(cmd)` (process substitution via tempfile)
and `$(<file)` (no-fork file read) both avoid the racing fork+wait sequence.
These are not real fixes; they only avoid the libsystem/xnu code path that
loses the wakeup.

## Configuration

- Hardware: Apple Silicon (aarch64-darwin)
- OS: macOS 26.4.1 (25E253)
- Shell: `/bin/zsh` (zsh 5.9, system) and zsh 5.9 from Nix — both reproduce
- Terminal multiplexer: tmux 3.6a (Homebrew)
- Reproduces in Terminal.app, iTerm2, and Ghostty as the host terminal

## References

- rdar://FB18565075 — https://openradar.appspot.com/FB18565075 (direct match, kernel-level diagnosis)
- rdar://FB7731811 — https://developer.apple.com/forums/thread/134003 (2020 precedent, fork/signal race)
- https://access.redhat.com/solutions/2720181 (zsh-side race documentation)
- https://github.com/Homebrew/homebrew-core/issues/64921 (Big Sur instance, 2020)
- https://github.com/zsh-users/zsh/blob/master/Src/signals.c (zsh `signal_suspend()`)

---

## Filing Instructions

1. **Open Feedback Assistant.** Spotlight (Cmd-Space) → "Feedback Assistant"
   → Return. Or: open `/System/Applications/Utilities/Feedback Assistant.app`.
   Sign in with your developer Apple ID if you have one — feedback under a
   developer account is routed faster.

2. **New Feedback → macOS.**

3. **Area: Kernel** (macOS → Kernel). The defect is xnu-side per
   FB18565075's diagnosis. If "Kernel" isn't exposed under your account
   type, use **"All Other macOS Issues"** and call out the kernel
   attribution in the first sentence. "Frameworks → libsystem" is a
   defensible second choice but the syscall stub there is thin — the lost
   wakeup is kernel-side.

4. **Paste the writeup above** as the description.

5. **Attach diagnostics.** Capture these in a fresh shell and attach:
   - Stack sample (run while a zsh is hung):
     ```
     sample <hung-pid> 10 -file ~/Desktop/zsh-sigsuspend-sample.txt
     ```
   - `system_profiler SPSoftwareDataType > ~/Desktop/sw.txt`
   - `{ /bin/zsh --version; tmux -V; sw_vers; uname -a; } > ~/Desktop/versions.txt`
   - Optional but valuable: `sudo sysdiagnose -f ~/Desktop` taken shortly
     after a hang. ~300 MB but triagers love them — having one pre-attached
     saves a round trip.

6. **File new, reference FB18565075 and FB7731811 by number.** You can't
   append to someone else's radar, but Apple's triage links related reports
   by ID search, so naming them in-body gets you merged into the existing
   investigation.

7. **Save your `FB#######` number.** If you want others to cite it (e.g. on
   zsh-workers, Homebrew issue tracker), post it at
   https://openradar.appspot.com.

8. **Expectations.** Apple rarely responds within weeks; SIGCHLD bugs with
   an existing radar may sit a full release cycle. You'll likely get an
   automated "Recent Similar Reports" ack first. Engineering reads these —
   tone matters less than reproducibility, but crisp reproducers get
   prioritized.
