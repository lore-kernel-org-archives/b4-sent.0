From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:46 +1000
Subject: [PATCH RESEND 05/16] mach-snapdragon: gate ARM64 features
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-5-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=3504;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=bIJ7cYF6vytERhAUWslfSVzczauhvqi7mIbsGwwGNTw=;
 b=0dQl4/Xpv+rUY+KgHDQf+5AmOhjo5+fEX6Zj2EizI1CmMY1U4P5o57BW0q5qC9E756ciTALH0
 GgDaXregaopAHM9nAHndXzaAskkoQEyEwfITFohDdtC42Xce1alcKCe
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With some strategic (and minimal) #ifdef ARM64 gating, we can ensure
that mach-snapdragon board code compiles cleanly on arm32 toolchains.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/mach-snapdragon/board.c | 29 +++++++++++++++++++----------
 1 file changed, 19 insertions(+), 10 deletions(-)

diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index 56e943058ed..627b566d178 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -9,10 +9,8 @@
 #define LOG_CATEGORY LOGC_BOARD
 #define pr_fmt(fmt) "QCOM: " fmt
 
-#include <asm/armv8/mmu.h>
 #include <asm/gpio.h>
 #include <asm/io.h>
-#include <asm/psci.h>
 #include <asm/system.h>
 #include <dm/device.h>
 #include <dm/pinctrl.h>
@@ -22,9 +20,7 @@
 #include <env.h>
 #include <fdt_support.h>
 #include <init.h>
-#include <linux/arm-smccc.h>
 #include <linux/bug.h>
-#include <linux/psci.h>
 #include <linux/sizes.h>
 #include <lmb.h>
 #include <malloc.h>
@@ -35,13 +31,20 @@
 
 #include "qcom-priv.h"
 
-DECLARE_GLOBAL_DATA_PTR;
-
-enum qcom_boot_source qcom_boot_source __section(".data") = 0;
+#ifdef CONFIG_ARM64
+#include <asm/armv8/mmu.h>
+#include <asm/psci.h>
+#include <linux/arm-smccc.h>
+#include <linux/psci.h>
 
 static struct mm_region rbx_mem_map[CONFIG_NR_DRAM_BANKS + 2] = { { 0 } };
 
 struct mm_region *mem_map = rbx_mem_map;
+#endif
+
+DECLARE_GLOBAL_DATA_PTR;
+
+enum qcom_boot_source qcom_boot_source __section(".data") = 0;
 
 static struct {
 	phys_addr_t start;
@@ -174,6 +177,7 @@ static int qcom_parse_memory(const void *fdt)
 
 static void show_psci_version(void)
 {
+#ifdef CONFIG_ARM64
 	struct arm_smccc_res res;
 
 	arm_smccc_smc(ARM_PSCI_0_2_FN_PSCI_VERSION, 0, 0, 0, 0, 0, 0, 0, &res);
@@ -185,6 +189,7 @@ static void show_psci_version(void)
 	debug("PSCI:  v%ld.%ld\n",
 	      PSCI_VERSION_MAJOR(res.a0),
 	      PSCI_VERSION_MINOR(res.a0));
+#endif
 }
 
 /**
@@ -196,6 +201,7 @@ static void show_psci_version(void)
  */
 static void qcom_psci_fixup(void *fdt)
 {
+#ifdef CONFIG_ARM64
 	int offset, ret;
 	struct arm_smccc_res res;
 
@@ -212,6 +218,7 @@ static void qcom_psci_fixup(void *fdt)
 	ret = fdt_del_node(fdt, offset);
 	if (ret)
 		log_err("Failed to delete /psci node: %d\n", ret);
+#endif
 }
 
 /* We support booting U-Boot with an internal DT when running as a first-stage bootloader
@@ -234,8 +241,8 @@ int board_fdt_blob_setup(void **fdtp)
 	 * Bail out while we can still print a useful error message.
 	 */
 	if (!internal_valid && !external_valid)
-		panic("Internal FDT is invalid and no external FDT was provided! (fdt=%#llx)\n",
-		      (phys_addr_t)external_fdt);
+		panic("Internal FDT is invalid and no external FDT was provided! (fdt=%p)\n",
+		      external_fdt);
 
 	/* Prefer memory information from internal DT if it's present */
 	if (internal_valid)
@@ -261,7 +268,7 @@ int board_fdt_blob_setup(void **fdtp)
 		qcom_boot_source = QCOM_BOOT_SOURCE_XBL;
 
 	debug("ram_base = %#011lx, ram_size = %#011llx\n",
-	      gd->ram_base, gd->ram_size);
+	      gd->ram_base, (unsigned long long)gd->ram_size);
 
 	if (internal_valid) {
 		debug("Using built in FDT\n");
@@ -595,6 +602,7 @@ int board_late_init(void)
 	return 0;
 }
 
+#ifdef CONFIG_ARM64
 static void build_mem_map(void)
 {
 	int i, j;
@@ -768,3 +776,4 @@ void enable_caches(void)
 	}
 	dcache_enable();
 }
+#endif

-- 
2.54.0

