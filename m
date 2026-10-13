From: Steve Meek <stevemeek82@gmail.com>
Date: Tue, 13 Oct 2026 15:14:34 +0100
Subject: [PATCH] bus: mhi: host: pci_generic: Disable doorbell burst mode
 for Quectel RM500Q-AE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-rm500q-db-burst-v1-1-bb850d54e2c4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMk8zmoC/yXMQQqDQAxA0atI1g1kHJTBq5QunDFqBG2bqBTEu
 3dal2/x/wHGKmzQFAco72LyXDLcrYA0tsvAKF02lFTWjpxHnSuiN3YR46a2IqcqUGpD8N5Brl7
 KvXz+x/vjsm1x4rT+NnCeX8gAupZzAAAA
X-Change-ID: 20261013-rm500q-db-burst-ec580ca88331
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Jeff Hugo <jeff.hugo@oss.qualcomm.com>
Cc: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 mhi@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Steve Meek <stevemeek82@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791900873; l=5124;
 i=stevemeek82@gmail.com; s=20261011; h=from:subject:message-id;
 bh=BSBArFla/DwFyRCB336wqMsgkVGpFN/iXB3N8/Qra/0=;
 b=btAw/hV6faG3YXcI5l3o0FZ5UthK5ZINCeCCRun9RKtYNjPxuiXtcbxQpQIopxfBWWtTdv6tg
 SxjdZ6T9L0uDm2vFl90bCpxDDn2a8nC8s3+SIe4FzT6MVn5CUACxskT
X-Developer-Key: i=stevemeek82@gmail.com; a=ed25519;
 pk=dtyc4btZAMr4Kqf5DaioLF7wBCQbkFYyDo3X5EcpZw8=
X-Endpoint-Received: by B4 Relay for stevemeek82@gmail.com/20261011 with auth_id=1154
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With burst mode enabled on the IP_HW0_MBIM hardware channels, the
RM500Q-AE downlink stops under sustained multi-stream load. The MHI
state stays M0 and uplink keeps working, but the downlink event ring
stops interrupting, and after a while the MBIM control channel times
out as well. Only a reboot recovers it.

At the stall, the last doorbell the host rang on channel 101 covered a
single buffer. The host then refilled the ring without ringing again,
as db_mode had been cleared, and the device never signalled doorbell
mode again, so it never saw the new buffers. Writing the channel 101
doorbell by hand with the current ring write pointer restores the
downlink immediately.

It is load dependent: it reproduces within a 25 second 16-stream TCP
download when the wwan0 receive work runs on the same CPU as the
modem's MSI, and was not seen with that work moved to another CPU.
PCIe runtime PM is not involved, as it reproduces with PCIe port PM
disabled.

Give the RM500Q-AE its own channel table with burst mode disabled on
the two hardware channels, so the host rings the doorbell on every
transfer. Other modems sharing the em1xx table are left unchanged.

Tested on a Xunison Exigo Hub D50 5G (IPQ5018, RM500Q-AE firmware
RM500QAEAAR13A03M4G, 6.18 with this driver): with the receive work on
the modem's CPU at up to 100% load, about 200 seconds of multi-stream
downloads at up to 135 Mbps, no stall and no MHI errors, where the
unpatched driver stalled within the first 25 second run.

Fixes: f6985f512f82 ("bus: mhi: host: pci_generic: Add Quectel RM500Q-AE support")
Assisted-by: LLM
Signed-off-by: Steve Meek <stevemeek82@gmail.com>
---
Hi Mani,

A follow-up to the RM500Q-AE support you applied on 11 Oct. Under heavy
multi-stream download the modem's downlink stalls with burst mode on,
and a manual doorbell write on channel 101 brings it straight back, so
this turns burst mode off for the RM500Q-AE's two hardware channels
only.

The stall looks like a lost doorbell-mode handshake rather than
anything board-specific, so it may affect other modems on the shared
em1xx table under the same load. I've only got the RM500Q-AE to test
on, so I've kept the change to that device. If you'd rather it were
fixed in the core, I'm happy to send the traces from the stall.
---
 drivers/bus/mhi/host/pci_generic.c | 49 +++++++++++++++++++++++++++++++++++++-
 1 file changed, 48 insertions(+), 1 deletion(-)

diff --git a/drivers/bus/mhi/host/pci_generic.c b/drivers/bus/mhi/host/pci_generic.c
index 7193a384c..f6672f1cc 100644
--- a/drivers/bus/mhi/host/pci_generic.c
+++ b/drivers/bus/mhi/host/pci_generic.c
@@ -490,10 +490,57 @@ static const struct mhi_pci_dev_info mhi_quectel_rm5xx_info = {
 	.sideband_wake = true,
 };
 
+/*
+ * The RM500Q-AE stalls its downlink when the host refills the hardware
+ * channel in burst mode: the last doorbell covers one buffer, the host
+ * then queues the rest without ringing, and the device never signals
+ * doorbell mode again. Ring the doorbell on every transfer instead.
+ */
+#define MHI_CHANNEL_CONFIG_HW_NOBRST(ch_num, ch_name, el_count, ev_ring, d) \
+	{						\
+		.num = ch_num,				\
+		.name = ch_name,			\
+		.num_elements = el_count,		\
+		.event_ring = ev_ring,			\
+		.dir = d,				\
+		.ee_mask = BIT(MHI_EE_AMSS),		\
+		.pollcfg = 0,				\
+		.doorbell = MHI_DB_BRST_DISABLE,	\
+		.lpm_notify = false,			\
+		.offload_channel = false,		\
+		.doorbell_mode_switch = false,		\
+	}
+
+static const struct mhi_channel_config mhi_quectel_rm500q_channels[] = {
+	MHI_CHANNEL_CONFIG_UL(0, "NMEA", 32, 0),
+	MHI_CHANNEL_CONFIG_DL(1, "NMEA", 32, 0),
+	MHI_CHANNEL_CONFIG_UL_SBL(2, "SAHARA", 32, 0),
+	MHI_CHANNEL_CONFIG_DL_SBL(3, "SAHARA", 32, 0),
+	MHI_CHANNEL_CONFIG_UL(4, "DIAG", 32, 1),
+	MHI_CHANNEL_CONFIG_DL(5, "DIAG", 32, 1),
+	MHI_CHANNEL_CONFIG_UL(12, "MBIM", 32, 0),
+	MHI_CHANNEL_CONFIG_DL(13, "MBIM", 32, 0),
+	MHI_CHANNEL_CONFIG_UL(32, "DUN", 32, 0),
+	MHI_CHANNEL_CONFIG_DL(33, "DUN", 32, 0),
+	MHI_CHANNEL_CONFIG_UL_FP(34, "FIREHOSE", 32, 0),
+	MHI_CHANNEL_CONFIG_DL_FP(35, "FIREHOSE", 32, 0),
+	MHI_CHANNEL_CONFIG_HW_NOBRST(100, "IP_HW0_MBIM", 128, 2, DMA_TO_DEVICE),
+	MHI_CHANNEL_CONFIG_HW_NOBRST(101, "IP_HW0_MBIM", 128, 3, DMA_FROM_DEVICE),
+};
+
+static const struct mhi_controller_config modem_quectel_rm500q_config = {
+	.max_channels = 128,
+	.timeout_ms = 20000,
+	.num_channels = ARRAY_SIZE(mhi_quectel_rm500q_channels),
+	.ch_cfg = mhi_quectel_rm500q_channels,
+	.num_events = ARRAY_SIZE(mhi_quectel_em1xx_events),
+	.event_cfg = mhi_quectel_em1xx_events,
+};
+
 static const struct mhi_pci_dev_info mhi_quectel_rm500q_info = {
 	.name = "quectel-rm500q",
 	.edl = "qcom/sdx55m/edl.mbn",
-	.config = &modem_quectel_em1xx_config,
+	.config = &modem_quectel_rm500q_config,
 	.bar_num = MHI_PCI_DEFAULT_BAR_NUM,
 	.dma_data_width = 32,
 	.mru_default = 32768,

---
base-commit: 0b1883ca75c0005ab5ca52c7bc1a26329bc39746
change-id: 20261013-rm500q-db-burst-ec580ca88331

Best regards,
--  
Steve Meek <stevemeek82@gmail.com>

