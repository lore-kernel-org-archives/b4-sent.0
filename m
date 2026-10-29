From: Mark Korenberg <socketpair@gmail.com>
Subject: [PATCH bpf-next v2 0/2] bpftool: Make the LLVM disassembler an
 optional runtime dependency
Date: Thu, 29 Oct 2026 17:43:17 +0500
Message-Id: <20261029-bpftool-plugin-v2-0-1a47b2391b0b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ6DIBBEf8XsuduAWFJ76n80HpAuuImCAWtsj
 P9e4r3HyZt5s0OmxJThUe2QaOXMMZRQXyqwgwmekN8lQy1qLbRQ2M9uiXHEefx4DmjbtumtIqE
 bBWU0J3K8ncIXlC4G2hboChk4LzF9z6dVnvyfdJUoUd+tMLaV7mbU00+Gx6uNE3THcfwAHfHQh
 rYAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793277817; l=2496;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=zLigtogb2hNT9/npTF66tViWfleGoRd//6M0rXeSiyM=;
 b=pV2kzMabYC80Jid/Kv+FKPzcvfWUjTKszoWxsw6TcbY2zNeEEe+k+fKas/26bnTxVO1omH3oZ
 20xhndlSoCiBXgqCKEgHoEnv+Is9D9EeTCmTfxZle4RbYclcqy7nX7B
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

libLLVM (~140 MiB on Fedora) is a hard dependency of bpftool, although it
is only used by "bpftool prog dump jited". This series moves the LLVM
disassembler to a plugin that bpftool loads on demand, so that
distributions can make it optional. Patch 1 fixes a leak found on the way.

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
 tools/bpf/bpftool/jit_disasm.c  | 161 ++++++++++++++++++++++++++++------------
 tools/bpf/bpftool/llvm_disasm.c |  84 +++++++++++++++++++++
 tools/bpf/bpftool/llvm_disasm.h |  41 ++++++++++
 tools/bpf/bpftool/main.c        |   3 +-
 tools/bpf/bpftool/main.h        |   3 +
 6 files changed, 279 insertions(+), 51 deletions(-)
---
base-commit: d80373a8e70d3193151232c3062abbbe367ff5ad
change-id: 20260603-bpftool-plugin-c994bc3e0643

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

