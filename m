From: Mark Korenberg <socketpair@gmail.com>
Subject: [PATCH bpf-next v3 0/2] bpftool: Make the LLVM disassembler an
 optional runtime dependency
Date: Thu, 29 Oct 2026 18:05:36 +0500
Message-Id: <20261029-bpftool-plugin-v3-0-87af799da40a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNywrCMBREf0Xu2it51Ghc+R/iIolpG2iTktRQK
 f13QxYiiMth5pxZIdnobILLboVos0su+BL4fgemV76z6B4lAyNMEEE46qmdQxhwGp6d82ikbLT
 hloiGQ4GmaFu3VOENyha9XWa4l6Z3aQ7xVZ8yrf0/aaZIUZwNUUbS9qj4tRuVGw4mjFWV2Qenh
 MkfnCFBqpqTZlxSTfQ3vm3bGzLVaGH1AAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793279142; l=2789;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=4+EVE0vRRHLPdxZueJ3Z0rAQkXRNx4EBHKNnKXGICFc=;
 b=3b61HIda+LvZWU94BX+vCZzYrThe3BCs40LS4OpIm+W09DBcofh39uT5hDHoua/0i3W6GoYZ1
 3rCH3FG558rBB6tXw7G3nHFVNwKuiPn2leCvd2fisZAAWToY1bCNbJv
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

libLLVM (~140 MiB on Fedora) is a hard dependency of bpftool, although it
is only used by "bpftool prog dump jited". This series moves the LLVM
disassembler to a plugin that bpftool loads on demand, so that
distributions can make it optional. Patch 1 fixes a leak found on the way.

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

Tested on Fedora 44 x86_64, LLVM 22: plugin, built-in and SKIP_LLVM
builds; plugin lookup (installed, build directory, missing, wrong ABI);
install/uninstall; "prog dump jited" (plain and JSON) on live programs,
and disassembly of aarch64 code through the plugin. Not tested: a fully
static build (no static libraries available).

The v2 changes were written with the help of an AI assistant (Claude),
from the review comments; I reviewed and tested them.

---
Mark Korenberg (2):
      bpftool: Fix disposal of the LLVM disassembler context
      bpftool: Make the LLVM disassembler an optional runtime dependency

 tools/bpf/bpftool/Makefile      |  38 +++++++++-
 tools/bpf/bpftool/jit_disasm.c  | 158 ++++++++++++++++++++++++++++------------
 tools/bpf/bpftool/llvm_disasm.c |  84 +++++++++++++++++++++
 tools/bpf/bpftool/llvm_disasm.h |  41 +++++++++++
 tools/bpf/bpftool/main.c        |   3 +-
 tools/bpf/bpftool/main.h        |   3 +
 6 files changed, 276 insertions(+), 51 deletions(-)
---
base-commit: d80373a8e70d3193151232c3062abbbe367ff5ad
change-id: 20260603-bpftool-plugin-c994bc3e0643

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

