From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Thu, 24 Jul 2025 17:23:27 +0200
Subject: [PATCH v5 3/7] riscv: Add xmipsexectl instructions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250724-p8700-pause-v5-3-a6cbbe1c3412@htecgroup.com>
References: <20250724-p8700-pause-v5-0-a6cbbe1c3412@htecgroup.com>
In-Reply-To: <20250724-p8700-pause-v5-0-a6cbbe1c3412@htecgroup.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Jonathan Corbet <corbet@lwn.net>
Cc: Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 Djordje Todorovic <djordje.todorovic@htecgroup.com>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Aleksa Paunovic <aleksa.paunovic@htecgroup.com>, 
 Alexandre Ghiti <alexghiti@rivosinc.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753370612; l=1601;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=UiyuNpcwz9mf/w7Z4EE+JWW7TpbY11AARRS/HoJAhyY=;
 b=kXnwDRLnXwjTZ4lr4Rsy/L+SAr13tjMAbNWyOnuvvm6e4zSvz3YLRNrh0IR7dMh+8xMX09US2
 Wwjwe0PaWVDBXThnyVKeFAMlGqY3bEoiyc6llpvBoqixkCM53+F0yMu
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add xmipsexectl instruction opcodes. This includes the MIPS.PAUSE,
MIPS.EHB, and MIPS.IHB instructions.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Reviewed-by: Alexandre Ghiti <alexghiti@rivosinc.com>
---
 arch/riscv/include/asm/vendor_extensions/mips.h | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/arch/riscv/include/asm/vendor_extensions/mips.h b/arch/riscv/include/asm/vendor_extensions/mips.h
index 133e55985d827ce7d6057004b590bdcbbdb1ec8c..ea8ca747d691df2e9ee7e5360f800fbdccfe3945 100644
--- a/arch/riscv/include/asm/vendor_extensions/mips.h
+++ b/arch/riscv/include/asm/vendor_extensions/mips.h
@@ -15,4 +15,23 @@ struct riscv_isa_vendor_ext_data_list;
 extern struct riscv_isa_vendor_ext_data_list riscv_isa_vendor_ext_list_mips;
 #endif
 
+/* Extension specific instructions */
+
+/*
+ * All of the xmipsexectl extension instructions are
+ * ‘hint’ encodings of the SLLI instruction,
+ * with rd = 0, rs1 = 0 and imm = 1 for IHB, imm = 3 for EHB,
+ * and imm = 5 for PAUSE.
+ * MIPS.PAUSE is an alternative opcode which is implemented to have the
+ * same behavior as PAUSE on some MIPS RISCV cores.
+ * MIPS.EHB clears all execution hazards before allowing
+ * any subsequent instructions to execute.
+ * MIPS.IHB clears all instruction hazards before
+ * allowing any subsequent instructions to fetch.
+ */
+
+#define MIPS_PAUSE	".4byte 0x00501013\n\t"
+#define MIPS_EHB	".4byte 0x00301013\n\t"
+#define MIPS_IHB	".4byte 0x00101013\n\t"
+
 #endif // _ASM_RISCV_VENDOR_EXTENSIONS_MIPS_H

-- 
2.34.1

