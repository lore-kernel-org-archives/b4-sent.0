From: Cytops <cyridge@proton.me>
Date: Sat, 24 Oct 2026 18:46:33 -0700
Subject: [PATCH] x86/kcfi: Don't emit KCFI_REFERENCE() in modules
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-kcfi-reference-modules-v1-1-43c2a4a9e657@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw7CMAyE4atUXmPJCRELroJYFHcC5pGiuEVIV
 e9OgOUnzfwLOarBad8tVPEyt7E0hE1HeunLGWxDM0WJuyAx8U2zcUVGRVHwYxzmO5wl6TaKpD6
 nQO38bBN7/8KH498+n67Q6Vujdf0A+zirNnoAAAA=
X-Change-ID: 20261024-kcfi-reference-modules-04c32004af41
To: x86@kernel.org, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, Chris Li <sparse@chrisli.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>
Cc: "H. Peter Anvin" <hpa@zytor.com>, Peter Zijlstra <peterz@infradead.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Kees Cook <kees@kernel.org>, 
 llvm@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-sparse@vger.kernel.org, Cytops <cyridge@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792892794; l=3893;
 i=cyridge@proton.me; s=20261025; h=from:subject:message-id;
 bh=Fe94LxVGlnE7TJPGMDWrW2p2gjEVsTcy+l0YVlT+XbQ=;
 b=3ms2BQ7UUfPIgKWFHNG+ZqtmWMnXu2DPdyGZKqyMErCmt0kQPJuLnEUKY5NtqR9dver0GC+24
 NBd3966TkZ0DVDNh+Pey0aXFAh127ip+BSYSSfVGwmtE+nJBiqYDd2p
X-Developer-Key: i=cyridge@proton.me; a=ed25519;
 pk=vUzN9FERlHN1g72uX883qK0g48rf4ZgAQ82J2Aieyyo=
X-Endpoint-Received: by B4 Relay for cyridge@proton.me/20261025 with auth_id=1315
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KCFI_REFERENCE() takes the address of a symbol so that the compiler
emits its __kcfi_typeid_ symbol, which the SYM_TYPED_FUNC_START()
assembly implementing it needs. It is used from arch/x86 headers for
__clear_pages_unrolled(), copy_page(), __memset() and __memmove(), and
all of that assembly is built into vmlinux.

Modules include the same headers, so with CONFIG_CFI=y every module
also gets an __ADDRESSABLE() reference to each of these symbols in
.discard.addressable. This serves no purpose there, and since
__clear_pages_unrolled() is EXPORT_SYMBOL_GPL, modpost now rejects any
GPL-incompatible module that includes <linux/mm.h>:

  ERROR: modpost: GPL-incompatible module repro.ko uses GPL-only
  symbol '__clear_pages_unrolled'

even though the module never uses the symbol. This makes OpenZFS
impossible to build against CFI kernels; its configure checks fail
in the same way and are misreported as CONFIG_DEBUG_LOCK_ALLOC.

Only emit the reference when building vmlinux.

Tested on x86_64 with clang 23.1.3, CONFIG_CFI=y and
CONFIG_LTO_CLANG_FULL=y (the configuration from the Fixes: commit):
vmlinux links without warnings and still contains
__kcfi_typeid___clear_pages_unrolled, __kcfi_typeid_copy_page,
__kcfi_typeid___memset and __kcfi_typeid___memmove. It boots in QEMU
with no CFI failures. A minimal module with MODULE_LICENSE("Proprietary")
including <linux/mm.h> fails modpost before this change and builds and
loads after it. OpenZFS builds against a CFI kernel with this change,
and its pool, encryption, checksum and send/recv operations run with
CONFIG_CFI_PERMISSIVE=y without CFI failures.

Fixes: 9b041a4b66b3 ("x86/mm: Ensure clear_page() variants always have __kcfi_typeid_ symbols")
Link: https://github.com/openzfs/zfs/issues/18092
Assisted-by: LLM
Signed-off-by: Cytops <cyridge@proton.me>
---
Notes for reviewers:

- The fix was found and written with an AI coding assistant (Claude
  Opus 5.5, Claude Code). It started from "CONFIG_CFI breaks
  OpenZFS"; the assistant traced that to the modpost failure,
  wrote this change, and ran the tests described in the changelog.
  I have reviewed it and take responsibility for it.
- An alternative would be wrapping the KCFI_REFERENCE() lines in
  arch/x86/include/asm/page_64.h in #ifndef MODULE, as suggested in
  the OpenZFS report; doing it in the macro covers all users.
- Only x86_64 was tested; it is the only architecture using
  KCFI_REFERENCE(). Tested with CONFIG_LTO_CLANG_FULL=y on this tree
  and with LTO disabled on v7.3; not tested with
  CONFIG_LTO_CLANG_THIN=y. In-tree modules were built but not loaded.
- checkpatch reports "Non-standard signature: Assisted-by:", which
  conflicts with Documentation/process/coding-assistants.rst.
---
 include/linux/compiler.h | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/include/linux/compiler.h b/include/linux/compiler.h
index 0ea7150db..ea161a72d 100644
--- a/include/linux/compiler.h
+++ b/include/linux/compiler.h
@@ -258,10 +258,13 @@ void ftrace_likely_update(struct ftrace_likely_data *f, int val,
 
 #endif /* __KERNEL__ */
 
-#if defined(CONFIG_CFI) && !defined(__DISABLE_EXPORTS) && !defined(BUILD_VDSO)
+#if defined(CONFIG_CFI) && !defined(__DISABLE_EXPORTS) && !defined(BUILD_VDSO) && \
+	!defined(MODULE)
 /*
  * Force a reference to the external symbol so the compiler generates
- * __kcfi_typid.
+ * __kcfi_typid. Only vmlinux needs it, as that is where the assembly
+ * using the typeid lives; in a module it would only add a reference to
+ * the symbol, which fails modpost if the symbol is GPL-only.
  */
 #define KCFI_REFERENCE(sym) __ADDRESSABLE(sym)
 #else

---
base-commit: 6fba331225f5040e93d0947d1027e9712238291f
change-id: 20261024-kcfi-reference-modules-04c32004af41

Best regards,
--  
Cytops <cyridge@proton.me>

