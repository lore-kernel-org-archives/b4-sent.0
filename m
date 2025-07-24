From: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Date: Thu, 24 Jul 2025 17:23:30 +0200
Subject: [PATCH v5 6/7] riscv: Add tools support for xmipsexectl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250724-p8700-pause-v5-6-a6cbbe1c3412@htecgroup.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753370612; l=1792;
 i=aleksa.paunovic@htecgroup.com; s=20250514; h=from:subject:message-id;
 bh=ptovTVTWzY5ypMsdB9qvG2p0IpF3HX1Qk6cCHZ2BJ7Y=;
 b=cvYEEQqQIscI391aoxjPcy38xGkvOs72Op5o37Fz5zGhuJJuNcrQhOxlfmlgERoDpENItBnq9
 kxhulaZVCwvDvIUoa6kfudy7fSW90tgqTJ6jiIKVIE6S+mTGgzMZ/pR
X-Developer-Key: i=aleksa.paunovic@htecgroup.com; a=ed25519;
 pk=gFVSVYLKAgJiS5qCnDyUMGOFuczv8C6o0UmRs+fgisA=
X-Endpoint-Received: by B4 Relay for aleksa.paunovic@htecgroup.com/20250514 with auth_id=403
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the hwprobe syscall to decide which PAUSE instruction to execute in
userspace code.

Signed-off-by: Aleksa Paunovic <aleksa.paunovic@htecgroup.com>
Reviewed-by: Alexandre Ghiti <alexghiti@rivosinc.com>
---
 tools/arch/riscv/include/asm/vdso/processor.h | 27 +++++++++++++++++----------
 1 file changed, 17 insertions(+), 10 deletions(-)

diff --git a/tools/arch/riscv/include/asm/vdso/processor.h b/tools/arch/riscv/include/asm/vdso/processor.h
index 0665b117f30f2766a23446fbd7c8ce82d1843a93..b089d4be998f4ab7bc43a96496a6c6f1bb38da4d 100644
--- a/tools/arch/riscv/include/asm/vdso/processor.h
+++ b/tools/arch/riscv/include/asm/vdso/processor.h
@@ -4,26 +4,33 @@
 
 #ifndef __ASSEMBLER__
 
+#include <asm/hwprobe.h>
+#include <sys/hwprobe.h>
+#include <asm/vendor/mips.h>
+#include <asm/vendor_extensions/mips.h>
 #include <asm-generic/barrier.h>
 
 static inline void cpu_relax(void)
 {
+	struct riscv_hwprobe pair;
+	bool has_mipspause;
 #ifdef __riscv_muldiv
 	int dummy;
 	/* In lieu of a halt instruction, induce a long-latency stall. */
 	__asm__ __volatile__ ("div %0, %0, zero" : "=r" (dummy));
 #endif
 
-#ifdef CONFIG_TOOLCHAIN_HAS_ZIHINTPAUSE
-	/*
-	 * Reduce instruction retirement.
-	 * This assumes the PC changes.
-	 */
-	__asm__ __volatile__ ("pause");
-#else
-	/* Encoding of the pause instruction */
-	__asm__ __volatile__ (".4byte 0x100000F");
-#endif
+	pair.key = RISCV_HWPROBE_KEY_VENDOR_EXT_MIPS_0;
+	__riscv_hwprobe(&pair, 1, 0, NULL, 0);
+	has_mipspause = pair.value & RISCV_HWPROBE_VENDOR_EXT_XMIPSEXECTL;
+
+	if (has_mipspause) {
+		__asm__ __volatile__(MIPS_PAUSE);
+	} else {
+		/* Encoding of the pause instruction */
+		__asm__ __volatile__(".4byte 0x100000F");
+	}
+
 	barrier();
 }
 

-- 
2.34.1

