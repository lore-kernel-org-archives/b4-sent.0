From: Mark Korenberg <socketpair@gmail.com>
Subject: [PATCH bpf-next v4 0/2] bpftool: Make the LLVM disassembler an
 optional runtime dependency
Date: Mon, 02 Nov 2026 17:44:10 +0500
Message-Id: <20261102-bpftool-plugin-v4-0-5a853e973db9@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTQ6CMBAF4KuQrh0z/RGoK+9hXLSlQBOgBLDBE
 O5u04UxGl2+vPnebGS2k7MzOWcbmWxws/NDDOKQEdOqobHgqpgJQ5Zjjhz0WC/edzB298YNYKQ
 U2nCLueAkonGytVvT4JXEWxjsupBbbFo3L356pE+Bpv7XaKBAIS8NKiNpfVL80vTKdUfj+zQV2
 ItTZPKLM0CgShSacUk16k/O/3MeeVmoupCyUgLVO9/3/QmVAESRNAEAAA==
X-Change-ID: 20260603-bpftool-plugin-c994bc3e0643
To: Quentin Monnet <qmo@kernel.org>, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, Bill Wendling <morbo@google.com>, 
 Justin Stitt <justinstitt@google.com>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Nick Desaulniers <ndesaulniers@google.com>
Cc: linux-kernel@vger.kernel.org, bpf@vger.kernel.org, llvm@lists.linux.dev, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793623450; l=3058;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=s1BbFMwahYj2EEmbxI8ooWySbm8Sdb/tUQr9mxtP7uY=;
 b=r9H0AK2by86Kthvuqg88ineEV295m+sPSFKixzmZg8wXsojAwENyTtUt1ZTcbRZiRf6j03FZJ
 SbaWivmTQbeC96PvwLJQCz7cUFjb4bHPoTuUNqSyTyq8zT68ipaJrPT
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

libLLVM (~140 MiB on Fedora) is a hard dependency of bpftool, although it
is only used by "bpftool prog dump jited". With this series, bpftool is
no longer linked with libLLVM.so but loads it with dlopen() when it needs
to disassemble JITed programs, so that distributions can make it optional.
Patch 1 fixes a leak found on the way.

Changes in v4:
- Drop the plugin, load libLLVM.so with dlopen() instead, as suggested by
  Alexei. This also makes "prog dump jited" work with the bpftool built by
  selftests.
- Keep "llvm" in "bpftool version" a build time feature (Alexei)
- Unlike the suggested diff, still link with LLVM built with
  BUILD_SHARED_LIBS=ON, rather than failing to build
- Link to v3: https://lore.kernel.org/r/20261029-bpftool-plugin-v3-0-87af799da40a@gmail.com

Changes in v3:
- Look for the plugin next to the bpftool binary before its install
  directory, so that bpftool run from its build directory does not pick
  an older installed plugin (Sashiko)
- Link to v2: https://lore.kernel.org/r/20261029-bpftool-plugin-v2-0-1a47b2391b0b@gmail.com

Changes in v2:
- Move the LLVMDisasmDispose() fix to a separate patch (Quentin)
- Look for the plugin next to the bpftool binary when it is not installed,
  so that bpftool works from its build directory (Quentin, Sashiko). Not in
  the current directory: bpftool usually runs as root.
- Export a single versioned structure of callbacks from the plugin (Quentin)
- Only report "llvm" in "bpftool version" if the plugin loads (Quentin)
- Handle dlerror() returning NULL (Quentin)
- Rebuild jit_disasm.o if libdir changes between "make" and
  "make install" (Quentin)
- uninstall: use QUIET_UNINST, remove $(libdir)/bpftool (Quentin)
- With a static libLLVM, which a static bpftool requires, link the
  disassembler into bpftool as before (Sashiko). This drops
  LLVM_LINK_STATIC: static LLVM archives are never linked into a shared
  object.
- Commit log and comment fixes (Quentin, Sashiko)
- Rebase on bpf-next
- Link to v1: https://lore.kernel.org/r/20260603-bpftool-plugin-v1-1-68c0ac91f5a3@gmail.com

Tested on Fedora 44 x86_64, LLVM 22: builds with shared, static and
per-component LLVM, and with SKIP_LLVM; "prog dump jited" (plain and
JSON) on live programs; bpftool, also when installed as selftests do,
loads libLLVM.so only for "prog dump jited" and reports an error if it is
missing.

The changes since v1 were written with the help of an AI assistant
(Claude), from the review comments; I reviewed and tested them.

---
Mark Korenberg (2):
      bpftool: Fix disposal of the LLVM disassembler context
      bpftool: Make the LLVM disassembler an optional runtime dependency

 tools/bpf/bpftool/Makefile     | 10 ++++-
 tools/bpf/bpftool/jit_disasm.c | 88 +++++++++++++++++++++++++++++++++++++++++-
 2 files changed, 96 insertions(+), 2 deletions(-)
---
base-commit: cd5bc55288d4fd999595c8f2af6a5408cbe92a52
change-id: 20260603-bpftool-plugin-c994bc3e0643

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

