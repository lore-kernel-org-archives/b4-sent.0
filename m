From: Sam Day <me@samcday.com>
Date: Tue, 02 Jun 2026 17:19:00 +1000
Subject: [PATCH v2 4/6] mach-snapdragon: fixup CPUs with PSCI enable-method
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-msm8916-smp-support-v2-4-792e53dac374@samcday.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780384740; l=2527;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=oyW4SjIaPw8uMUpJo0OqFTwzoLj2elwRTqTh9Cf/umk=;
 b=gVb1kgCfLjKaa+d9kuzBilStJA2K8MjfV90IfBscl+QA+mCOOSqhNZe+Ni09Op7BhTRRxlw3U
 EmD1y7NQS+pCQ9gfg/HEoGRf9X3z/py77qP2p/wYPOjHEYZEhqvz2po
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If there's no PSCI implementation, then change the enable-method of all
CPUs from "psci" to "spin-table". Later, when spin_table_update_dt runs,
it will further patch the CPU nodes with the necessary cpu-release-addr.

This new fixup is only applied when CONFIG_ARMV8_SPIN_TABLE is enabled,
since that also determines whether spin_table_update_dt runs.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/mach-snapdragon/board.c | 41 ++++++++++++++++++++++++++++++++++++++++
 1 file changed, 41 insertions(+)

diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index 829a0109ac7..3b08069af98 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -183,7 +183,9 @@ static void show_psci_version(void)
 static void qcom_psci_fixup(void *fdt)
 {
 	int offset, ret;
+	uint reg;
 	struct arm_smccc_res res;
+	const char *prop;
 
 	arm_smccc_smc(ARM_PSCI_0_2_FN_PSCI_VERSION, 0, 0, 0, 0, 0, 0, 0, &res);
 
@@ -198,6 +200,45 @@ static void qcom_psci_fixup(void *fdt)
 	ret = fdt_del_node(fdt, offset);
 	if (ret)
 		log_err("Failed to delete /psci node: %d\n", ret);
+
+	if (!CONFIG_IS_ENABLED(ARMV8_SPIN_TABLE))
+		return;
+
+	/* If spin-table support is enabled, make sure any CPU nodes with a
+	 * PSCI enable-method are updated to spin-table. Further, any PSCI
+	 * power-domains properties are removed.
+	 */
+
+	offset = fdt_path_offset(fdt, "/cpus");
+	if (offset < 0)
+		return;
+
+	for (offset = fdt_first_subnode(fdt, offset);
+	     offset >= 0;
+	     offset = fdt_next_subnode(fdt, offset)) {
+		prop = fdt_getprop(fdt, offset, "device_type", NULL);
+		if (!prop || strcmp(prop, "cpu"))
+			continue;
+
+		prop = fdt_getprop(fdt, offset, "enable-method", NULL);
+		if (!prop || strcmp(prop, "psci"))
+			continue;
+
+		reg = fdtdec_get_uint(fdt, offset, "reg", 0);
+		ret = fdt_setprop_string(fdt, offset,
+					 "enable-method", "spin-table");
+		if (ret)
+			log_err("Failed to set CPU%d enable-method to 'spin-table', this CPU will not be available to booted OS! %d\n",
+				reg, ret);
+
+		log_info("Patched CPU%d enable-method to 'spin-table'\n", reg);
+
+		prop = fdt_getprop(fdt, offset, "power-domain-names", NULL);
+		if (prop && !strcmp(prop, "psci")) {
+			fdt_delprop(fdt, offset, "power-domains");
+			fdt_delprop(fdt, offset, "power-domain-names");
+		}
+	}
 }
 
 /* We support booting U-Boot with an internal DT when running as a first-stage bootloader

-- 
2.54.0

