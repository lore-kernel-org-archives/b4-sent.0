From: Joseph Telaak <joseph@telaak.dev>
Date: Thu, 26 Nov 2026 14:21:31 -0500
Subject: [PATCH v3 3/5] MIPS: siflower: Override the kmalloc alignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-sf19a2890-mips-v3-3-1f808d38ab37@telaak.dev>
References: <20261126-sf19a2890-mips-v3-0-1f808d38ab37@telaak.dev>
In-Reply-To: <20261126-sf19a2890-mips-v3-0-1f808d38ab37@telaak.dev>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Burton <paulburton@kernel.org>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Chuanhong Guo <gch981213@gmail.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, linux-mips@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795720891; l=2095;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=EVyfyjeyZ6p+fuc1LhbQN8uCXhli0ff7zLHw1TglBzM=;
 b=hLtcKgn2pI1DY0p7hYt5vMEqTSVmnsXMIdY25FHiAi5XfyztDLaCEHPZKuGyD8oryRzJZhB6M
 qkfN13CWiHFCAIpxXVL4++nZetZPEsypPo3PQcyY9OI4w29U6ASRxAP
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuanhong Guo <gch981213@gmail.com>

Most devices on the market with Siflower MIPS SoCs come with 64M or
less DRAM. Their InterAptiv cores have 32-byte cache lines, so add a
kmalloc.h that sets ARCH_DMA_MINALIGN to 32 instead of the generic 128,
to conserve memory.

Signed-off-by: Chuanhong Guo <gch981213@gmail.com>
[Joseph Telaak: split out of "MIPS: Add support for Siflower MIPS SoCs"]
Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 MAINTAINERS                                   | 1 +
 arch/mips/generic/Platform                    | 1 +
 arch/mips/include/asm/mach-siflower/kmalloc.h | 9 +++++++++
 3 files changed, 11 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 7fb18c2d6959..3aa80a8dd785 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25703,6 +25703,7 @@ M:	Joseph Telaak <joseph@telaak.dev>
 L:	linux-mips@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/mips/siflower.yaml
+F:	arch/mips/include/asm/mach-siflower/
 N:	sf19a2890
 
 SILEAD TOUCHSCREEN DRIVER
diff --git a/arch/mips/generic/Platform b/arch/mips/generic/Platform
index 0c03623f3897..c09a8484db9b 100644
--- a/arch/mips/generic/Platform
+++ b/arch/mips/generic/Platform
@@ -10,6 +10,7 @@
 
 # Note: order matters, keep the asm/mach-generic include last.
 cflags-$(CONFIG_MACH_INGENIC_SOC)	+= -I$(srctree)/arch/mips/include/asm/mach-ingenic
+cflags-$(CONFIG_MACH_SIFLOWER_MIPS)	+= -I$(srctree)/arch/mips/include/asm/mach-siflower
 cflags-$(CONFIG_MIPS_GENERIC)	+= -I$(srctree)/arch/mips/include/asm/mach-generic
 
 load-$(CONFIG_MIPS_GENERIC)	+= 0xffffffff80100000
diff --git a/arch/mips/include/asm/mach-siflower/kmalloc.h b/arch/mips/include/asm/mach-siflower/kmalloc.h
new file mode 100644
index 000000000000..0887ae3575d7
--- /dev/null
+++ b/arch/mips/include/asm/mach-siflower/kmalloc.h
@@ -0,0 +1,9 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+#ifndef __ASM_MACH_SIFLOWER_KMALLOC_H
+#define __ASM_MACH_SIFLOWER_KMALLOC_H
+
+#ifdef CONFIG_DMA_NONCOHERENT
+#define ARCH_DMA_MINALIGN	32
+#endif
+
+#endif /* __ASM_MACH_SIFLOWER_KMALLOC_H */

-- 
Git-155)

