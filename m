From: Demeter Barna <me@fromdisposition.org>
Date: Sat, 14 Nov 2026 02:21:57 +0000
Subject: [PATCH 3/9] interconnect: qcom: Add SM8350 interconnect driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-sm8350-support-v1-3-414271f59474@fromdisposition.org>
References: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
In-Reply-To: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Lukasz Majewski <lukma@nabladev.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Biswapriyo Nath <nathbappai@gmail.com>, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Erikas Bitovtas <xerikasxx@gmail.com>, Johan Jonker <jbx6244@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Michael Srba <Michael.Srba@seznam.cz>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Demeter Barna <me@fromdisposition.org>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794622936; l=9700;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=Y/9S1F4K86ewGZ32pcgQfy1f16WZQerIRRZt0CQBHNA=;
 b=oxhew4EGDD8fFXGSEYSCuGVgVXphoc5fegJ+e3RAg9pnSWJdqJ9wak/0Ji01D0Cpi7brpE2nP
 HgPMusYYxqLDJmV0RDfe+L3d89yxyactrmVpi4pfJ9mA5PPxCAXfuUU
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the interconnect (NoC) driver for SM8350 with the nodes of the two
UFS paths, the only ones U-Boot requests, as the QCS8300 driver has
them.

Taken from Linux's drivers/interconnect/qcom/sm8350.c (tag v7.4-rc1).

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/interconnect/qcom/Kconfig  |   7 +
 drivers/interconnect/qcom/Makefile |   1 +
 drivers/interconnect/qcom/sm8350.c | 271 +++++++++++++++++++++++++++++++++++++
 drivers/interconnect/qcom/sm8350.h |  25 ++++
 4 files changed, 304 insertions(+)

diff --git a/drivers/interconnect/qcom/Kconfig b/drivers/interconnect/qcom/Kconfig
index 4123a1d224..6a030a7891 100644
--- a/drivers/interconnect/qcom/Kconfig
+++ b/drivers/interconnect/qcom/Kconfig
@@ -17,6 +17,13 @@ config INTERCONNECT_QCOM_QCS8300
 	help
 	  Enable support for the interconnect driver for the QCS8300 SoC.
 
+config INTERCONNECT_QCOM_SM8350
+	bool "Enable interconnect support for SM8350 SoC"
+	depends on INTERCONNECT_QCOM_RPMH
+	help
+	  Enable support for the interconnect driver for the SM8350 SoC.
+	  It has the nodes of the UFS paths.
+
 config INTERCONNECT_QCOM_SM8650
 	bool "Enable interconnect support for SM8650 SoC"
 	depends on INTERCONNECT_QCOM_RPMH
diff --git a/drivers/interconnect/qcom/Makefile b/drivers/interconnect/qcom/Makefile
index ac6b8cee19..c4b38d13a0 100644
--- a/drivers/interconnect/qcom/Makefile
+++ b/drivers/interconnect/qcom/Makefile
@@ -6,4 +6,5 @@
 obj-$(CONFIG_$(PHASE_)INTERCONNECT_QCOM_RPMH) += icc-rpmh.o bcm-voter.o
 obj-$(CONFIG_$(PHASE_)INTERCONNECT_QCOM_QCS8300) += qcs8300.o
 obj-$(CONFIG_$(PHASE_)INTERCONNECT_QCOM_SC7280) += sc7280.o
+obj-$(CONFIG_$(PHASE_)INTERCONNECT_QCOM_SM8350) += sm8350.o
 obj-$(CONFIG_$(PHASE_)INTERCONNECT_QCOM_SM8650) += sm8650.o
diff --git a/drivers/interconnect/qcom/sm8350.c b/drivers/interconnect/qcom/sm8350.c
new file mode 100644
index 0000000000..71423c9b22
--- /dev/null
+++ b/drivers/interconnect/qcom/sm8350.c
@@ -0,0 +1,271 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * Copyright (c) 2019-2020, The Linux Foundation. All rights reserved.
+ * Copyright (c) 2021, Linaro Limited
+ */
+
+#include <dm.h>
+#include <interconnect-uclass.h>
+#include <dt-bindings/interconnect/qcom,sm8350.h>
+
+#include "icc-rpmh.h"
+#include "sm8350.h"
+
+static struct qcom_icc_node xm_ufs_mem = {
+	.name = "xm_ufs_mem",
+	.id = SM8350_MASTER_UFS_MEM,
+	.channels = 1,
+	.buswidth = 8,
+	.num_links = 1,
+	.links = { SM8350_SLAVE_A1NOC_SNOC },
+};
+
+static struct qcom_icc_node qnm_gemnoc_cnoc = {
+	.name = "qnm_gemnoc_cnoc",
+	.id = SM8350_MASTER_GEM_NOC_CNOC,
+	.channels = 1,
+	.buswidth = 16,
+	.num_links = 1,
+	.links = { SM8350_SLAVE_UFS_MEM_CFG },
+};
+
+static struct qcom_icc_node chm_apps = {
+	.name = "chm_apps",
+	.id = SM8350_MASTER_APPSS_PROC,
+	.channels = 2,
+	.buswidth = 32,
+	.num_links = 1,
+	.links = { SM8350_SLAVE_GEM_NOC_CNOC },
+};
+
+static struct qcom_icc_node qnm_snoc_sf = {
+	.name = "qnm_snoc_sf",
+	.id = SM8350_MASTER_SNOC_SF_MEM_NOC,
+	.channels = 1,
+	.buswidth = 16,
+	.num_links = 1,
+	.links = { SM8350_SLAVE_LLCC },
+};
+
+static struct qcom_icc_node llcc_mc = {
+	.name = "llcc_mc",
+	.id = SM8350_MASTER_LLCC,
+	.channels = 4,
+	.buswidth = 4,
+	.num_links = 1,
+	.links = { SM8350_SLAVE_EBI1 },
+};
+
+static struct qcom_icc_node qnm_aggre1_noc = {
+	.name = "qnm_aggre1_noc",
+	.id = SM8350_MASTER_A1NOC_SNOC,
+	.channels = 1,
+	.buswidth = 16,
+	.num_links = 1,
+	.links = { SM8350_SLAVE_SNOC_GEM_NOC_SF },
+};
+
+static struct qcom_icc_node qns_a1noc_snoc = {
+	.name = "qns_a1noc_snoc",
+	.id = SM8350_SLAVE_A1NOC_SNOC,
+	.channels = 1,
+	.buswidth = 16,
+	.num_links = 1,
+	.links = { SM8350_MASTER_A1NOC_SNOC },
+};
+
+static struct qcom_icc_node qhs_ufs_mem_cfg = {
+	.name = "qhs_ufs_mem_cfg",
+	.id = SM8350_SLAVE_UFS_MEM_CFG,
+	.channels = 1,
+	.buswidth = 4,
+	.num_links = 0,
+};
+
+static struct qcom_icc_node qns_gem_noc_cnoc = {
+	.name = "qns_gem_noc_cnoc",
+	.id = SM8350_SLAVE_GEM_NOC_CNOC,
+	.channels = 1,
+	.buswidth = 16,
+	.num_links = 1,
+	.links = { SM8350_MASTER_GEM_NOC_CNOC },
+};
+
+static struct qcom_icc_node qns_llcc = {
+	.name = "qns_llcc",
+	.id = SM8350_SLAVE_LLCC,
+	.channels = 4,
+	.buswidth = 16,
+	.num_links = 1,
+	.links = { SM8350_MASTER_LLCC },
+};
+
+static struct qcom_icc_node ebi = {
+	.name = "ebi",
+	.id = SM8350_SLAVE_EBI1,
+	.channels = 4,
+	.buswidth = 4,
+	.num_links = 0,
+};
+
+static struct qcom_icc_node qns_gemnoc_sf = {
+	.name = "qns_gemnoc_sf",
+	.id = SM8350_SLAVE_SNOC_GEM_NOC_SF,
+	.channels = 1,
+	.buswidth = 16,
+	.num_links = 1,
+	.links = { SM8350_MASTER_SNOC_SF_MEM_NOC },
+};
+
+static struct qcom_icc_bcm bcm_acv = {
+	.name = "ACV",
+	.enable_mask = BIT(3),
+	.num_nodes = 1,
+	.nodes = { &ebi },
+};
+
+static struct qcom_icc_bcm bcm_cn0 = {
+	.name = "CN0",
+	.keepalive = true,
+	.num_nodes = 1,
+	.nodes = { &qnm_gemnoc_cnoc },
+};
+
+static struct qcom_icc_bcm bcm_cn1 = {
+	.name = "CN1",
+	.num_nodes = 1,
+	.nodes = { &qhs_ufs_mem_cfg },
+};
+
+static struct qcom_icc_bcm bcm_mc0 = {
+	.name = "MC0",
+	.keepalive = true,
+	.num_nodes = 1,
+	.nodes = { &ebi },
+};
+
+static struct qcom_icc_bcm bcm_sh0 = {
+	.name = "SH0",
+	.keepalive = true,
+	.num_nodes = 1,
+	.nodes = { &qns_llcc },
+};
+
+static struct qcom_icc_bcm bcm_sh4 = {
+	.name = "SH4",
+	.num_nodes = 1,
+	.nodes = { &chm_apps },
+};
+
+static struct qcom_icc_bcm bcm_sn0 = {
+	.name = "SN0",
+	.keepalive = true,
+	.num_nodes = 1,
+	.nodes = { &qns_gemnoc_sf },
+};
+
+static struct qcom_icc_bcm bcm_sn7 = {
+	.name = "SN7",
+	.num_nodes = 1,
+	.nodes = { &qnm_aggre1_noc },
+};
+
+static struct qcom_icc_node * const aggre1_noc_nodes[] = {
+	[MASTER_UFS_MEM] = &xm_ufs_mem,
+	[SLAVE_A1NOC_SNOC] = &qns_a1noc_snoc,
+};
+
+static const struct qcom_icc_desc sm8350_aggre1_noc = {
+	.nodes = aggre1_noc_nodes,
+	.num_nodes = ARRAY_SIZE(aggre1_noc_nodes),
+};
+
+static struct qcom_icc_bcm * const config_noc_bcms[] = {
+	&bcm_cn0,
+	&bcm_cn1,
+};
+
+static struct qcom_icc_node * const config_noc_nodes[] = {
+	[MASTER_GEM_NOC_CNOC] = &qnm_gemnoc_cnoc,
+	[SLAVE_UFS_MEM_CFG] = &qhs_ufs_mem_cfg,
+};
+
+static const struct qcom_icc_desc sm8350_config_noc = {
+	.nodes = config_noc_nodes,
+	.num_nodes = ARRAY_SIZE(config_noc_nodes),
+	.bcms = config_noc_bcms,
+	.num_bcms = ARRAY_SIZE(config_noc_bcms),
+};
+
+static struct qcom_icc_bcm * const gem_noc_bcms[] = {
+	&bcm_sh0,
+	&bcm_sh4,
+};
+
+static struct qcom_icc_node * const gem_noc_nodes[] = {
+	[MASTER_APPSS_PROC] = &chm_apps,
+	[MASTER_SNOC_SF_MEM_NOC] = &qnm_snoc_sf,
+	[SLAVE_GEM_NOC_CNOC] = &qns_gem_noc_cnoc,
+	[SLAVE_LLCC] = &qns_llcc,
+};
+
+static const struct qcom_icc_desc sm8350_gem_noc = {
+	.nodes = gem_noc_nodes,
+	.num_nodes = ARRAY_SIZE(gem_noc_nodes),
+	.bcms = gem_noc_bcms,
+	.num_bcms = ARRAY_SIZE(gem_noc_bcms),
+};
+
+static struct qcom_icc_bcm * const mc_virt_bcms[] = {
+	&bcm_acv,
+	&bcm_mc0,
+};
+
+static struct qcom_icc_node * const mc_virt_nodes[] = {
+	[MASTER_LLCC] = &llcc_mc,
+	[SLAVE_EBI1] = &ebi,
+};
+
+static const struct qcom_icc_desc sm8350_mc_virt = {
+	.nodes = mc_virt_nodes,
+	.num_nodes = ARRAY_SIZE(mc_virt_nodes),
+	.bcms = mc_virt_bcms,
+	.num_bcms = ARRAY_SIZE(mc_virt_bcms),
+};
+
+static struct qcom_icc_bcm * const system_noc_bcms[] = {
+	&bcm_sn0,
+	&bcm_sn7,
+};
+
+static struct qcom_icc_node * const system_noc_nodes[] = {
+	[MASTER_A1NOC_SNOC] = &qnm_aggre1_noc,
+	[SLAVE_SNOC_GEM_NOC_SF] = &qns_gemnoc_sf,
+};
+
+static const struct qcom_icc_desc sm8350_system_noc = {
+	.nodes = system_noc_nodes,
+	.num_nodes = ARRAY_SIZE(system_noc_nodes),
+	.bcms = system_noc_bcms,
+	.num_bcms = ARRAY_SIZE(system_noc_bcms),
+};
+
+static const struct udevice_id qnoc_of_match[] = {
+	{ .compatible = "qcom,sm8350-aggre1-noc", .data = (ulong)&sm8350_aggre1_noc },
+	{ .compatible = "qcom,sm8350-config-noc", .data = (ulong)&sm8350_config_noc },
+	{ .compatible = "qcom,sm8350-gem-noc", .data = (ulong)&sm8350_gem_noc },
+	{ .compatible = "qcom,sm8350-mc-virt", .data = (ulong)&sm8350_mc_virt },
+	{ .compatible = "qcom,sm8350-system-noc", .data = (ulong)&sm8350_system_noc },
+	{ }
+};
+
+U_BOOT_DRIVER(qnoc_sm8350) = {
+	.name = "qnoc-sm8350",
+	.id = UCLASS_INTERCONNECT,
+	.of_match = qnoc_of_match,
+	.probe = qcom_icc_rpmh_probe,
+	.bind = qcom_icc_rpmh_bind,
+	.unbind = qcom_icc_rpmh_unbind,
+	.ops = &qcom_icc_rpmh_ops,
+	.plat_auto = sizeof(struct qcom_icc_provider),
+};
diff --git a/drivers/interconnect/qcom/sm8350.h b/drivers/interconnect/qcom/sm8350.h
new file mode 100644
index 0000000000..580b139185
--- /dev/null
+++ b/drivers/interconnect/qcom/sm8350.h
@@ -0,0 +1,25 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+/*
+ * SM8350 interconnect IDs
+ *
+ * Copyright (c) 2019-2020, The Linux Foundation. All rights reserved.
+ * Copyright (c) 2021, Linaro Limited
+ */
+
+#ifndef __DRIVERS_INTERCONNECT_QCOM_SM8350_H
+#define __DRIVERS_INTERCONNECT_QCOM_SM8350_H
+
+#define SM8350_MASTER_UFS_MEM		0
+#define SM8350_MASTER_GEM_NOC_CNOC	1
+#define SM8350_MASTER_APPSS_PROC	2
+#define SM8350_MASTER_SNOC_SF_MEM_NOC	3
+#define SM8350_MASTER_LLCC		4
+#define SM8350_MASTER_A1NOC_SNOC	5
+#define SM8350_SLAVE_A1NOC_SNOC		6
+#define SM8350_SLAVE_UFS_MEM_CFG	7
+#define SM8350_SLAVE_GEM_NOC_CNOC	8
+#define SM8350_SLAVE_LLCC		9
+#define SM8350_SLAVE_EBI1		10
+#define SM8350_SLAVE_SNOC_GEM_NOC_SF	11
+
+#endif

-- 
2.53.0

