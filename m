From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 25 Nov 2026 15:24:48 -0500
Subject: [PATCH v6 1/6] MIPS: Add support for Siflower MIPS SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-sf19a2890-sysm-v6-1-181875c10682@telaak.dev>
References: <20261125-sf19a2890-sysm-v6-0-181875c10682@telaak.dev>
In-Reply-To: <20261125-sf19a2890-sysm-v6-0-181875c10682@telaak.dev>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: Paul Burton <paulburton@kernel.org>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>, Chuanhong Guo <gch981213@gmail.com>, 
 Yao Zi <me@ziyao.cc>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-mips@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795638294; l=2176;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=ziqqvVYU3GmZibawv8t72n+ZZ3zc07HtvebkWxBkx+8=;
 b=9uC3DLpXVwKSKJCQxSbqousLs/2Wh8+FP/Fegt/w6HCj1TfMYonkex0FBQ7zwcdkPFbbE84xq
 oOBoCrqtP5vAJ9RKtIEAVrjyPHnyCrgO0KX25JD4zTOjwCSAJuyVlBN
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuanhong Guo <gch981213@gmail.com>

Siflower MIPS SoCs like SF19A2890 use a dual-core MIPS InterAptiv
processor, built-in GMAC, USB, dual-band WiFi and various other
peripherals.

Notably, they use some ARM PLxxx peripherals, and ARM_AMBA is
selected for the drivers.

Most devices on the market with this chip come with 64M or less
DRAM, so a MACH_SIFLOWER_MIPS is created with reduced features
instead of using the generic kernel.

Signed-off-by: Chuanhong Guo <gch981213@gmail.com>
[Joseph Telaak:
  - rebase on v7.4-rc1 and use the "MIPS:" prefix
  - longer Kconfig help
  - commit message grammar and paragraphs
  - move the kmalloc.h override to a patch of its own]
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 arch/mips/Kconfig | 33 +++++++++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/arch/mips/Kconfig b/arch/mips/Kconfig
index ed17c9b1624c..549bc7d13dd9 100644
--- a/arch/mips/Kconfig
+++ b/arch/mips/Kconfig
@@ -937,6 +937,39 @@ config SIBYTE_BIGSUR
 	select ZONE_DMA32 if 64BIT
 	select SWIOTLB if ARCH_DMA_ADDR_T_64BIT && PCI
 
+config MACH_SIFLOWER_MIPS
+	bool "Siflower MIPS SoCs"
+	select MIPS_GENERIC
+	select MACH_GENERIC_CORE
+	select ARM_AMBA
+	select BOOT_RAW
+	select CEVT_R4K
+	select CLKSRC_MIPS_GIC
+	select COMMON_CLK
+	select CPU_MIPSR2_IRQ_EI
+	select CPU_MIPSR2_IRQ_VI
+	select CSRC_R4K
+	select DMA_NONCOHERENT
+	select IRQ_MIPS_CPU
+	select MIPS_CPU_SCACHE
+	select MIPS_GIC
+	select MIPS_L1_CACHE_SHIFT_5
+	select NO_EXCEPT_FILL
+	select SMP_UP if SMP
+	select SYS_HAS_CPU_MIPS32_R2
+	select SYS_SUPPORTS_32BIT_KERNEL
+	select SYS_SUPPORTS_LITTLE_ENDIAN
+	select SYS_SUPPORTS_MIPS16
+	select SYS_SUPPORTS_MIPS_CPS
+	select SYS_SUPPORTS_MULTITHREADING
+	select USE_OF
+	help
+	  Select this to build a kernel which supports SoCs from Siflower
+	  with MIPS InterAptiv cores, like Siflower SF19A2890. These have
+	  ARM PrimeCell peripherals, so ARM_AMBA is selected. Most boards
+	  with them have 64M of DRAM or less, so this kernel leaves out the
+	  generic kernel's support for other boards.
+
 config SNI_RM
 	bool "SNI RM200/300/400"
 	select ARC_MEMORY

-- 
Git-155)

