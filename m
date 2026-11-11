From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 11 Nov 2026 03:27:18 -0500
Subject: [PATCH v2 4/4] MIPS: configs: Add sf19a2890_defconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-sf19a2890-mips-v2-4-36730fa4f5a6@telaak.dev>
References: <20261111-sf19a2890-mips-v2-0-36730fa4f5a6@telaak.dev>
In-Reply-To: <20261111-sf19a2890-mips-v2-0-36730fa4f5a6@telaak.dev>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Burton <paulburton@kernel.org>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794385652; l=1372;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=jrZFDuNOVQSJQnzMtSdYByrN6lytb/mj6TbF+QbIufc=;
 b=fRtO233xcWqqziTzm7CZbFUCGAVR2y5D3Xox+oMdW8p/mwK5zwVUX5a6KRuQOxjRy6kUw8vgI
 z9/NHHJC0mRBBDIume8oj2+9/DTpSrNYE++HxTwRz0LVsRNbKyuYsL6
X-Developer-Key: i=joseph@telaak.dev; a=ed25519;
 pk=oQI+UfddlZ0wK2ac4WKOGNjUl1ZEN8j9ZVFSqEDoNP0=
X-Endpoint-Received: by B4 Relay for joseph@telaak.dev/20261104 with auth_id=1404
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a defconfig for boards with the Siflower SF19A2890. It boots with
the device tree appended to the kernel, as the GL.iNet GL-SFT1200's
U-Boot passes none.

Signed-off-by: Joseph Telaak <joseph@telaak.dev>
---
 MAINTAINERS                           |  1 +
 arch/mips/configs/sf19a2890_defconfig | 15 +++++++++++++++
 2 files changed, 16 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 23ad08c7d8d1..4c8daaae5501 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25704,6 +25704,7 @@ L:	linux-mips@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/mips/siflower.yaml
 F:	arch/mips/boot/dts/siflower/
+F:	arch/mips/configs/sf19a2890_defconfig
 F:	arch/mips/include/asm/mach-siflower/
 N:	sf19a2890
 
diff --git a/arch/mips/configs/sf19a2890_defconfig b/arch/mips/configs/sf19a2890_defconfig
new file mode 100644
index 000000000000..ec0992ac6340
--- /dev/null
+++ b/arch/mips/configs/sf19a2890_defconfig
@@ -0,0 +1,15 @@
+CONFIG_SYSVIPC=y
+CONFIG_NO_HZ_IDLE=y
+CONFIG_HIGH_RES_TIMERS=y
+CONFIG_BLK_DEV_INITRD=y
+CONFIG_CC_OPTIMIZE_FOR_SIZE=y
+CONFIG_MACH_SIFLOWER_MIPS=y
+CONFIG_MIPS_CPS=y
+CONFIG_NR_CPUS=4
+CONFIG_MIPS_RAW_APPENDED_DTB=y
+CONFIG_DEVTMPFS=y
+CONFIG_DEVTMPFS_MOUNT=y
+CONFIG_SERIAL_AMBA_PL011=y
+CONFIG_SERIAL_AMBA_PL011_CONSOLE=y
+CONFIG_TMPFS=y
+CONFIG_PRINTK_TIME=y

-- 
Git-155)

