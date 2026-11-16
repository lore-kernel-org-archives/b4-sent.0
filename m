From: David Heidelberg <david@ixit.cz>
Date: Mon, 16 Nov 2026 16:50:44 +0100
Subject: [PATCH v3 2/3] remoteproc: qcom_q6v5_mss: Publish socinfo for
 Pixel modems
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-modemsmem-v3-2-24ebc7ed6eb9@ixit.cz>
References: <20261116-modemsmem-v3-0-24ebc7ed6eb9@ixit.cz>
In-Reply-To: <20261116-modemsmem-v3-0-24ebc7ed6eb9@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Sibi Sankar <sibi.sankar@oss.qualcomm.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Miro Mraz <mraz.miro@seznam.cz>
Cc: Richard Acayan <mailingradian@gmail.com>, linux-arm-msm@vger.kernel.org, 
 linux-remoteproc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5814; i=david@ixit.cz;
 h=from:subject:message-id; bh=RwIpafmzT0uNWBF3Nvx6g7u04fLCPqObCGKjspl4C0I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBq+yZfxGoYmj7ZU7NGjvRKdLI7GxJj4I2EElBW/
 mKkcpn398KJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCavsmXwAKCRBgAj/E00kg
 cgsWD/40nzeSboMn70E0bkKamrMeAAnRJFC/Jn1K+JN9+9hNpjlhBHq626/rK2gqJP4QRZZVLzZ
 Ai6YVcoMO7fg98MoT90Hlv4FJoFd30nSLJvaLvilFXeAMcZjc03TFYshI9HsuDqU1bhMV0Z+PS+
 r0OXWnklfz8NwDiIFwLWBbKO7Do5voQaQyL4DB4/a4UMzGFBD++AupsoLqbDdA6sp6Ndl7hklUz
 JM/KHYyVY5RTEFOmA+X8P/CDCMFWHwn8lJklh7R5OBokozwkD2u67j1cXC2RILWzTIngvfVqCAr
 GyhXaJZZZonwOJItg8fI65n7xI5lH2ZI9fGun+z4e7H3E/3Tx4dqRReY1klkTqtv2vjX731JyZ1
 G3ZUsYChV5bafBmWWJ9PT1Ds8tfgQ7bs8xBatJ3He9rqixuXgnOMKqHjDHhtx9jUqEG7Qui2TbH
 l7fvI54NZJYyXzapDOvdZld7wXrEwskYKknTydZKnW+3zFtgks2wyQNWZ8zqOHuXNzqifuwAgth
 S8NwyXJbY07WuCjca+RXhrw7QdtH8hql2gP4uyUvJ2zHdogiqFkUoCdv2hIY/1IFCukNUwBkt8l
 YuDiLM2ALOF4YBavpiVzQDC16jedyQCpw2GvDfoe9OT6C7Z/qY1WKZSSBF78n6jaOl1jvdPsiTa
 U7uoy0MLgnE1XHQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The modem firmware on Google Pixel boards (Pixel 3 through Pixel 5a)
reads the SoC platform type, subtype and revision from the first
vendor-reserved SMEM item (item 134) when it boots, and refuses to
come up unless the application processor has filled it in.

When the "google,require-socinfo" property is present on the MSS
remoteproc node, copy the relevant socinfo fields into that item from
the socinfo SMEM data before starting the modem. The SMEM item id and
layout are a contract between Google's downstream kernel and the modem
firmware rather than hardware, so they are hard-coded in the driver.

The item is written in full: modem_flag, efs_magic and ftm_magic are
left zero. Downstream fills modem_flag from a bootloader-provided
/chosen/cdt/cdb2 property that is not always present, and the two magic
values only matter for factory test mode.

Based on work of: Richard Acayan.
Adapted from the original form using both human & LLM work.

Suggested-by: Bjorn Andersson <andersson@kernel.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/remoteproc/qcom_q6v5_mss.c | 75 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 75 insertions(+)

diff --git a/drivers/remoteproc/qcom_q6v5_mss.c b/drivers/remoteproc/qcom_q6v5_mss.c
index dd052a62b8583..53deabea62259 100644
--- a/drivers/remoteproc/qcom_q6v5_mss.c
+++ b/drivers/remoteproc/qcom_q6v5_mss.c
@@ -23,27 +23,35 @@
 #include <linux/pm_runtime.h>
 #include <linux/regmap.h>
 #include <linux/regulator/consumer.h>
 #include <linux/remoteproc.h>
 #include <linux/reset.h>
 #include <linux/soc/qcom/mdt_loader.h>
 #include <linux/iopoll.h>
 #include <linux/slab.h>
+#include <linux/soc/qcom/smem.h>
+#include <linux/soc/qcom/socinfo.h>
 
 #include "remoteproc_internal.h"
 #include "qcom_common.h"
 #include "qcom_pil_info.h"
 #include "qcom_q6v5.h"
 
 #include <linux/firmware/qcom/qcom_pas.h>
 #include <linux/firmware/qcom/qcom_scm.h>
 
 #define MPSS_CRASH_REASON_SMEM		421
 
+/*
+ * First vendor-reserved SMEM item; Google's modem firmware reads the SoC
+ * platform information from it when the modem boots.
+ */
+#define SMEM_ID_VENDOR0			134
+
 #define MBA_LOG_SIZE			SZ_4K
 
 #define MPSS_PAS_ID			5
 
 /* RMB Status Register Values */
 #define RMB_PBL_SUCCESS			0x1
 
 #define RMB_MBA_XPU_UNLOCKED		0x1
@@ -247,16 +255,17 @@ struct q6v5 {
 	bool need_pas_mem_setup;
 	bool has_alt_reset;
 	bool has_mba_logs;
 	bool has_spare_reg;
 	bool has_qaccept_regs;
 	bool has_ext_bhs_reg;
 	bool has_ext_cntl_regs;
 	bool has_vq6;
+	bool need_socinfo;
 	u64 mpss_perm;
 	u64 mba_perm;
 	const char *hexagon_mdt_image;
 	int version;
 };
 
 enum {
 	MSS_MDM9607,
@@ -1668,22 +1677,86 @@ static void qcom_q6v5_dump_segment(struct rproc *rproc,
 						false, true,
 						qproc->mpss_phys,
 						qproc->mpss_size);
 			q6v5_mba_reclaim(qproc);
 		}
 	}
 }
 
+/* Layout of the vendor-defined SMEM item read by the Pixel modem firmware */
+struct modem_smem_info {
+	__le32 version;
+	__le32 modem_flag;
+	__le32 major_id;
+	__le32 minor_id;
+	__le32 subtype;
+	__le32 platform;
+	__le32 efs_magic;
+	__le32 ftm_magic;
+};
+
+#define MODEM_SMEM_VERSION	0
+#define PLAT_VER_TO_MAJOR_ID(v)	(((v) >> 16) & 0xff)
+#define PLAT_VER_TO_MINOR_ID(v)	((v) & 0xff)
+
+static int q6v5_socinfo_publish(struct q6v5 *qproc)
+{
+	struct modem_smem_info *info;
+	struct socinfo *socinfo;
+	u32 plat_ver;
+	int ret;
+
+	socinfo = qcom_smem_get(QCOM_SMEM_HOST_ANY, SMEM_HW_SW_BUILD_ID, NULL);
+	if (IS_ERR(socinfo))
+		return dev_err_probe(qproc->dev, PTR_ERR(socinfo),
+				     "could not get socinfo\n");
+
+	/* hw_plat_subtype was added in socinfo format 0.6 */
+	if (le32_to_cpu(socinfo->fmt) < SOCINFO_VERSION(0, 6))
+		return dev_err_probe(qproc->dev, -EOPNOTSUPP,
+				     "socinfo format too old\n");
+
+	/* -EEXIST: the item survived an earlier boot */
+	ret = qcom_smem_alloc(QCOM_SMEM_HOST_ANY, SMEM_ID_VENDOR0, sizeof(*info));
+	if (ret && ret != -EEXIST)
+		return dev_err_probe(qproc->dev, ret,
+				     "could not allocate modem smem\n");
+
+	info = qcom_smem_get(QCOM_SMEM_HOST_ANY, SMEM_ID_VENDOR0, NULL);
+	if (IS_ERR(info))
+		return dev_err_probe(qproc->dev, PTR_ERR(info),
+				     "could not get modem smem\n");
+
+	plat_ver = le32_to_cpu(socinfo->plat_ver);
+
+	/* modem_flag, efs_magic and ftm_magic are left zero */
+	*info = (struct modem_smem_info) {
+		.version   = cpu_to_le32(MODEM_SMEM_VERSION),
+		.major_id  = cpu_to_le32(PLAT_VER_TO_MAJOR_ID(plat_ver)),
+		.minor_id  = cpu_to_le32(PLAT_VER_TO_MINOR_ID(plat_ver)),
+		.subtype   = socinfo->hw_plat_subtype,
+		.platform  = socinfo->hw_plat,
+	};
+
+	return 0;
+}
+
 static int q6v5_start(struct rproc *rproc)
 {
 	struct q6v5 *qproc = rproc->priv;
 	int xfermemop_ret;
 	int ret;
 
+	if (qproc->need_socinfo) {
+		ret = q6v5_socinfo_publish(qproc);
+		if (ret)
+			return ret;
+	}
+
 	ret = q6v5_mba_load(qproc);
 	if (ret)
 		return ret;
 
 	dev_info(qproc->dev, "MBA booted with%s debug policy, loading mpss\n",
 		 qproc->dp_size ? "" : "out");
 
 	ret = q6v5_mpss_load(qproc);
@@ -2127,16 +2200,18 @@ static int q6v5_probe(struct platform_device *pdev)
 
 	platform_set_drvdata(pdev, qproc);
 
 	qproc->has_qaccept_regs = desc->has_qaccept_regs;
 	qproc->has_ext_bhs_reg = desc->has_ext_bhs_reg;
 	qproc->has_ext_cntl_regs = desc->has_ext_cntl_regs;
 	qproc->has_vq6 = desc->has_vq6;
 	qproc->has_spare_reg = desc->has_spare_reg;
+	qproc->need_socinfo =
+		of_property_read_bool(pdev->dev.of_node, "google,require-socinfo");
 	ret = q6v5_init_mem(qproc, pdev);
 	if (ret)
 		return ret;
 
 	ret = q6v5_alloc_memory_region(qproc);
 	if (ret)
 		return ret;
 

-- 
2.55.0

