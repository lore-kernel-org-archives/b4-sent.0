From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Mon, 03 Nov 2025 16:05:48 +0100
Subject: [PATCH] riscv: Update MIPS vendor id to 0x127.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251103-mips-vendorid-v1-1-4fcb5f4d53fe@htecgroup.com>
X-B4-Tracking: v=1; b=H4sIAMvECGkC/x2MQQqAIBBFryKzbkCNCLpKtJAcaxapKEgg3r2h1
 eM9+L9DpcJUYVMdCjWunKKImRSct4sXIXtxsNouRs8GH84VG0WfCnv0QaIjgVlBNrlQ4Pf/248
 xPmYzIjhfAAAA
X-Change-ID: 20251031-mips-vendorid-df103aedf117
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>
Cc: Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chao-ying Fu <cfu@wavecomp.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762182369; l=1072;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=3SOEHxo/iLuGukJm8WAmBVDY7Kaj7mnCfvYaKbPje/c=;
 b=4Kkbdn4PPtXv972XSyF6kf21wrzTj1bJorDUmNmTyjB4IwTbb7oxuMvedD8ZLszZ2g9Nqoo7u
 scJ+8ITMU60CBZIIxKx9oqKbZ2ibIQMpBlaBbdfTKqGsbYUHHuWe1DK
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chao-ying Fu <cfu@wavecomp.com>

[1] defines MIPS vendor id as 0x127.

[1] https://mips.com/wp-content/uploads/2025/06/P8700_Programmers_Reference_Manual_Rev1.84_5-31-2025.pdf

Fixes: a8fed1bc03ace27902338e4f0d318335883ac847 ("riscv: Add xmipsexectl as a vendor extension")
Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 arch/riscv/include/asm/vendorid_list.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/riscv/include/asm/vendorid_list.h b/arch/riscv/include/asm/vendorid_list.h
index 3b09874d7a6dfb8f8aa45b0be41c20711d539e78..55205f7938055ba2b744dba5118bba935bcac008 100644
--- a/arch/riscv/include/asm/vendorid_list.h
+++ b/arch/riscv/include/asm/vendorid_list.h
@@ -9,6 +9,6 @@
 #define MICROCHIP_VENDOR_ID	0x029
 #define SIFIVE_VENDOR_ID	0x489
 #define THEAD_VENDOR_ID		0x5b7
-#define MIPS_VENDOR_ID		0x722
+#define MIPS_VENDOR_ID		0x127
 
 #endif

---
base-commit: dcb6fa37fd7bc9c3d2b066329b0d27dedf8becaa
change-id: 20251031-mips-vendorid-df103aedf117

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

