From: Gleb Pesin <dormancygrace@gmail.com>
Date: Tue, 06 Oct 2026 03:35:55 +0300
Subject: [PATCH 2/3] riscv: Make the vendor extension headers usable from
 assembly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-riscv-xtheadvector-vs-v1-2-b00e5abc9f7a@gmail.com>
References: <20261006-riscv-xtheadvector-vs-v1-0-b00e5abc9f7a@gmail.com>
In-Reply-To: <20261006-riscv-xtheadvector-vs-v1-0-b00e5abc9f7a@gmail.com>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Andy Chiu <tchiu@tenstorrent.com>, 
 Charlie Jenkins <thecharlesjenkins@gmail.com>, stable@vger.kernel.org, 
 Gleb Pesin <dormancygrace@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791246959; l=3518;
 i=dormancygrace@gmail.com; s=20261006; h=from:subject:message-id;
 bh=uS9Af9tVoEa4c8sQkOgjv/oYrhckO8osB2DVAqKiDJQ=;
 b=I76PHL05C45eefzwCne75zKJetUcvKyxASA+9GHQHReQHPfJWy9KtwPAkZqJGQjsO5B+WPb/r
 G5jFL7LEXOhDaleql+jNFOTSav9N5LXlgtjDTjSYQZxQz+8FKUp6Y0b
X-Developer-Key: i=dormancygrace@gmail.com; a=ed25519;
 pk=Ha8pk6XE0bhPh/mNtu1MKWgYqiX+CxZdhLyDR1rgD/M=
X-Endpoint-Received: by B4 Relay for dormancygrace@gmail.com/20261006 with auth_id=1121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

<asm/vendor_extensions.h> and <asm/vendor_extensions/thead.h> provide
the constants that ALTERNATIVE() needs for a vendor extension
(RISCV_VENDOR_EXT_ALTERNATIVES_BASE and RISCV_ISA_VENDOR_EXT_*), but
they also pull in C headers and declarations, so assembly files cannot
include them.

Keep the constants visible to assembly and guard the rest with
__ASSEMBLY__. No functional change.

This is needed by the next patch, which uses the xtheadvector
alternative in entry.S.

Cc: stable@vger.kernel.org # 6.14+: needed by the next patch
Assisted-by: LLM
Signed-off-by: Gleb Pesin <dormancygrace@gmail.com>
---
 arch/riscv/include/asm/vendor_extensions.h       | 28 ++++++++++++++----------
 arch/riscv/include/asm/vendor_extensions/thead.h |  8 +++++--
 2 files changed, 22 insertions(+), 14 deletions(-)

diff --git a/arch/riscv/include/asm/vendor_extensions.h b/arch/riscv/include/asm/vendor_extensions.h
index 7437304a7..c9fca8591 100644
--- a/arch/riscv/include/asm/vendor_extensions.h
+++ b/arch/riscv/include/asm/vendor_extensions.h
@@ -6,16 +6,25 @@
 #ifndef _ASM_VENDOR_EXTENSIONS_H
 #define _ASM_VENDOR_EXTENSIONS_H
 
-#include <asm/cpufeature.h>
-
-#include <linux/array_size.h>
-#include <linux/types.h>
-
 /*
  * The extension keys of each vendor must be strictly less than this value.
  */
 #define RISCV_ISA_VENDOR_EXT_MAX 32
 
+/*
+ * The alternatives need some way of distinguishing between vendor extensions
+ * and errata. Incrementing all of the vendor extension keys so they are at
+ * least 0x8000 accomplishes that.
+ */
+#define RISCV_VENDOR_EXT_ALTERNATIVES_BASE	0x8000
+
+#ifndef __ASSEMBLY__
+
+#include <asm/cpufeature.h>
+
+#include <linux/array_size.h>
+#include <linux/types.h>
+
 struct riscv_isavendorinfo {
 	DECLARE_BITMAP(isa, RISCV_ISA_VENDOR_EXT_MAX);
 };
@@ -32,13 +41,6 @@ extern struct riscv_isa_vendor_ext_data_list *riscv_isa_vendor_ext_list[];
 
 extern const size_t riscv_isa_vendor_ext_list_size;
 
-/*
- * The alternatives need some way of distinguishing between vendor extensions
- * and errata. Incrementing all of the vendor extension keys so they are at
- * least 0x8000 accomplishes that.
- */
-#define RISCV_VENDOR_EXT_ALTERNATIVES_BASE	0x8000
-
 #define VENDOR_EXT_ALL_CPUS			-1
 
 bool __riscv_isa_vendor_extension_available(int cpu, unsigned long vendor, unsigned int bit);
@@ -101,4 +103,6 @@ static __always_inline bool riscv_cpu_has_vendor_extension_unlikely(const unsign
 	return __riscv_isa_vendor_extension_available(cpu, vendor, ext);
 }
 
+#endif /* __ASSEMBLY__ */
+
 #endif /* _ASM_VENDOR_EXTENSIONS_H */
diff --git a/arch/riscv/include/asm/vendor_extensions/thead.h b/arch/riscv/include/asm/vendor_extensions/thead.h
index e85c75b3b..625f44175 100644
--- a/arch/riscv/include/asm/vendor_extensions/thead.h
+++ b/arch/riscv/include/asm/vendor_extensions/thead.h
@@ -4,13 +4,15 @@
 
 #include <asm/vendor_extensions.h>
 
-#include <linux/types.h>
-
 /*
  * Extension keys must be strictly less than RISCV_ISA_VENDOR_EXT_MAX.
  */
 #define RISCV_ISA_VENDOR_EXT_XTHEADVECTOR		0
 
+#ifndef __ASSEMBLY__
+
+#include <linux/types.h>
+
 extern struct riscv_isa_vendor_ext_data_list riscv_isa_vendor_ext_list_thead;
 
 #ifdef CONFIG_RISCV_ISA_VENDOR_EXT_THEAD
@@ -19,6 +21,8 @@ void disable_xtheadvector(void);
 static inline void disable_xtheadvector(void) { }
 #endif
 
+#endif /* __ASSEMBLY__ */
+
 /* Extension specific helpers */
 
 /*

-- 
2.53.0

