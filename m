From: Sam Day <me@samcday.com>
Date: Tue, 02 Jun 2026 17:19:01 +1000
Subject: [PATCH v2 5/6] mach-snapdragon: MSM8916 spin-table CPU boot
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-msm8916-smp-support-v2-5-792e53dac374@samcday.com>
References: <20260602-msm8916-smp-support-v2-0-792e53dac374@samcday.com>
In-Reply-To: <20260602-msm8916-smp-support-v2-0-792e53dac374@samcday.com>
To: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Mark Kettenis <mark.kettenis@xs4all.nl>, Sumit Garg <sumit.garg@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 Casey Connolly <casey.connolly@linaro.org>, Simon Glass <sjg@chromium.org>, 
 Kory Maincent <kory.maincent@bootlin.com>, Yao Zi <me@ziyao.cc>, 
 Peng Fan <peng.fan@nxp.com>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Michael Trimarchi <michael@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Sughosh Ganu <sughosh.ganu@arm.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780384740; l=4774;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=0/tcg4B+FG8c0znBkfL/bXBmugnneb14sAtnVLQt5Ac=;
 b=mBCoz5bSPKJGrj8XXkqwcsuZo+B3mLzJGP7zHDdPgssXsdghOaQmp7IuPZL9gPEuI/QGBGA/W
 VJ3prhLzKwXA8qDzeFesRwsryP2Oke58RMa82H452WbtS4NyW05x33X
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Most MSM8916 devices lack PSCI support, instead they're brought online
with a qcom SCM call to set the boot address, and some register poking
of the APCS register block.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/mach-snapdragon/Makefile      |   1 +
 arch/arm/mach-snapdragon/msm8916-smp.c | 138 +++++++++++++++++++++++++++++++++
 2 files changed, 139 insertions(+)

diff --git a/arch/arm/mach-snapdragon/Makefile b/arch/arm/mach-snapdragon/Makefile
index 343e825c6fd..584b8af055a 100644
--- a/arch/arm/mach-snapdragon/Makefile
+++ b/arch/arm/mach-snapdragon/Makefile
@@ -5,3 +5,4 @@
 obj-y += board.o
 obj-$(CONFIG_EFI_HAVE_CAPSULE_SUPPORT) += capsule_update.o
 obj-$(CONFIG_OF_LIVE) += of_fixup.o
+obj-$(CONFIG_ARMV8_SPIN_TABLE) += msm8916-smp.o
diff --git a/arch/arm/mach-snapdragon/msm8916-smp.c b/arch/arm/mach-snapdragon/msm8916-smp.c
new file mode 100644
index 00000000000..24f5590ccc3
--- /dev/null
+++ b/arch/arm/mach-snapdragon/msm8916-smp.c
@@ -0,0 +1,138 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * On MSM8916 devices that lack a PSCI implementation, firing up the secondary
+ * cores requires a call to TZ to set the boot address, and some poking of ACPS
+ * register block.
+ *
+ * Copyright (c) 2025 Linaro Ltd.
+ */
+
+#include <asm/io.h>
+#include <asm/spin_table.h>
+#include <asm/system.h>
+#include <cpu_func.h>
+#include <dm/ofnode.h>
+#include <firmware/qcom/scm.h>
+#include <linux/arm-smccc.h>
+#include <linux/delay.h>
+
+#define APCS_CPU_PWR_CTL	0x04
+#define CORE_PWRD_UP		BIT(7)
+#define COREPOR_RST		BIT(5)
+#define CORE_RST		BIT(4)
+#define CORE_MEM_HS		BIT(3)
+#define CORE_MEM_CLAMP		BIT(1)
+#define CLAMP			BIT(0)
+
+#define APC_PWR_GATE_CTL	0x14
+#define GDHS_CNT_SHIFT		24
+#define GDHS_EN			BIT(0)
+
+static void qcom_boot_cortex_a53(phys_addr_t acc_base)
+{
+	u32 reg_val;
+
+	/* Put the CPU into reset. */
+	reg_val = CORE_RST | COREPOR_RST | CLAMP | CORE_MEM_CLAMP;
+	writel(reg_val, acc_base + APCS_CPU_PWR_CTL);
+
+	/* Turn on the GDHS and set the GDHS_CNT to 16 XO clock cycles */
+	writel(GDHS_EN | (0x10 << GDHS_CNT_SHIFT), acc_base + APC_PWR_GATE_CTL);
+	/* Wait for the GDHS to settle */
+	udelay(2);
+
+	reg_val &= ~CORE_MEM_CLAMP;
+	writel(reg_val, acc_base + APCS_CPU_PWR_CTL);
+	reg_val |= CORE_MEM_HS;
+	writel(reg_val, acc_base + APCS_CPU_PWR_CTL);
+	udelay(2);
+
+	reg_val &= ~CLAMP;
+	writel(reg_val, acc_base + APCS_CPU_PWR_CTL);
+	udelay(2);
+
+	/* Release CPU out of reset and bring it to life. */
+	reg_val &= ~(CORE_RST | COREPOR_RST);
+	writel(reg_val, acc_base + APCS_CPU_PWR_CTL);
+	reg_val |= CORE_PWRD_UP;
+	writel(reg_val, acc_base + APCS_CPU_PWR_CTL);
+}
+
+static int qcom_scm_set_boot_addr_mc(void *entry, unsigned int flags)
+{
+	struct qcom_scm_desc desc = {
+		.svc = QCOM_SCM_SVC_BOOT,
+		.cmd = QCOM_SCM_BOOT_SET_ADDR_MC,
+		.owner = ARM_SMCCC_OWNER_SIP,
+		.arginfo = QCOM_SCM_ARGS(6),
+		.args = {
+			(u64)entry,
+			/* Apply to all CPUs in all affinity levels */
+			~0ULL, ~0ULL, ~0ULL, ~0ULL,
+			flags,
+		},
+	};
+
+	if (!qcom_scm_is_call_available(desc.svc, desc.cmd))
+		return -EOPNOTSUPP;
+
+	return qcom_scm_call(&desc, NULL);
+}
+
+static bool boot_addr_set;
+
+int spin_table_boot_cpu(void *fdt, int cpu_offset)
+{
+	struct fdtdec_phandle_args acc;
+	u32 mpidr_aff, acc_base, reg;
+	int ret;
+
+	if (fdt_node_check_compatible(fdt, 0, "qcom,msm8916"))
+		return 0;
+
+	reg = fdtdec_get_uint(fdt, cpu_offset, "reg", 0);
+
+	if (fdt_node_check_compatible(fdt, cpu_offset, "arm,cortex-a53")) {
+		log_warning("CPU%d is not arm,cortex-a53 compatible\n", reg);
+		return -EINVAL;
+	}
+
+	if (!boot_addr_set) {
+		debug("Setting CPU boot address to 0x%llx\n",
+		      (phys_addr_t)&spin_table_reserve_begin);
+		ret = qcom_scm_set_boot_addr_mc(&spin_table_reserve_begin,
+						QCOM_SCM_BOOT_MC_FLAG_AARCH64 |
+						QCOM_SCM_BOOT_MC_FLAG_COLDBOOT);
+		if (ret) {
+			log_err("Failed to set CPU boot addr: %d\n", ret);
+			return ret;
+		}
+
+		boot_addr_set = true;
+	}
+
+	mpidr_aff = read_mpidr() & 0xffffff;
+
+	if (reg == mpidr_aff) {
+		debug("Skipping boot of current CPU%d\n", reg);
+		return 0;
+	}
+
+	ret = fdtdec_parse_phandle_with_args(fdt, cpu_offset, "qcom,acc",
+					     NULL, 0, 0, &acc);
+	if (ret) {
+		log_err("Failed to parse qcom,acc phandle: %d\n", reg);
+		return ret;
+	}
+
+	acc_base = fdtdec_get_addr_size_auto_noparent(fdt, acc.node, "reg", 0,
+						      NULL, true);
+	if (!acc_base) {
+		log_err("Failed to parse qcom,acc regbase\n");
+		return -EINVAL;
+	}
+
+	log_info("Booting CPU%d @ 0x%x\n", reg, acc_base);
+	qcom_boot_cortex_a53(acc_base);
+	return 0;
+}

-- 
2.54.0

