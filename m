From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Wed, 25 Jun 2025 16:20:58 +0200
Subject: [PATCH v4 3/7] riscv: Add xmipsexectl PAUSE instruction
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250625-p8700-pause-v4-3-6c7dd7f85756@htecgroup.com>
References: <20250625-p8700-pause-v4-0-6c7dd7f85756@htecgroup.com>
In-Reply-To: <20250625-p8700-pause-v4-0-6c7dd7f85756@htecgroup.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Jonathan Corbet <corbet@lwn.net>
Cc: Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750861257; l=1045;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=H0DxxoGpB6+hFMlnoBCgKy/YEJN661bNeg8dzqTTc9Y=;
 b=j7mQ6M5PdjVnNF0Zd2eESw6UiAPu59p74ZSfKVOFi6F9oGfE+2+5A6EVzEf/XaS+NC9vhT0Du
 XMLyI4dbDM9AoC8vs7d+rXKvwQOcX3466I12/JDG/c8n/dmgsVwKKJ/
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MIPS.PAUSE instruction opcode. This instruction is a part of the
xmipsexectl vendor extension.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
---
 arch/riscv/include/asm/vendor_extensions/mips.h | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/riscv/include/asm/vendor_extensions/mips.h b/arch/riscv/include/asm/vendor_extensions/mips.h
index 757c941cfd86e9fced6169b1a82200e6bb5c6132..f8eca0bcf53e2de1bbdc66821fe95987105ed85a 100644
--- a/arch/riscv/include/asm/vendor_extensions/mips.h
+++ b/arch/riscv/include/asm/vendor_extensions/mips.h
@@ -13,4 +13,11 @@
 
 extern struct riscv_isa_vendor_ext_data_list riscv_isa_vendor_ext_list_mips;
 
+/* MIPS.PAUSE is an alternative opcode which is implemented to have the */
+/* same behavior as PAUSE on some MIPS RISCV cores. */
+/* It is a ‘hint’ encoding of the SLLI instruction, */
+/* with rd = 0, rs1 = 0 and imm = 5. */
+
+#define MIPS_PAUSE	".4byte 0x00501013\n\t"
+
 #endif // _ASM_RISCV_VENDOR_EXTENSIONS_MIPS_H

-- 
2.34.1

