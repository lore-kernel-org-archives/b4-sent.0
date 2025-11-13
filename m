From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Thu, 13 Nov 2025 17:10:32 +0100
Subject: [PATCH v2] riscv: Update MIPS vendor id to 0x127.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-mips-vendorid-v2-1-3279489b7f84@htecgroup.com>
X-B4-Tracking: v=1; b=H4sIAPcCFmkC/12MQQ7CIBBFr9LMWkyhJSauvIfposJQZlEgUImm4
 e6Odefq5/3kvR0KZsIC126HjJUKxcCgTh0YP4cFBVlmUL3Ssh+kWCkVUTHYmMkK6/ickUdegJ2
 U0dHr6N0nZk9li/l95Kv8vr8SW3+lKoUUozMP7UarB4c3v6FZcnyms4krTK21D4p8D3euAAAA
X-Change-ID: 20251031-mips-vendorid-df103aedf117
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Conor Dooley <conor.dooley@microchip.com>
Cc: Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chao-ying Fu <cfu@wavecomp.com>, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763050233; l=1465;
 i=aleksa.paunovic@htecgroup.com; s=20250806; h=from:subject:message-id;
 bh=htvoMgY/r9ZZuZiS5oLQr0msScykVQRnyI0BkorgU5s=;
 b=DH0Z+mWY5DvQ1ZxYsIpMOn7gANn02HB+BPNMvkRg7eQ4UStyb1EgAQ25LZVGT9XGYIyk6D91j
 lGONnSsnfbdAof526t7owx6W4CImuzeLdyRHSBbcDvie3SEj0LzNJCv
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=Dn4KMnDdgyhlXJNspQQrlHJ04i7/irG29p2H27Avd+8=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250806 with auth_id=476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chao-ying Fu <cfu@wavecomp.com>

[1] defines MIPS vendor id as 0x127. All previous MIPS RISC-V patches
were tested on QEMU, also modified to use 0x722 as MIPS_VENDOR_ID. This
new value should reflect real hardware.

[1] https://mips.com/wp-content/uploads/2025/06/P8700_Programmers_Reference_Manual_Rev1.84_5-31-2025.pdf

Fixes: a8fed1bc03ac ("riscv: Add xmipsexectl as a vendor extension")
Signed-off-by: Chao-ying Fu <cfu@wavecomp.com>
Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
Changes in v2:
- Fix "Fixes" formatting
- Move "MIPS_VENDOR_ID" to the correct place.
- Link to v1: https://lore.kernel.org/r/20251103-mips-vendorid-v1-1-4fcb5f4d53fe@htecgroup.com
---
 arch/riscv/include/asm/vendorid_list.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/riscv/include/asm/vendorid_list.h b/arch/riscv/include/asm/vendorid_list.h
index 3b09874d7a6dfb8f8aa45b0be41c20711d539e78..7f5030ee1fcf830b17c6529e9c430fe19ac68b05 100644
--- a/arch/riscv/include/asm/vendorid_list.h
+++ b/arch/riscv/include/asm/vendorid_list.h
@@ -7,8 +7,8 @@
 
 #define ANDES_VENDOR_ID		0x31e
 #define MICROCHIP_VENDOR_ID	0x029
+#define MIPS_VENDOR_ID		0x127
 #define SIFIVE_VENDOR_ID	0x489
 #define THEAD_VENDOR_ID		0x5b7
-#define MIPS_VENDOR_ID		0x722
 
 #endif

---
base-commit: dcb6fa37fd7bc9c3d2b066329b0d27dedf8becaa
change-id: 20251031-mips-vendorid-df103aedf117

Best regards,
-- 
Aleksa Paunovic <aleksa.paunovic@htecgroup.com>

