From: Gleb Pesin <dormancygrace@gmail.com>
Date: Tue, 06 Oct 2026 03:35:56 +0300
Subject: [PATCH 3/3] riscv: Disable the xtheadvector unit on kernel entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-riscv-xtheadvector-vs-v1-3-b00e5abc9f7a@gmail.com>
References: <20261006-riscv-xtheadvector-vs-v1-0-b00e5abc9f7a@gmail.com>
In-Reply-To: <20261006-riscv-xtheadvector-vs-v1-0-b00e5abc9f7a@gmail.com>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Andy Chiu <tchiu@tenstorrent.com>, 
 Charlie Jenkins <thecharlesjenkins@gmail.com>, stable@vger.kernel.org, 
 Gleb Pesin <dormancygrace@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791246959; l=2161;
 i=dormancygrace@gmail.com; s=20261006; h=from:subject:message-id;
 bh=QQB545Y5GthJc3aps7t7217QNuC1lzUjs760uVslRWU=;
 b=pBklWC8ABOaDr3+tT9E9nKkIEvVnsrT62W428b1i7o5ARYAGv/Qe9xtflZQYjkx7ZnqLgS6kj
 feKzM8Be0AkBfMmsEnLSuVlAt0QHg1W7ulhLorjvdn86iEBSThdjL2B
X-Developer-Key: i=dormancygrace@gmail.com; a=ed25519;
 pk=Ha8pk6XE0bhPh/mNtu1MKWgYqiX+CxZdhLyDR1rgD/M=
X-Endpoint-Received: by B4 Relay for dormancygrace@gmail.com/20261006 with auth_id=1121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

handle_exception clears SR_FS_VS on entry so that stray floating-point
or vector instructions in the kernel raise an illegal-instruction
exception. xtheadvector keeps its vector status in SR_VS_THEAD
(sstatus bits 24:23), which that mask does not cover. On 64-bit kernels
bit 23 happens to be cleared as SR_SPELP, so the T-Head field is only
partly reset: DIRTY becomes CLEAN, and the vector unit stays enabled in
the kernel after a trap from a context that used it.

Clear the whole SR_VS_THEAD field on cores with xtheadvector. The status
saved in pt_regs still holds the interrupted value, so the vector state
is restored on return exactly as before. Other cores keep the current
mask, because bit 24 is not part of the vector status there.

Fixes: d863910eabaf ("riscv: vector: Support xtheadvector save/restore")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Gleb Pesin <dormancygrace@gmail.com>
---
 arch/riscv/kernel/entry.S | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/arch/riscv/kernel/entry.S b/arch/riscv/kernel/entry.S
index d799c4e56..aeb99c20b 100644
--- a/arch/riscv/kernel/entry.S
+++ b/arch/riscv/kernel/entry.S
@@ -16,6 +16,8 @@
 #include <asm/thread_info.h>
 #include <asm/asm-offsets.h>
 #include <asm/errata_list.h>
+#include <asm/vendor_extensions.h>
+#include <asm/vendor_extensions/thead.h>
 #include <linux/sizes.h>
 
 	.section .irqentry.text, "ax"
@@ -176,9 +178,14 @@ SYM_CODE_START(handle_exception)
 	 * actual user copy routines.
 	 *
 	 * Disable the FPU/Vector to detect illegal usage of floating point
-	 * or vector in kernel space.
+	 * or vector in kernel space. xtheadvector keeps its vector status in
+	 * a different sstatus field; those bits are reserved elsewhere.
 	 */
-	li t0, SR_SUM | SR_FS_VS
+	ALTERNATIVE(__stringify(li t0, SR_SUM | SR_FS_VS),
+		    __stringify(li t0, SR_SUM | SR_FS_VS | SR_VS_THEAD),
+		    THEAD_VENDOR_ID,
+		    RISCV_VENDOR_EXT_ALTERNATIVES_BASE + RISCV_ISA_VENDOR_EXT_XTHEADVECTOR,
+		    CONFIG_RISCV_ISA_XTHEADVECTOR)
 #ifdef CONFIG_64BIT
 	li t1, SR_ELP
 	or t0, t0, t1

-- 
2.53.0

