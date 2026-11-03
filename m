From: Mark Korenberg <socketpair@gmail.com>
Date: Tue, 03 Nov 2026 18:59:55 +0500
Subject: [PATCH bpf-next v5 3/3] bpftool: Make the LLVM disassembler an
 optional runtime dependency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-bpftool-plugin-v5-3-683e08a25df0@gmail.com>
References: <20261103-bpftool-plugin-v5-0-683e08a25df0@gmail.com>
In-Reply-To: <20261103-bpftool-plugin-v5-0-683e08a25df0@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793714393; l=7039;
 i=socketpair@gmail.com; s=20260603; h=from:subject:message-id;
 bh=3dDAosnyE94NMtj/8b2EU45HkmtEBU2i9iXb/AyeRnI=;
 b=WrSxL7L+pULTJafcSdpjC3Ucgo+owqxvUhcEpiYDpZNZpvwXJl+87DHg8qPMVDuKYRXGHFnWx
 Kl899Vt5naSAKyRuCdIRboORqK1NgRCSDdZBkzGoiO/R6Q4aq3oXF6H
X-Developer-Key: i=socketpair@gmail.com; a=ed25519;
 pk=2iAMjWhs7kA9X8ccetT2YVX8dvniXua2okQogw3Don8=
X-Endpoint-Received: by B4 Relay for socketpair@gmail.com/20260603 with auth_id=806
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

libLLVM is only needed for "bpftool prog dump jited", yet it is a hard
dependency of bpftool: on Fedora 43, installing the ~730 KiB bpftool pulls
in ~140 MiB of llvm20-libs.

When libLLVM is a shared library, don't link bpftool with it. Instead,
disasm_init() loads it with dlopen(), under its soname read at build
time, and resolves the few llvm-c functions bpftool uses with dlsym(),
like perf does for libcapstone. Distributions can then make LLVM an
optional dependency of bpftool.

"bpftool version" still reports "llvm" as a build time feature. Static
LLVM, and LLVM built with one library per component, are linked as before.

Link: https://github.com/libbpf/bpftool/issues/262
Suggested-by: Alexei Starovoitov <ast@kernel.org>
Signed-off-by: Mark Korenberg <socketpair@gmail.com>
---
 tools/bpf/bpftool/Documentation/common_options.rst | 10 ++-
 tools/bpf/bpftool/Makefile                         | 16 +++-
 tools/bpf/bpftool/jit_disasm.c                     | 86 ++++++++++++++++++++++
 3 files changed, 107 insertions(+), 5 deletions(-)

diff --git a/tools/bpf/bpftool/Documentation/common_options.rst b/tools/bpf/bpftool/Documentation/common_options.rst
index 9234b9dab7682..b00fff6195e51 100644
--- a/tools/bpf/bpftool/Documentation/common_options.rst
+++ b/tools/bpf/bpftool/Documentation/common_options.rst
@@ -6,10 +6,12 @@
 -V, --version
     Print bpftool's version number (similar to **bpftool version**), the number
     of the libbpf version in use, and optional features that were included when
-    bpftool was compiled. Optional features include linking against LLVM or
-    libbfd to provide the disassembler for JIT-ted programs (**bpftool prog
-    dump jited**) and usage of BPF skeletons (some features like **bpftool prog
-    profile** or showing pids associated to BPF objects may rely on it).
+    bpftool was compiled. Optional features include LLVM or libbfd to provide
+    the disassembler for JIT-ted programs (**bpftool prog dump jited**) and
+    usage of BPF skeletons (some features like **bpftool prog profile** or
+    showing pids associated to BPF objects may rely on it). A shared libLLVM
+    is only loaded to disassemble JIT-ted programs, so "llvm" is listed even
+    if it is not installed.
 
 -j, --json
     Generate JSON output. For commands that cannot produce JSON, this option
diff --git a/tools/bpf/bpftool/Makefile b/tools/bpf/bpftool/Makefile
index b0f7168e79432..49dabf2eded04 100644
--- a/tools/bpf/bpftool/Makefile
+++ b/tools/bpf/bpftool/Makefile
@@ -186,10 +186,24 @@ ifeq ($(HAS_LLVM),1)
   # Makefile includes lib.mk which sets -D_GNU_SOURCE) which would cause
   # compilation error due to redefinition. Let's filter it out here.
   CFLAGS  += $(filter-out -D_GNU_SOURCE,$(shell $(LLVM_CONFIG) --cflags))
-  LIBS    += $(shell $(LLVM_CONFIG) --libs $(LLVM_CONFIG_LIB_COMPONENTS))
+  LIBLLVM_SO := $(shell $(LLVM_CONFIG) --libfiles $(LLVM_CONFIG_LIB_COMPONENTS))
   ifeq ($(shell $(LLVM_CONFIG) --shared-mode),static)
+    LIBS += $(shell $(LLVM_CONFIG) --libs $(LLVM_CONFIG_LIB_COMPONENTS))
     LIBS += $(shell $(LLVM_CONFIG) --system-libs $(LLVM_CONFIG_LIB_COMPONENTS))
     LIBS += -lstdc++
+  else ifeq ($(words $(LIBLLVM_SO)),1)
+    # Don't link with libLLVM.so. "prog dump jited" loads it with dlopen(),
+    # under the name the linker would put in DT_NEEDED.
+    LIBLLVM_SONAME := $(shell LC_ALL=C $(READELF) -d $(LIBLLVM_SO) | sed -nE \
+	's/.*\(SONAME\).*\[(.*)\]/\1/p')
+    ifeq ($(LIBLLVM_SONAME),)
+      $(error Cannot read the soname of $(LIBLLVM_SO))
+    endif
+    CFLAGS += -DLIBLLVM_SO='"$(LIBLLVM_SONAME)"'
+    LIBS += -ldl
+  else
+    # LLVM built with BUILD_SHARED_LIBS=ON, one library per component
+    LIBS += $(shell $(LLVM_CONFIG) --libs $(LLVM_CONFIG_LIB_COMPONENTS))
   endif
   LDFLAGS += $(shell $(LLVM_CONFIG) --ldflags)
 else
diff --git a/tools/bpf/bpftool/jit_disasm.c b/tools/bpf/bpftool/jit_disasm.c
index 5ff144ce84a1c..2c646626e2560 100644
--- a/tools/bpf/bpftool/jit_disasm.c
+++ b/tools/bpf/bpftool/jit_disasm.c
@@ -25,6 +25,7 @@
 #include <bpf/libbpf.h>
 
 #ifdef HAVE_LLVM_SUPPORT
+#include <dlfcn.h>
 #include <llvm-c/Core.h>
 #include <llvm-c/Disassembler.h>
 #include <llvm-c/Target.h>
@@ -47,6 +48,89 @@ static int oper_count;
 
 typedef LLVMDisasmContextRef disasm_ctx_t;
 
+#ifdef LIBLLVM_SO
+/*
+ * libLLVM.so is big and only "prog dump jited" needs it. bpftool is not linked
+ * with it. disasm_init() loads it.
+ */
+#define LLVM_FUNCS(F)			\
+	F(LLVMCreateDisasm)		\
+	F(LLVMCreateDisasmCPUFeatures)	\
+	F(LLVMDisasmDispose)		\
+	F(LLVMDisasmInstruction)	\
+	F(LLVMDisposeMessage)		\
+	F(LLVMGetDefaultTargetTriple)	\
+	F(LLVMNormalizeTargetTriple)
+
+#define F(fn) static __typeof__(&fn) p_##fn;
+LLVM_FUNCS(F)
+#undef F
+
+static const struct {
+	const char *name;
+	void *ptr;
+} llvm_funcs[] = {
+#define F(fn) { #fn, &p_##fn },
+	LLVM_FUNCS(F)
+#undef F
+};
+
+/* The functions that LLVMInitializeAll*() in llvm-c/Target.h call */
+static const char * const llvm_init_funcs[] = {
+#define LLVM_TARGET(t)	"LLVMInitialize" #t "TargetInfo",	\
+			"LLVMInitialize" #t "TargetMC",
+#include <llvm/Config/Targets.def>
+#define LLVM_DISASSEMBLER(t) "LLVMInitialize" #t "Disassembler",
+#include <llvm/Config/Disassemblers.def>
+};
+
+#define LLVMCreateDisasm		p_LLVMCreateDisasm
+#define LLVMCreateDisasmCPUFeatures	p_LLVMCreateDisasmCPUFeatures
+#define LLVMDisasmDispose		p_LLVMDisasmDispose
+#define LLVMDisasmInstruction		p_LLVMDisasmInstruction
+#define LLVMDisposeMessage		p_LLVMDisposeMessage
+#define LLVMGetDefaultTargetTriple	p_LLVMGetDefaultTargetTriple
+#define LLVMNormalizeTargetTriple	p_LLVMNormalizeTargetTriple
+
+static void *llvm_sym(void *lib, const char *name)
+{
+	void *sym = dlsym(lib, name);
+
+	if (!sym)
+		p_err("%s is not in %s", name, LIBLLVM_SO);
+	return sym;
+}
+
+int disasm_init(void)
+{
+	void (*init)(void);
+	void *lib, *sym;
+	size_t i;
+
+	lib = dlopen(LIBLLVM_SO, RTLD_NOW);
+	if (!lib) {
+		p_err("failed to load %s: %s", LIBLLVM_SO,
+		      dlerror() ?: "unknown error");
+		return -1;
+	}
+
+	for (i = 0; i < ARRAY_SIZE(llvm_funcs); i++) {
+		sym = llvm_sym(lib, llvm_funcs[i].name);
+		if (!sym)
+			return -1;
+		*(void **)llvm_funcs[i].ptr = sym;
+	}
+
+	for (i = 0; i < ARRAY_SIZE(llvm_init_funcs); i++) {
+		init = llvm_sym(lib, llvm_init_funcs[i]);
+		if (!init)
+			return -1;
+		init();
+	}
+	return 0;
+}
+#endif /* LIBLLVM_SO */
+
 static int printf_json(char *s)
 {
 	s = strtok(s, " \t");
@@ -135,6 +219,7 @@ disassemble_insn(disasm_ctx_t *ctx, unsigned char *image, ssize_t len, int pc,
 	return count;
 }
 
+#ifndef LIBLLVM_SO
 int disasm_init(void)
 {
 	LLVMInitializeAllTargetInfos();
@@ -142,6 +227,7 @@ int disasm_init(void)
 	LLVMInitializeAllDisassemblers();
 	return 0;
 }
+#endif
 #endif /* HAVE_LLVM_SUPPORT */
 
 #ifdef HAVE_LIBBFD_SUPPORT

-- 
2.56.0

