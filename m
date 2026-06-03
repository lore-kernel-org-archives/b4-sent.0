From: Korenberg Mark <socketpair@gmail.com>
Date: Wed, 03 Jun 2026 22:39:53 +0500
Subject: [PATCH] bpftool: Make the LLVM disassembler an optional runtime
 dependency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260603-bpftool-plugin-v1-1-68c0ac91f5a3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBMsQ7CrRIu00QZERSuC8O5Jy
 7f4/4WCmbDA3L2Q8aZCMTQMfQfm2IJDRnszjHyUXHLBdLJnjJ4lfzkKzCg1aSOQy0lAi1JGS88
 /XNZaP9YWoPxgAAAA
X-Change-ID: 20260603-bpftool-plugin-c994bc3e0643
To: Quentin Monnet <qmo@kernel.org>, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <nick.desaulniers+lkml@gmail.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: linux-kernel@vger.kernel.org, bpf@vger.kernel.org, llvm@lists.linux.dev, 
 Korenberg Mark <socketpair@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780508396; l=17763;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=aP25w5DlRMlpRD13hPXrY+sdA/kazAuiqSIzsN6jCjo=;
 b=KO2gDX0W+nZYLgZElcrJXmy1YebBcl8lyEaNBrgdrldgnNmGQcB8fotxNzTDKTGXHmgwBtBgy
 wOYA2Fu/PB+AqbHme1fxuiUuJcm/Eb/FtP0IK03y7L+VJnJybh7yVAR
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes https://github.com/libbpf/bpftool/issues/262

Signed-off-by: Korenberg Mark <socketpair@gmail.com>
---
On Fedora 43, installing `bpftool` pulls in `llvm20-libs` (~140 MiB) as a hard
dependency, even though the bpftool binary itself is ~730 KiB:

    # dnf install bpftool
    Installing:
     bpftool            x86_64   7.6.0-1.fc43    fedora   731.4 KiB
    Installing dependencies:
     llvm20-filesystem  x86_64   20.1.8-2.fc43   fedora   0.0   B
     llvm20-libs        x86_64   20.1.8-2.fc43   fedora   139.7 MiB

The LLVM library is only used to disassemble JIT-compiled (native) programs,
i.e. `bpftool prog dump jited`. Every other use case  works
without LLVM. For scripting, automation, and CI, dragging in ~140 MB of LLVM
just to have a single optional command available is a heavy cost.

Load the LLVM disassembler lazily at runtime via `dlopen`/`dlsym` instead of
linking against it at build time. When `prog dump jited` is invoked and the
library is unavailable, fall back gracefully (libbfd, or an informative message).
This would remove the automatic ELF dependency on `libLLVM.so`, allowing distributions to make
LLVM a weak/optional dependency (e.g. RPM `Recommends`) rather than a hard one.

The `perf` tool is solving the exact same problem (libLLVM/libcapstone
bloating dependencies for users who never disassemble) by dlopen-ing these
libraries at runtime, so distributions can ship them as a separate, optional
package:

- Overview: https://lwn.net/Articles/1040879/
- https://lore.kernel.org/lkml/?q=Capstone%2Fllvm+dlopen

- Build with the libbfd disassembler instead of LLVM (smaller, but a build/
  packaging choice and subject to libbfd's unstable ABI).
- Build with no disassembler at all (loses `prog dump jited` entirely).
- Ship the disassembler in a separate binary (works, but less idiomatic for a
  single-binary tool; dlopen keeps the existing UX intact).

- bpftool 7.6.0-1.fc43 (Fedora 43), x86_64
---
 tools/bpf/bpftool/Makefile      |  63 ++++++++++++++++++----
 tools/bpf/bpftool/jit_disasm.c  | 112 +++++++++++++++++++++++-----------------
 tools/bpf/bpftool/llvm_disasm.c |  85 ++++++++++++++++++++++++++++++
 tools/bpf/bpftool/llvm_disasm.h |  38 ++++++++++++++
 4 files changed, 240 insertions(+), 58 deletions(-)

diff --git a/tools/bpf/bpftool/Makefile b/tools/bpf/bpftool/Makefile
index 0febf60e1..9887ac6fb 100644
--- a/tools/bpf/bpftool/Makefile
+++ b/tools/bpf/bpftool/Makefile
@@ -62,6 +62,7 @@ $(LIBBPF_BOOTSTRAP)-clean: FORCE | $(LIBBPF_BOOTSTRAP_OUTPUT)
 	$(Q)$(MAKE) -C $(BPF_DIR) OUTPUT=$(LIBBPF_BOOTSTRAP_OUTPUT) clean >/dev/null
 
 prefix ?= /usr/local
+libdir ?= $(prefix)/lib
 bash_compdir ?= /usr/share/bash-completion/completions
 
 CFLAGS += -O2
@@ -157,6 +158,8 @@ include $(wildcard $(OUTPUT)*.d)
 all: $(OUTPUT)bpftool
 
 SRCS := $(wildcard *.c)
+# llvm_disasm.c is compiled separately into the bpftool-llvm.so plugin.
+SRCS := $(filter-out llvm_disasm.c,$(SRCS))
 
 ifeq ($(feature-llvm),1)
 ifneq ($(SKIP_LLVM),1)
@@ -165,19 +168,36 @@ endif
 endif
 
 ifeq ($(HAS_LLVM),1)
+  # The libLLVM-based JIT disassembler is built as a separate plugin,
+  # bpftool-llvm.so, which is the only object that links against libLLVM.
+  # bpftool loads it lazily with dlopen() (see jit_disasm.c), so the bpftool
+  # binary itself keeps no dependency on the large libLLVM shared object.
   CFLAGS  += -DHAVE_LLVM_SUPPORT
+  CFLAGS  += -DLLVM_PLUGIN_DIR='"$(libdir)/bpftool"'
+  # dlopen() lives in libc on modern glibc, but keep -ldl for portability.
+  LIBS    += -ldl
+
+  # Flags used to build the plugin itself (the only part that needs libLLVM).
   LLVM_CONFIG_LIB_COMPONENTS := mcdisassembler all-targets
-  # llvm-config always adds -D_GNU_SOURCE, however, it may already be in CFLAGS
-  # (e.g. when bpftool build is called from selftests build as selftests
-  # Makefile includes lib.mk which sets -D_GNU_SOURCE) which would cause
-  # compilation error due to redefinition. Let's filter it out here.
-  CFLAGS  += $(filter-out -D_GNU_SOURCE,$(shell $(LLVM_CONFIG) --cflags))
-  LIBS    += $(shell $(LLVM_CONFIG) --libs $(LLVM_CONFIG_LIB_COMPONENTS))
+  # llvm-config always adds -D_GNU_SOURCE, which llvm_disasm.c already defines;
+  # filter it out to avoid a redefinition warning.
+  LLVM_PLUGIN_CFLAGS := $(filter-out -D_GNU_SOURCE,$(shell $(LLVM_CONFIG) --cflags))
+
+  # Embed libLLVM into the plugin statically when requested with
+  # LLVM_LINK_STATIC=1, or when this LLVM install only ships static libraries
+  # ("llvm-config --shared-mode" reports "static"). Otherwise link the shared
+  # libLLVM, which is the only runtime dependency of the plugin.
   ifeq ($(shell $(LLVM_CONFIG) --shared-mode),static)
-    LIBS += $(shell $(LLVM_CONFIG) --system-libs $(LLVM_CONFIG_LIB_COMPONENTS))
-    LIBS += -lstdc++
+    LLVM_LINK_STATIC := 1
+  endif
+  ifeq ($(LLVM_LINK_STATIC),1)
+    LLVM_PLUGIN_LIBS := $(shell $(LLVM_CONFIG) --link-static --libs $(LLVM_CONFIG_LIB_COMPONENTS))
+    LLVM_PLUGIN_LIBS += $(shell $(LLVM_CONFIG) --link-static --system-libs $(LLVM_CONFIG_LIB_COMPONENTS))
+    LLVM_PLUGIN_LIBS += -lstdc++
+  else
+    LLVM_PLUGIN_LIBS := $(shell $(LLVM_CONFIG) --libs $(LLVM_CONFIG_LIB_COMPONENTS))
   endif
-  LDFLAGS += $(shell $(LLVM_CONFIG) --ldflags)
+  LLVM_PLUGIN_LDFLAGS := $(shell $(LLVM_CONFIG) --ldflags)
 else
   ifneq ($(SKIP_LIBBFD),1)
   # Fall back on libbfd
@@ -276,6 +296,20 @@ $(BPFTOOL_BOOTSTRAP): $(BOOTSTRAP_OBJS) $(LIBBPF_BOOTSTRAP)
 $(OUTPUT)bpftool: $(OBJS) $(LIBBPF)
 	$(QUIET_LINK)$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) $(LIBS) -o $@
 
+ifeq ($(HAS_LLVM),1)
+all: $(OUTPUT)bpftool-llvm.so
+
+$(OUTPUT)llvm_disasm.o: llvm_disasm.c
+	$(QUIET_CC)$(CC) $(CFLAGS) $(LLVM_PLUGIN_CFLAGS) -fPIC -c -MMD $< -o $@
+
+# The plugin is a shared object by definition, so drop a global -static (e.g.
+# from EXTRA_LDFLAGS for a static bpftool) which would conflict with -shared.
+# Embedding libLLVM statically is controlled separately (see LLVM_LINK_STATIC).
+$(OUTPUT)bpftool-llvm.so: $(OUTPUT)llvm_disasm.o
+	$(QUIET_LINK)$(CC) $(CFLAGS) $(filter-out -static,$(LDFLAGS)) \
+		$(LLVM_PLUGIN_LDFLAGS) -shared -o $@ $< $(LLVM_PLUGIN_LIBS)
+endif
+
 $(BOOTSTRAP_OUTPUT)%.o: %.c $(LIBBPF_BOOTSTRAP_INTERNAL_HDRS) | $(BOOTSTRAP_OUTPUT)
 	$(QUIET_CC)$(HOSTCC) $(HOST_CFLAGS) -c -MMD $< -o $@
 
@@ -288,17 +322,25 @@ feature-detect-clean:
 
 clean: $(LIBBPF)-clean $(LIBBPF_BOOTSTRAP)-clean feature-detect-clean
 	$(call QUIET_CLEAN, bpftool)
-	$(Q)$(RM) -- $(OUTPUT)bpftool $(OUTPUT)*.o $(OUTPUT)*.d
+	$(Q)$(RM) -- $(OUTPUT)bpftool $(OUTPUT)bpftool-llvm.so $(OUTPUT)*.o $(OUTPUT)*.d
 	$(Q)$(RM) -- $(OUTPUT)*.skel.h $(OUTPUT)vmlinux.h
 	$(Q)$(RM) -r -- $(LIBBPF_OUTPUT) $(BOOTSTRAP_OUTPUT)
 	$(call QUIET_CLEAN, core-gen)
 	$(Q)$(RM) -- $(OUTPUT)FEATURE-DUMP.bpftool
 	$(Q)$(RM) -r -- $(OUTPUT)feature/
 
+ifeq ($(HAS_LLVM),1)
+install-bin: $(OUTPUT)bpftool-llvm.so
+endif
 install-bin: $(OUTPUT)bpftool
 	$(call QUIET_INSTALL, bpftool)
 	$(Q)$(INSTALL) -m 0755 -d $(DESTDIR)$(prefix)/sbin
 	$(Q)$(INSTALL) $(OUTPUT)bpftool $(DESTDIR)$(prefix)/sbin/bpftool
+ifeq ($(HAS_LLVM),1)
+	$(call QUIET_INSTALL, bpftool-llvm.so)
+	$(Q)$(INSTALL) -m 0755 -d $(DESTDIR)$(libdir)/bpftool
+	$(Q)$(INSTALL) -m 0755 $(OUTPUT)bpftool-llvm.so $(DESTDIR)$(libdir)/bpftool/bpftool-llvm.so
+endif
 
 install: install-bin
 	$(Q)$(INSTALL) -m 0755 -d $(DESTDIR)$(bash_compdir)
@@ -307,6 +349,7 @@ install: install-bin
 uninstall:
 	$(call QUIET_UNINST, bpftool)
 	$(Q)$(RM) -- $(DESTDIR)$(prefix)/sbin/bpftool
+	$(Q)$(RM) -- $(DESTDIR)$(libdir)/bpftool/bpftool-llvm.so
 	$(Q)$(RM) -- $(DESTDIR)$(bash_compdir)/bpftool
 
 doc:
diff --git a/tools/bpf/bpftool/jit_disasm.c b/tools/bpf/bpftool/jit_disasm.c
index 04541155e..e8cef2da2 100644
--- a/tools/bpf/bpftool/jit_disasm.c
+++ b/tools/bpf/bpftool/jit_disasm.c
@@ -25,10 +25,9 @@
 #include <bpf/libbpf.h>
 
 #ifdef HAVE_LLVM_SUPPORT
-#include <llvm-c/Core.h>
-#include <llvm-c/Disassembler.h>
-#include <llvm-c/Target.h>
-#include <llvm-c/TargetMachine.h>
+#include <dlfcn.h>
+
+#include "llvm_disasm.h"
 #endif
 
 #ifdef HAVE_LIBBFD_SUPPORT
@@ -45,7 +44,32 @@ static int oper_count;
 #ifdef HAVE_LLVM_SUPPORT
 #define DISASM_SPACER
 
-typedef LLVMDisasmContextRef disasm_ctx_t;
+/*
+ * The libLLVM-based disassembler used for "bpftool prog dump jited" lives in a
+ * separate plugin, bpftool-llvm.so, which is the only object linked against
+ * libLLVM. This keeps the bpftool binary itself free of a hard dependency on
+ * the (large) libLLVM shared object: the plugin is loaded lazily with dlopen()
+ * the first time a JITed image actually needs to be disassembled, with its
+ * entry points resolved by dlsym(). See llvm_disasm.c for the plugin.
+ *
+ * LLVM_PLUGIN_DIR is the install directory baked in at build time
+ * ($(libdir)/bpftool). When set, the plugin is loaded from that absolute
+ * location; otherwise only the bare file name is used, i.e. the plugin is
+ * looked up via the dynamic linker search path (or the current directory).
+ */
+#ifdef LLVM_PLUGIN_DIR
+#define LLVM_PLUGIN_PATH LLVM_PLUGIN_DIR "/bpftool-llvm.so"
+#else
+#define LLVM_PLUGIN_PATH "bpftool-llvm.so"
+#endif
+
+typedef void *disasm_ctx_t;
+
+static void *llvm_plugin_handle;
+static __typeof__(&bpftool_llvm_init) p_bpftool_llvm_init;
+static __typeof__(&bpftool_llvm_create_context) p_bpftool_llvm_create_context;
+static __typeof__(&bpftool_llvm_destroy_context) p_bpftool_llvm_destroy_context;
+static __typeof__(&bpftool_llvm_disassemble) p_bpftool_llvm_disassemble;
 
 static int printf_json(char *s)
 {
@@ -63,48 +87,13 @@ static int printf_json(char *s)
 	return 0;
 }
 
-/* This callback to set the ref_type is necessary to have the LLVM disassembler
- * print PC-relative addresses instead of byte offsets for branch instruction
- * targets.
- */
-static const char *
-symbol_lookup_callback(__maybe_unused void *disasm_info,
-		       __maybe_unused uint64_t ref_value,
-		       uint64_t *ref_type, __maybe_unused uint64_t ref_PC,
-		       __maybe_unused const char **ref_name)
-{
-	*ref_type = LLVMDisassembler_ReferenceType_InOut_None;
-	return NULL;
-}
-
 static int
 init_context(disasm_ctx_t *ctx, const char *arch,
 	     __maybe_unused const char *disassembler_options,
 	     __maybe_unused unsigned char *image, __maybe_unused ssize_t len,
 	     __maybe_unused __u64 func_ksym)
 {
-	char *triple;
-
-	if (arch)
-		triple = LLVMNormalizeTargetTriple(arch);
-	else
-		triple = LLVMGetDefaultTargetTriple();
-	if (!triple) {
-		p_err("Failed to retrieve triple");
-		return -1;
-	}
-
-	/*
-	 * Enable all aarch64 ISA extensions so the disassembler can handle any
-	 * instruction the kernel JIT might emit (e.g. ARM64 LSE atomics).
-	 */
-	if (!strncmp(triple, "aarch64", 7))
-		*ctx = LLVMCreateDisasmCPUFeatures(triple, "", "+all", NULL, 0, NULL,
-						   symbol_lookup_callback);
-	else
-		*ctx = LLVMCreateDisasm(triple, NULL, 0, NULL, symbol_lookup_callback);
-	LLVMDisposeMessage(triple);
-
+	*ctx = p_bpftool_llvm_create_context(arch);
 	if (!*ctx) {
 		p_err("Failed to create disassembler");
 		return -1;
@@ -115,7 +104,7 @@ init_context(disasm_ctx_t *ctx, const char *arch,
 
 static void destroy_context(disasm_ctx_t *ctx)
 {
-	LLVMDisposeMessage(*ctx);
+	p_bpftool_llvm_destroy_context(*ctx);
 }
 
 static int
@@ -125,8 +114,8 @@ disassemble_insn(disasm_ctx_t *ctx, unsigned char *image, ssize_t len, int pc,
 	char buf[256];
 	int count;
 
-	count = LLVMDisasmInstruction(*ctx, image + pc, len - pc, func_ksym + pc,
-				      buf, sizeof(buf));
+	count = p_bpftool_llvm_disassemble(*ctx, image, len, pc, func_ksym,
+					   buf, sizeof(buf));
 	if (json_output)
 		printf_json(buf);
 	else
@@ -137,10 +126,37 @@ disassemble_insn(disasm_ctx_t *ctx, unsigned char *image, ssize_t len, int pc,
 
 int disasm_init(void)
 {
-	LLVMInitializeAllTargetInfos();
-	LLVMInitializeAllTargetMCs();
-	LLVMInitializeAllDisassemblers();
-	return 0;
+	if (llvm_plugin_handle)
+		return p_bpftool_llvm_init();
+
+	/* Load the plugin by its absolute install path. */
+	llvm_plugin_handle = dlopen(LLVM_PLUGIN_PATH, RTLD_NOW | RTLD_LOCAL);
+	if (!llvm_plugin_handle) {
+		p_err("failed to load %s, install it to disassemble JITed programs: %s",
+		      LLVM_PLUGIN_PATH, dlerror());
+		return -1;
+	}
+
+#define RESOLVE(name)							       \
+	do {								       \
+		p_##name = (__typeof__(p_##name))dlsym(llvm_plugin_handle,     \
+						       #name);		       \
+		if (!p_##name) {					       \
+			p_err("%s is missing symbol %s: %s",		       \
+			      LLVM_PLUGIN_PATH, #name, dlerror());	       \
+			dlclose(llvm_plugin_handle);			       \
+			llvm_plugin_handle = NULL;			       \
+			return -1;					       \
+		}							       \
+	} while (0)
+
+	RESOLVE(bpftool_llvm_init);
+	RESOLVE(bpftool_llvm_create_context);
+	RESOLVE(bpftool_llvm_destroy_context);
+	RESOLVE(bpftool_llvm_disassemble);
+#undef RESOLVE
+
+	return p_bpftool_llvm_init();
 }
 #endif /* HAVE_LLVM_SUPPORT */
 
diff --git a/tools/bpf/bpftool/llvm_disasm.c b/tools/bpf/bpftool/llvm_disasm.c
new file mode 100644
index 000000000..b83216191
--- /dev/null
+++ b/tools/bpf/bpftool/llvm_disasm.c
@@ -0,0 +1,85 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+/*
+ * libLLVM-based BPF JIT disassembler plugin for bpftool.
+ *
+ * This translation unit is built into a standalone shared object
+ * (bpftool-llvm.so) which is the only bpftool component that links against
+ * libLLVM. bpftool loads it lazily with dlopen() (see jit_disasm.c) so that
+ * the bpftool binary itself does not depend on the large libLLVM shared
+ * object. Only the small, stable C ABI declared in llvm_disasm.h is exposed.
+ */
+#ifndef _GNU_SOURCE
+#define _GNU_SOURCE
+#endif
+#include <stdint.h>
+#include <string.h>
+#include <sys/types.h>
+
+#include <llvm-c/Core.h>
+#include <llvm-c/Disassembler.h>
+#include <llvm-c/Target.h>
+#include <llvm-c/TargetMachine.h>
+
+#include "llvm_disasm.h"
+
+/* This callback to set the ref_type is necessary to have the LLVM disassembler
+ * print PC-relative addresses instead of byte offsets for branch instruction
+ * targets.
+ */
+static const char *
+symbol_lookup_callback(void *disasm_info, uint64_t ref_value,
+		       uint64_t *ref_type, uint64_t ref_PC,
+		       const char **ref_name)
+{
+	*ref_type = LLVMDisassembler_ReferenceType_InOut_None;
+	return NULL;
+}
+
+int bpftool_llvm_init(void)
+{
+	LLVMInitializeAllTargetInfos();
+	LLVMInitializeAllTargetMCs();
+	LLVMInitializeAllDisassemblers();
+
+	return 0;
+}
+
+void *bpftool_llvm_create_context(const char *arch)
+{
+	LLVMDisasmContextRef ctx;
+	char *triple;
+
+	if (arch)
+		triple = LLVMNormalizeTargetTriple(arch);
+	else
+		triple = LLVMGetDefaultTargetTriple();
+	if (!triple)
+		return NULL;
+
+	/*
+	 * Enable all aarch64 ISA extensions so the disassembler can handle any
+	 * instruction the kernel JIT might emit (e.g. ARM64 LSE atomics).
+	 */
+	if (!strncmp(triple, "aarch64", 7))
+		ctx = LLVMCreateDisasmCPUFeatures(triple, "", "+all", NULL, 0,
+						  NULL, symbol_lookup_callback);
+	else
+		ctx = LLVMCreateDisasm(triple, NULL, 0, NULL,
+				       symbol_lookup_callback);
+	LLVMDisposeMessage(triple);
+
+	return ctx;
+}
+
+void bpftool_llvm_destroy_context(void *ctx)
+{
+	LLVMDisasmDispose(ctx);
+}
+
+int bpftool_llvm_disassemble(void *ctx, unsigned char *image, ssize_t len,
+			     int pc, uint64_t func_ksym, char *buf,
+			     size_t buf_sz)
+{
+	return LLVMDisasmInstruction(ctx, image + pc, len - pc, func_ksym + pc,
+				     buf, buf_sz);
+}
diff --git a/tools/bpf/bpftool/llvm_disasm.h b/tools/bpf/bpftool/llvm_disasm.h
new file mode 100644
index 000000000..cd9491ea3
--- /dev/null
+++ b/tools/bpf/bpftool/llvm_disasm.h
@@ -0,0 +1,38 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+#ifndef __BPFTOOL_LLVM_DISASM_H
+#define __BPFTOOL_LLVM_DISASM_H
+
+#include <stddef.h>
+#include <stdint.h>
+#include <sys/types.h>
+
+/*
+ * Stable C ABI between bpftool and its optional libLLVM-based JIT disassembler
+ * plugin (bpftool-llvm.so). bpftool resolves these symbols with dlsym()
+ * after dlopen()ing the plugin; the plugin is the only object that links
+ * against libLLVM. See jit_disasm.c (loader) and llvm_disasm.c (plugin).
+ */
+
+/* Initialize the libLLVM targets and disassemblers. Returns 0 on success. */
+int bpftool_llvm_init(void);
+
+/*
+ * Create a disassembler context for @arch (NULL selects the host
+ * architecture). Returns an opaque context pointer, or NULL on failure.
+ */
+void *bpftool_llvm_create_context(const char *arch);
+
+/* Release a context previously returned by bpftool_llvm_create_context(). */
+void bpftool_llvm_destroy_context(void *ctx);
+
+/*
+ * Disassemble the single instruction at @image[@pc] into @buf as a NUL
+ * terminated string. @func_ksym is the kernel address of @image and is used to
+ * render absolute branch targets. Returns the instruction length in bytes, or
+ * 0 if the instruction could not be decoded.
+ */
+int bpftool_llvm_disassemble(void *ctx, unsigned char *image, ssize_t len,
+			     int pc, uint64_t func_ksym, char *buf,
+			     size_t buf_sz);
+
+#endif /* __BPFTOOL_LLVM_DISASM_H */

---
base-commit: ba3e43a9e601636f5edb54e259a74f96ca3b8fd8
change-id: 20260603-bpftool-plugin-c994bc3e0643

Best regards,
-- 
Korenberg Mark <socketpair@gmail.com>

