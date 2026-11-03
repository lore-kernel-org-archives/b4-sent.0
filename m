From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Tue, 03 Nov 2026 13:30:20 +0100
Subject: [PATCH v8 04/14] can: peak_usb: harden channel handling in
 PCAN-USB FD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-canfd_check_channel_idx-v8-4-4e8b2c0a8806@peak-system.fr>
References: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
In-Reply-To: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793709024; l=9897;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=DaOssuVq84IIUNzeWllHnVlqfJyEpYEFDgpVdAIr+Ac=;
 b=N6D6aAha61VHMDorp10N4zg9nMK0dVrjP3sAMzHxgFhIJvwM65HAlawReVZBDnZj+DFTrFiqu
 uodAx5QSCz/CowSRLAsYbdlnDUstND/560uXkw4PfJRlZ8Gt2mxhj2R
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Records received from PCAN-USB FD family devices carry a CAN channel
number used to index the adapter CAN device table usb_if->dev[].

The decoders only checked this number against the size of the table
(2 entries). On single-channel adapters (PCAN-USB FD, PCAN-Chip USB),
dev[1] is never set, so a record for channel 1 led to a NULL pointer
dereference in URB completion context. On two-channel adapters, a
channel slot is also NULL until that channel has been initialized,
while the RX URBs of channel 0 may already be running.

Check the channel number against the number of controllers of the
adapter and reject records for a channel whose slot is empty. Such a
record makes the decoder stop processing the rest of the URB.

When probing a channel fails after its slot has been filled, the channel
is freed but its slot kept pointing to it. Clear the slot in
pcan_usb_fd_free() and, before freeing the channel, stop RX on this
channel and on the sibling channels already created, since the whole
interface is then released anyway. Slots are published with
smp_store_release() and read with READ_ONCE().

Finally, peak_usb_disconnect() now stops RX on all channels before
unregistering any of them: it clears CONNECTED, which makes
peak_usb_ndo_open() fail, then poisons the RX anchors. This matters
when it is called from the probe error path, where the USB core has
not disabled the interface.

CONNECTED is cleared under RTNL, to serialize with peak_usb_ndo_open():
otherwise, an ndo_open() that has already passed the CONNECTED test
may have anchored an RX URB without having submitted it yet, which
makes usb_poison_anchored_urbs() busy-wait until it is submitted.

Fixes: a6921dd524fe ("can: peak_usb: add range checking in decode operations")
Assisted-by: LLM
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb_core.c | 39 ++++++++++++++++-
 drivers/net/can/usb/peak_usb/pcan_usb_fd.c   | 62 +++++++++++++++++++++-------
 2 files changed, 84 insertions(+), 17 deletions(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_core.c b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
index a1b17e1e6fea..f5c39b43b0fa 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_core.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
@@ -13,6 +13,7 @@
 #include <linux/init.h>
 #include <linux/module.h>
 #include <linux/netdevice.h>
+#include <linux/rtnetlink.h>
 #include <linux/signal.h>
 #include <linux/slab.h>
 #include <linux/sysfs.h>
@@ -574,6 +575,9 @@ static int peak_usb_ndo_open(struct net_device *netdev)
 	struct peak_usb_device *dev = netdev_priv(netdev);
 	int err;
 
+	if (!test_bit(PCAN_USB_STATE_CONNECTED, &dev->state))
+		return -ENODEV;
+
 	/* common open */
 	err = open_candev(netdev);
 	if (err)
@@ -904,6 +908,29 @@ int pcan_get_ts_info(struct net_device *dev, struct kernel_ethtool_ts_info *info
 	return 0;
 }
 
+/*
+ * stop RX on dev and on all its previous siblings: clearing CONNECTED makes
+ * peak_usb_ndo_open() fail, then poisoning the RX anchors waits for running
+ * completion handlers and makes any later submission on them fail.
+ *
+ * peak_usb_ndo_open() runs under RTNL: clearing CONNECTED under RTNL ensures
+ * that no ndo_open() is in progress (so no RX URB is anchored but not yet
+ * submitted, which usb_poison_anchored_urbs() would busy-wait on) and that
+ * any later one fails.
+ */
+static void peak_usb_stop_rx(struct peak_usb_device *dev)
+{
+	struct peak_usb_device *d;
+
+	rtnl_lock();
+	for (d = dev; d; d = d->prev_siblings)
+		clear_bit(PCAN_USB_STATE_CONNECTED, &d->state);
+	rtnl_unlock();
+
+	for (d = dev; d; d = d->prev_siblings)
+		usb_poison_anchored_urbs(&d->rx_submitted);
+}
+
 /*
  * create one device which is attached to CAN controller #ctrl_idx of the
  * usb adapter.
@@ -1014,6 +1041,13 @@ static int peak_usb_create_dev(const struct peak_usb_adapter *peak_usb_adapter,
 	return 0;
 
 adap_dev_free:
+	/* the whole interface is released when probing a channel fails:
+	 * stop RX on this channel, which may already be open, and on the
+	 * channels already created, since their RX URBs may carry records
+	 * for this one.
+	 */
+	peak_usb_stop_rx(dev);
+
 	if (dev->adapter->dev_free)
 		dev->adapter->dev_free(dev);
 
@@ -1038,13 +1072,14 @@ static void peak_usb_disconnect(struct usb_interface *intf)
 	struct peak_usb_device *dev;
 	struct peak_usb_device *dev_prev_siblings;
 
-	/* unregister as many netdev devices as siblings */
+	/* stop RX on all channels before unregistering and freeing them */
+	peak_usb_stop_rx(usb_get_intfdata(intf));
+
 	for (dev = usb_get_intfdata(intf); dev; dev = dev_prev_siblings) {
 		struct net_device *netdev = dev->netdev;
 		char name[IFNAMSIZ];
 
 		dev_prev_siblings = dev->prev_siblings;
-		clear_bit(PCAN_USB_STATE_CONNECTED, &dev->state);
 		strscpy(name, netdev->name, IFNAMSIZ);
 
 		unregister_candev(netdev);
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_fd.c b/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
index c3d962fc8da0..a9f81fb12738 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
@@ -60,6 +60,7 @@ struct __packed pcan_ufd_fw_info {
 
 /* handle device specific info used by the netdevices */
 struct pcan_usb_fd_if {
+	const struct peak_usb_adapter *adapter;
 	struct peak_usb_device	*dev[PCAN_USB_MAX_CHANNEL];
 	struct pcan_ufd_fw_info	fw_info;
 	struct peak_time_ref	time_ref;
@@ -536,10 +537,16 @@ static int pcan_usb_fd_decode_canmsg(struct pcan_usb_fd_if *usb_if,
 	struct sk_buff *skb;
 	const u16 rx_msg_flags = le16_to_cpu(rm->flags);
 
-	if (pucan_msg_get_channel(rm) >= ARRAY_SIZE(usb_if->dev))
-		return -ENOMEM;
+	/* Reject invalid channel numbers reported by the firmware */
+	if (pucan_msg_get_channel(rm) >= usb_if->adapter->ctrl_count)
+		return -EINVAL;
+
+	dev = READ_ONCE(usb_if->dev[pucan_msg_get_channel(rm)]);
+
+	/* reject records for a channel that is not (or no longer) set up */
+	if (!dev)
+		return -EINVAL;
 
-	dev = usb_if->dev[pucan_msg_get_channel(rm)];
 	netdev = dev->netdev;
 
 	if (rx_msg_flags & PUCAN_MSG_EXT_DATA_LEN) {
@@ -605,10 +612,16 @@ static int pcan_usb_fd_decode_status(struct pcan_usb_fd_if *usb_if,
 	struct can_frame *cf;
 	struct sk_buff *skb;
 
-	if (pucan_stmsg_get_channel(sm) >= ARRAY_SIZE(usb_if->dev))
-		return -ENOMEM;
+	/* Reject invalid channel numbers reported by the firmware */
+	if (pucan_stmsg_get_channel(sm) >= usb_if->adapter->ctrl_count)
+		return -EINVAL;
+
+	dev = READ_ONCE(usb_if->dev[pucan_stmsg_get_channel(sm)]);
+
+	/* reject records for a channel that is not (or no longer) set up */
+	if (!dev)
+		return -EINVAL;
 
-	dev = usb_if->dev[pucan_stmsg_get_channel(sm)];
 	pdev = container_of(dev, struct pcan_usb_fd_device, dev);
 	netdev = dev->netdev;
 
@@ -662,10 +675,16 @@ static int pcan_usb_fd_decode_error(struct pcan_usb_fd_if *usb_if,
 	struct pcan_usb_fd_device *pdev;
 	struct peak_usb_device *dev;
 
-	if (pucan_ermsg_get_channel(er) >= ARRAY_SIZE(usb_if->dev))
+	/* Reject invalid channel numbers reported by the firmware */
+	if (pucan_ermsg_get_channel(er) >= usb_if->adapter->ctrl_count)
+		return -EINVAL;
+
+	dev = READ_ONCE(usb_if->dev[pucan_ermsg_get_channel(er)]);
+
+	/* reject records for a channel that is not (or no longer) set up */
+	if (!dev)
 		return -EINVAL;
 
-	dev = usb_if->dev[pucan_ermsg_get_channel(er)];
 	pdev = container_of(dev, struct pcan_usb_fd_device, dev);
 
 	/* keep a trace of tx and rx error counters for later use */
@@ -685,10 +704,16 @@ static int pcan_usb_fd_decode_overrun(struct pcan_usb_fd_if *usb_if,
 	struct can_frame *cf;
 	struct sk_buff *skb;
 
-	if (pufd_omsg_get_channel(ov) >= ARRAY_SIZE(usb_if->dev))
+	/* Reject invalid channel numbers reported by the firmware */
+	if (pufd_omsg_get_channel(ov) >= usb_if->adapter->ctrl_count)
+		return -EINVAL;
+
+	dev = READ_ONCE(usb_if->dev[pufd_omsg_get_channel(ov)]);
+
+	/* reject records for a channel that is not (or no longer) set up */
+	if (!dev)
 		return -EINVAL;
 
-	dev = usb_if->dev[pufd_omsg_get_channel(ov)];
 	netdev = dev->netdev;
 
 	/* allocate an skb to store the error frame */
@@ -981,6 +1006,9 @@ static int pcan_usb_fd_init(struct peak_usb_device *dev)
 		if (!pdev->usb_if)
 			goto err_out;
 
+		/* needed by the decoders to check channel numbers */
+		pdev->usb_if->adapter = dev->adapter;
+
 		/* allocate command buffer once for all for the interface */
 		pdev->cmd_buffer_addr = kzalloc(PCAN_UFD_CMD_BUFFER_SIZE,
 						GFP_KERNEL);
@@ -1054,7 +1082,8 @@ static int pcan_usb_fd_init(struct peak_usb_device *dev)
 		fw_info = &pdev->usb_if->fw_info;
 	}
 
-	pdev->usb_if->dev[dev->ctrl_idx] = dev;
+	/* publish dev to the decoders, after the ctrlmode copies above */
+	smp_store_release(&pdev->usb_if->dev[dev->ctrl_idx], dev);
 	dev->can_channel_id =
 		le32_to_cpu(pdev->usb_if->fw_info.dev_id[dev->ctrl_idx]);
 
@@ -1124,14 +1153,17 @@ static void pcan_usb_fd_exit(struct peak_usb_device *dev)
 	}
 }
 
-/* called when the USB adapter is unplugged */
+/* called when the USB adapter is unplugged, or when probing a sibling fails */
 static void pcan_usb_fd_free(struct peak_usb_device *dev)
 {
+	struct pcan_usb_fd_device *pdev =
+		container_of(dev, struct pcan_usb_fd_device, dev);
+
+	/* clear this channel's slot: dev is going to be freed */
+	WRITE_ONCE(pdev->usb_if->dev[dev->ctrl_idx], NULL);
+
 	/* last device: can free shared objects now */
 	if (!dev->prev_siblings && !dev->next_siblings) {
-		struct pcan_usb_fd_device *pdev =
-			container_of(dev, struct pcan_usb_fd_device, dev);
-
 		/* free commands buffer */
 		kfree(pdev->cmd_buffer_addr);
 

-- 
2.53.0

