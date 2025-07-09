From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Wed, 09 Jul 2025 19:05:59 +0800
Subject: [PATCH v2 8/9] MIPS: Unify Loongson1 PRID_REV
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250709-loongson1-arch-v2-8-bcff6e518c09@gmail.com>
References: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
In-Reply-To: <20250709-loongson1-arch-v2-0-bcff6e518c09@gmail.com>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
Cc: linux-mips@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Philippe_Mathieu-Daud=C3=A9?= <philmd@linaro.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752059245; l=1706;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=gUS5VFP2+HU6UgsUMUAXlQqSqNjhcNxWcW8wuO4vtbs=;
 b=5YLS4SMYr8orsDZy7V/3WCDQ1s6xa3cg/XEeO93cXs4+mrzKYxMDCNiK2izFY7KUMM0UIHHJU
 JrPFZslP2QEDDHqQk2Y0R8levJLXqvRPHMu1rVnufyoHzTbKxLtx9oS
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LS1B and LS1C share the same PRID value, so unify them
into a single definition: PRID_REV_LOONGSON1.

Reviewed-by: Philippe Mathieu-Daudé <philmd@linaro.org>
Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 arch/mips/include/asm/cpu.h  | 3 +--
 arch/mips/kernel/cpu-probe.c | 6 +++---
 2 files changed, 4 insertions(+), 5 deletions(-)

diff --git a/arch/mips/include/asm/cpu.h b/arch/mips/include/asm/cpu.h
index ecb9854cb432..4163b22c0a9a 100644
--- a/arch/mips/include/asm/cpu.h
+++ b/arch/mips/include/asm/cpu.h
@@ -248,8 +248,7 @@
 #define PRID_REV_VR4181A		0x0070	/* Same as VR4122 */
 #define PRID_REV_VR4130			0x0080
 #define PRID_REV_34K_V1_0_2		0x0022
-#define PRID_REV_LOONGSON1B		0x0020
-#define PRID_REV_LOONGSON1C		0x0020	/* Same as Loongson-1B */
+#define PRID_REV_LOONGSON1		0x0020
 #define PRID_REV_LOONGSON2E		0x0002
 #define PRID_REV_LOONGSON2F		0x0003
 #define PRID_REV_LOONGSON2K_R1_0	0x0000
diff --git a/arch/mips/kernel/cpu-probe.c b/arch/mips/kernel/cpu-probe.c
index af7412549e6e..ca1ab765d4ac 100644
--- a/arch/mips/kernel/cpu-probe.c
+++ b/arch/mips/kernel/cpu-probe.c
@@ -1286,14 +1286,14 @@ static inline void cpu_probe_legacy(struct cpuinfo_mips *c, unsigned int cpu)
 		set_cpu_asid_mask(c, MIPS_ENTRYHI_ASID);
 		c->writecombine = _CACHE_UNCACHED_ACCELERATED;
 		break;
-	case PRID_IMP_LOONGSON_32:  /* Loongson-1 */
+	case PRID_IMP_LOONGSON_32:
 		decode_configs(c);
 
 		c->cputype = CPU_LOONGSON32;
 
 		switch (c->processor_id & PRID_REV_MASK) {
-		case PRID_REV_LOONGSON1B:
-			__cpu_name[cpu] = "Loongson 1B";
+		case PRID_REV_LOONGSON1:
+			__cpu_name[cpu] = "ICT Loongson-1";
 			break;
 		}
 

-- 
2.43.0

