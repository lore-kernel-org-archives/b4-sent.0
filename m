From: Sam Day <me@samcday.com>
Date: Wed, 10 Jun 2026 11:57:20 +1000
Subject: [PATCH v2] mach-snapdragon: formalize APQ8016 debug UART init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-apq8016-debug-uart-v2-1-acf43d28add6@samcday.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22Nyw7CIBBFf6WZtZgBGzSu/A/TBR2GlkUfQktsG
 v5dbOLOzOrc3Htmh8jBc4R7tUPg5KOfxgLqVAH1ZuxYeFsYFCqNGpUw8+uGUgvL7dqJ1YRF4JW
 QXM2yFKAM58DOvw/psync+7hMYTt+JPlNf7rLP12SohzXulVk0bF+RDOQNduZpgGanPMHuVeb8
 bYAAAA=
X-Change-ID: 20260602-apq8016-debug-uart-07c0cf4e1060
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Dmitrii Sharshakov <d3dx12.xx@gmail.com>, 
 Brian Sune <briansune@gmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Simon Glass <sjg@chromium.org>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, Daniel Palmer <daniel@0x0f.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, Yao Zi <me@ziyao.cc>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781056642; l=5997;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=Gz4fnU7tzDyqtY/6QXvgDxcyZWDmbGM5J2fSNKKy7ic=;
 b=yB8XYGnN9GwLAYBvsLosP+dQWn5JpjcShyVDu0Z5l6SeajUo0H2VkZrwwQJHA1gYyeRlw8yuV
 5ZsR9kZzLl7CHcZdCgeSZznbVtrEFn2PF75Jn58T5DVvFimHP/QEOeT
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dragonboard410c (and likely other SB-off devices) can run U-Boot
early enough in the boot chain such that UART clock isn't started, and
pins aren't configured.

APQ8016 has two UART peripherals, each with its own clock and TLMM pins.

Two new debug-apq8016-uartN.config fragments are provided. Each
configures the appropriate UARTDM aperture. The newly introduced
DEBUG_UART_APQ8016 Kconfig symbol pulls in MSM debug UART, and enables a
board-level debug_uart_init function to start the right clock and mux
the right TX pin.

Signed-off-by: Sam Day <me@samcday.com>
---
Changes in v2:
- Rename APQ8016_TLMM_GPIO_ENABLE to APQ8016_TLMM_GPIO_OE
- Link to v1: https://lore.kernel.org/r/20260603-apq8016-debug-uart-v1-1-1e46b2cd0fe6@samcday.com
---
 arch/arm/mach-snapdragon/Kconfig              |  9 +++++++
 arch/arm/mach-snapdragon/Makefile             |  1 +
 arch/arm/mach-snapdragon/debug-uart-apq8016.c | 37 +++++++++++++++++++++++++++
 board/qualcomm/debug-apq8016-uart1.config     |  4 +++
 board/qualcomm/debug-apq8016-uart2.config     |  4 +++
 drivers/serial/Kconfig                        |  1 +
 drivers/serial/serial_msm.c                   | 10 --------
 7 files changed, 56 insertions(+), 10 deletions(-)

diff --git a/arch/arm/mach-snapdragon/Kconfig b/arch/arm/mach-snapdragon/Kconfig
index d3de8693b5a..43e6fd1bc42 100644
--- a/arch/arm/mach-snapdragon/Kconfig
+++ b/arch/arm/mach-snapdragon/Kconfig
@@ -1,5 +1,14 @@
 if ARCH_SNAPDRAGON
 
+config DEBUG_UART_APQ8016
+	bool "APQ8016 early debug initialization"
+	select CLK_QCOM_APQ8016
+	select CONFIG_DEBUG_UART_MSM
+	select DEBUG_UART_BOARD_INIT
+	help
+	  Ensures BLSP UART clocks+pins are setup. Useful when U-Boot is running from
+	  aboot (such as on the dragonboard410c).
+
 config SYS_SOC
 	default "snapdragon"
 
diff --git a/arch/arm/mach-snapdragon/Makefile b/arch/arm/mach-snapdragon/Makefile
index 343e825c6fd..824bb4d5daf 100644
--- a/arch/arm/mach-snapdragon/Makefile
+++ b/arch/arm/mach-snapdragon/Makefile
@@ -5,3 +5,4 @@
 obj-y += board.o
 obj-$(CONFIG_EFI_HAVE_CAPSULE_SUPPORT) += capsule_update.o
 obj-$(CONFIG_OF_LIVE) += of_fixup.o
+obj-$(CONFIG_DEBUG_UART_APQ8016) += debug-uart-apq8016.o
diff --git a/arch/arm/mach-snapdragon/debug-uart-apq8016.c b/arch/arm/mach-snapdragon/debug-uart-apq8016.c
new file mode 100644
index 00000000000..1c156c854b3
--- /dev/null
+++ b/arch/arm/mach-snapdragon/debug-uart-apq8016.c
@@ -0,0 +1,37 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * SoC-specific debug UART initialization (clocks/pins) lives here
+ */
+
+#include <asm/io.h>
+#include <dt-bindings/clock/qcom,gcc-msm8916.h>
+
+extern int apq8016_clk_init_uart(phys_addr_t gcc_base, unsigned long id);
+
+#define APQ8016_GCC_BASE		((phys_addr_t)0x01800000)
+
+#define APQ8016_TLMM_BASE		((phys_addr_t)0x01000000)
+#define APQ8016_TLMM_FUNC_BLSP_UART	(2 << 2)
+#define APQ8016_TLMM_DRV_8MA		(3 << 6)
+#define APQ8016_TLMM_GPIO_OE		BIT(9)
+#define APQ8016_GPIO_CFG(gpio)		(APQ8016_TLMM_BASE + (phys_addr_t)(gpio) * 0x1000)
+#define APQ8016_DEBUG_UART_PINCFG	(APQ8016_TLMM_FUNC_BLSP_UART | \
+					 APQ8016_TLMM_DRV_8MA | \
+					 APQ8016_TLMM_GPIO_OE)
+
+void board_debug_uart_init(void)
+{
+	/* infer BLSP clock and TX pin by the configured UART base */
+	switch (CONFIG_VAL(DEBUG_UART_BASE)) {
+	case 0x078af000:
+		apq8016_clk_init_uart(APQ8016_GCC_BASE,
+				      GCC_BLSP1_UART1_APPS_CLK);
+		writel(APQ8016_DEBUG_UART_PINCFG, APQ8016_GPIO_CFG(0));
+		break;
+	case 0x078b0000:
+		apq8016_clk_init_uart(APQ8016_GCC_BASE,
+				      GCC_BLSP1_UART2_APPS_CLK);
+		writel(APQ8016_DEBUG_UART_PINCFG, APQ8016_GPIO_CFG(4));
+		break;
+	}
+}
diff --git a/board/qualcomm/debug-apq8016-uart1.config b/board/qualcomm/debug-apq8016-uart1.config
new file mode 100644
index 00000000000..283fbf20ff8
--- /dev/null
+++ b/board/qualcomm/debug-apq8016-uart1.config
@@ -0,0 +1,4 @@
+CONFIG_DEBUG_UART=y
+CONFIG_DEBUG_UART_ANNOUNCE=y
+CONFIG_DEBUG_UART_BASE=0x078af000
+CONFIG_DEBUG_UART_APQ8016=y
diff --git a/board/qualcomm/debug-apq8016-uart2.config b/board/qualcomm/debug-apq8016-uart2.config
new file mode 100644
index 00000000000..61e56d4eb5a
--- /dev/null
+++ b/board/qualcomm/debug-apq8016-uart2.config
@@ -0,0 +1,4 @@
+CONFIG_DEBUG_UART=y
+CONFIG_DEBUG_UART_ANNOUNCE=y
+CONFIG_DEBUG_UART_BASE=0x078b0000
+CONFIG_DEBUG_UART_APQ8016=y
diff --git a/drivers/serial/Kconfig b/drivers/serial/Kconfig
index 5f8b98f0704..698205aa035 100644
--- a/drivers/serial/Kconfig
+++ b/drivers/serial/Kconfig
@@ -565,6 +565,7 @@ config DEBUG_UART_CLOCK
 	default 100000000 if DEBUG_UART_ZYNQ && ARCH_ZYNQMP
 	default 50000000 if DEBUG_UART_ZYNQ && ARCH_ZYNQ
 	default 100000000 if DEBUG_UART_PL011 && (ARCH_VERSAL || ARCH_VERSAL_NET || ARCH_VERSAL2)
+	default 7372800 if DEBUG_UART_APQ8016
 	help
 	  The UART input clock determines the speed of the internal UART
 	  circuitry. The baud rate is derived from this by dividing the input
diff --git a/drivers/serial/serial_msm.c b/drivers/serial/serial_msm.c
index 18d15b7b15b..e25cb71696f 100644
--- a/drivers/serial/serial_msm.c
+++ b/drivers/serial/serial_msm.c
@@ -235,18 +235,8 @@ static struct msm_serial_data init_serial_data = {
 
 #include <debug_uart.h>
 
-/* Uncomment to turn on UART clocks when debugging U-Boot as aboot on MSM8916 */
-//int apq8016_clk_init_uart(phys_addr_t gcc_base, unsigned long id);
-
 static inline void _debug_uart_init(void)
 {
-	/*
-	 * Uncomment to turn on UART clocks when debugging U-Boot as aboot
-	 * on MSM8916. Supported debug UART clock IDs:
-	 *   - db410c: GCC_BLSP1_UART2_APPS_CLK
-	 *   - HMIBSC: GCC_BLSP1_UART1_APPS_CLK
-	 */
-	//apq8016_clk_init_uart(0x1800000, <uart_clk_id>);
 	uart_dm_init(&init_serial_data);
 }
 

---
base-commit: f76fb6495b2df5163f4c88dc222acc934caffbfb
change-id: 20260602-apq8016-debug-uart-07c0cf4e1060

Best regards,
-- 
Sam Day <me@samcday.com>

