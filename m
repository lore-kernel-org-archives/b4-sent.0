From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Wed, 08 Jul 2026 10:12:38 -0700
Subject: [PATCH net-next v7 08/15] net: ethernet: oa_tc6: Support for
 hardware timestamp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260708-s2500-mac-phy-support-v7-8-478c877aa1a9@onsemi.com>
References: <20260708-s2500-mac-phy-support-v7-0-478c877aa1a9@onsemi.com>
In-Reply-To: <20260708-s2500-mac-phy-support-v7-0-478c877aa1a9@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783530757; l=27438;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=rQm5iYgd5voZEwI08WChQtW1kiI0kBTzrNvhIx+vMS0=;
 b=HQW5aqB1WQdeGt2mN6KeAhU0z7YWj4/xF5YekFjVONzzuxHUz/Uxn9r/QIlVJtViI3tHFbWfw
 nKOSECll8z+AY0ktVu0LnpRZbXeQGf39yrTpQCGLmybnvdApcsVAiuU
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PTP register/unregister calls are implemented in oa_tc6_ptp.c.
The APIs that work with the hardware for timestamp is provided
by vendor code as it may be vendor dependent.

Interface for ndo_hwtstamp_set/get, ioctl, control and status
callback for ethtool are provided to support hardware timestamp
feature.

Besides ioctl interface, hardware timestamp functions that handles
header and footer data are in oa_tc6.c. Helper functions are in
oa_tc6_tstamp.c.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v7
  - Fixed the parameter name mismatch in function protoype and
    definition
  - CONFIG0 is set with 64 bit timestamp support by default.
  - Added information about return value for API documentation.
changes in v6
  - Fixed the issue of function parameter in oa_tc6_get_ts_stats
    not described in comments section for documentation.
  - Avoided typecasting __be32 as u32
changes in v5
  - As subtracting skb len by FCS size is considered bug, changes
    are removed. Will be fixed in stable branch (net repo)
changes in v4
  - Fixed the condition check for subtracting the FCS size
    from skb len.
changes in v3
  - Replaced warning printk with ratelimited printk
  - Checking the hardware register before enabling hardware
    timestamp
changes in v1
  - Added hardware timestamp support to the OA TC6 framework.
---
 MAINTAINERS                                  |   1 +
 drivers/net/ethernet/oa_tc6/Makefile         |   2 +-
 drivers/net/ethernet/oa_tc6/oa_tc6.c         | 218 +++++++++++++++++++++++++--
 drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c     |  70 +++++++++
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h |  34 +++++
 drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c  | 205 +++++++++++++++++++++++++
 include/linux/oa_tc6.h                       |  12 ++
 7 files changed, 527 insertions(+), 15 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index c9b101d8e1fd..fb19a6431951 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -20216,6 +20216,7 @@ F:	drivers/rtc/rtc-optee.c
 
 OPEN ALLIANCE 10BASE-T1S MACPHY SERIAL INTERFACE FRAMEWORK
 M:	Parthiban Veerasooran <parthiban.veerasooran@microchip.com>
+M:	Selva Rajagopal <selvamani.rajagopal@onsemi.com> (timestamp support)
 L:	netdev@vger.kernel.org
 S:	Maintained
 F:	Documentation/networking/oa-tc6-framework.rst
diff --git a/drivers/net/ethernet/oa_tc6/Makefile b/drivers/net/ethernet/oa_tc6/Makefile
index f24aae852ef2..964f668efc2d 100644
--- a/drivers/net/ethernet/oa_tc6/Makefile
+++ b/drivers/net/ethernet/oa_tc6/Makefile
@@ -4,4 +4,4 @@
 #
 
 obj-$(CONFIG_OA_TC6) := oa_tc6_mod.o
-oa_tc6_mod-objs := oa_tc6.o
+oa_tc6_mod-objs := oa_tc6.o oa_tc6_ptp.o oa_tc6_tstamp.o
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6.c b/drivers/net/ethernet/oa_tc6/oa_tc6.c
index bf96e8d1ccb9..939935cb170d 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6.c
@@ -14,6 +14,15 @@
 
 #include "oa_tc6_std_def.h"
 
+struct oa_tc6_ts_info_rx {
+	bool rtsa;
+	bool rtsp;
+};
+
+struct oa_tc6_ts_info_tx {
+	u8 tsc;
+};
+
 static int oa_tc6_spi_transfer(struct oa_tc6 *tc6,
 			       enum oa_tc6_header_type header_type, u16 length)
 {
@@ -48,6 +57,156 @@ static int oa_tc6_get_parity(u32 p)
 	return !((p >> 28) & 1);
 }
 
+static struct oa_tc6_ts_info_tx *oa_tc6_tsinfo_tx(struct sk_buff *skb)
+{
+	return (struct oa_tc6_ts_info_tx *)(skb->cb);
+}
+
+static struct oa_tc6_ts_info_rx *oa_tc6_tsinfo_rx(struct sk_buff *skb)
+{
+	return (struct oa_tc6_ts_info_rx *)(skb->cb);
+}
+
+static void oa_tc6_defer_for_hwtstamp(struct oa_tc6 *tc6,
+				      struct sk_buff *skb)
+{
+	if (!tc6->hw_tstamp_enabled)
+		return;
+	if (!skb || (skb_shinfo(skb)->tx_flags & SKBTX_HW_TSTAMP) == 0)
+		return;
+	if (tc6->ts_config.tx_type != HWTSTAMP_TX_ON) {
+		tc6->tx_hwtstamp_lost++;
+		return;
+	}
+
+	skb_shinfo(skb)->tx_flags |= SKBTX_IN_PROGRESS;
+	u8 ret = tc6->tx_ts_idx++;
+
+	if (ret == OA_TC6_TTSCC_REG_ID)
+		tc6->tx_ts_idx = OA_TC6_TTSCA_REG_ID;
+	oa_tc6_tsinfo_tx(skb)->tsc = ret;
+
+	list_add_tail(&skb->list, &tc6->tx_ts_skb_q);
+}
+
+static int oa_tc6_process_deferred_skb(struct oa_tc6 *tc6, u8 tsc)
+{
+	struct skb_shared_hwtstamps tstamp;
+	struct oa_tc6_ts_info_tx *ski;
+	struct sk_buff *skb, *tmp;
+	bool found = false;
+	int ret = 0;
+
+	/* Size of data must match OA_TC6_TSTAMP_SZ */
+	u32 data[2];
+
+	list_for_each_entry_safe(skb, tmp, &tc6->tx_ts_skb_q, list) {
+		ski = oa_tc6_tsinfo_tx(skb);
+		if (ski->tsc != tsc)
+			continue;
+		if (found) {
+			dev_warn_ratelimited(&tc6->spi->dev,
+					     "Multiple skbs. tsc = %d\n",
+					     tsc);
+			tc6->tx_hwtstamp_err++;
+		}
+		found = true;
+		list_del(&skb->list);
+
+		/* Retrieve the timestamping info */
+		ret = oa_tc6_read_registers(tc6,
+					    OA_TC6_REG_TTSCA_HIGH +
+					    2 * (tsc - 1), &data[0], 2);
+
+		if (!ret) {
+			tstamp.hwtstamp = ktime_set(data[0], data[1]);
+			skb_tstamp_tx(skb, &tstamp);
+			tc6->tx_hwtstamp_pkts++;
+		}
+
+		dev_kfree_skb(skb);
+	}
+	return ret;
+}
+
+static void oa_tc6_events_handle(struct oa_tc6 *tc6, u32 val)
+{
+	/* Check TX timestamping */
+	if (val & STATUS0_TTSCAA)
+		oa_tc6_process_deferred_skb(tc6, OA_TC6_TTSCA_REG_ID);
+
+	if (val & STATUS0_TTSCAB)
+		oa_tc6_process_deferred_skb(tc6, OA_TC6_TTSCB_REG_ID);
+
+	if (val & STATUS0_TTSCAC)
+		oa_tc6_process_deferred_skb(tc6, OA_TC6_TTSCC_REG_ID);
+}
+
+static void oa_tc6_update_ts_in_rx_skb(struct oa_tc6 *tc6)
+{
+	struct sk_buff *skb = tc6->rx_skb;
+	struct oa_tc6_ts_info_rx *ski;
+	__be32 ts_val[2];
+	u32 ts[2];
+
+	if (!tc6->hw_tstamp_enabled)
+		return;
+	ski = oa_tc6_tsinfo_rx(skb);
+	if (!ski->rtsa)
+		return;
+
+	memcpy(&ts_val[0], skb->data, 4);
+	memcpy(&ts_val[1], (u32 *)skb->data + 1, 4);
+
+	ts[0] = be32_to_cpu(ts_val[0]);
+	ts[1] = be32_to_cpu(ts_val[1]);
+
+	/* Check parity */
+	if ((oa_tc6_get_parity(ts[0]) ^ oa_tc6_get_parity(ts[1])) ==
+	    !ski->rtsp) {
+		struct skb_shared_hwtstamps *hw_ts;
+
+		/* Report timestamp to the upper layers */
+		hw_ts = skb_hwtstamps(skb);
+		memset(hw_ts, 0, sizeof(*hw_ts));
+		hw_ts->hwtstamp = ktime_set(ts[0], ts[1]);
+	}
+	skb_pull(skb, sizeof(ts));
+}
+
+static int oa_tc6_update_standard_capability(struct oa_tc6 *tc6)
+{
+	u32 regval = 0;
+	int ret;
+
+	ret = oa_tc6_read_register(tc6, OA_TC6_REG_STDCAP, &regval);
+	if (ret)
+		return ret;
+	if (regval & STDCAP_FRAME_TIMESTAMP_CAPABILITY)
+		tc6->hw_tstamp_supported = true;
+	return 0;
+}
+
+/**
+ * oa_tc6_ioctl - generic ioctl interface for MAC-PHY drivers.
+ * @tc6: oa_tc6 struct.
+ * @rq: request from socket interface
+ * @cmd: value to set/get timestamp configuration
+ *
+ * Return: 0 on success otherwise failed.
+ */
+int oa_tc6_ioctl(struct oa_tc6 *tc6, struct ifreq *rq, int cmd)
+{
+	if (!netif_running(tc6->netdev))
+		return -EINVAL;
+
+	if (cmd == SIOCSHWTSTAMP || cmd == SIOCGHWTSTAMP)
+		return oa_tc6_tstamp_ioctl(tc6, rq, cmd);
+	else
+		return phy_do_ioctl_running(tc6->netdev, rq, cmd);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_ioctl);
+
 static __be32 oa_tc6_prepare_ctrl_header(u32 addr, u8 length,
 					 enum oa_tc6_register_op reg_op)
 {
@@ -571,6 +730,9 @@ static int oa_tc6_process_extended_status(struct oa_tc6 *tc6)
 		return ret;
 	}
 
+	if ((value & STATUS0_TTSCA_MASK) != 0)
+		oa_tc6_events_handle(tc6, value & STATUS0_TTSCA_MASK);
+
 	/* Clear the error interrupts status */
 	ret = oa_tc6_write_register(tc6, OA_TC6_REG_STATUS0, value);
 	if (ret) {
@@ -653,6 +815,7 @@ static void oa_tc6_submit_rx_skb(struct oa_tc6 *tc6)
 	    tc6->rx_skb->len > ETH_FCS_LEN)
 		skb_trim(tc6->rx_skb, tc6->rx_skb->len - ETH_FCS_LEN);
 
+	oa_tc6_update_ts_in_rx_skb(tc6);
 	tc6->rx_skb->protocol = eth_type_trans(tc6->rx_skb, tc6->netdev);
 	tc6->netdev->stats.rx_packets++;
 	tc6->netdev->stats.rx_bytes += tc6->rx_skb->len;
@@ -667,24 +830,29 @@ static void oa_tc6_update_rx_skb(struct oa_tc6 *tc6, u8 *payload, u8 length)
 	memcpy(skb_put(tc6->rx_skb, length), payload, length);
 }
 
-static int oa_tc6_allocate_rx_skb(struct oa_tc6 *tc6)
+static int oa_tc6_allocate_rx_skb(struct oa_tc6 *tc6, u32 footer)
 {
+	struct oa_tc6_ts_info_rx *ski;
+
 	tc6->rx_skb = netdev_alloc_skb_ip_align(tc6->netdev, tc6->netdev->mtu +
-						ETH_HLEN + ETH_FCS_LEN);
+						ETH_HLEN + ETH_FCS_LEN + OA_TC6_TSTAMP_SZ);
 	if (!tc6->rx_skb) {
 		tc6->netdev->stats.rx_dropped++;
 		return -ENOMEM;
 	}
 
+	ski = oa_tc6_tsinfo_rx(tc6->rx_skb);
+	ski->rtsa = FIELD_GET(OA_TC6_DATA_FOOTER_RTSA_VALID, footer);
+	ski->rtsp = FIELD_GET(OA_TC6_DATA_FOOTER_RTSP_VALID, footer);
 	return 0;
 }
 
 static int oa_tc6_prcs_complete_rx_frame(struct oa_tc6 *tc6, u8 *payload,
-					 u16 size)
+					 u16 size, u32 footer)
 {
 	int ret;
 
-	ret = oa_tc6_allocate_rx_skb(tc6);
+	ret = oa_tc6_allocate_rx_skb(tc6, footer);
 	if (ret)
 		return ret;
 
@@ -695,11 +863,11 @@ static int oa_tc6_prcs_complete_rx_frame(struct oa_tc6 *tc6, u8 *payload,
 	return 0;
 }
 
-static int oa_tc6_prcs_rx_frame_start(struct oa_tc6 *tc6, u8 *payload, u16 size)
+static int oa_tc6_prcs_rx_frame_start(struct oa_tc6 *tc6, u8 *payload, u16 size, u32 footer)
 {
 	int ret;
 
-	ret = oa_tc6_allocate_rx_skb(tc6);
+	ret = oa_tc6_allocate_rx_skb(tc6, footer);
 	if (ret)
 		return ret;
 
@@ -744,7 +912,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 		size = end_byte_offset + 1 - start_byte_offset;
 		return oa_tc6_prcs_complete_rx_frame(tc6,
 						     &data[start_byte_offset],
-						     size);
+						     size, footer);
 	}
 
 	/* Process the chunk with only rx frame start */
@@ -752,7 +920,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 		size = OA_TC6_CHUNK_PAYLOAD_SIZE - start_byte_offset;
 		return oa_tc6_prcs_rx_frame_start(tc6,
 						  &data[start_byte_offset],
-						  size);
+						  size, footer);
 	}
 
 	/* Process the chunk with only rx frame end */
@@ -777,7 +945,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 		size = OA_TC6_CHUNK_PAYLOAD_SIZE - start_byte_offset;
 		return oa_tc6_prcs_rx_frame_start(tc6,
 						  &data[start_byte_offset],
-						  size);
+						  size, footer);
 	}
 
 	/* Process the chunk with ongoing rx frame data */
@@ -831,13 +999,15 @@ static int oa_tc6_process_spi_data_rx_buf(struct oa_tc6 *tc6, u16 length)
 }
 
 static __be32 oa_tc6_prepare_data_header(bool data_valid, bool start_valid,
-					 bool end_valid, u8 end_byte_offset)
+					 bool end_valid, u8 end_byte_offset,
+					 u8 tsc)
 {
 	u32 header = FIELD_PREP(OA_TC6_DATA_HEADER_DATA_NOT_CTRL,
 				OA_TC6_DATA_HEADER) |
 		     FIELD_PREP(OA_TC6_DATA_HEADER_DATA_VALID, data_valid) |
 		     FIELD_PREP(OA_TC6_DATA_HEADER_START_VALID, start_valid) |
 		     FIELD_PREP(OA_TC6_DATA_HEADER_END_VALID, end_valid) |
+		     FIELD_PREP(OA_TC6_DATA_HEADER_TSC_OFFSET, tsc) |
 		     FIELD_PREP(OA_TC6_DATA_HEADER_END_BYTE_OFFSET,
 				end_byte_offset);
 
@@ -856,6 +1026,7 @@ static void oa_tc6_add_tx_skb_to_spi_buf(struct oa_tc6 *tc6)
 	enum oa_tc6_data_start_valid_info start_valid;
 	u8 end_byte_offset = 0;
 	u16 length_to_copy;
+	u8 tsc = 0;
 
 	/* Initial value is assigned here to avoid more than 80 characters in
 	 * the declaration place.
@@ -865,8 +1036,10 @@ static void oa_tc6_add_tx_skb_to_spi_buf(struct oa_tc6 *tc6)
 	/* Set start valid if the current tx chunk contains the start of the tx
 	 * ethernet frame.
 	 */
-	if (!tc6->tx_skb_offset)
+	if (!tc6->tx_skb_offset) {
 		start_valid = OA_TC6_DATA_START_VALID;
+		tsc = oa_tc6_tsinfo_tx(tc6->ongoing_tx_skb)->tsc;
+	}
 
 	/* If the remaining tx skb length is more than the chunk payload size of
 	 * 64 bytes then copy only 64 bytes and leave the ongoing tx skb for
@@ -887,12 +1060,18 @@ static void oa_tc6_add_tx_skb_to_spi_buf(struct oa_tc6 *tc6)
 		tc6->tx_skb_offset = 0;
 		tc6->netdev->stats.tx_bytes += tc6->ongoing_tx_skb->len;
 		tc6->netdev->stats.tx_packets++;
-		kfree_skb(tc6->ongoing_tx_skb);
+
+		/* Free the ones that are not saved for later processing,
+		 * like timestamping.
+		 */
+		if (!(skb_shinfo(tc6->ongoing_tx_skb)->tx_flags &
+		    SKBTX_IN_PROGRESS))
+			kfree_skb(tc6->ongoing_tx_skb);
 		tc6->ongoing_tx_skb = NULL;
 	}
 
 	*tx_buf = oa_tc6_prepare_data_header(OA_TC6_DATA_VALID, start_valid,
-					     end_valid, end_byte_offset);
+					     end_valid, end_byte_offset, tsc);
 	tc6->spi_data_tx_buf_offset += OA_TC6_CHUNK_SIZE;
 }
 
@@ -910,6 +1089,8 @@ static u16 oa_tc6_prepare_spi_tx_buf_for_tx_skbs(struct oa_tc6 *tc6)
 			tc6->ongoing_tx_skb = tc6->waiting_tx_skb;
 			tc6->waiting_tx_skb = NULL;
 			spin_unlock_bh(&tc6->tx_skb_lock);
+			oa_tc6_defer_for_hwtstamp(tc6,
+						  tc6->ongoing_tx_skb);
 		}
 		if (!tc6->ongoing_tx_skb)
 			break;
@@ -926,7 +1107,7 @@ static void oa_tc6_add_empty_chunks_to_spi_buf(struct oa_tc6 *tc6,
 
 	header = oa_tc6_prepare_data_header(OA_TC6_DATA_INVALID,
 					    OA_TC6_DATA_START_INVALID,
-					    OA_TC6_DATA_END_INVALID, 0);
+					    OA_TC6_DATA_END_INVALID, 0, false);
 
 	while (needed_empty_chunks--) {
 		__be32 *tx_buf = tc6->spi_data_tx_buf +
@@ -1118,6 +1299,7 @@ netdev_tx_t oa_tc6_start_xmit(struct oa_tc6 *tc6, struct sk_buff *skb)
 		return NETDEV_TX_OK;
 	}
 
+	oa_tc6_tsinfo_tx(skb)->tsc = 0;
 	spin_lock_bh(&tc6->tx_skb_lock);
 	tc6->waiting_tx_skb = skb;
 	spin_unlock_bh(&tc6->tx_skb_lock);
@@ -1151,6 +1333,8 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev)
 	SET_NETDEV_DEV(netdev, &spi->dev);
 	mutex_init(&tc6->spi_ctrl_lock);
 	spin_lock_init(&tc6->tx_skb_lock);
+	tc6->tx_ts_idx = OA_TC6_TTSCA_REG_ID;
+	INIT_LIST_HEAD(&tc6->tx_ts_skb_q);
 
 	/* Set the SPI controller to pump at realtime priority */
 	tc6->spi->rt = true;
@@ -1216,6 +1400,12 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev)
 		goto phy_exit;
 	}
 
+	ret = oa_tc6_update_standard_capability(tc6);
+	if (ret) {
+		dev_err(&tc6->spi->dev, "Failed to read capability\n");
+		goto phy_exit;
+	}
+
 	ret = devm_request_threaded_irq(&tc6->spi->dev, tc6->spi->irq,
 					oa_tc6_macphy_isr,
 					oa_tc6_macphy_threaded_irq,
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c b/drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c
new file mode 100644
index 000000000000..0cde5545ee27
--- /dev/null
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c
@@ -0,0 +1,70 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Support for hardware timestamping feature for OPEN Alliance
+ * 10BASE‑T1x MAC‑PHY Serial Interface framework
+ *
+ * Author: Selva Rajagopal <selvamani.rajagopal@onsemi.com>
+ */
+
+#include <linux/hrtimer.h>
+#include <linux/irq.h>
+#include <linux/irqdomain.h>
+#include <linux/kernel.h>
+#include <linux/netdevice.h>
+#include <linux/phylink.h>
+#include <linux/spi/spi.h>
+#include <linux/oa_tc6.h>
+#include <linux/net_tstamp.h>
+#include <linux/ptp_clock_kernel.h>
+#include <linux/delay.h>
+#include <linux/mutex.h>
+#include <linux/ktime.h>
+#include <linux/errno.h>
+
+#include "oa_tc6_std_def.h"
+
+/**
+ * oa_tc6_ptp_register - Registers clock related callbacks
+ * @tc6: oa_tc6 struct.
+ * @info: Describes a PTP hardware clock
+ *
+ * Description: Vendors are expected to set the hardware timestamp
+ * related callbacks before calling this function.
+ *
+ * Return: 0 on success otherwise failed.
+ *
+ */
+int oa_tc6_ptp_register(struct oa_tc6 *tc6, struct ptp_clock_info *info)
+{
+	/* Not supporting hardware timestamp isn't an error */
+	if (!tc6->hw_tstamp_supported)
+		return 0;
+
+	snprintf(info->name, sizeof(info->name), "%s",
+		 "OA TC6 PTP clock");
+	tc6->ptp_clock = ptp_clock_register(info, &tc6->spi->dev);
+	if (IS_ERR(tc6->ptp_clock)) {
+		dev_err(&tc6->spi->dev, "Registration of %s failed",
+			info->name);
+		return -EFAULT;
+	}
+	dev_info(&tc6->spi->dev, "%s registered. index %d", info->name,
+		 ptp_clock_index(tc6->ptp_clock));
+	return 0;
+}
+EXPORT_SYMBOL_GPL(oa_tc6_ptp_register);
+
+/**
+ * oa_tc6_ptp_unregister - Unregisters clock related callbacks
+ * @tc6: oa_tc6 struct.
+ */
+void oa_tc6_ptp_unregister(struct oa_tc6 *tc6)
+{
+	if (tc6->ptp_clock)
+		ptp_clock_unregister(tc6->ptp_clock);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_ptp_unregister);
+
+MODULE_DESCRIPTION("OPEN Alliance 10BASE‑T1x MAC‑PHY Serial Interface Lib");
+MODULE_AUTHOR("Selva Rajagopal <selvamani.rajagopal@onsemi.com>");
+MODULE_LICENSE("GPL");
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
index 6bacf254a36a..3781503be7f5 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
@@ -22,6 +22,7 @@
 /* Standard Capabilities Register */
 #define OA_TC6_REG_STDCAP			0x0002
 #define STDCAP_DIRECT_PHY_REG_ACCESS		BIT(8)
+#define STDCAP_FRAME_TIMESTAMP_CAPABILITY	BIT(6)
 
 /* Reset Control and Status Register */
 #define OA_TC6_REG_RESET			0x0003
@@ -31,9 +32,15 @@
 #define OA_TC6_REG_CONFIG0			0x0004
 #define CONFIG0_SYNC				BIT(15)
 #define CONFIG0_ZARFE_ENABLE			BIT(12)
+#define CONFIG0_FTSE_ENABLE			BIT(7)
+#define CONFIG0_FTSS_64BIT_TSTAMP		BIT(6)
 
 /* Status Register #0 */
 #define OA_TC6_REG_STATUS0			0x0008
+#define STATUS0_TTSCAC				BIT(10)
+#define STATUS0_TTSCAB				BIT(9)
+#define STATUS0_TTSCAA				BIT(8)
+#define STATUS0_TTSCA_MASK		GENMASK(10, 8)
 #define STATUS0_RESETC				BIT(6)
 #define STATUS0_HEADER_ERROR			BIT(5)
 #define STATUS0_LOSS_OF_FRAME_ERROR		BIT(4)
@@ -47,6 +54,7 @@
 
 /* Interrupt Mask Register #0 */
 #define OA_TC6_REG_INT_MASK0			0x000C
+#define INT_MASK0_TTSCA_MASK			GENMASK(10, 8)
 #define INT_MASK0_HEADER_ERR_MASK		BIT(5)
 #define INT_MASK0_LOSS_OF_FRAME_ERR_MASK	BIT(4)
 #define INT_MASK0_RX_BUFFER_OVERFLOW_ERR_MASK	BIT(3)
@@ -58,6 +66,9 @@
 #define OA_TC6_PHY_STD_REG_ADDR_BASE		0xFF00
 #define OA_TC6_PHY_STD_REG_ADDR_MASK		0x1F
 
+/* Tx timestamp capture register A (high) */
+#define OA_TC6_REG_TTSCA_HIGH			(0x10)
+
 /* Control command header */
 #define OA_TC6_CTRL_HEADER_DATA_NOT_CTRL	BIT(31)
 #define OA_TC6_CTRL_HEADER_WRITE_NOT_READ	BIT(29)
@@ -73,6 +84,7 @@
 #define OA_TC6_DATA_HEADER_START_WORD_OFFSET	GENMASK(19, 16)
 #define OA_TC6_DATA_HEADER_END_VALID		BIT(14)
 #define OA_TC6_DATA_HEADER_END_BYTE_OFFSET	GENMASK(13, 8)
+#define OA_TC6_DATA_HEADER_TSC_OFFSET		GENMASK(7, 6)
 #define OA_TC6_DATA_HEADER_PARITY		BIT(0)
 
 /* Data footer */
@@ -84,6 +96,8 @@
 #define OA_TC6_DATA_FOOTER_START_VALID		BIT(20)
 #define OA_TC6_DATA_FOOTER_START_WORD_OFFSET	GENMASK(19, 16)
 #define OA_TC6_DATA_FOOTER_END_VALID		BIT(14)
+#define OA_TC6_DATA_FOOTER_RTSA_VALID		BIT(7)
+#define OA_TC6_DATA_FOOTER_RTSP_VALID		BIT(6)
 #define OA_TC6_DATA_FOOTER_END_BYTE_OFFSET	GENMASK(13, 8)
 #define OA_TC6_DATA_FOOTER_TX_CREDITS		GENMASK(5, 1)
 
@@ -105,6 +119,12 @@
 #define STATUS0_RESETC_POLL_DELAY		1000
 #define STATUS0_RESETC_POLL_TIMEOUT		1000000
 
+#define OA_TC6_TSTAMP_SZ			8
+
+#define OA_TC6_TTSCA_REG_ID			1
+#define OA_TC6_TTSCB_REG_ID			2
+#define OA_TC6_TTSCC_REG_ID			3
+
 /* Internal structure for MAC-PHY drivers */
 struct oa_tc6 {
 	struct net_device *netdev;
@@ -127,6 +147,17 @@ struct oa_tc6 {
 	bool rx_buf_overflow;
 	bool int_flag;
 	bool disable_traffic;
+	struct ptp_clock_info ptp_clock_info;
+	struct hwtstamp_config ts_config;
+	struct list_head tx_ts_skb_q;
+	struct ptp_clock *ptp_clock;
+	bool hw_tstamp_supported;
+	bool hw_tstamp_enabled;
+	u32 tx_hwtstamp_pkts;
+	u32 tx_hwtstamp_lost;
+	u32 tx_hwtstamp_err;
+	int vend1_mms;
+	u8 tx_ts_idx;
 };
 
 enum oa_tc6_header_type {
@@ -153,5 +184,8 @@ enum oa_tc6_data_end_valid_info {
 	OA_TC6_DATA_END_INVALID,
 	OA_TC6_DATA_END_VALID,
 };
+
+int oa_tc6_tstamp_ioctl(struct oa_tc6 *tc6, struct ifreq *rq, int cmd);
+
 #endif /* OA_TC6_STD_DEF_H */
 
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c b/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c
new file mode 100644
index 000000000000..f80f1a4916a3
--- /dev/null
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c
@@ -0,0 +1,205 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * OPEN Alliance 10BASE‑T1x MAC‑PHY Serial Interface framework
+ *
+ * Author: Selva Rajagopal <selvamani.rajagopal@onsemi.com>
+ */
+
+#include <linux/bitfield.h>
+#include <linux/iopoll.h>
+#include <linux/mdio.h>
+#include <linux/phy.h>
+#include <linux/oa_tc6.h>
+
+#include "oa_tc6_std_def.h"
+
+static int oa_tc6_set_hwtstamp_settings(struct oa_tc6 *tc6)
+{
+	u32 cfg0, irqm, status0;
+	int ret;
+
+	ret = oa_tc6_read_register(tc6, OA_TC6_REG_CONFIG0, &cfg0);
+	if (ret) {
+		dev_err(&tc6->spi->dev, "Failed to read CFG0 register\n");
+		goto out;
+	}
+
+	ret = oa_tc6_read_register(tc6, OA_TC6_REG_INT_MASK0, &irqm);
+	if (ret) {
+		dev_err(&tc6->spi->dev, "failed to read IRQM register\n");
+		goto out;
+	}
+
+	/* Hardware timestamp feature supports 64-bit timestamp only */
+	if (tc6->ts_config.tx_type == HWTSTAMP_TX_ON ||
+	    tc6->ts_config.rx_filter == HWTSTAMP_FILTER_ALL)
+		cfg0 |= (CONFIG0_FTSE_ENABLE |
+			 CONFIG0_FTSS_64BIT_TSTAMP);
+	else
+		cfg0 &= ~CONFIG0_FTSE_ENABLE;
+
+	if (tc6->ts_config.tx_type == HWTSTAMP_TX_ON)
+		irqm &= ~INT_MASK0_TTSCA_MASK;
+	else
+		irqm |= INT_MASK0_TTSCA_MASK;
+
+	/* Clear timestamp related IRQs */
+	status0 = STATUS0_TTSCA_MASK;
+	ret = oa_tc6_write_register(tc6, OA_TC6_REG_STATUS0, status0);
+	if (ret) {
+		dev_err(&tc6->spi->dev, "failed to write STATUS0 register\n");
+		goto out;
+	}
+
+	ret = oa_tc6_write_register(tc6, OA_TC6_REG_INT_MASK0, irqm);
+	if (ret) {
+		dev_err(&tc6->spi->dev, "failed to write IRQM register\n");
+		goto out;
+	}
+
+	ret = oa_tc6_write_register(tc6, OA_TC6_REG_CONFIG0, cfg0);
+	if (ret) {
+		dev_err(&tc6->spi->dev, "failed to write CFG0 register\n");
+		goto out;
+	}
+	if (cfg0 & CONFIG0_FTSE_ENABLE)
+		tc6->hw_tstamp_enabled = true;
+	else
+		tc6->hw_tstamp_enabled = false;
+out:
+	return ret;
+}
+
+/**
+ * oa_tc6_hwtstamp_get - gets hardware timestamp config
+ * @tc6: oa_tc6 struct.
+ * @cfg: kernel copy of hardware timestamp config
+ */
+void oa_tc6_hwtstamp_get(struct oa_tc6 *tc6,
+			 struct kernel_hwtstamp_config *cfg)
+{
+	hwtstamp_config_to_kernel(cfg, &tc6->ts_config);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_hwtstamp_get);
+
+/**
+ * oa_tc6_hwtstamp_set - sets hardware timestamp config
+ * @tc6: oa_tc6 struct.
+ * @cfg: kernel copy of hardware timestamp config
+ *
+ * Return: 0 on success otherwise failed.
+ */
+int oa_tc6_hwtstamp_set(struct oa_tc6 *tc6,
+			struct kernel_hwtstamp_config *cfg)
+{
+	if (!netif_running(tc6->netdev))
+		return -EIO;
+
+	if (!tc6->hw_tstamp_supported)
+		return -EOPNOTSUPP;
+
+	switch (cfg->tx_type) {
+	case HWTSTAMP_TX_OFF:
+	case HWTSTAMP_TX_ON:
+		break;
+	default:
+		return -ERANGE;
+	}
+
+	switch (cfg->rx_filter) {
+	case HWTSTAMP_FILTER_NONE:
+	case HWTSTAMP_FILTER_ALL:
+	case HWTSTAMP_FILTER_SOME:
+	case HWTSTAMP_FILTER_PTP_V1_L4_EVENT:
+	case HWTSTAMP_FILTER_PTP_V1_L4_SYNC:
+	case HWTSTAMP_FILTER_PTP_V1_L4_DELAY_REQ:
+	case HWTSTAMP_FILTER_PTP_V2_L4_EVENT:
+	case HWTSTAMP_FILTER_PTP_V2_L4_SYNC:
+	case HWTSTAMP_FILTER_PTP_V2_L4_DELAY_REQ:
+	case HWTSTAMP_FILTER_PTP_V2_L2_EVENT:
+	case HWTSTAMP_FILTER_PTP_V2_L2_SYNC:
+	case HWTSTAMP_FILTER_PTP_V2_L2_DELAY_REQ:
+	case HWTSTAMP_FILTER_PTP_V2_EVENT:
+	case HWTSTAMP_FILTER_PTP_V2_SYNC:
+	case HWTSTAMP_FILTER_PTP_V2_DELAY_REQ:
+	case HWTSTAMP_FILTER_NTP_ALL:
+		break;
+	default:
+		return -ERANGE;
+	}
+	hwtstamp_config_from_kernel(&tc6->ts_config, cfg);
+
+	/* Supports timestamping all traffic */
+	if (cfg->rx_filter != HWTSTAMP_FILTER_NONE)
+		tc6->ts_config.rx_filter = HWTSTAMP_FILTER_ALL;
+	return oa_tc6_set_hwtstamp_settings(tc6);
+}
+EXPORT_SYMBOL_GPL(oa_tc6_hwtstamp_set);
+
+/**
+ * oa_tc6_get_ts_stats - Provides timestamping stats
+ * @tc6: oa_tc6 struct.
+ * @stats: ethtool data structure to fill in
+ */
+void oa_tc6_get_ts_stats(struct oa_tc6 *tc6,
+			 struct ethtool_ts_stats *stats)
+{
+	stats->pkts = tc6->tx_hwtstamp_pkts;
+	stats->err = tc6->tx_hwtstamp_err;
+	stats->lost = tc6->tx_hwtstamp_lost;
+}
+EXPORT_SYMBOL_GPL(oa_tc6_get_ts_stats);
+
+int oa_tc6_tstamp_ioctl(struct oa_tc6 *tc6, struct ifreq *rq, int cmd)
+{
+	struct kernel_hwtstamp_config kcfg;
+	struct hwtstamp_config tscfg;
+	int ret = 0;
+
+	if (!tc6->hw_tstamp_supported)
+		return -EOPNOTSUPP;
+
+	if (cmd == SIOCSHWTSTAMP) {
+		if (copy_from_user(&tscfg, rq->ifr_data,
+				   sizeof(tscfg)))
+			return -EFAULT;
+
+		if (tscfg.flags)
+			return -EINVAL;
+		hwtstamp_config_to_kernel(&kcfg, &tscfg);
+		ret = oa_tc6_hwtstamp_set(tc6, &kcfg);
+		if (ret)
+			return ret;
+	}
+	if (copy_to_user(rq->ifr_data, &tc6->ts_config,
+			 sizeof(tc6->ts_config)))
+		ret = -EFAULT;
+	return ret;
+}
+
+/**
+ * oa_tc6_get_ts_info - Provides timestamp info for ethtool
+ * @tc6: oa_tc6 struct.
+ * @info: ethtool timestamping info structure
+ *
+ * Return: 0 on success otherwise failed.
+ */
+int oa_tc6_get_ts_info(struct oa_tc6 *tc6,
+		       struct kernel_ethtool_ts_info *info)
+{
+	if (!tc6->ptp_clock)
+		return ethtool_op_get_ts_info(tc6->netdev, info);
+
+	info->so_timestamping = SOF_TIMESTAMPING_RAW_HARDWARE |
+				SOF_TIMESTAMPING_TX_HARDWARE |
+				SOF_TIMESTAMPING_RX_HARDWARE;
+	info->phc_index = ptp_clock_index(tc6->ptp_clock);
+	info->tx_types = BIT(HWTSTAMP_TX_ON);
+	info->rx_filters = BIT(HWTSTAMP_FILTER_ALL);
+	return 0;
+}
+EXPORT_SYMBOL_GPL(oa_tc6_get_ts_info);
+
+MODULE_DESCRIPTION("OPEN Alliance 10BASE‑T1x MAC‑PHY Serial Interface Lib");
+MODULE_AUTHOR("Selva Rajagopal <selvamani.rajagopal@onsemi.com>");
+MODULE_LICENSE("GPL");
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 39b80033dfa9..e678a12aedf1 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -12,6 +12,7 @@
 
 #include <linux/etherdevice.h>
 #include <linux/spi/spi.h>
+#include <linux/ptp_clock_kernel.h>
 
 /* PHY – Clause 45 registers memory map selector (MMS) as per table 6 in
  * the OPEN Alliance specification.
@@ -36,4 +37,15 @@ int oa_tc6_read_registers(struct oa_tc6 *tc6, u32 address, u32 value[],
 			  u8 length);
 netdev_tx_t oa_tc6_start_xmit(struct oa_tc6 *tc6, struct sk_buff *skb);
 int oa_tc6_zero_align_receive_frame_enable(struct oa_tc6 *tc6);
+int oa_tc6_ptp_register(struct oa_tc6 *tc6, struct ptp_clock_info *info);
+int oa_tc6_ioctl(struct oa_tc6 *tc6, struct ifreq *rq, int cmd);
+int oa_tc6_get_ts_info(struct oa_tc6 *tc6,
+		       struct kernel_ethtool_ts_info *info);
+void oa_tc6_hwtstamp_get(struct oa_tc6 *tc6,
+			 struct kernel_hwtstamp_config *cfg);
+void oa_tc6_get_ts_stats(struct oa_tc6 *tc6,
+			 struct ethtool_ts_stats *stats);
+int oa_tc6_hwtstamp_set(struct oa_tc6 *tc6,
+			struct kernel_hwtstamp_config *cfg);
+void oa_tc6_ptp_unregister(struct oa_tc6 *tc6);
 #endif /* _LINUX_OA_TC6_H */

-- 
2.43.0

