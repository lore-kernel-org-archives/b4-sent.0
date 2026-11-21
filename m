From: Haipeng Lin <jimmie.lin@gmail.com>
Date: Fri, 20 Nov 2026 23:30:54 -0500
Subject: [PATCH v3] bus: mhi: host: pci_generic: Add MBIM-mode config for
 generic SDX65
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-mhi-sdx65-mbim-rfc-v3-1-20741d24da0c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NTQ6CMBCG4auQrh3TKQLFlfcwLvoHTGLBtKbBE
 O5uYWNMjMv3S+aZhUUXyEV2LhYWXKJI05ijPBTMDGrsHZDNzQQXNXJE8ANBtHNdgdfkIXQGpDJ
 SK26bRiqWDx/BdTTv6PWWe6D4nMJr/5FwW/9yCQFBctnqky1LW+lL7xXdj2bybOOS+BCI/CchM
 tGhbVBVyrTqi1jX9Q0TJKFs9wAAAA==
X-Change-ID: 20261011-mhi-sdx65-mbim-rfc-8ac8ba0d778a
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Jeff Hugo <jeff.hugo@oss.qualcomm.com>
Cc: mhi@lists.linux.dev, linux-arm-msm@vger.kernel.org, daleyo@gmail.com, 
 Johan Hovold <johan@kernel.org>, linux-kernel@vger.kernel.org, 
 Haipeng Lin <jimmie.lin@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795235487; l=5133;
 i=jimmie.lin@gmail.com; s=20261011; h=from:subject:message-id;
 bh=6qEhayVyUMduqrYRZdyaVcdgAqFbrpWlcIPHaQarGjA=;
 b=CrJJ5ZywjFK3X/Wtr7iQ3v4P+75Fo2r7ASY4c49UU3U36L88N90G74rOl8KikUc8ZxEmZ7TjL
 acpD9B1hL21CKDtv4MO9XE+StDrk6nBzy23E+xdC4g1w4CEHXJEs/+T
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

There is no known way to query the modem for MIBM mode before the
channels are set up. As a limitation, a separate SDX65 using generic
IDs on a matching machine (e.g., via USB4 PCIe tunneling) would also
get the MBIM config.

Like the SC8280XP CRD entry, reuse the Foxconn SDX55 channel config
which works with this firmware. The MRU is 32 KiB to match the
modem's downlink aggregation size.

Tested on a Surface Pro 11 5G (Surface_Pro_with_5G_11th_Edition_2077,
modem firmware 251216-DE-dc49bb9-00197) on a v7.2.11-based kernel:
ModemManager registers the modem on wwan0mbim0, uses wwan0 for data and
wwan0at0 for AT commands, and connects over LTE and 5G NR.

Signed-off-by: Haipeng Lin <jimmie.lin@gmail.com>
---
Hi Mani and Jeff,

Dropping the RFC prefix and resending for your consideration.

A known limitation to this patch as raised by Jeff in RFC v2 was that a
SDX65 dongle would also match to MBIM-mode by this. A bigger patch
could be adding a property on the PCIe endpoint's DT node. Please let
me know if machine-compatible matching is acceptable, happy to try
other approaches.

LLM was used to draft the MBIM configuration patch and assisted with
testing on device.

Thanks,
---
Changes in v3:
- Drop RFC prefix
- No code changes
- Commit message updated to note limitation for SDX65 dongles on
  matching machines as raised by Jeff Hugo.
- OEM PK hash method ruled out in discussion: https://lore.kernel.org/all/088d0be9-5d45-4454-b160-efff83e7a647@oss.qualcomm.com
- Dropped Assisted-by trailer and clarified in cover letter per 7.4 guidance.
- Link to v2: https://lore.kernel.org/r/20261110-mhi-sdx65-mbim-rfc-v2-1-f1d71a5ac9ab@gmail.com

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

