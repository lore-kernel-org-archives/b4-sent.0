From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:53 +1000
Subject: [PATCH RESEND 12/16] mach-snapdragon: parse incoming ARM32 ATAGS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-12-05a08d87e476@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=5615;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=1IbKZZVRHheo07MgFndHTzIn40/6vZ4NQ9WPRDlkx/c=;
 b=f6xk/oYaImOVq9Nh1Im9Rq+N+K0JfqVyt+jDcoTUS48YVTPoxKOMXVAKJ8dXCxefQbwrN+Jyl
 BWEWaZnSplvBOq3bdYeYCphYC/j3dpcjehqLzTBOhuFKx6FNr8sUpTb
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Many (often fused) bootloaders on older ARMv7 qcom SoCs do not support
FDTs at all, and instead pass along ATAGS in r2.

Minimal support for parsing memory info out of these tags is introduced,
so that we can support mainline devicetrees, which expect the bootloader
to populate /memory nodes.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/mach-snapdragon/board.c | 119 ++++++++++++++++++++++++++++++---------
 1 file changed, 91 insertions(+), 28 deletions(-)

diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index 627b566d178..753983467a0 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -11,6 +11,7 @@
 
 #include <asm/gpio.h>
 #include <asm/io.h>
+#include <asm/setup.h>
 #include <asm/system.h>
 #include <dm/device.h>
 #include <dm/pinctrl.h>
@@ -175,6 +176,67 @@ static int qcom_parse_memory(const void *fdt)
 	return 0;
 }
 
+static bool qcom_atags_valid(const phys_addr_t p)
+{
+	const struct tag *tags = (const struct tag *)p;
+
+	return tags && tags->hdr.tag == ATAG_CORE &&
+	       tags->hdr.size >= sizeof(struct tag_header) / sizeof(u32);
+}
+
+static int qcom_parse_atags(const struct tag *tags)
+{
+	phys_addr_t ram_end = 0;
+	const struct tag *t;
+	bool atags_end = false;
+	u32 words = 0;
+	int j = 0;
+
+	memset(prevbl_ddr_banks, 0, sizeof(prevbl_ddr_banks));
+
+	for (t = tags; words < SZ_16K / sizeof(u32); t = tag_next(t)) {
+		if (t->hdr.tag == ATAG_NONE) {
+			atags_end = true;
+			break;
+		}
+		if (t->hdr.size < sizeof(struct tag_header) / sizeof(u32))
+			return -EINVAL;
+		if (t->hdr.size > SZ_16K / sizeof(u32) - words)
+			return -EINVAL;
+
+		words += t->hdr.size;
+
+		if (t->hdr.tag != ATAG_MEM)
+			continue;
+		if (t->hdr.size < tag_size(tag_mem32))
+			return -EINVAL;
+		if (!t->u.mem.size)
+			continue;
+
+		prevbl_ddr_banks[j].start = t->u.mem.start;
+		prevbl_ddr_banks[j].size = t->u.mem.size;
+		ram_end = max(ram_end, (phys_addr_t)t->u.mem.start + t->u.mem.size);
+		j++;
+
+		if (j == CONFIG_NR_DRAM_BANKS)
+			break;
+	}
+
+	if (!atags_end && j < CONFIG_NR_DRAM_BANKS) {
+		log_err("Provided more memory banks than we can handle\n");
+		return -EINVAL;
+	}
+	if (!j)
+		return -ENODATA;
+
+	qsort(prevbl_ddr_banks, j, sizeof(prevbl_ddr_banks[0]), ddr_bank_cmp);
+
+	gd->ram_base = prevbl_ddr_banks[0].start;
+	gd->ram_size = ram_end - gd->ram_base;
+
+	return 0;
+}
+
 static void show_psci_version(void)
 {
 #ifdef CONFIG_ARM64
@@ -227,42 +289,52 @@ static void qcom_psci_fixup(void *fdt)
  */
 int board_fdt_blob_setup(void **fdtp)
 {
-	struct fdt_header *external_fdt, *internal_fdt;
-	bool internal_valid, external_valid;
-	int ret = -ENODATA;
-
-	internal_fdt = (struct fdt_header *)*fdtp;
-	external_fdt = (struct fdt_header *)get_prev_bl_fdt_addr();
-	external_valid = external_fdt && !fdt_check_header(external_fdt);
-	internal_valid = !fdt_check_header(internal_fdt);
+	int ret = -ENODATA, setup_ret = -EEXIST;
+	struct fdt_header *internal_fdt = *fdtp;
+	phys_addr_t prev_bl_arg = get_prev_bl_fdt_addr();
+	bool internal_valid = internal_fdt && !fdt_check_header(internal_fdt);
+	bool external_is_fdt = prev_bl_arg &&
+			       !fdt_check_header((const void *)prev_bl_arg);
 
-	/*
-	 * There is no point returning an error here, U-Boot can't do anything useful in this situation.
-	 * Bail out while we can still print a useful error message.
-	 */
-	if (!internal_valid && !external_valid)
+	if (internal_valid) {
+		debug("Using built in FDT\n");
+	} else if (external_is_fdt) {
+		debug("Using external FDT\n");
+		*fdtp = (void *)prev_bl_arg;
+		setup_ret = 0;
+	} else {
+		/*
+		 * There is no point returning an error here, U-Boot can't do
+		 * anything useful in this situation. Bail out while we can
+		 * still print a useful error message.
+		 */
 		panic("Internal FDT is invalid and no external FDT was provided! (fdt=%p)\n",
-		      external_fdt);
+		      (void *)prev_bl_arg);
+	}
 
 	/* Prefer memory information from internal DT if it's present */
 	if (internal_valid)
 		ret = qcom_parse_memory(internal_fdt);
 
-	if (ret < 0 && external_valid) {
+	if (ret < 0 && prev_bl_arg) {
 		/* No internal FDT or it lacks a proper /memory node.
 		 * The previous bootloader handed us something, let's try that.
 		 */
 		if (internal_valid)
 			debug("No memory info in internal FDT, falling back to external\n");
 
-		ret = qcom_parse_memory(external_fdt);
+		/* the prev BL arg is either an FDT or ATAGS */
+		if (external_is_fdt)
+			ret = qcom_parse_memory((const void *)prev_bl_arg);
+		if (ret < 0 && qcom_atags_valid(prev_bl_arg))
+			ret = qcom_parse_atags((const struct tag *)prev_bl_arg);
 	}
 
 	if (ret < 0)
 		panic("No valid memory ranges found!\n");
 
-	/* If we have an external FDT, it can only have come from the Android bootloader. */
-	if (external_valid)
+	/* If we have a prev BL arg, we assume it came from ABL */
+	if (prev_bl_arg)
 		qcom_boot_source = QCOM_BOOT_SOURCE_ANDROID;
 	else
 		qcom_boot_source = QCOM_BOOT_SOURCE_XBL;
@@ -270,18 +342,9 @@ int board_fdt_blob_setup(void **fdtp)
 	debug("ram_base = %#011lx, ram_size = %#011llx\n",
 	      gd->ram_base, (unsigned long long)gd->ram_size);
 
-	if (internal_valid) {
-		debug("Using built in FDT\n");
-		ret = -EEXIST;
-	} else {
-		debug("Using external FDT\n");
-		*fdtp = external_fdt;
-		ret = 0;
-	}
-
 	qcom_psci_fixup(*fdtp);
 
-	return ret;
+	return setup_ret;
 }
 
 /*

-- 
2.54.0

