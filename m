From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 06 Nov 2026 15:18:51 -0800
Subject: [PATCH net-next v10 05/11] net: ethernet: oa_tc6: Support for
 hardware timestamp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261106-s2500-mac-phy-support-v10-5-31b5a69b85b7@onsemi.com>
References: <20261106-s2500-mac-phy-support-v10-0-31b5a69b85b7@onsemi.com>
In-Reply-To: <20261106-s2500-mac-phy-support-v10-0-31b5a69b85b7@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794007133; l=37015;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=dSkx3HsmmcAb9555C7YqItkzStBydw+OrfTOXC4SU5w=;
 b=agQA2aV+bO5PvnnosMAjYkz2MmPoWANeZl+GtLQTDLCJKTVGEvL5QfGGpMnjcxf/N6I0MAJ3G
 ADk3GcJasmjDvRqqOnhdqSAOYJEl6aJvZTwpAzASuwvWRjREoAo/xfr
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PTP register/unregister calls are implemented in oa_tc6_ptp.c.
The APIs that work with the hardware for timestamp is provided
by vendor code as it may be vendor dependent.

Interface for ndo_hwtstamp_set/get, control and status
callback for ethtool are provided to support hardware timestamp
feature. ioctl interface passes the request to PHY.

Hardware timestamp functions that handle the traffic are generally
placed in oa_tc6.c. Rest of the timestamp functionalities, mostly
helper functions are in oa_tc6_tstamp.c.

When all the three timestamp capture registers are busy and not
available, driver drops the incoming TX SKB, if it comes with the
request for hardware timestamping. Normal traffic without timestamp
request is not affected.

Practically, application using hardware timestamp is not expected to
hit this scenario as three timestamp capture registers are plenty
considering the amount of traffic expected in such applications.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v10
   - Added protection to skb queue handling when timestamp
     feature is enabled/disabled.
changes in v9
  - Moved the vend1_mms initialization to the correct patch
  - Fixed the confusing goto statements to return true or false
  - Changed the magic number offset to index into array to names.
  - Checking valid tsc instead of relying on SKBTX_IN_PROGRESS
    as life of this flag may not be 100% internal to the driver
changes in v8
  - Moved few timestamp defintions to header file from source file.
  - Improved logic in handling timestamp capture register events.
  - timestamp skb queue is protected inside spinlock
  - Removed unnecessary ioctl callback
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
 MAINTAINERS                                    |   1 +
 drivers/net/ethernet/adi/Kconfig               |   1 +
 drivers/net/ethernet/microchip/lan865x/Kconfig |   1 +
 drivers/net/ethernet/oa_tc6/Kconfig            |   1 +
 drivers/net/ethernet/oa_tc6/Makefile           |   2 +-
 drivers/net/ethernet/oa_tc6/oa_tc6_main.c      | 328 +++++++++++++++++++++++--
 drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c       |  65 +++++
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h   |  47 ++++
 drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c    | 224 +++++++++++++++++
 include/linux/oa_tc6.h                         |  23 ++
 10 files changed, 676 insertions(+), 17 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 7cf0e33a8be9..5661d164c03b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -21026,6 +21026,7 @@ F:	drivers/rtc/rtc-optee.c
 
 OPEN ALLIANCE 10BASE-T1S MACPHY SERIAL INTERFACE FRAMEWORK
 M:	Parthiban Veerasooran <parthiban.veerasooran@microchip.com>
+M:	Selva Rajagopal <selvamani.rajagopal@onsemi.com> (timestamp support)
 L:	netdev@vger.kernel.org
 S:	Maintained
 F:	Documentation/networking/oa-tc6-framework.rst
diff --git a/drivers/net/ethernet/adi/Kconfig b/drivers/net/ethernet/adi/Kconfig
index bdb8ff7d15da..120a52e6b283 100644
--- a/drivers/net/ethernet/adi/Kconfig
+++ b/drivers/net/ethernet/adi/Kconfig
@@ -29,6 +29,7 @@ config ADIN1110
 config ADIN1140
 	tristate "Analog Devices ADIN1140 MAC-PHY"
 	depends on SPI
+	depends on PTP_1588_CLOCK_OPTIONAL
 	select ADIN1140_PHY
 	select OA_TC6
 	help
diff --git a/drivers/net/ethernet/microchip/lan865x/Kconfig b/drivers/net/ethernet/microchip/lan865x/Kconfig
index 7f2a4e7e1915..342172cb8837 100644
--- a/drivers/net/ethernet/microchip/lan865x/Kconfig
+++ b/drivers/net/ethernet/microchip/lan865x/Kconfig
@@ -8,6 +8,7 @@ if NET_VENDOR_MICROCHIP
 config LAN865X
 	tristate "LAN865x support"
 	depends on SPI
+	depends on PTP_1588_CLOCK_OPTIONAL
 	select OA_TC6
 	help
 	  Support for the Microchip LAN8650/1 Rev.B0/B1 MACPHY Ethernet chip. It
diff --git a/drivers/net/ethernet/oa_tc6/Kconfig b/drivers/net/ethernet/oa_tc6/Kconfig
index 657567276030..2c8c881d5b99 100644
--- a/drivers/net/ethernet/oa_tc6/Kconfig
+++ b/drivers/net/ethernet/oa_tc6/Kconfig
@@ -6,6 +6,7 @@
 config OA_TC6
 	tristate "OPEN Alliance TC6 10BASE-T1x MAC-PHY support" if COMPILE_TEST
 	depends on SPI
+	depends on PTP_1588_CLOCK_OPTIONAL
 	select PHYLIB
 	help
 	  This library implements OPEN Alliance TC6 10BASE-T1x MAC-PHY
diff --git a/drivers/net/ethernet/oa_tc6/Makefile b/drivers/net/ethernet/oa_tc6/Makefile
index c51621fae8be..a645584bdca0 100644
--- a/drivers/net/ethernet/oa_tc6/Makefile
+++ b/drivers/net/ethernet/oa_tc6/Makefile
@@ -4,4 +4,4 @@
 #
 
 obj-$(CONFIG_OA_TC6) += oa_tc6.o
-oa_tc6-objs := oa_tc6_main.o
+oa_tc6-objs := oa_tc6_main.o oa_tc6_ptp.o oa_tc6_tstamp.o
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_main.c b/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
index 45eb896cd986..e793d7fb0635 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_main.c
@@ -8,6 +8,7 @@
 #include <linux/bitfield.h>
 #include <linux/delay.h>
 #include <linux/gpio/consumer.h>
+#include <linux/bitops.h>
 #include <linux/iopoll.h>
 #include <linux/interrupt.h>
 #include <linux/mdio.h>
@@ -15,6 +16,16 @@
 
 #include "oa_tc6_std_def.h"
 
+struct oa_tc6_ts_info_rx {
+	bool rtsa;
+	bool rtsp;
+};
+
+struct oa_tc6_ts_info_tx {
+	ktime_t hwtstamp;
+	u8 tsc;
+};
+
 static int oa_tc6_spi_transfer(struct oa_tc6 *tc6,
 			       enum oa_tc6_header_type header_type, u16 length)
 {
@@ -49,6 +60,212 @@ static int oa_tc6_get_parity(u32 p)
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
+static u8 oa_tc6_next_tsc(u8 tsc)
+{
+	return tsc < OA_TC6_TTSCC_REG_ID ? tsc + 1 : OA_TC6_TTSCA_REG_ID;
+}
+
+static bool oa_tc6_req_tx_hwtstamp(struct oa_tc6 *tc6, struct sk_buff *skb)
+{
+	u8 tsc;
+	u8 i;
+
+	lockdep_assert_held(&tc6->tx_skb_lock);
+
+	if (!skb || !(skb_shinfo(skb)->tx_flags & SKBTX_HW_TSTAMP))
+		return false;
+
+	if (!tc6->hw_tstamp_enabled ||
+	    tc6->ts_config.tx_type != HWTSTAMP_TX_ON)
+		return false;
+
+	tsc = tc6->ttsc_current_id;
+	for (i = 0; i < OA_TC6_TTSCC_REG_ID; i++) {
+		if (!(tc6->ts_ttsc_pending &
+		    BIT(tsc - OA_TC6_TTSCA_REG_ID)))
+			goto slot_found;
+		tsc = oa_tc6_next_tsc(tsc);
+	}
+
+	/* All the three slots are waiting for its event. This skb
+	 * can't request timestamp. Marking it to be dropped.
+	 */
+	tc6->tx_hwtstamp_err++;
+	return true;
+
+slot_found:
+	tc6->ts_ttsc_pending |= BIT(tsc - OA_TC6_TTSCA_REG_ID);
+	tc6->ttsc_current_id = oa_tc6_next_tsc(tsc);
+	oa_tc6_tsinfo_tx(skb)->tsc = tsc;
+	skb_shinfo(skb)->tx_flags |= SKBTX_IN_PROGRESS;
+	return false;
+}
+
+/* Hand a fully sent frame over to wait for its timestamp event. */
+static void oa_tc6_queue_tx_tstamp_skb(struct oa_tc6 *tc6,
+				       struct sk_buff *skb)
+{
+	u8 tsc = oa_tc6_tsinfo_tx(skb)->tsc;
+
+	spin_lock_bh(&tc6->tx_skb_lock);
+
+	/* Clear if oa_tc6_cleanup_tx_tstamp_skbs() abandoned this frame's
+	 * slot while the frame was being sent.
+	 */
+	if (tc6->ts_ttsc_pending & BIT(tsc - OA_TC6_TTSCA_REG_ID)) {
+		list_add_tail(&skb->list, &tc6->tx_ts_skb_q);
+		spin_unlock_bh(&tc6->tx_skb_lock);
+		return;
+	}
+
+	tc6->tx_hwtstamp_lost++;
+	spin_unlock_bh(&tc6->tx_skb_lock);
+	dev_kfree_skb(skb);
+}
+
+static void oa_tc6_events_handle(struct oa_tc6 *tc6, u32 val, const u32 *ts)
+{
+	struct skb_shared_hwtstamps tstamp;
+	struct oa_tc6_ts_info_tx *ski;
+	struct sk_buff *skb, *tmp;
+	LIST_HEAD(deliver);
+	LIST_HEAD(drop);
+	u8 tsc, bit_num;
+	u32 handled = 0;
+	u32 event;
+
+	spin_lock_bh(&tc6->tx_skb_lock);
+	list_for_each_entry_safe(skb, tmp, &tc6->tx_ts_skb_q, list) {
+		ski = oa_tc6_tsinfo_tx(skb);
+		tsc = ski->tsc;
+		bit_num = tsc - OA_TC6_TTSCA_REG_ID;
+		event = OA_TC6_STATUS0_TTSCAA << bit_num;
+		if (!(val & event))
+			continue;
+		if (handled & event) {
+			dev_warn_ratelimited(&tc6->spi->dev,
+					     "Multiple skbs\n");
+			tc6->tx_hwtstamp_err++;
+			list_move_tail(&skb->list, &drop);
+			continue;
+		}
+
+		handled |= event;
+		tc6->ts_ttsc_pending &= ~BIT(bit_num);
+
+		ski->hwtstamp = ktime_set(ts[2 * bit_num],
+					  ts[2 * bit_num + 1]);
+		tc6->tx_hwtstamp_pkts++;
+		list_move_tail(&skb->list, &deliver);
+	}
+	spin_unlock_bh(&tc6->tx_skb_lock);
+
+	/* skb_tstamp_tx() clones the skb and wakes the owning socket, so keep
+	 * it out of the lock that oa_tc6_start_xmit() takes.
+	 */
+	list_for_each_entry_safe(skb, tmp, &deliver, list) {
+		list_del(&skb->list);
+		memset(&tstamp, 0, sizeof(tstamp));
+		tstamp.hwtstamp = oa_tc6_tsinfo_tx(skb)->hwtstamp;
+		skb_tstamp_tx(skb, &tstamp);
+		dev_kfree_skb(skb);
+	}
+
+	list_for_each_entry_safe(skb, tmp, &drop, list) {
+		list_del(&skb->list);
+		dev_kfree_skb(skb);
+	}
+
+	if (val & ~handled) {
+		tc6->tx_hwtstamp_err += hweight32(val & ~handled);
+		dev_warn_ratelimited(&tc6->spi->dev,
+				     "Unexpected event: 0x%x\n",
+				     val & ~handled);
+	}
+}
+
+void oa_tc6_cleanup_tx_tstamp_skbs(struct oa_tc6 *tc6)
+{
+	struct sk_buff *skb, *tmp;
+
+	spin_lock_bh(&tc6->tx_skb_lock);
+	list_for_each_entry_safe(skb, tmp, &tc6->tx_ts_skb_q, list) {
+		list_del(&skb->list);
+		dev_kfree_skb(skb);
+
+		/* The frame was transmitted, only its timestamp is lost. */
+		tc6->tx_hwtstamp_lost++;
+	}
+
+	/* Also abandons the slot of a frame still being sent. */
+	tc6->ts_ttsc_pending = 0;
+	spin_unlock_bh(&tc6->tx_skb_lock);
+}
+
+static int oa_tc6_update_ts_in_rx_skb(struct oa_tc6 *tc6)
+{
+	unsigned int expected_len = ETH_HLEN;
+	struct sk_buff *skb = tc6->rx_skb;
+	struct oa_tc6_ts_info_rx *ski;
+	__be32 ts_val[2];
+	u32 ts[2];
+
+	ski = oa_tc6_tsinfo_rx(skb);
+	if (ski->rtsa)
+		expected_len += OA_TC6_TSTAMP_SZ;
+
+	if (skb->len < expected_len) {
+		tc6->netdev->stats.rx_length_errors++;
+		return -EINVAL;
+	}
+
+	if (!ski->rtsa)
+		return 0;
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
+
+	return 0;
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
+	if (regval & OA_TC6_STDCAP_FTSC_CAPABILITY) /* Timestamp */
+		tc6->ftsc_capable = true;
+	return 0;
+}
+
 static __be32 oa_tc6_prepare_ctrl_header(u32 addr, u8 length,
 					 enum oa_tc6_register_op reg_op)
 {
@@ -624,6 +841,16 @@ static void oa_tc6_cleanup_ongoing_rx_skb(struct oa_tc6 *tc6)
 
 static void oa_tc6_cleanup_ongoing_tx_skb(struct oa_tc6 *tc6)
 {
+	if (tc6->ongoing_tx_skb &&
+	    oa_tc6_tsinfo_tx(tc6->ongoing_tx_skb)->tsc) {
+		u8 tsc = oa_tc6_tsinfo_tx(tc6->ongoing_tx_skb)->tsc;
+
+		spin_lock_bh(&tc6->tx_skb_lock);
+		tc6->ts_ttsc_pending &= ~BIT(tsc - OA_TC6_TTSCA_REG_ID);
+		spin_unlock_bh(&tc6->tx_skb_lock);
+	}
+
+	tc6->tx_skb_offset = 0;
 	oa_tc6_drop_tx_skb(tc6, tc6->ongoing_tx_skb);
 	tc6->ongoing_tx_skb = NULL;
 }
@@ -649,6 +876,7 @@ static void oa_tc6_free_pending_skbs(struct oa_tc6 *tc6)
 {
 	oa_tc6_free_ongoing_skbs(tc6);
 	oa_tc6_cleanup_waiting_tx_skb(tc6);
+	oa_tc6_cleanup_tx_tstamp_skbs(tc6);
 }
 
 static void oa_tc6_look_for_new_frame(struct oa_tc6 *tc6)
@@ -677,6 +905,8 @@ static void oa_tc6_disable_traffic(struct oa_tc6 *tc6)
 	netif_tx_disable(tc6->netdev);
 	oa_tc6_drop_tx_skb(tc6, skb);
 	oa_tc6_free_ongoing_skbs(tc6);
+	oa_tc6_cleanup_tx_tstamp_skbs(tc6);
+
 	oa_tc6_write_register(tc6, OA_TC6_REG_INT_MASK0, regval);
 	oa_tc6_read_register(tc6, OA_TC6_REG_STATUS0, &regval);
 	oa_tc6_write_register(tc6, OA_TC6_REG_STATUS0, regval);
@@ -685,15 +915,28 @@ static void oa_tc6_disable_traffic(struct oa_tc6 *tc6)
 
 static int oa_tc6_process_extended_status(struct oa_tc6 *tc6)
 {
+	u32 regs[OA_TC6_STATUS0_TTSC_REG_COUNT];
+	bool ts_valid = !!tc6->ptp_clock;
 	u32 value;
 	int ret;
 
-	ret = oa_tc6_read_register(tc6, OA_TC6_REG_STATUS0, &value);
+	/* When timestamp is disabled, there is no behavior change
+	 * as it reads only STATUS0 register. When enabled,
+	 * TTSCA_HIGH..TTSCC_LOW are fetched together with STATUS0
+	 * to avoid having to make second SPI transaction. Reading few
+	 * extra registers, even it may not be needed every time this
+	 * function is called, it is more efficient than making second
+	 * SPI transaction, when needed.
+	 */
+	ret = oa_tc6_read_registers(tc6, OA_TC6_REG_STATUS0, regs,
+				    ts_valid ?
+				    OA_TC6_STATUS0_TTSC_REG_COUNT : 1);
 	if (ret) {
 		netdev_err(tc6->netdev, "STATUS0 register read failed: %d\n",
 			   ret);
 		return ret;
 	}
+	value = regs[0];
 
 	/* This function is called for each chunk received in a given SPI
 	 * transaction. In case, extended status bit is set in more than
@@ -702,6 +945,12 @@ static int oa_tc6_process_extended_status(struct oa_tc6 *tc6)
 	if (!value)
 		return 0;
 
+	/* Without ts_valid the TTSC registers were not read. */
+	if (ts_valid && (value & OA_TC6_STATUS0_TTSCA_MASK) != 0)
+		oa_tc6_events_handle(tc6, value &
+				     OA_TC6_STATUS0_TTSCA_MASK,
+				     &regs[OA_TC6_TTSC_REG_OFFSET]);
+
 	/* Clear the error interrupts status */
 	ret = oa_tc6_write_register(tc6, OA_TC6_REG_STATUS0, value);
 	if (ret) {
@@ -787,6 +1036,13 @@ static void oa_tc6_submit_rx_skb(struct oa_tc6 *tc6)
 	    tc6->rx_skb->len > ETH_FCS_LEN)
 		skb_trim(tc6->rx_skb, tc6->rx_skb->len - ETH_FCS_LEN);
 
+	if (oa_tc6_update_ts_in_rx_skb(tc6)) {
+		tc6->netdev->stats.rx_dropped++;
+		dev_kfree_skb_any(tc6->rx_skb);
+		tc6->rx_skb = NULL;
+		return;
+	}
+
 	tc6->rx_skb->protocol = eth_type_trans(tc6->rx_skb, tc6->netdev);
 	tc6->netdev->stats.rx_packets++;
 	tc6->netdev->stats.rx_bytes += tc6->rx_skb->len;
@@ -822,25 +1078,32 @@ static int oa_tc6_update_rx_skb(struct oa_tc6 *tc6, u8 *payload, u8 length)
  * buffer pointer. We should release, if a valid pointer is found before
  * allocating a new one.
  */
-static int oa_tc6_allocate_rx_skb(struct oa_tc6 *tc6)
+static int oa_tc6_allocate_rx_skb(struct oa_tc6 *tc6, u32 footer)
 {
+	struct oa_tc6_ts_info_rx *ski;
+
 	oa_tc6_cleanup_ongoing_rx_skb(tc6);
-	tc6->rx_skb = netdev_alloc_skb_ip_align(tc6->netdev, tc6->netdev->mtu +
-						ETH_HLEN + ETH_FCS_LEN);
+	tc6->rx_skb = netdev_alloc_skb_ip_align(tc6->netdev,
+						tc6->netdev->mtu +
+						ETH_HLEN + ETH_FCS_LEN +
+						OA_TC6_TSTAMP_SZ);
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
 
@@ -853,11 +1116,11 @@ static int oa_tc6_prcs_complete_rx_frame(struct oa_tc6 *tc6, u8 *payload,
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
 
@@ -904,7 +1167,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 		size = end_byte_offset + 1 - start_byte_offset;
 		return oa_tc6_prcs_complete_rx_frame(tc6,
 						     &data[start_byte_offset],
-						     size);
+						     size, footer);
 	}
 
 	/* Process the chunk with only rx frame start */
@@ -912,7 +1175,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 		size = OA_TC6_CHUNK_PAYLOAD_SIZE - start_byte_offset;
 		return oa_tc6_prcs_rx_frame_start(tc6,
 						  &data[start_byte_offset],
-						  size);
+						  size, footer);
 	}
 
 	/* Process the chunk with only rx frame end */
@@ -945,7 +1208,7 @@ static int oa_tc6_prcs_rx_chunk_payload(struct oa_tc6 *tc6, u8 *data,
 		size = OA_TC6_CHUNK_PAYLOAD_SIZE - start_byte_offset;
 		return oa_tc6_prcs_rx_frame_start(tc6,
 						  &data[start_byte_offset],
-						  size);
+						  size, footer);
 	}
 
 	/* Process the chunk with ongoing rx frame data */
@@ -1024,13 +1287,15 @@ static int oa_tc6_process_spi_data_rx_buf(struct oa_tc6 *tc6, u16 length)
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
 
@@ -1049,6 +1314,7 @@ static void oa_tc6_add_tx_skb_to_spi_buf(struct oa_tc6 *tc6)
 	enum oa_tc6_data_start_valid_info start_valid;
 	u8 end_byte_offset = 0;
 	u16 length_to_copy;
+	u8 tsc = 0;
 
 	/* Initial value is assigned here to avoid more than 80 characters in
 	 * the declaration place.
@@ -1058,8 +1324,10 @@ static void oa_tc6_add_tx_skb_to_spi_buf(struct oa_tc6 *tc6)
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
@@ -1080,17 +1348,25 @@ static void oa_tc6_add_tx_skb_to_spi_buf(struct oa_tc6 *tc6)
 		tc6->tx_skb_offset = 0;
 		tc6->netdev->stats.tx_bytes += tc6->ongoing_tx_skb->len;
 		tc6->netdev->stats.tx_packets++;
-		kfree_skb(tc6->ongoing_tx_skb);
+
+		/* Free the ones that are not saved for later processing,
+		 * like timestamping.
+		 */
+		if (!oa_tc6_tsinfo_tx(tc6->ongoing_tx_skb)->tsc)
+			kfree_skb(tc6->ongoing_tx_skb);
+		else
+			oa_tc6_queue_tx_tstamp_skb(tc6, tc6->ongoing_tx_skb);
 		tc6->ongoing_tx_skb = NULL;
 	}
 
 	*tx_buf = oa_tc6_prepare_data_header(OA_TC6_DATA_VALID, start_valid,
-					     end_valid, end_byte_offset);
+					     end_valid, end_byte_offset, tsc);
 	tc6->spi_data_tx_buf_offset += OA_TC6_CHUNK_SIZE;
 }
 
 static u16 oa_tc6_prepare_spi_tx_buf_for_tx_skbs(struct oa_tc6 *tc6)
 {
+	struct sk_buff *drop_skb;
 	u16 used_tx_credits;
 
 	/* Get tx skbs and convert them into tx chunks based on the tx credits
@@ -1099,10 +1375,21 @@ static u16 oa_tc6_prepare_spi_tx_buf_for_tx_skbs(struct oa_tc6 *tc6)
 	for (used_tx_credits = 0; used_tx_credits < tc6->tx_credits;
 	     used_tx_credits++) {
 		if (!tc6->ongoing_tx_skb) {
+			drop_skb = NULL;
 			spin_lock_bh(&tc6->tx_skb_lock);
 			tc6->ongoing_tx_skb = tc6->waiting_tx_skb;
 			tc6->waiting_tx_skb = NULL;
+			if (oa_tc6_req_tx_hwtstamp(tc6,
+						   tc6->ongoing_tx_skb)) {
+				drop_skb = tc6->ongoing_tx_skb;
+				tc6->ongoing_tx_skb = NULL;
+				if (!tc6->disable_traffic &&
+				    netif_running(tc6->netdev) &&
+				    netif_queue_stopped(tc6->netdev))
+					netif_wake_queue(tc6->netdev);
+			}
 			spin_unlock_bh(&tc6->tx_skb_lock);
+			oa_tc6_drop_tx_skb(tc6, drop_skb);
 		}
 		if (!tc6->ongoing_tx_skb)
 			break;
@@ -1119,7 +1406,7 @@ static void oa_tc6_add_empty_chunks_to_spi_buf(struct oa_tc6 *tc6,
 
 	header = oa_tc6_prepare_data_header(OA_TC6_DATA_INVALID,
 					    OA_TC6_DATA_START_INVALID,
-					    OA_TC6_DATA_END_INVALID, 0);
+					    OA_TC6_DATA_END_INVALID, 0, 0);
 
 	while (needed_empty_chunks--) {
 		__be32 *tx_buf = tc6->spi_data_tx_buf +
@@ -1311,6 +1598,7 @@ netdev_tx_t oa_tc6_start_xmit(struct oa_tc6 *tc6, struct sk_buff *skb)
 		return NETDEV_TX_OK;
 	}
 
+	oa_tc6_tsinfo_tx(skb)->tsc = 0;
 	spin_lock_bh(&tc6->tx_skb_lock);
 	if (tc6->waiting_tx_skb) {
 		netif_stop_queue(tc6->netdev);
@@ -1370,6 +1658,8 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev,
 	SET_NETDEV_DEV(netdev, &spi->dev);
 	mutex_init(&tc6->spi_ctrl_lock);
 	spin_lock_init(&tc6->tx_skb_lock);
+	tc6->ttsc_current_id = OA_TC6_TTSCA_REG_ID;
+	INIT_LIST_HEAD(&tc6->tx_ts_skb_q);
 
 	if (quirks)
 		tc6->quirk_flags = quirks->quirk_flags;
@@ -1435,6 +1725,12 @@ struct oa_tc6 *oa_tc6_init(struct spi_device *spi, struct net_device *netdev,
 		return ERR_PTR(ret);
 	}
 
+	ret = oa_tc6_update_standard_capability(tc6);
+	if (ret) {
+		dev_err(&tc6->spi->dev, "Failed to read capability\n");
+		goto phy_exit;
+	}
+
 	ret = oa_tc6_unmask_macphy_error_interrupts(tc6);
 	if (ret) {
 		dev_err(&tc6->spi->dev,
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c b/drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c
new file mode 100644
index 000000000000..7d21c0608ee8
--- /dev/null
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_ptp.c
@@ -0,0 +1,65 @@
+// SPDX-License-Identifier: GPL-2.0+
+/*
+ * Support for hardware timestamping feature for OPEN Alliance
+ * 10BASE‑T1x MAC‑PHY Serial Interface framework
+ *
+ * Author: Selva Rajagopal <selvamani.rajagopal@onsemi.com>
+ */
+
+#include <linux/kernel.h>
+#include <linux/spi/spi.h>
+#include <linux/ptp_clock_kernel.h>
+#include <linux/ethtool.h>
+#include <linux/phy.h>
+#include <linux/oa_tc6.h>
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
+	int ret = 0;
+
+	/* Not supporting hardware timestamp isn't an error */
+	if (!tc6->ftsc_capable)
+		return ret;
+
+	snprintf(info->name, sizeof(info->name), "OA TC6 PTP %s",
+		 dev_name(&tc6->spi->dev));
+	tc6->ptp_clock = ptp_clock_register(info, &tc6->spi->dev);
+	if (IS_ERR(tc6->ptp_clock)) {
+		ret = PTR_ERR(tc6->ptp_clock);
+		tc6->ptp_clock = NULL;
+		dev_err(&tc6->spi->dev, "Registration of %s failed\n",
+			info->name);
+	}
+
+	if (tc6->ptp_clock)
+		dev_info(&tc6->spi->dev, "%s registered. index %d\n",
+			 info->name, ptp_clock_index(tc6->ptp_clock));
+	return ret;
+}
+EXPORT_SYMBOL_GPL(oa_tc6_ptp_register);
+
+/**
+ * oa_tc6_ptp_unregister - Unregisters clock related callbacks
+ * @tc6: oa_tc6 struct.
+ */
+void oa_tc6_ptp_unregister(struct oa_tc6 *tc6)
+{
+	if (tc6->ptp_clock) {
+		ptp_clock_unregister(tc6->ptp_clock);
+		tc6->ptp_clock = NULL;
+	}
+}
+EXPORT_SYMBOL_GPL(oa_tc6_ptp_unregister);
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
index c61672aa618c..a4d269cd685f 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
@@ -19,6 +19,9 @@
 #include <linux/wait.h>
 #include <linux/oa_tc6.h>
 
+/* Tx timestamp capture register A (high) */
+#define OA_TC6_REG_TTSCA_HIGH			(0x10)
+
 /* Control command header */
 #define OA_TC6_CTRL_HEADER_DATA_NOT_CTRL	BIT(31)
 #define OA_TC6_CTRL_HEADER_WRITE_NOT_READ	BIT(29)
@@ -34,6 +37,7 @@
 #define OA_TC6_DATA_HEADER_START_WORD_OFFSET	GENMASK(19, 16)
 #define OA_TC6_DATA_HEADER_END_VALID		BIT(14)
 #define OA_TC6_DATA_HEADER_END_BYTE_OFFSET	GENMASK(13, 8)
+#define OA_TC6_DATA_HEADER_TSC_OFFSET		GENMASK(7, 6)
 #define OA_TC6_DATA_HEADER_PARITY		BIT(0)
 
 /* Data footer */
@@ -44,7 +48,10 @@
 #define OA_TC6_DATA_FOOTER_DATA_VALID		BIT(21)
 #define OA_TC6_DATA_FOOTER_START_VALID		BIT(20)
 #define OA_TC6_DATA_FOOTER_START_WORD_OFFSET	GENMASK(19, 16)
+#define OA_TC6_DATA_FOOTER_FRAME_DROP		BIT(15)
 #define OA_TC6_DATA_FOOTER_END_VALID		BIT(14)
+#define OA_TC6_DATA_FOOTER_RTSA_VALID		BIT(7)
+#define OA_TC6_DATA_FOOTER_RTSP_VALID		BIT(6)
 #define OA_TC6_DATA_FOOTER_END_BYTE_OFFSET	GENMASK(13, 8)
 #define OA_TC6_DATA_FOOTER_TX_CREDITS		GENMASK(5, 1)
 
@@ -71,6 +78,33 @@
 
 #define OA_TC6_REG_MMS_MASK		GENMASK(19, 16)
 
+#define OA_TC6_TSTAMP_SZ			8
+
+#define OA_TC6_TTSCA_REG_ID			1
+#define OA_TC6_TTSCB_REG_ID			2
+#define OA_TC6_TTSCC_REG_ID			3
+
+/* OA TC6 register addresses count 32-bit registers, not bytes. The difference
+ * of two addresses is therefore the index into a u32 array that was read
+ * starting at the first address, so the OFFSET macros below are array indices.
+ */
+#define OA_TC6_TTSC_REG_OFFSET		(OA_TC6_REG_TTSCA_HIGH - \
+					 OA_TC6_REG_STATUS0)
+#define OA_TC6_TTSC_REG_COUNT		(2 * OA_TC6_TTSCC_REG_ID)
+#define OA_TC6_STATUS0_TTSC_REG_COUNT	(OA_TC6_TTSC_REG_OFFSET + \
+					 OA_TC6_TTSC_REG_COUNT)
+
+/* Useful for reading all the registers between CONFIG0 and INT_MASK0
+ * in a single SPI transaction
+ */
+#define CFG0_TO_IMASK0_REG_COUNT	(OA_TC6_REG_INT_MASK0 - \
+					 OA_TC6_REG_CONFIG0 + 1)
+#define CFG0_VAL_OFFSET			(0)
+#define STATUS0_VAL_OFFSET		(OA_TC6_REG_STATUS0 - \
+					 OA_TC6_REG_CONFIG0)
+#define IRQM_VAL_OFFSET			(OA_TC6_REG_INT_MASK0 - \
+					 OA_TC6_REG_CONFIG0)
+
 /* Internal structure for MAC-PHY drivers */
 struct oa_tc6 {
 	struct net_device *netdev;
@@ -96,6 +130,16 @@ struct oa_tc6 {
 	bool prot_ctrl;
 	enum oa_tc6_quirk_flag quirk_flags;
 	struct gpio_desc *reset_gpio;
+	struct hwtstamp_config ts_config;
+	struct list_head tx_ts_skb_q;
+	struct ptp_clock *ptp_clock;
+	bool ftsc_capable; /* Timestamp capability */
+	bool hw_tstamp_enabled;
+	u64 tx_hwtstamp_pkts;
+	u64 tx_hwtstamp_lost;
+	u64 tx_hwtstamp_err;
+	u8 ts_ttsc_pending;
+	u8 ttsc_current_id;
 };
 
 enum oa_tc6_header_type {
@@ -122,5 +166,8 @@ enum oa_tc6_data_end_valid_info {
 	OA_TC6_DATA_END_INVALID,
 	OA_TC6_DATA_END_VALID,
 };
+
+void oa_tc6_cleanup_tx_tstamp_skbs(struct oa_tc6 *tc6);
+
 #endif /* OA_TC6_STD_DEF_H */
 
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c b/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c
new file mode 100644
index 000000000000..539cbd36a1d0
--- /dev/null
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c
@@ -0,0 +1,224 @@
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
+static int oa_tc6_set_hwtstamp_settings(struct oa_tc6 *tc6,
+					const struct hwtstamp_config *ts_cfg)
+{
+	u32 regs[CFG0_TO_IMASK0_REG_COUNT];
+	u32 cfg0, irqm, status0;
+	bool disabled;
+	int ret;
+
+	if (tc6->ts_config.flags == ts_cfg->flags &&
+	    tc6->ts_config.tx_type == ts_cfg->tx_type &&
+	    tc6->ts_config.rx_filter == ts_cfg->rx_filter)
+		return 0;
+
+	spin_lock_bh(&tc6->tx_skb_lock);
+	disabled = tc6->disable_traffic;
+	spin_unlock_bh(&tc6->tx_skb_lock);
+	if (disabled)
+		return -EIO;
+
+	/* CONFIG0, STATUS0 and INT_MASK0 span one register block, so a
+	 * single control transaction covers all three.
+	 */
+	ret = oa_tc6_read_registers(tc6, OA_TC6_REG_CONFIG0, regs,
+				    ARRAY_SIZE(regs));
+	if (ret) {
+		dev_err(&tc6->spi->dev, "Failed to read CFG0 block\n");
+		goto out;
+	}
+
+	cfg0 = regs[CFG0_VAL_OFFSET];
+	status0 = regs[STATUS0_VAL_OFFSET];
+	irqm = regs[IRQM_VAL_OFFSET];
+
+	/* Hardware timestamp feature supports 64-bit timestamp only */
+	if (ts_cfg->tx_type == HWTSTAMP_TX_ON ||
+	    ts_cfg->rx_filter == HWTSTAMP_FILTER_ALL)
+		cfg0 |= (OA_TC6_CONFIG0_FTSE_ENABLE |
+			 OA_TC6_CONFIG0_FTSS_64BIT_TSTAMP);
+	else
+		cfg0 &= ~OA_TC6_CONFIG0_FTSE_ENABLE;
+
+	if (ts_cfg->tx_type == HWTSTAMP_TX_ON)
+		irqm &= ~OA_TC6_INT_MASK0_TTSCA_MASK;
+	else
+		irqm |= OA_TC6_INT_MASK0_TTSCA_MASK;
+
+	/* STATUS0 is write-one-to-clear, so this acknowledges a capture
+	 * without delivering its timestamp. Skip it while TX timestamping
+	 * stays enabled, where a capture may still be outstanding.
+	 */
+	status0 &= OA_TC6_STATUS0_TTSCA_MASK;
+	if (status0 && (tc6->ts_config.tx_type != HWTSTAMP_TX_ON ||
+			ts_cfg->tx_type != HWTSTAMP_TX_ON)) {
+		ret = oa_tc6_write_register(tc6, OA_TC6_REG_STATUS0,
+					    status0);
+		if (ret) {
+			dev_err(&tc6->spi->dev,
+				"failed to write STATUS0 register\n");
+			goto out;
+		}
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
+	spin_lock_bh(&tc6->tx_skb_lock);
+	tc6->ts_config = *ts_cfg;
+	if (cfg0 & OA_TC6_CONFIG0_FTSE_ENABLE)
+		tc6->hw_tstamp_enabled = true;
+	else
+		tc6->hw_tstamp_enabled = false;
+	spin_unlock_bh(&tc6->tx_skb_lock);
+
+	/* The TX timestamp completion interrupt is masked now. Time
+	 * to release the queued skbs.
+	 */
+	if (ts_cfg->tx_type != HWTSTAMP_TX_ON)
+		oa_tc6_cleanup_tx_tstamp_skbs(tc6);
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
+	struct hwtstamp_config ts_cfg;
+	int ret;
+
+	if (!netif_running(tc6->netdev))
+		return -EIO;
+
+	/* Set only when STDCAP advertised the capability and the PHC
+	 * registered, which is what ethtool -T reports.
+	 */
+	if (!tc6->ptp_clock)
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
+
+	hwtstamp_config_from_kernel(&ts_cfg, cfg);
+
+	/* Supports timestamping all traffic */
+	if (cfg->rx_filter != HWTSTAMP_FILTER_NONE ||
+	    cfg->tx_type == HWTSTAMP_TX_ON)
+		ts_cfg.rx_filter = HWTSTAMP_FILTER_ALL;
+
+	ret = oa_tc6_set_hwtstamp_settings(tc6, &ts_cfg);
+	if (ret)
+		return ret;
+
+	/* Report what was programmed, not asked. */
+	cfg->rx_filter = ts_cfg.rx_filter;
+
+	return 0;
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
+	info->tx_types = BIT(HWTSTAMP_TX_OFF) | BIT(HWTSTAMP_TX_ON);
+	info->rx_filters = BIT(HWTSTAMP_FILTER_NONE) |
+			   BIT(HWTSTAMP_FILTER_ALL);
+	return 0;
+}
+EXPORT_SYMBOL_GPL(oa_tc6_get_ts_info);
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 27f652d4920b..adfa83cd92ee 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -7,13 +7,18 @@
  * Author: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>
  */
 
+#ifndef _LINUX_OA_TC6_H
+#define _LINUX_OA_TC6_H
+
 #include <linux/etherdevice.h>
 #include <linux/spi/spi.h>
+#include <linux/ptp_clock_kernel.h>
 
 /* OPEN Alliance TC6 registers */
 /* Standard Capabilities Register */
 #define OA_TC6_REG_STDCAP			0x0002
 #define OA_TC6_STDCAP_DIRECT_PHY_REG_ACCESS	BIT(8)
+#define OA_TC6_STDCAP_FTSC_CAPABILITY		BIT(6)
 
 /* Reset Control and Status Register */
 #define OA_TC6_REG_RESET			0x0003
@@ -23,6 +28,8 @@
 #define OA_TC6_REG_CONFIG0			0x0004
 #define OA_TC6_CONFIG0_SYNC			BIT(15)
 #define OA_TC6_CONFIG0_ZARFE_ENABLE		BIT(12)
+#define OA_TC6_CONFIG0_FTSE_ENABLE		BIT(7)
+#define OA_TC6_CONFIG0_FTSS_64BIT_TSTAMP	BIT(6)
 #define OA_TC6_CONFIG0_PROTE			BIT(5)
 
 /* Configuration Register #2 */
@@ -30,6 +37,10 @@
 
 /* Status Register #0 */
 #define OA_TC6_REG_STATUS0			0x0008
+#define OA_TC6_STATUS0_TTSCAC			BIT(10)
+#define OA_TC6_STATUS0_TTSCAB			BIT(9)
+#define OA_TC6_STATUS0_TTSCAA			BIT(8)
+#define OA_TC6_STATUS0_TTSCA_MASK		GENMASK(10, 8)
 #define OA_TC6_STATUS0_RESETC			BIT(6)	/* Reset Complete */
 #define OA_TC6_STATUS0_HEADER_ERROR		BIT(5)
 #define OA_TC6_STATUS0_LOSS_OF_FRAME_ERROR	BIT(4)
@@ -43,6 +54,7 @@
 
 /* Interrupt Mask Register #0 */
 #define OA_TC6_REG_INT_MASK0				0x000C
+#define OA_TC6_INT_MASK0_TTSCA_MASK			GENMASK(10, 8)
 #define OA_TC6_INT_MASK0_HEADER_ERR_MASK		BIT(5)
 #define OA_TC6_INT_MASK0_LOSS_OF_FRAME_ERR_MASK		BIT(4)
 #define OA_TC6_INT_MASK0_RX_BUFFER_OVERFLOW_ERR_MASK	BIT(3)
@@ -93,3 +105,14 @@ int oa_tc6_mdiobus_read_c45(struct mii_bus *bus, int addr, int devnum,
 			    int regnum);
 int oa_tc6_mdiobus_write_c45(struct mii_bus *bus, int addr, int devnum,
 			     int regnum, u16 val);
+int oa_tc6_ptp_register(struct oa_tc6 *tc6, struct ptp_clock_info *info);
+int oa_tc6_get_ts_info(struct oa_tc6 *tc6,
+		       struct kernel_ethtool_ts_info *info);
+void oa_tc6_hwtstamp_get(struct oa_tc6 *tc6,
+			 struct kernel_hwtstamp_config *cfg);
+void oa_tc6_get_ts_stats(struct oa_tc6 *tc6,
+			 struct ethtool_ts_stats *stats);
+int oa_tc6_hwtstamp_set(struct oa_tc6 *tc6,
+			struct kernel_hwtstamp_config *cfg);
+void oa_tc6_ptp_unregister(struct oa_tc6 *tc6);
+#endif /* _LINUX_OA_TC6_H */

-- 
2.43.0

