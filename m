From: Joseph Telaak <joseph@telaak.dev>
Date: Wed, 04 Nov 2026 02:16:56 -0500
Subject: [PATCH 4/4] MIPS: configs: Add sf19a2890_defconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sf19a2890-mips-v1-4-eae80820af68@telaak.dev>
References: <20261104-sf19a2890-mips-v1-0-eae80820af68@telaak.dev>
In-Reply-To: <20261104-sf19a2890-mips-v1-0-eae80820af68@telaak.dev>
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Burton <paulburton@kernel.org>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Chuanhong Guo <gch981213@gmail.com>, linux-mips@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joseph Telaak <joseph@telaak.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793776620; l=1391;
 i=joseph@telaak.dev; s=20261104; h=from:subject:message-id;
 bh=zztkLUC+M2zOWpFkypE450mBbf/dXLLRQ6Wq8WWfycI=;
 b=Vgm4vQJhrgBlWzR/8b8vKxlphG65RyYHmw6WSyI6idNoAvjuByOzu+TE3TgdTuBF54tWeBh7Z
 4gZbROby73nCsoVRgAEtolWi3P2ulRFYu33HUHioj09SsmyoC0+ZuZF
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
index 425b52d4f..4eaa92605 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25704,6 +25704,7 @@ L:	linux-mips@vger.kernel.org
 S:	Maintained
 F:	Documentation/devicetree/bindings/mips/siflower.yaml
 F:	arch/mips/boot/dts/siflower/
+F:	arch/mips/configs/sf19a2890_defconfig
 F:	arch/mips/include/asm/mach-siflower/
 F:	drivers/gpio/gpio-siflower.c
 N:	sf19a2890
diff --git a/arch/mips/configs/sf19a2890_defconfig b/arch/mips/configs/sf19a2890_defconfig
new file mode 100644
index 000000000..ec0992ac6
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

