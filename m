From: Nikita Shubin <nikita.shubin@maquefel.me>
Date: Mon, 09 Sep 2024 11:10:57 +0300
Subject: [PATCH v12 32/38] ARM: ep93xx: DT for the Cirrus ep93xx SoC
 platforms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240909-ep93xx-v12-32-e86ab2423d4b@maquefel.me>
References: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
In-Reply-To: <20240909-ep93xx-v12-0-e86ab2423d4b@maquefel.me>
To: Russell King <linux@armlinux.org.uk>, 
 Hartley Sweeten <hsweeten@visionengravers.com>, 
 Alexander Sverdlin <alexander.sverdlin@gmail.com>, 
 Andrew Davis <afd@ti.com>, Arnd Bergmann <arnd@arndb.de>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Masahiro Yamada <masahiroy@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Nikita Shubin <nikita.shubin@maquefel.me>
Cc: "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13-dev-e3e53
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725869532; l=3110;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=MU0azT5lNnulLeP5AfbO0wMy6289MR0wM0qk0K+/fy8=;
 b=z7mt8ZsZw1L4VQRwH0UtATvP+b9vQI8XflGSsXma++7DMFAnVqGxlerCCY0NtkJgSlK3rxUrZPoQ
 MRUyJ/pmDRytliiGdt+VKvTS4V8RiQ5TMuFoW/RJe9g8a/wfyNCZ
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compulsory device tree support to the Cirrus ep93xx ARMv4 platform.

- select PINCTRL_EP93xx
- select COMMON_CLK_EP93XX, as clock driver moved out of platform code
- select ARCH_HAS_RESET_CONTROLLER

Select ARM_ATAG_DTB_COMPAT to update device tree with information
about memory passed from bootloader.

We have to leave all MACH options as they are used for board checking
before decomp, to turn off watchdog and ethernet DMA.

Tested-by: Alexander Sverdlin <alexander.sverdlin@gmail.com>
Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
 arch/arm/Makefile             |  1 -
 arch/arm/mach-ep93xx/Kconfig  | 20 ++++++++++----------
 arch/arm/mach-ep93xx/Makefile | 11 -----------
 3 files changed, 10 insertions(+), 22 deletions(-)

diff --git a/arch/arm/Makefile b/arch/arm/Makefile
index 71afdd98ddf2..aafebf145738 100644
--- a/arch/arm/Makefile
+++ b/arch/arm/Makefile
@@ -183,7 +183,6 @@ machine-$(CONFIG_ARCH_CLPS711X)		+= clps711x
 machine-$(CONFIG_ARCH_DAVINCI)		+= davinci
 machine-$(CONFIG_ARCH_DIGICOLOR)	+= digicolor
 machine-$(CONFIG_ARCH_DOVE)		+= dove
-machine-$(CONFIG_ARCH_EP93XX)		+= ep93xx
 machine-$(CONFIG_ARCH_EXYNOS)		+= exynos
 machine-$(CONFIG_ARCH_FOOTBRIDGE)	+= footbridge
 machine-$(CONFIG_ARCH_GEMINI)		+= gemini
diff --git a/arch/arm/mach-ep93xx/Kconfig b/arch/arm/mach-ep93xx/Kconfig
index 703f3d232a60..812b71dcf60e 100644
--- a/arch/arm/mach-ep93xx/Kconfig
+++ b/arch/arm/mach-ep93xx/Kconfig
@@ -3,27 +3,27 @@ menuconfig ARCH_EP93XX
 	bool "EP93xx-based"
 	depends on ATAGS
 	depends on ARCH_MULTI_V4T
+	# CONFIG_ARCH_MULTI_V7 is not set
 	depends on CPU_LITTLE_ENDIAN
+	select ARCH_HAS_RESET_CONTROLLER
 	select ARCH_SPARSEMEM_ENABLE
 	select ARM_AMBA
 	select ARM_VIC
+	select ARM_APPENDED_DTB # Old Redboot bootloaders deployed
+	select ARM_ATAG_DTB_COMPAT # we need this to update dt memory node
+	select COMMON_CLK_EP93XX
+	select EP93XX_TIMER
 	select CLKSRC_MMIO
 	select CPU_ARM920T
 	select GPIOLIB
+	select PINCTRL
+	select PINCTRL_EP93XX
 	help
 	  This enables support for the Cirrus EP93xx series of CPUs.
 
 if ARCH_EP93XX
 
-menu "Cirrus EP93xx Implementation Options"
-
-config EP93XX_SOC_COMMON
-	bool
-	default y
-	select SOC_BUS
-	select LEDS_GPIO_REGISTER
-
-comment "EP93xx Platforms"
+# menu "EP93xx Platforms"
 
 config MACH_BK3
 	bool "Support Liebherr BK3.1"
@@ -103,6 +103,6 @@ config MACH_VISION_EP9307
 	  Say 'Y' here if you want your kernel to support the
 	  Vision Engraving Systems EP9307 SoM.
 
-endmenu
+# endmenu
 
 endif
diff --git a/arch/arm/mach-ep93xx/Makefile b/arch/arm/mach-ep93xx/Makefile
deleted file mode 100644
index 62e37403df14..000000000000
--- a/arch/arm/mach-ep93xx/Makefile
+++ /dev/null
@@ -1,11 +0,0 @@
-# SPDX-License-Identifier: GPL-2.0
-#
-# Makefile for the linux kernel.
-#
-obj-y			:= core.o clock.o timer-ep93xx.o
-
-obj-$(CONFIG_EP93XX_DMA)	+= dma.o
-
-obj-$(CONFIG_MACH_EDB93XX)	+= edb93xx.o
-obj-$(CONFIG_MACH_TS72XX)	+= ts72xx.o
-obj-$(CONFIG_MACH_VISION_EP9307)+= vision_ep9307.o

-- 
2.43.2

