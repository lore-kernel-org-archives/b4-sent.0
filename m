From: David Heidelberg <david@ixit.cz>
Date: Sun, 06 Sep 2026 02:41:13 +0200
Subject: [PATCH RFC 2/4] soc: qcom: Add modemsmem for Google phones
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-modemsmem-v1-2-a3634b553841@ixit.cz>
References: <20260906-modemsmem-v1-0-a3634b553841@ixit.cz>
In-Reply-To: <20260906-modemsmem-v1-0-a3634b553841@ixit.cz>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Richard Acayan <mailingradian@gmail.com>, Petr Vorel <petr.vorel@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5934; i=david@ixit.cz;
 h=from:subject:message-id; bh=4BeR5PJTB/rdJa2OMEM7EGRFcjX2yhiQzjQLRvb1iqg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnLav2gKlA3kSeorPevUXt3YQ3EyrkEXAHyTfE
 P++nUVs12qJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapy2rwAKCRBgAj/E00kg
 coGAEACZ/VDp9XlxiaS+lS+Ic1xZjjonNPT6R59xnKObkmDNucb4CHRTAQl/yInfhCXc/7FLGj5
 67NCn8xQiVIbQ9whDZRcDTa3Xmeh/0vIymS/7PBJcEtb4ij/g21QxU+7qRvKxZWZvycUJBY3ttF
 Jre+MdgJ+HJH4+YRK7KpYEesREoIvSoZe0tvCfKBBKjU8OAak1o8CW+145Q9N+srUUV0D4xlOa6
 JBoNpQfzO9GvK/purzqvutUSb9LmyQkzYsQlPR4TWLYqSHPkmoX8tBirBOOtuOI9E36xcZl0SaU
 qBk6m7KfX6PdygODd+pvD7DssU28ICBc5kYn1siCNTCv3vmUsLzcGYQ0VLRDxFpR5Y+li9LDX8m
 fPyC2QhcCRPpJKeXTJ2QYD+YwlieQhv99l2Xo+9+1vTDKcL+05tZPFiYdwQlYNOufepFW3Zd0Wc
 vT201rRu3e5TEnDGrUkxgeDzLo/cD5eQ9sUq8UVnCPnX7yVH6nbjVEyJG+sm70ejA9ogdawdW8a
 4H43NUCOB+qGi8tmwuWDxMG93nAyUQcEAo8wBs1042fut/QD+/Xnjwum97onBArDoV9UZEAa0Ny
 tUfj3WFP2Rk2BcaU6WBVUygSzphz4FzllwoMqwPysUcH2WFqtUFBei/XWGvMeyhXzaZLXx8jEnO
 EN0JgfJxtn+g8RQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Richard Acayan <mailingradian@gmail.com>

Modems on Google Pixel devices require extra information about the
SoC to be passed through a vendor-controlled Shared Memory (SMEM)
channel. This driver provides this information.

Skimming through the device tree overlays, modemsmem seems to be used by
every Pixel chronologically between the Pixel 3 and Pixel 5a, inclusive.

The modem_flag field is not being initialized yet because the bootloader
doesn't always add the property in dtb (so it might not be necessary)
and because there are problems with how the proper value is being
retrieved in the original downstream driver.

Downstream kernels have this driver in:
drivers/soc/qcom/modemsmem/modemsmem.c

Assisted-by: LLM
Signed-off-by: Richard Acayan <mailingradian@gmail.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/soc/qcom/Kconfig     | 14 +++++++
 drivers/soc/qcom/Makefile    |  1 +
 drivers/soc/qcom/modemsmem.c | 98 ++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 113 insertions(+)

diff --git a/drivers/soc/qcom/Kconfig b/drivers/soc/qcom/Kconfig
index 2b524154d9fb3..32975f90bd63f 100644
--- a/drivers/soc/qcom/Kconfig
+++ b/drivers/soc/qcom/Kconfig
@@ -284,16 +284,30 @@ config QCOM_PBS
 	depends on SPMI
 	default m if ARCH_QCOM
 	help
 	  This driver supports configuring software programmable boot sequencer (PBS)
 	  trigger event through PBS RAM on Qualcomm Technologies, Inc. PMICs.
 	  This module provides the APIs to the client drivers that wants to send the
 	  PBS trigger event to the PBS RAM.
 
+config QCOM_MODEMSMEM
+	tristate "Google Pixel modem SMEM information"
+	depends on ARCH_QCOM || COMPILE_TEST
+	depends on OF
+	depends on QCOM_SMEM
+	help
+	  The modem firmware on Google Pixel 3 through Pixel 5a devices expects
+	  the application processor to publish SoC platform type and revision
+	  in a vendor-defined SMEM item before the modem is started. This
+	  driver fills in that item from the socinfo SMEM data.
+
+	  Say Y or M if you want a working modem on one of those phones.
+	  If unsure, say N.
+
 endif
 
 # Options selected by other drivers from different subsystems must be outside
 # of the menuconfig if-block:
 
 config QCOM_INLINE_CRYPTO_ENGINE
 	tristate
 	select QCOM_SCM
diff --git a/drivers/soc/qcom/Makefile b/drivers/soc/qcom/Makefile
index 798643be3590c..4a04cd6e497d1 100644
--- a/drivers/soc/qcom/Makefile
+++ b/drivers/soc/qcom/Makefile
@@ -35,9 +35,10 @@ obj-$(CONFIG_QCOM_STATS)	+= qcom_stats.o
 obj-$(CONFIG_QCOM_WCNSS_CTRL) += wcnss_ctrl.o
 obj-$(CONFIG_QCOM_APR) += apr.o
 obj-$(CONFIG_QCOM_LLCC) += llcc-qcom.o
 obj-$(CONFIG_QCOM_KRYO_L2_ACCESSORS) +=	kryo-l2-accessors.o
 obj-$(CONFIG_QCOM_ICC_BWMON)	+= icc-bwmon.o
 qcom_ice-objs			+= ice.o
 obj-$(CONFIG_QCOM_INLINE_CRYPTO_ENGINE)	+= qcom_ice.o
 obj-$(CONFIG_QCOM_PBS) +=	qcom-pbs.o
+obj-$(CONFIG_QCOM_MODEMSMEM)	+= modemsmem.o
 obj-$(CONFIG_QCOM_UBWC_CONFIG) += ubwc_config.o
diff --git a/drivers/soc/qcom/modemsmem.c b/drivers/soc/qcom/modemsmem.c
new file mode 100644
index 0000000000000..7a733422ff7c1
--- /dev/null
+++ b/drivers/soc/qcom/modemsmem.c
@@ -0,0 +1,98 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/*
+ * SoC Information over Shared Memory.
+ *
+ * Copyright 2022-2024, Richard Acayan.
+ */
+
+#include <linux/err.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/platform_device.h>
+#include <linux/soc/qcom/smem.h>
+#include <linux/soc/qcom/socinfo.h>
+
+#define MODEM_SMEM_VERSION 0
+
+#define PLAT_VER_TO_MAJOR_ID(v) (((v) >> 16) & 0xff)
+#define PLAT_VER_TO_MINOR_ID(v) ((v) & 0xff)
+
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
+static int write_socinfo(struct modem_smem_info *target)
+{
+	struct socinfo *socinfo;
+	u32 plat_ver;
+
+	socinfo = qcom_smem_get(QCOM_SMEM_HOST_ANY, SMEM_HW_SW_BUILD_ID, NULL);
+	if (IS_ERR(socinfo))
+		return PTR_ERR(socinfo);
+
+	/* hw_plat_subtype was added in socinfo format 0.6 */
+	if (le32_to_cpu(socinfo->fmt) < SOCINFO_VERSION(0, 6))
+		return -EOPNOTSUPP;
+
+	plat_ver = le32_to_cpu(socinfo->plat_ver);
+
+	target->version = cpu_to_le32(MODEM_SMEM_VERSION);
+	target->major_id = cpu_to_le32(PLAT_VER_TO_MAJOR_ID(plat_ver));
+	target->minor_id = cpu_to_le32(PLAT_VER_TO_MINOR_ID(plat_ver));
+	target->platform = socinfo->hw_plat;
+	target->subtype = socinfo->hw_plat_subtype;
+
+	return 0;
+}
+
+static int modemsmem_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct modem_smem_info *info;
+	u32 smem_id;
+	int ret;
+
+	ret = of_property_read_u32(dev->of_node, "qcom,smem-id", &smem_id);
+	if (ret)
+		return dev_err_probe(dev, ret, "Could not read smem id\n");
+
+	ret = qcom_smem_alloc(QCOM_SMEM_HOST_ANY, smem_id, sizeof(*info));
+	if (ret)
+		return dev_err_probe(dev, ret, "Could not allocate modem smem\n");
+
+	info = qcom_smem_get(QCOM_SMEM_HOST_ANY, smem_id, NULL);
+	if (IS_ERR(info))
+		return dev_err_probe(dev, PTR_ERR(info), "Could not get modem smem\n");
+
+	ret = write_socinfo(info);
+	if (ret)
+		return dev_err_probe(dev, ret, "Could not submit info to modemsmem\n");
+
+	return 0;
+}
+
+static const struct of_device_id modemsmem_of_match[] = {
+	{ .compatible = "google,modemsmem" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, modemsmem_of_match);
+
+static struct platform_driver modemsmem_driver = {
+	.probe = modemsmem_probe,
+	.driver = {
+		.name = "modemsmem",
+		.of_match_table = modemsmem_of_match,
+	},
+};
+module_platform_driver(modemsmem_driver);
+
+MODULE_AUTHOR("Richard Acayan <mailingradian@gmail.com>");
+MODULE_DESCRIPTION("SoC Information over SMEM driver");
+MODULE_LICENSE("GPL");

-- 
2.55.0

