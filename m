From: Haipeng Lin <jimmie.lin@gmail.com>
Date: Sun, 11 Oct 2026 22:35:56 -0400
Subject: [PATCH RFC] bus: mhi: host: pci_generic: Add MBIM-mode config for
 generic SDX65
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-mhi-sdx65-mbim-rfc-v1-1-8089b4d33d5b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0ND3dyMTN3ilAozU93cpMxc3aK0ZF2LxGSLpESDFHNzi0QloMaCotS
 0zAqwodFKQW7OSrG1tQCP/ef0aQAAAA==
X-Change-ID: 20261011-mhi-sdx65-mbim-rfc-8ac8ba0d778a
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Jeff Hugo <jeff.hugo@oss.qualcomm.com>
Cc: mhi@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, daleyo@gmail.com, 
 Haipeng Lin <jimmie.lin@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791772564; l=6715;
 i=jimmie.lin@gmail.com; s=20261011; h=from:subject:message-id;
 bh=12BqEQFC2zNFvRylvqVSEtj1UlA8nqo2lwDSkjHX2y0=;
 b=vP1kMRlhSbHPkFTrpYPTwc0Cuzavc6czw63h1+bxHRXfGcF9RgE3cHoZSsvOGG/JtUQP+lUKm
 co1PEGEMi6wAqB9R5UZC/bmtDxuRKJpQxpVqWFWqinFCrFRCciL9bPX
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
This modem carries the generic subsystem ID, so we select an MBIM
configuration by machine compatible instead. The channel layout is
modem_qcom_v1 with data on IP_HW0_MBIM and without the QMI and IP_SW0
channels. With the stock layout ModemManager spent about 45 s probing
the silent QMI port and put the bearer on mhi_swip0 (IP_SW0);
with this layout it does neither.
The MRU is 32 KiB to match the modem's downlink aggregation size.

Tested on a Surface Pro 11 5G (Surface_Pro_with_5G_11th_Edition_2077,
modem firmware 251216-DE-dc49bb9-00197) on a v7.2.8-based kernel:
ModemManager registers the modem on wwan0mbim0, uses wwan0 for data and
connects over 5G NR.

Assisted-by: claude-opus:5.5
Signed-off-by: Haipeng Lin <jimmie.lin@gmail.com>
---
Hi Mani, maintainers,

I am sending this patch developed to support the Qualcomm SDX65 modem
in the Surface Pro 5G (LCD, X1P-64-100 variant) for your consideration
and comments.

I am sending this as an RFC because I am not sure how you would like
the MBIM-mode configuration to be selected. The device exposes the
modem with fully generic PCI IDs (17cb:0308, subsystem 17cb:0308) so
we cannot tell it apart from QMI-mode SDX65 modules using
PCI_DEVICE_SUB() entries.

This patch proposes to match the machine compatible. This is a smaller
change without a new DT ABI but the PCI driver looking at the root
compatible may be unusual, hence the RFC.

An alternative would be to describe the endpoint in DT (a pci17cb,308
node under the root port) with a property naming the firmware mode or
channel layout, similar to ath11k's qcom,calibration-variant, then read
it from pdev->dev.of_node; this would describe the board instead of the
machine but needs a new binding.

Additionally we could potentially reuse modem_foxconn_sdx55_config
instead of adding a channel table, as the SC8280XP CRD entry does but I
haven't tested that layout on this modem yet.

I would be happy to rework the patch based on your comments.

DTs for Surface Pro 11 LCD are in the process of being upstreamed
separately and I've submitted patches to Dale Whinham's Surface Pro 11
tree to enable pcie5 to enumerate the modem. This patch was
functionally tested on top of that tree based on v7.2.8.

This patch is based on mhi-next and build-tested in arm64 and x86_64
without CONFIG_OF. mhi-next adds DUN (32/33) to
modem_qcom_v1_mhi_channels. I left DUN out of the MBIM table because
I haven't tested it on this modem.

Thank you for your consideration.

Best,
Haipeng
---
 drivers/bus/mhi/host/pci_generic.c | 55 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 55 insertions(+)

diff --git a/drivers/bus/mhi/host/pci_generic.c b/drivers/bus/mhi/host/pci_generic.c
index 7193a384cca4..4df5f9962ee7 100644
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
@@ -373,6 +374,33 @@ static const struct mhi_controller_config modem_qcom_v1_mhiv_config = {
 	.event_cfg = modem_qcom_v1_mhi_events,
 };
 
+/*
+ * Channel layout of the same modems running MBIM-mode firmware:
+ * data travels on IP_HW0 as MBIM NTBs,
+ * and the QMI and IP_SW0 channels go unused.
+ */
+static const struct mhi_channel_config modem_qcom_v1_mbim_channels[] = {
+	MHI_CHANNEL_CONFIG_UL(4, "DIAG", 16, 1),
+	MHI_CHANNEL_CONFIG_DL(5, "DIAG", 16, 1),
+	MHI_CHANNEL_CONFIG_UL(12, "MBIM", 4, 0),
+	MHI_CHANNEL_CONFIG_DL(13, "MBIM", 4, 0),
+	MHI_CHANNEL_CONFIG_UL(20, "IPCR", 8, 0),
+	MHI_CHANNEL_CONFIG_DL(21, "IPCR", 8, 0),
+	MHI_CHANNEL_CONFIG_UL_FP(34, "FIREHOSE", 32, 0),
+	MHI_CHANNEL_CONFIG_DL_FP(35, "FIREHOSE", 32, 0),
+	MHI_CHANNEL_CONFIG_HW_UL(100, "IP_HW0_MBIM", 128, 4),
+	MHI_CHANNEL_CONFIG_HW_DL(101, "IP_HW0_MBIM", 128, 5),
+};
+
+static const struct mhi_controller_config modem_qcom_v1_mbim_config = {
+	.max_channels = 128,
+	.timeout_ms = 8000,
+	.num_channels = ARRAY_SIZE(modem_qcom_v1_mbim_channels),
+	.ch_cfg = modem_qcom_v1_mbim_channels,
+	.num_events = ARRAY_SIZE(modem_qcom_v1_mhi_events),
+	.event_cfg = modem_qcom_v1_mhi_events,
+};
+
 static const struct mhi_pci_dev_info mhi_qcom_sa8775p_info = {
 	.name = "qcom-sa8775p",
 	.edl_trigger = false,
@@ -405,6 +433,29 @@ static const struct mhi_pci_dev_info mhi_qcom_sdx65_info = {
 	.sideband_wake = false,
 };
 
+static const struct mhi_pci_dev_info mhi_qcom_sdx65_mbim_info = {
+	.name = "qcom-sdx65m-mbim",
+	.fw = "qcom/sdx65m/xbl.elf",
+	.edl = "qcom/sdx65m/edl.mbn",
+	.edl_trigger = true,
+	.config = &modem_qcom_v1_mbim_config,
+	.bar_num = MHI_PCI_DEFAULT_BAR_NUM,
+	.dma_data_width = 32,
+	.mru_default = 32768,
+	.sideband_wake = false,
+};
+
+/*
+ * Machines whose SDX65 carries the generic Qualcomm IDs
+ * (17cb:0308, subsystem 17cb:0308) but runs the MBIM-mode firmware
+ * it ships with for Windows.
+ * The PCI IDs cannot tell these apart from QMI-mode modules, so match the machine.
+ */
+static const char *const mhi_qcom_sdx65_mbim_machines[] = {
+	"microsoft,denali",
+	NULL
+};
+
 static const struct mhi_pci_dev_info mhi_qcom_sdx55_info = {
 	.name = "qcom-sdx55m",
 	.fw = "qcom/sdx55m/sbl1.mbn",
@@ -1389,6 +1440,10 @@ static int mhi_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
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

