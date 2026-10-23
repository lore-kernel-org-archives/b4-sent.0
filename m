From: Han Gao <gaohan@iscas.ac.cn>
Date: Fri, 23 Oct 2026 15:33:18 +0800
Subject: [PATCH 5/5] riscv: mm: Reserve the DTB before scanning reserved
 memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-riscv-kexec-cma-fixes-v1-5-825b90ea23c4@iscas.ac.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792740795; l=1985;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=VzDY7dyAHKNfLvxVCMqMtt5zDiHGvSFYWd6M9xkmP3Q=;
 b=ynBWGFpdbYvy9nnbxS+RD2v0R24FuhHdVx/pA9FCO5SLszbXll6aF7o0YMqpG/cUfpt7vCaG6
 M/xMlmo/qUhDMflVxgs92GtOIBWgIfrlbCgqOjkxvuaz/kOdqlNapwe
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

setup_bootmem() reserves the DTB only after
early_init_fdt_scan_reserved_mem() has allocated the dynamically placed
reserved-memory regions. A CMA pool described with size and alloc-ranges
can therefore be placed over the DTB, which is later handed to the page
allocator and overwritten.

This happens after kexec_file has put the DTB of the next kernel in CMA:
the next kernel reuses that range for its own pool, and a further
kexec_file_load() fails with -FDT_ERR_BADMAGIC.

Reserve the DTB first.

Fixes: ef69d2559fe9 ("riscv: Move early dtb mapping into the fixmap region")
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 arch/riscv/mm/init.c | 18 ++++++++++--------
 1 file changed, 10 insertions(+), 8 deletions(-)

diff --git a/arch/riscv/mm/init.c b/arch/riscv/mm/init.c
index fb37b0b67efe..1ca908bcc4c0 100644
--- a/arch/riscv/mm/init.c
+++ b/arch/riscv/mm/init.c
@@ -290,21 +290,23 @@ static void __init setup_bootmem(void)
 
 	reserve_initrd_mem();
 
-	/*
-	 * No allocation should be done before reserving the memory as defined
-	 * in the device tree, otherwise the allocation could end up in a
-	 * reserved region.
-	 */
-	early_init_fdt_scan_reserved_mem();
-
 	/*
 	 * If DTB is built in, no need to reserve its memblock.
 	 * Otherwise, do reserve it but avoid using
 	 * early_init_fdt_reserve_self() since __pa() does
-	 * not work for DTB pointers that are fixmap addresses
+	 * not work for DTB pointers that are fixmap addresses.
+	 * Reserve it before dynamically placed reserved-memory
+	 * regions, such as a CMA pool, are allocated.
 	 */
 	if (!IS_ENABLED(CONFIG_BUILTIN_DTB))
 		memblock_reserve(dtb_early_pa, fdt_totalsize(dtb_early_va));
+
+	/*
+	 * No allocation should be done before reserving the memory as defined
+	 * in the device tree, otherwise the allocation could end up in a
+	 * reserved region.
+	 */
+	early_init_fdt_scan_reserved_mem();
 }
 
 #ifdef CONFIG_RELOCATABLE

-- 
2.55.0

