From: =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>
Date: Tue, 03 Nov 2026 18:37:10 +0800
Subject: [PATCH v3 5/6] board: rockchip: Add common NanoPi RK3528 board
 target
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-nanopi-r28s-v3-5-ae8664fd168f@proton.me>
References: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
In-Reply-To: <20261103-nanopi-r28s-v3-0-ae8664fd168f@proton.me>
To: u-boot@lists.u-boot-project.org
Cc: Kever Yang <kever.yang@rock-chips.com>, 
 Quentin Schulz <u-boot@0leil.net>, Jonas Karlman <jonas@kwiboo.se>, 
 Simon Glass <sjg@chromium.org>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?=E5=AE=89=E5=AE=B9?= <HystericalDragons@proton.me>, 
 Quentin Schulz <quentin.schulz@cherry.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6188;
 i=HystericalDragons@proton.me; s=20261103; h=from:subject:message-id;
 bh=HboyIzzulA+TijYJDv463UW209fkjiWrZEUJxID1dl8=;
 b=owGbwMvMwCU8Ldb53x4TtgLG02pJDFkvdwYHvP+56YFXRc2T0FS3doePtydO/C2ZuuyEp9zPL
 3/aLM7Ed2xnYRDmYpAVU2TplP488cvjC9O/3pyUBTOHlQlkCAMXpwBMJKqAid0zr1l/2sogPqFi
 857KFOPOjQ9O1DnX7Eibys4l2CstwHgl8+OGZT4KWZpPKstsv+lkPYsysmvZ3x03PTC85NCTkoY
 VTByLV9SnSHvLVBWeXn10Eptx6zGewCPzejIl07ZbLHJM/vIltHC5Wr6WtKPU95j8+DsCmxaqX5
 m5uqb4zm3FA73W67MdZgAA
X-Developer-Key: i=HystericalDragons@proton.me; a=openpgp;
 fpr=5A3AC293DCEEAA41A8A3266A910205A0AEB09D84
X-Endpoint-Received: by B4 Relay for HystericalDragons@proton.me/20261103 with auth_id=1393
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The board variant of the FriendlyElec NanoPi RK3528 family can be
identified using the HW_ID voltage divider on SARADC channel 2.

Add a TARGET_NANOPI_RK3528 board target, based on the Radxa ROCK 2
board target, that reads HW_ID to select the FDT in SPL and to set the
fdtfile env var. This allows one defconfig to support multiple NanoPi
RK3528 board variants.

Move the NanoPi Zero2 to the new board target, it is the only variant
for now.

Suggested-by: Jonas Karlman <jonas@kwiboo.se>
Signed-off-by: 安容 <HystericalDragons@proton.me>
Reviewed-by: Quentin Schulz <quentin.schulz@cherry.de>
---
 arch/arm/dts/rk3528-nanopi-u-boot.dtsi           |  5 ++
 arch/arm/mach-rockchip/rk3528/Kconfig            |  6 +++
 arch/arm/mach-rockchip/rk3528/MAINTAINERS        |  7 ---
 board/friendlyelec/nanopi-rk3528/Kconfig         | 14 ++++++
 board/friendlyelec/nanopi-rk3528/MAINTAINERS     |  7 +++
 board/friendlyelec/nanopi-rk3528/Makefile        |  3 ++
 board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c | 59 ++++++++++++++++++++++++
 configs/nanopi-zero2-rk3528_defconfig            |  1 +
 8 files changed, 95 insertions(+), 7 deletions(-)

diff --git a/arch/arm/dts/rk3528-nanopi-u-boot.dtsi b/arch/arm/dts/rk3528-nanopi-u-boot.dtsi
index 3e2fbd81da1..e8c8dc2f032 100644
--- a/arch/arm/dts/rk3528-nanopi-u-boot.dtsi
+++ b/arch/arm/dts/rk3528-nanopi-u-boot.dtsi
@@ -2,6 +2,11 @@
 
 #include "rk3528-u-boot.dtsi"
 
+&saradc {
+	bootph-pre-ram;
+	vdd-microvolts = <1800000>;
+};
+
 &vdd_arm {
 	regulator-init-microvolt = <953000>;
 };
diff --git a/arch/arm/mach-rockchip/rk3528/Kconfig b/arch/arm/mach-rockchip/rk3528/Kconfig
index 480ac2942ff..87b65d666e9 100644
--- a/arch/arm/mach-rockchip/rk3528/Kconfig
+++ b/arch/arm/mach-rockchip/rk3528/Kconfig
@@ -1,5 +1,10 @@
 if ROCKCHIP_RK3528
 
+config TARGET_NANOPI_RK3528
+	bool "FriendlyElec NanoPi Zero2"
+	help
+	  FriendlyElec NanoPi Zero2 single board computer with a RK3528A SoC.
+
 config TARGET_RADXA_ROCK_2_RK3528
 	bool "Radxa ROCK 2A/2F"
 	help
@@ -14,6 +19,7 @@ config ROCKCHIP_STIMER_BASE
 config SYS_SOC
 	default "rk3528"
 
+source "board/friendlyelec/nanopi-rk3528/Kconfig"
 source "board/radxa/rock-2-rk3528/Kconfig"
 
 config SYS_CONFIG_NAME
diff --git a/arch/arm/mach-rockchip/rk3528/MAINTAINERS b/arch/arm/mach-rockchip/rk3528/MAINTAINERS
index d1810fb0528..e56108d67cb 100644
--- a/arch/arm/mach-rockchip/rk3528/MAINTAINERS
+++ b/arch/arm/mach-rockchip/rk3528/MAINTAINERS
@@ -10,13 +10,6 @@ S:	Maintained
 F:	arch/arm/dts/rk3528-hinlink-h28k*
 F:	configs/hinlink-h28k-rk3528_defconfig
 
-NANOPI-ZERO2-RK3528
-M:	Jonas Karlman <jonas@kwiboo.se>
-S:	Maintained
-F:	arch/arm/dts/rk3528-nanopi-u-boot.dtsi
-F:	arch/arm/dts/rk3528-nanopi-zero2*
-F:	configs/nanopi-zero2-rk3528_defconfig
-
 RADXA-E20C
 M:	Jonas Karlman <jonas@kwiboo.se>
 S:	Maintained
diff --git a/board/friendlyelec/nanopi-rk3528/Kconfig b/board/friendlyelec/nanopi-rk3528/Kconfig
new file mode 100644
index 00000000000..94b15b06691
--- /dev/null
+++ b/board/friendlyelec/nanopi-rk3528/Kconfig
@@ -0,0 +1,14 @@
+if TARGET_NANOPI_RK3528
+
+config SYS_BOARD
+	default "nanopi-rk3528"
+
+config SYS_VENDOR
+	default "friendlyelec"
+
+config BOARD_SPECIFIC_OPTIONS # dummy
+	def_bool y
+	select ADC
+	select SPL_ADC
+
+endif
diff --git a/board/friendlyelec/nanopi-rk3528/MAINTAINERS b/board/friendlyelec/nanopi-rk3528/MAINTAINERS
new file mode 100644
index 00000000000..67f14661087
--- /dev/null
+++ b/board/friendlyelec/nanopi-rk3528/MAINTAINERS
@@ -0,0 +1,7 @@
+NANOPI-RK3528
+M:	Jonas Karlman <jonas@kwiboo.se>
+S:	Maintained
+F:	board/friendlyelec/nanopi-rk3528
+F:	arch/arm/dts/rk3528-nanopi-u-boot.dtsi
+F:	arch/arm/dts/rk3528-nanopi-zero2*
+F:	configs/nanopi-zero2-rk3528_defconfig
diff --git a/board/friendlyelec/nanopi-rk3528/Makefile b/board/friendlyelec/nanopi-rk3528/Makefile
new file mode 100644
index 00000000000..752426dcfdb
--- /dev/null
+++ b/board/friendlyelec/nanopi-rk3528/Makefile
@@ -0,0 +1,3 @@
+# SPDX-License-Identifier: GPL-2.0+
+
+obj-y += nanopi-rk3528.o
diff --git a/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c b/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c
new file mode 100644
index 00000000000..86932eab7c7
--- /dev/null
+++ b/board/friendlyelec/nanopi-rk3528/nanopi-rk3528.c
@@ -0,0 +1,59 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+#include <linux/errno.h>
+#include <linux/kernel.h>
+#include <adc.h>
+#include <env.h>
+
+#define HW_ID_CHANNEL	2
+
+struct board_model {
+	unsigned int low;
+	unsigned int high;
+	const char *fdtfile;
+};
+
+/* HW_ID buckets from the FriendlyElec vendor U-Boot hwrev.c */
+static const struct board_model board_models[] = {
+	{  82, 150, "rockchip/rk3528-nanopi-zero2.dtb" },
+};
+
+static const struct board_model *get_board_model(void)
+{
+	unsigned int val;
+	int i, ret;
+
+	ret = adc_channel_single_shot("adc@ffae0000", HW_ID_CHANNEL, &val);
+	if (ret)
+		return NULL;
+
+	for (i = 0; i < ARRAY_SIZE(board_models); i++) {
+		unsigned int min = board_models[i].low;
+		unsigned int max = board_models[i].high;
+
+		if (min <= val && val <= max)
+			return &board_models[i];
+	}
+
+	return NULL;
+}
+
+int rk_board_late_init(void)
+{
+	const struct board_model *model = get_board_model();
+
+	if (model)
+		env_set("fdtfile", model->fdtfile);
+
+	return 0;
+}
+
+int board_fit_config_name_match(const char *name)
+{
+	const struct board_model *model = get_board_model();
+
+	if (model && !strcmp(name, model->fdtfile))
+		return 0;
+
+	return -EINVAL;
+}
diff --git a/configs/nanopi-zero2-rk3528_defconfig b/configs/nanopi-zero2-rk3528_defconfig
index 2c725380ef4..dde9134112f 100644
--- a/configs/nanopi-zero2-rk3528_defconfig
+++ b/configs/nanopi-zero2-rk3528_defconfig
@@ -4,6 +4,7 @@ CONFIG_COUNTER_FREQUENCY=24000000
 CONFIG_ARCH_ROCKCHIP=y
 CONFIG_DEFAULT_DEVICE_TREE="rockchip/rk3528-nanopi-zero2"
 CONFIG_ROCKCHIP_RK3528=y
+CONFIG_TARGET_NANOPI_RK3528=y
 CONFIG_SYS_LOAD_ADDR=0xc00800
 CONFIG_DEBUG_UART_BASE=0xFF9F0000
 CONFIG_DEBUG_UART_CLOCK=24000000

-- 
2.56.0

