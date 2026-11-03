From: Mark Korenberg <socketpair@gmail.com>
Subject: [PATCH bpf-next v5 0/3] bpftool: Make the LLVM disassembler an
 optional runtime dependency
Date: Tue, 03 Nov 2026 18:59:52 +0500
Message-Id: <20261103-bpftool-plugin-v5-0-683e08a25df0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTWrDMBAF4KsErTtlpJF/Jqvco3QxkmVH4FjGd
 k1K8N0rvGhDQrp8vPne3NQcphhmdTzc1BTWOMc05FC8HZQ/y9AFiE3OyqApsUQCN7ZLSj2M/Vc
 XB/DM1nkKWFpSGY1TaON1H/xQ+RaGcF3UZ27OcV7S9L1/WvXevxpdNWgoa4/iWbeF0Km7SOzff
 brsU6v55RoNP3EDCFps5QyxdugeOf3PKfO6krZibsSiPHL7x7N/4jbzQuqCAlfUOL7n27b9AHO
 liWBzAQAA
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
 Nick Desaulniers <ndesaulniers@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Stanislav Fomichev <sdf@fomichev.me>
Cc: linux-kernel@vger.kernel.org, bpf@vger.kernel.org, llvm@lists.linux.dev, 
 Mark Korenberg <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793714393; l=4062;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=FTpGNAMeoY1x3nm3HnFThoT7APvBIz/tLsd5anzdXyg=;
 b=GOhRtZTKRCK2jOK3H5P/nT+F8yC+FXobdGQdayYJTcqsAXPp9Llk74PL5166ccg3PCn8XiwyK
 OuZ+XsG4mMRCy1KF8Q6kdUwdrrnwlNKMuO+ew8No82kyrTLOKQKWz1Z
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

libLLVM (~140 MiB on Fedora) is a hard dependency of bpftool, although it
is only used by "bpftool prog dump jited". With this series, bpftool is
no longer linked with libLLVM.so but loads it with dlopen() when it needs
to disassemble JITed programs, so that distributions can make it optional.
Patch 1 fixes a leak found on the way. Patch 2 makes "prog dump jited
... file FILE" work without a disassembler.

Changes in v5:
- Use the soname of libLLVM for dlopen(), not the name of the file it
  points to, which is not in the ld.so path on Ubuntu 24.04 (Sashiko,
  Alexei)
- New patch 2: call disasm_init() only when the image is disassembled,
  so that "prog dump jited ... file FILE" works without libLLVM (Alexei)
- Update common_options.rst, which still said that bpftool links with
  LLVM (Alexei)
- Rebase on bpf-next
- Link to v4: https://lore.kernel.org/r/20261102-bpftool-plugin-v4-0-5a853e973db9@gmail.com

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
per-component LLVM, and with SKIP_LLVM; "prog dump jited" (plain, JSON
and to a file) on live programs; bpftool, also when installed as
selftests do, loads libLLVM.so only for "prog dump jited" and reports an
error if it is missing; "prog dump jited ... file" works without a
disassembler. Also tested with Ubuntu 24.04 (LLVM 18) userspace, where
bpftool now loads libLLVM.so.18.1 (v4 tried libLLVM.so.1).

The changes since v1 were written with the help of an AI assistant
(Claude), from the review comments; I reviewed and tested them.

---
Mark Korenberg (3):
      bpftool: Fix disposal of the LLVM disassembler context
      bpftool: Don't require a disassembler to dump a JITed program to a file
      bpftool: Make the LLVM disassembler an optional runtime dependency

 tools/bpf/bpftool/Documentation/common_options.rst | 10 ++-
 tools/bpf/bpftool/Makefile                         | 16 +++-
 tools/bpf/bpftool/jit_disasm.c                     | 88 +++++++++++++++++++++-
 tools/bpf/bpftool/prog.c                           |  4 +-
 4 files changed, 110 insertions(+), 8 deletions(-)
---
base-commit: cd5bc55288d4fd999595c8f2af6a5408cbe92a52
change-id: 20260603-bpftool-plugin-c994bc3e0643

Best regards,
-- 
Mark Korenberg <socketpair@gmail.com>

