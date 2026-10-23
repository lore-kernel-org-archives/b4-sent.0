From: Han Gao <gaohan@iscas.ac.cn>
Date: Fri, 23 Oct 2026 15:33:14 +0800
Subject: [PATCH 1/5] riscv: kexec: Disable the MMU before walking the entry
 list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-riscv-kexec-cma-fixes-v1-1-825b90ea23c4@iscas.ac.cn>
References: <20261023-riscv-kexec-cma-fixes-v1-0-825b90ea23c4@iscas.ac.cn>
In-Reply-To: <20261023-riscv-kexec-cma-fixes-v1-0-825b90ea23c4@iscas.ac.cn>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Baoquan He <baoquan.he@linux.dev>, Mike Rapoport <rppt@kernel.org>, 
 Pasha Tatashin <pasha.tatashin@soleen.com>, 
 Pratyush Yadav <pratyush@kernel.org>, Yao Zi <me@ziyao.cc>
Cc: Han Gao <rabenda.cn@gmail.com>, Han Gao <gaohan@iscas.ac.cn>, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 llvm@lists.linux.dev, kexec@lists.infradead.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792740795; l=2405;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=EJAmc1LhiOIaPfBoanoCTj1bfUwyzJ9NpP/6hMQvfHg=;
 b=HLOjXket0TJYHSjizcezuxCYXNT1wamHy7x02PGGvb9bpIIlzpofSThrWyW6LG0iwUaelhZT9
 ertk9LY+oWQCK+TpyWDObtpYQmdHgxIQWiAwAV1oGrsKG+MLqHRx8Zi
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

riscv_kexec_relocate() only switches satp to Bare when it meets an
IND_INDIRECTION entry. Since segments may be allocated from CMA at their
destination, an image can have no indirection pages, and its list then
holds only IND_DONE. The relocation code jumps to the physical entry
point with the MMU still enabled and loops on instruction page faults.

Switch to Bare mode before reading the first entry, converting the list
pointer from its linear-map address.

Fixes: 07d24902977e ("kexec: enable CMA based contiguous allocation")
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/kernel/kexec_relocate.S | 29 +++++++++++++----------------
 1 file changed, 13 insertions(+), 16 deletions(-)

diff --git a/arch/riscv/kernel/kexec_relocate.S b/arch/riscv/kernel/kexec_relocate.S
index de0a4b35d01e..419b56600550 100644
--- a/arch/riscv/kernel/kexec_relocate.S
+++ b/arch/riscv/kernel/kexec_relocate.S
@@ -34,24 +34,22 @@ SYM_CODE_START(riscv_kexec_relocate)
 	csrw	CSR_SIP, zero
 
 	/*
-	 * When we switch SATP.MODE to "Bare" we'll only
-	 * play with physical addresses. However the first time
-	 * we try to jump somewhere, the offset on the jump
-	 * will be relative to pc which will still be on VA. To
-	 * deal with this we set stvec to the physical address at
-	 * the start of the loop below so that we jump there in
-	 * any case.
+	 * Switch SATP.MODE to "Bare" before reading any entry. An image
+	 * whose segments were allocated from CMA at their destination has
+	 * no indirection pages, so its list may hold only IND_DONE.
+	 *
+	 * pc is still a VA here: set stvec to the physical address of the
+	 * loop below, so that we get there even if the next instruction
+	 * fetch faults. The entry list starts at image->head, in the
+	 * linear mapping.
 	 */
 	la	s6, 1f
 	sub	s6, s6, s4
+	sub	s0, s0, s4
 	csrw	CSR_STVEC, s6
-
-	/*
-	 * With C-extension, here we get 42 Bytes and the next
-	 * .align directive would pad zeros here up to 44 Bytes.
-	 * So manually put a nop here to avoid zeros padding.
-	*/
-	nop
+	csrw	CSR_SATP, zero
+	sfence.vma
+	jr	s6
 
 	/* Process entries in a loop */
 .align 2
@@ -70,8 +68,7 @@ SYM_CODE_START(riscv_kexec_relocate)
 	andi	t1, t0, 0x2
 	beqz	t1, 2f
 	andi	s0, t0, ~0x2
-	csrw	CSR_SATP, zero
-	jr	s6
+	j	1b
 
 2:
 	/* IND_DONE entry ? -> jump to done label */

-- 
2.55.0

