From: Haipeng Lin <jimmie.lin@gmail.com>
Date: Tue, 10 Nov 2026 20:06:30 -0500
Subject: [PATCH RFC v2] bus: mhi: host: pci_generic: Add MBIM-mode config
 for generic SDX65
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-mhi-sdx65-mbim-rfc-v2-1-f1d71a5ac9ab@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NTQrCMBSEr1Le2idJa9voShA8gFvpIn9tH5hGE
 gmV0rsbcgCX3wzzzQbRBrIRLtUGwSaK5JcM9aECPctlskgmM9Ss7jjjHN1MGM3ategUOQyjRiG
 1UJKZvhcS8vAd7EhrkT7hcb/BkMOZ4seHbzlKvFT/nIkjR8HEWZ1M05hWXScn6XXU3sGw7/sPr
 DEQQLkAAAA=
X-Change-ID: 20261011-mhi-sdx65-mbim-rfc-8ac8ba0d778a
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Jeff Hugo <jeff.hugo@oss.qualcomm.com>
Cc: mhi@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, daleyo@gmail.com, 
 Johan Hovold <johan@kernel.org>, Haipeng Lin <jimmie.lin@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794359216; l=4467;
 i=jimmie.lin@gmail.com; s=20261011; h=from:subject:message-id;
 bh=ZLVxxQwkggsrloBrxJyjFyMexniwKJn2AL6lIKjlQ4w=;
 b=QboCyMkwfvriVeAw1+gALoE8intbzqfiWahZTM9uJq33pOwZ/IHc2Yt5cJW6tboFn5cL8/ey3
 J/ycjjJzXIhAcJLA4TBrt4m78+WfpJzLBmsDfnmRpbyr/pvzebI9x+A
X-Developer-Key: i=jimmie.lin@gmail.com; a=ed25519;
 pk=3KDRF1RQ/9A7ZUVTdRVEZnVrGltdmq1bRocsOYeXezI=
X-Endpoint-Received: by B4 Relay for jimmie.lin@gmail.com/20261011 with auth_id=1164
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Surface Pro 11 5G carries an SDX65 that enumerates with Qualcomm's
generic IDs (17cb:0308, subsystem 17cb:0308) but runs the MBIM-mode
firmware it ships with for Windows.

Control is MBIM only (the QMI channel never answers), and data on
channels 100/101 is framed as MBIM NTBs: the modem reports a WDA data
format of raw IP with MBIM aggregation, up to 32 KiB downlink.

The generic qcom-sdx65m entry names channels 100/101 "IP_HW0", which
binds mhi_net. mhi_net expects raw IP, so no data session can work.
The MBIM-mode modules in this driver name them "IP_HW0_MBIM" instead
which binds mhi_wwan_mbim.

Boards with a Qualcomm-ID modem in MBIM mode have so far been told
apart by subsystem ID, like the SC8280XP CRD's SDX55 (17cb:010c).
This modem carries the generic subsystem ID, so select an MBIM
configuration by machine compatible instead.

Like the SC8280XP CRD entry, reuse the Foxconn SDX55 channel config
which works with this firmware. The MRU is 32 KiB to match the
modem's downlink aggregation size.

Tested on a Surface Pro 11 5G (Surface_Pro_with_5G_11th_Edition_2077,
modem firmware 251216-DE-dc49bb9-00197) on a v7.2.11-based kernel:
ModemManager registers the modem on wwan0mbim0, uses wwan0 for data and
wwan0at0 for AT commands, and connects over LTE and 5G NR.

Assisted-by: LLM
Signed-off-by: Haipeng Lin <jimmie.lin@gmail.com>
---
Hi Mani and Jeff,

A follow-up to the RFC I sent last month (linked below). 

I tested the Foxconn SDX55 channel configuration on this modem and it
works, so v2 reuses it like the SC8280XP CRD entry does, and only the
selection is new. Hope this makes the patch clearer.

I would appreciate comments on whether matching the machine compatible
in probe is the acceptable approach, or if you would prefer a property
on the PCIe endpoint's DT node (although that would be a bigger patch)

Thanks.
---
Changes in v2:
- Reuse modem_foxconn_sdx55_config instead of adding a channel table.
  This adds the DUN channel (tested: answers AT commands) and drops
  IPCR which is unused by the Surface Pro 11.
- Link to v1: https://lore.kernel.org/r/20261011-mhi-sdx65-mbim-rfc-v1-1-8089b4d33d5b@gmail.com
---
 drivers/bus/mhi/host/pci_generic.c | 33 +++++++++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/drivers/bus/mhi/host/pci_generic.c b/drivers/bus/mhi/host/pci_generic.c
index 7193a384cca4..29b275572603 100644
--- a/drivers/bus/mhi/host/pci_generic.c
+++ b/drivers/bus/mhi/host/pci_generic.c
@@ -12,6 +12,7 @@
 #include <linux/device.h>
 #include <linux/mhi.h>
 #include <linux/module.h>
+#include <linux/of.h>
 #include <linux/pci.h>
 #include <linux/pm_runtime.h>
 #include <linux/timer.h>
@@ -582,6 +583,34 @@ static const struct mhi_pci_dev_info mhi_foxconn_sdx55_info = {
 	.sideband_wake = false,
 };
 
+/*
+ * Some machines have an SDX65 with the generic Qualcomm IDs
+ * (17cb:0308, subsystem 17cb:0308) running MBIM-mode firmware
+ * they ship with for Windows.
+ * The exact channel configuration is not known but the Foxconn SDX55
+ * configuration works with this firmware.
+ */
+static const struct mhi_pci_dev_info mhi_qcom_sdx65_mbim_info = {
+	.name = "qcom-sdx65m-mbim",
+	.fw = "qcom/sdx65m/xbl.elf",
+	.edl = "qcom/sdx65m/edl.mbn",
+	.edl_trigger = true,
+	.config = &modem_foxconn_sdx55_config,
+	.bar_num = MHI_PCI_DEFAULT_BAR_NUM,
+	.dma_data_width = 32,
+	.mru_default = 32768,
+	.sideband_wake = false,
+};
+
+/*
+ * The PCI IDs cannot tell these modems apart from QMI-mode modules,
+ * so match the machine instead.
+ */
+static const char *const mhi_qcom_sdx65_mbim_machines[] = {
+	"microsoft,denali",
+	NULL
+};
+
 static const struct mhi_pci_dev_info mhi_foxconn_t99w175_info = {
 	.name = "foxconn-t99w175",
 	.edl = "qcom/sdx55m/foxconn/prog_firehose_sdx55.mbn",
@@ -1389,6 +1418,10 @@ static int mhi_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	unsigned int dma_data_width;
 	int err;
 
+	if (info == &mhi_qcom_sdx65_info &&
+	    of_machine_compatible_match(mhi_qcom_sdx65_mbim_machines))
+		info = &mhi_qcom_sdx65_mbim_info;
+
 	dev_info(&pdev->dev, "MHI PCI device found: %s\n", info->name);
 
 	/* mhi_pdev.mhi_cntrl must be zero-initialized */

---
base-commit: 0b1883ca75c0005ab5ca52c7bc1a26329bc39746
change-id: 20261011-mhi-sdx65-mbim-rfc-8ac8ba0d778a

Best regards,
-- 
Haipeng Lin <jimmie.lin@gmail.com>

