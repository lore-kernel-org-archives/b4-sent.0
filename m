From: Zxyan Zhu <zxyan0222@gmail.com>
Date: Thu, 06 Aug 2026 16:03:19 +0800
Subject: [PATCH] net: stmmac: dwxgmac2: add XGMAC timestamp interrupt
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-dwxgmac2-timestamp-irq-v1-1-c051c79c9d90@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMY/dGoC/yXMywrCMBBG4Vcps3YgBgnWVxEXufzWEVJrJtVC6
 bsbdfktzllJUQRKp26lgpeoPMaG/a6jePPjAJbUTNZYZ47GcXovQ/bRcpUMrT5PLOXJIRz6ZB3
 QJ1CLp4KrLL/x+fK3zuGOWL832rYPLvoGynoAAAA=
X-Change-ID: 20260806-dwxgmac2-timestamp-irq-bb49d26ee9de
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Richard Cochran <richardcochran@gmail.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Zxyan Zhu <zxyan0222@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786003453; l=7574;
 i=zxyan0222@gmail.com; s=20260806; h=from:subject:message-id;
 bh=1H2uDk15GprK4olxaBElieXZeWUvadUaP0WjWNuFWEk=;
 b=meVt0tD1QaLl1n1yEJbRwW09U1bM1wvqktb5GfdqoAOAFhOfewOgrO8Loq6GiMIR+p60D5/DI
 AFTKMi0DU21DaYMEyYTfar2YUS5ED3tyFTg5eAAAv3kyHgnkT4GYynB
X-Developer-Key: i=zxyan0222@gmail.com; a=ed25519;
 pk=9n789MT3lKb996clw/h0V/qpdwGmJqHCQwKFogLsWRw=
X-Endpoint-Received: by B4 Relay for zxyan0222@gmail.com/20260806 with auth_id=922
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DWXGMAC2 uses different timestamp status registers and interrupt clear
semantics from the generic stmmac PTP implementation. In particular,
reading XGMAC_TIMESTAMP_STATUS clears the transient TSIS and AUXTSTRIG
status bits that the generic timestamp interrupt handler relies on.

The TX timestamp retrieval path polls XGMAC_TIMESTAMP_STATUS for TXTSC,
which may consume TSIS and AUXTSTRIG before the generic interrupt handler
executes. As a result, auxiliary snapshot events can be missed even
though the hardware has recorded them.

Unlike TSIS and AUXTSTRIG, the ATSNS field remains valid across status
register reads and therefore survives TX timestamp polling. Use this
persistent counter to determine the number of pending auxiliary snapshot
events instead of relying on the transient interrupt status bits.

Implement a dedicated DWXGMAC2 timestamp interrupt handler that reads
XGMAC_TIMESTAMP_STATUS directly, derives the pending snapshot count from
ATSNS, and generates the corresponding PTP_CLOCK_EXTTS events. Also
enable XGMAC timestamp interrupts and hook the new handler into the
DWXGMAC2 hardware timestamp operations.

This avoids the race between TX timestamp polling and auxiliary snapshot
interrupt handling, ensuring that external timestamp events are reported
correctly on DWXGMAC2.

Signed-off-by: Zxyan Zhu <zxyan0222@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h     |  2 +-
 .../net/ethernet/stmicro/stmmac/dwxgmac2_core.c    | 41 +++++++++++++++++++++-
 drivers/net/ethernet/stmicro/stmmac/hwif.c         |  4 +--
 drivers/net/ethernet/stmicro/stmmac/hwif.h         |  1 +
 .../net/ethernet/stmicro/stmmac/stmmac_hwtstamp.c  | 12 +++++++
 drivers/net/ethernet/stmicro/stmmac/stmmac_ptp.h   |  1 +
 6 files changed, 57 insertions(+), 4 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h b/drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h
index 61b6d45a02f5..76e2860a9517 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h
+++ b/drivers/net/ethernet/stmicro/stmmac/dwxgmac2.h
@@ -87,7 +87,7 @@
 #define XGMAC_TSIE			BIT(12)
 #define XGMAC_LPIIE			BIT(5)
 #define XGMAC_PMTIE			BIT(4)
-#define XGMAC_INT_DEFAULT_EN		(XGMAC_LPIIE | XGMAC_PMTIE)
+#define XGMAC_INT_DEFAULT_EN		(XGMAC_LPIIE | XGMAC_PMTIE | XGMAC_TSIE)
 #define XGMAC_Qx_TX_FLOW_CTRL(x)	(0x00000070 + (x) * 4)
 #define XGMAC_PT			GENMASK(31, 16)
 #define XGMAC_TFE			BIT(1)
diff --git a/drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c b/drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c
index f02b434bbd50..daef5225200f 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwxgmac2_core.c
@@ -1150,10 +1150,49 @@ static int dwxgmac2_get_mac_tx_timestamp(struct mac_device_info *hw, u64 *ts)
 		return -EBUSY;
 
 	*ts = readl(ioaddr + XGMAC_TXTIMESTAMP_NSEC) & XGMAC_TXTSSTSLO;
-	*ts += readl(ioaddr + XGMAC_TXTIMESTAMP_SEC) * 1000000000ULL;
+	*ts += (u64)readl(ioaddr + XGMAC_TXTIMESTAMP_SEC) * 1000000000ULL;
 	return 0;
 }
 
+void dwxgmac2_timestamp_interrupt(struct stmmac_priv *priv)
+{
+	u32 ts_status, pending_snapshots, acr_value, channel;
+	struct ptp_clock_event event;
+	unsigned long flags;
+	u64 ptp_time;
+	int i;
+
+	if (!(priv->plat->flags & STMMAC_FLAG_EXT_SNAPSHOT_EN))
+		return;
+
+	/* Read XGMAC_TIMESTAMP_STATUS unconditionally.
+	 * TX timestamp polling also reads this register and clears
+	 * TSIS/AUXTSTRIG, so rely on ATSNS instead.
+	 */
+	ts_status = readl(priv->ioaddr + XGMAC_TIMESTAMP_STATUS);
+
+	pending_snapshots = FIELD_GET(XGMAC_TIMESTAMP_ATSNS_MASK, ts_status);
+	if (!pending_snapshots)
+		return;
+
+	acr_value = readl(priv->ptpaddr + PTP_ACR);
+	channel = FIELD_GET(PTP_ACR_MASK, acr_value);
+	if (!channel)
+		return;
+	channel = ilog2(channel);
+
+	for (i = 0; i < pending_snapshots; i++) {
+		read_lock_irqsave(&priv->ptp_lock, flags);
+		stmmac_get_ptptime(priv, priv->ptpaddr, &ptp_time);
+		read_unlock_irqrestore(&priv->ptp_lock, flags);
+
+		event.type = PTP_CLOCK_EXTTS;
+		event.index = channel;
+		event.timestamp = ptp_time;
+		ptp_clock_event(priv->ptp_clock, &event);
+	}
+}
+
 static int dwxgmac2_flex_pps_config(void __iomem *ioaddr, int index,
 				    struct stmmac_pps_cfg *cfg, bool enable,
 				    u32 sub_second_inc, u32 systime_flags)
diff --git a/drivers/net/ethernet/stmicro/stmmac/hwif.c b/drivers/net/ethernet/stmicro/stmmac/hwif.c
index 511b0fd5e834..9718582b8480 100644
--- a/drivers/net/ethernet/stmicro/stmmac/hwif.c
+++ b/drivers/net/ethernet/stmicro/stmmac/hwif.c
@@ -258,7 +258,7 @@ static const struct stmmac_hwif_entry {
 		.dma = &dwxgmac210_dma_ops,
 		.mac = &dwxgmac210_ops,
 		.vlan = &dwxgmac210_vlan_ops,
-		.hwtimestamp = &stmmac_ptp,
+		.hwtimestamp = &dwxgmac2_ptp,
 		.ptp = &stmmac_ptp_clock_ops,
 		.mode = NULL,
 		.tc = &dwmac510_tc_ops,
@@ -280,7 +280,7 @@ static const struct stmmac_hwif_entry {
 		.dma = &dwxgmac210_dma_ops,
 		.mac = &dwxlgmac2_ops,
 		.vlan = &dwxlgmac2_vlan_ops,
-		.hwtimestamp = &stmmac_ptp,
+		.hwtimestamp = &dwxgmac2_ptp,
 		.ptp = &stmmac_ptp_clock_ops,
 		.mode = NULL,
 		.tc = &dwmac510_tc_ops,
diff --git a/drivers/net/ethernet/stmicro/stmmac/hwif.h b/drivers/net/ethernet/stmicro/stmmac/hwif.h
index e6317b94fff7..818ab3daa91c 100644
--- a/drivers/net/ethernet/stmicro/stmmac/hwif.h
+++ b/drivers/net/ethernet/stmicro/stmmac/hwif.h
@@ -671,6 +671,7 @@ extern const struct stmmac_desc_ops ndesc_ops;
 
 extern const struct stmmac_hwtimestamp stmmac_ptp;
 extern const struct stmmac_hwtimestamp dwmac1000_ptp;
+extern const struct stmmac_hwtimestamp dwxgmac2_ptp;
 
 extern const struct stmmac_mode_ops ring_mode_ops;
 extern const struct stmmac_mode_ops chain_mode_ops;
diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_hwtstamp.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_hwtstamp.c
index b9a985fa772c..9d7d24259abd 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_hwtstamp.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_hwtstamp.c
@@ -277,3 +277,15 @@ const struct stmmac_hwtimestamp dwmac1000_ptp = {
 	.get_ptptime = dwmac1000_get_ptptime,
 	.timestamp_interrupt = dwmac1000_timestamp_interrupt,
 };
+
+const struct stmmac_hwtimestamp dwxgmac2_ptp = {
+	.config_hw_tstamping = config_hw_tstamping,
+	.init_systime = init_systime,
+	.config_sub_second_increment = config_sub_second_increment,
+	.config_addend = config_addend,
+	.adjust_systime = adjust_systime,
+	.get_systime = get_systime,
+	.get_ptptime = get_ptptime,
+	.timestamp_interrupt = dwxgmac2_timestamp_interrupt,
+	.hwtstamp_correct_latency = hwtstamp_correct_latency,
+};
diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_ptp.h b/drivers/net/ethernet/stmicro/stmmac/stmmac_ptp.h
index 3fe0e3a80e80..dade09614163 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_ptp.h
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_ptp.h
@@ -103,6 +103,7 @@ int dwmac1000_ptp_enable(struct ptp_clock_info *ptp,
 
 void dwmac1000_get_ptptime(void __iomem *ptpaddr, u64 *ptp_time);
 void dwmac1000_timestamp_interrupt(struct stmmac_priv *priv);
+void dwxgmac2_timestamp_interrupt(struct stmmac_priv *priv);
 
 extern const struct ptp_clock_info stmmac_ptp_clock_ops;
 extern const struct ptp_clock_info dwmac1000_ptp_clock_ops;

---
base-commit: 1df10cef2d1e7f9f2fb7eddb67fc70d3abf101f9
change-id: 20260806-dwxgmac2-timestamp-irq-bb49d26ee9de

Best regards,
--  
Zxyan Zhu <zxyan0222@gmail.com>

