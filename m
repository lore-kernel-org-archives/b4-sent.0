From: Ridge Lomont <cyridge@proton.me>
Date: Tue, 27 Oct 2026 15:29:21 -0700
Subject: [PATCH v2] x86/kcfi: Don't emit KCFI_REFERENCE() in modules
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-kcfi-reference-modules-v2-1-3a3247f15806@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0Jm7Zi2VIyuvIdhUcsgo9KSthAN4
 e4WPIDLl7z//gyRAlOEczFDoIkje5dB7QqwnXF3Qm4ygxKqkkJpfNqWMVBLgZwl7H0zviii0LZ
 UQmjTagl5PGSF31v4Wv84jrcH2bTWVqPjmHz4bM+TXL2/J5NEibq0ymhzoupwvAzBJ+/2PUG9L
 MsXINswks4AAAA=
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
 linux-sparse@vger.kernel.org, Ridge Lomont <cyridge@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793140168; l=4583;
 i=cyridge@proton.me; s=20261025; h=from:subject:message-id;
 bh=OQJeHIflLTXu8GG/soe5gJtL1JN4lbjLzWGutcYzYdg=;
 b=6F9puhQ8giJgHtu2O11XOMl3gX9kmfChhfvdlW1snl0do298NDHav1MNEv1s4gxln4pPHnqpX
 fFSoz5RncMyBEr/G0tGtiNgwPwfHc2yfiDKs5l+daJQ8Rg6y32rWe10
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

scripts/module.lds.S does not help here: modpost checks <module>.o
before the final link, and even after it the discarded section only
loses its relocations, the undefined symbols stay in .symtab, where
the module loader resolves them with the same license check.

Only emit the reference when building vmlinux.

Tested on x86_64 with clang 23.1.3 and CONFIG_CFI=y, with both
CONFIG_LTO_CLANG_FULL=y (the configuration from the Fixes: commit) and
CONFIG_LTO_CLANG_THIN=y: vmlinux links without warnings and still contains
__kcfi_typeid___clear_pages_unrolled, __kcfi_typeid_copy_page,
__kcfi_typeid___memset and __kcfi_typeid___memmove. It boots in QEMU
with no CFI failures. A minimal module with MODULE_LICENSE("Proprietary")
including <linux/mm.h> fails modpost before this change and builds and
loads after it. OpenZFS builds against a CFI kernel with this change,
and its pool, encryption, checksum and send/recv operations run
without CFI failures, in QEMU and on a desktop with CFI enforcing.

Fixes: 9b041a4b66b3 ("x86/mm: Ensure clear_page() variants always have __kcfi_typeid_ symbols")
Link: https://github.com/openzfs/zfs/issues/18092
Assisted-by: LLM
Signed-off-by: Ridge Lomont <cyridge@proton.me>
Acked-by: Nathan Chancellor <nathan@kernel.org>
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
  KCFI_REFERENCE(). Tested with CONFIG_LTO_CLANG_FULL=y and
  CONFIG_LTO_CLANG_THIN=y on this tree and with LTO disabled on v7.3.
  In-tree modules were built but not loaded.
- checkpatch reports "Non-standard signature: Assisted-by:", which
  conflicts with Documentation/process/coding-assistants.rst.
---
Changes in v2:
- Sign off with my real name (Peter, Borislav).
- Explain in the changelog why module.lds.S discarding
  .discard.addressable does not help (Nathan).
- Also tested with CONFIG_LTO_CLANG_THIN=y.
- Add Nathan's Acked-by.
- Link to v1: https://patch.msgid.link/20261024-kcfi-reference-modules-v1-1-43c2a4a9e657@proton.me
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
Ridge

