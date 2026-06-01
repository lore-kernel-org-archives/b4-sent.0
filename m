From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:44 +1000
Subject: [PATCH RESEND 03/16] arm: save_prev_bl_data: ARM32 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-3-05a08d87e476@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=3484;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=+BNM3pjGz3YO1/+L5soCN/xvFf8ElKZj/cCDYKJmZL8=;
 b=MI1i7o4mLVZ1+l78JmTu57Sqg1pJe2zXqlfsAbL+JuvN7PI1SMj35uPKWEFyrGhM6eTCpKH5e
 hKNXshY3gxgDt/UWm/yGPEfhDA4/Aiisf0MzVJRzQnvNdwO37WenzT9
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The main change here is to make is_addr_accessible() portable, by using
gd->bd->bi_ram rather than the ARMv8 memory map. AFAICT, at the point
that this is running, these two things are 1:1 anyway (see
qcom_configure_bi_dram).

Once that's out of the way, we add ARM32 support by looking at r2 rather
than r0 and using portable pointer types.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/lib/save_prev_bl_data.c | 49 ++++++++++++++++++++++++----------------
 1 file changed, 29 insertions(+), 20 deletions(-)

diff --git a/arch/arm/lib/save_prev_bl_data.c b/arch/arm/lib/save_prev_bl_data.c
index 4357acaef6c..83670541c50 100644
--- a/arch/arm/lib/save_prev_bl_data.c
+++ b/arch/arm/lib/save_prev_bl_data.c
@@ -12,33 +12,41 @@
 #include <fdt.h>
 #include <linux/errno.h>
 #include <asm/system.h>
-#include <asm/armv8/mmu.h>
 
-static ulong reg0 __section(".data");
+#include <asm/global_data.h>
+
+DECLARE_GLOBAL_DATA_PTR;
+
+static phys_addr_t prev_bl_fdt_addr __section(".data");
 
 /**
- * Save x0 register value, assuming previous bootloader set it to
- * point on loaded fdt or (for older linux kernels)atags.
+ * Save the register value used by Linux boot ABI to pass the FDT or ATAGS.
  */
-void save_boot_params(ulong r0)
+void save_boot_params(ulong r0, ulong __always_unused r1, ulong r2)
 {
-	reg0 = r0;
+	if (IS_ENABLED(CONFIG_ARM64))
+		prev_bl_fdt_addr = r0;
+	else
+		prev_bl_fdt_addr = r2;
+
 	save_boot_params_ret();
 }
 
 bool is_addr_accessible(phys_addr_t addr)
 {
-	struct mm_region *mem = mem_map;
 	phys_addr_t bank_start;
 	phys_addr_t bank_end;
 
-	while (mem->size) {
-		bank_start = mem->phys;
-		bank_end = bank_start + mem->size;
-		debug("check if block %pap - %pap includes %pap\n", &bank_start, &bank_end, &addr);
-		if (addr > bank_start && addr < bank_end)
+	for (int i = 0; i < CONFIG_NR_DRAM_BANKS; i++) {
+		if (!gd->bd->bi_dram[i].size)
+			continue;
+
+		bank_start = gd->bd->bi_dram[i].start;
+		bank_end = bank_start + gd->bd->bi_dram[i].size;
+		debug("check if block %pap - %pap includes %pap\n",
+		      &bank_start, &bank_end, &addr);
+		if (addr >= bank_start && addr < bank_end)
 			return true;
-		mem++;
 	}
 
 	return false;
@@ -46,33 +54,34 @@ bool is_addr_accessible(phys_addr_t addr)
 
 phys_addr_t get_prev_bl_fdt_addr(void)
 {
-	return reg0;
+	return prev_bl_fdt_addr;
 }
 
 int save_prev_bl_data(void)
 {
 	struct fdt_header *fdt_blob;
 	int node;
-	u64 initrd_start_prop;
+	phys_addr_t initrd_start_prop;
 
-	if (!is_addr_accessible((phys_addr_t)reg0))
+	if (!is_addr_accessible(prev_bl_fdt_addr))
 		return -ENODATA;
 
-	fdt_blob = (struct fdt_header *)reg0;
+	fdt_blob = (struct fdt_header *)prev_bl_fdt_addr;
 	if (!fdt_valid(&fdt_blob)) {
-		pr_warn("%s: address 0x%lx is not a valid fdt\n", __func__, reg0);
+		pr_warn("%s: address 0x%lx is not a valid fdt\n",
+			__func__, prev_bl_fdt_addr);
 		return -ENODATA;
 	}
 
 	if (IS_ENABLED(CONFIG_SAVE_PREV_BL_FDT_ADDR))
-		env_set_addr("prevbl_fdt_addr", (void *)reg0);
+		env_set_addr("prevbl_fdt_addr", (const void *)prev_bl_fdt_addr);
 	if (!IS_ENABLED(CONFIG_SAVE_PREV_BL_INITRAMFS_START_ADDR))
 		return 0;
 
 	node = fdt_path_offset(fdt_blob, "/chosen");
 	if (!node) {
 		pr_warn("%s: chosen node not found in device tree at addr: 0x%lx\n",
-					__func__, reg0);
+					__func__, prev_bl_fdt_addr);
 		return -ENODATA;
 	}
 	/*

-- 
2.54.0

