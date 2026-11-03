From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Tue, 03 Nov 2026 13:30:23 +0100
Subject: [PATCH v8 07/14] can: peak_usb: register the netdevs only once all
 channels are set up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-canfd_check_channel_idx-v8-7-4e8b2c0a8806@peak-system.fr>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793709024; l=8119;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=wzAGLFhXXU/vNiSRj5UBCBL6x7232wbHfmhdj2xLAIE=;
 b=qyr+TDuVDT9RIYikKinctINYiPP6e0tKK8fBntP28sKEBzFCkSIDrSnX/mvY3VpWxSqmcjqbG
 Vj4k0m/7JfDCGWKPX1dIYHN7KWQValbyRGWsryE1bpiocOS39UFzHVc
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

peak_usb_create_dev() registers the netdev of a channel before calling
dev_init(), dev_set_bus() and dev_get_can_channel_id(). Userspace can
therefore open or configure the netdev while the channel is still being
initialized, outside of rtnl_lock():

- peak_usb_ndo_open() may run before dev_init() has set up the adapter
  private data, e.g. pdev->usb_if, which is then dereferenced while
  still NULL by pcan_usb_pro_start() or pcan_usb_fd_start();
- the commands sent by the open or bittiming callbacks may race with
  the ones sent by dev_init() on the same command buffer;
- dev_set_bus(dev, 0) may switch the controller off right after
  peak_usb_ndo_open() has started it.

On multi-channel adapters, the same applies to the channels already
created while a sibling is being initialized, since they share the
interface resources: on PCAN-USB Pro FD and PCAN-USB X6, the command
buffer and the firmware info used by the sibling init, and the
ctrlmode copied from the first channel.

Moreover, if dev_init() or dev_set_bus() fails, the adapter private
data is released before unregister_candev(), which closes the netdev
if it has been opened in the meantime, and then accesses the released
data (interface object and, on the CAN FD adapters, command buffer).

Register the netdevs in peak_usb_probe(), only once all the channels of
the interface have been initialized, and only unregister (and report as
removed) the registered ones in peak_usb_disconnect(). Since no netdev
is registered while the channels are being created, there is no RX to
stop anymore when creating a channel fails. If registering a netdev
fails, peak_usb_disconnect() still stops RX on the channels already
registered, which may have been opened in the meantime. Since the
channel id is now read before the netdev is registered, PCAN-USB reports
a failure to read it with dev_err() instead of netdev_err().

Fixes: bb4785551f64 ("can: usb: PEAK-System Technik USB adapters driver core")
Assisted-by: LLM
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb.c      |  7 ++-
 drivers/net/can/usb/peak_usb/pcan_usb_core.c | 68 +++++++++++++++++-----------
 drivers/net/can/usb/peak_usb/pcan_usb_core.h |  1 +
 3 files changed, 47 insertions(+), 29 deletions(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb.c b/drivers/net/can/usb/peak_usb/pcan_usb.c
index 90f69afcba97..451d08421504 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb.c
@@ -390,9 +390,12 @@ static int pcan_usb_get_can_channel_id(struct peak_usb_device *dev, u32 *can_ch_
 	int err;
 
 	err = pcan_usb_wait_rsp(dev, PCAN_USB_CMD_DEVID, PCAN_USB_GET, args);
+	/* explicit use of dev_xxx() instead of netdev_xxx() here: this is
+	 * also called during probe, before the netdev is registered.
+	 */
 	if (err)
-		netdev_err(dev->netdev, "getting can channel id failure: %d\n", err);
-
+		dev_err(dev->netdev->dev.parent,
+			"getting can channel id failure: %d\n", err);
 	else
 		*can_ch_id = args[0];
 
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_core.c b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
index f5c39b43b0fa..e5198ec5c760 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_core.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
@@ -1006,15 +1006,6 @@ static int peak_usb_create_dev(const struct peak_usb_adapter *peak_usb_adapter,
 	SET_NETDEV_DEV(netdev, &intf->dev);
 	netdev->dev_id = ctrl_idx;
 
-	err = register_candev(netdev);
-	if (err) {
-		dev_err(&intf->dev, "couldn't register CAN device: %d\n", err);
-		goto lbl_restore_intf_data;
-	}
-
-	if (dev->prev_siblings)
-		(dev->prev_siblings)->next_siblings = dev;
-
 	/* keep hw revision into the netdevice */
 	tmp16 = le16_to_cpu(usb_dev->descriptor.bcdDevice);
 	dev->device_rev = tmp16 >> 8;
@@ -1022,7 +1013,7 @@ static int peak_usb_create_dev(const struct peak_usb_adapter *peak_usb_adapter,
 	if (dev->adapter->dev_init) {
 		err = dev->adapter->dev_init(dev);
 		if (err)
-			goto lbl_unregister_candev;
+			goto lbl_restore_intf_data;
 	}
 
 	/* set bus off */
@@ -1035,25 +1026,15 @@ static int peak_usb_create_dev(const struct peak_usb_adapter *peak_usb_adapter,
 	/* get CAN channel id early */
 	dev->adapter->dev_get_can_channel_id(dev, &dev->can_channel_id);
 
-	netdev_info(netdev, "attached to %s channel %u (device 0x%08X)\n",
-		    peak_usb_adapter->name, ctrl_idx, dev->can_channel_id);
+	if (dev->prev_siblings)
+		(dev->prev_siblings)->next_siblings = dev;
 
 	return 0;
 
 adap_dev_free:
-	/* the whole interface is released when probing a channel fails:
-	 * stop RX on this channel, which may already be open, and on the
-	 * channels already created, since their RX URBs may carry records
-	 * for this one.
-	 */
-	peak_usb_stop_rx(dev);
-
 	if (dev->adapter->dev_free)
 		dev->adapter->dev_free(dev);
 
-lbl_unregister_candev:
-	unregister_candev(netdev);
-
 lbl_restore_intf_data:
 	usb_set_intfdata(intf, dev->prev_siblings);
 	kfree(dev->cmd_buf);
@@ -1078,11 +1059,15 @@ static void peak_usb_disconnect(struct usb_interface *intf)
 	for (dev = usb_get_intfdata(intf); dev; dev = dev_prev_siblings) {
 		struct net_device *netdev = dev->netdev;
 		char name[IFNAMSIZ];
+		bool registered;
 
 		dev_prev_siblings = dev->prev_siblings;
 		strscpy(name, netdev->name, IFNAMSIZ);
 
-		unregister_candev(netdev);
+		/* on probe error, some netdevs may not be registered yet */
+		registered = test_bit(PCAN_USB_STATE_REGISTERED, &dev->state);
+		if (registered)
+			unregister_candev(netdev);
 
 		kfree(dev->cmd_buf);
 		dev->next_siblings = NULL;
@@ -1090,7 +1075,8 @@ static void peak_usb_disconnect(struct usb_interface *intf)
 			dev->adapter->dev_free(dev);
 
 		free_candev(netdev);
-		dev_info(&intf->dev, "%s removed\n", name);
+		if (registered)
+			dev_info(&intf->dev, "%s removed\n", name);
 	}
 
 	usb_set_intfdata(intf, NULL);
@@ -1103,6 +1089,7 @@ static int peak_usb_probe(struct usb_interface *intf,
 			  const struct usb_device_id *id)
 {
 	const struct peak_usb_adapter *peak_usb_adapter;
+	struct peak_usb_device *dev;
 	int i, err = -ENOMEM;
 
 	/* get corresponding PCAN-USB adapter */
@@ -1117,13 +1104,40 @@ static int peak_usb_probe(struct usb_interface *intf,
 
 	for (i = 0; i < peak_usb_adapter->ctrl_count; i++) {
 		err = peak_usb_create_dev(peak_usb_adapter, intf, i);
+		if (err)
+			goto lbl_disconnect;
+	}
+
+	/* register the netdevs only once all the channels are set up: the
+	 * channels of an interface share resources (command buffer, firmware
+	 * info, ctrlmode copied from the 1st channel...) that must not be
+	 * used through a netdev while a sibling is being initialized.
+	 */
+	for (dev = usb_get_intfdata(intf); dev->prev_siblings;
+	     dev = dev->prev_siblings)
+		;
+
+	for (; dev; dev = dev->next_siblings) {
+		err = register_candev(dev->netdev);
 		if (err) {
-			/* deregister already created devices */
-			peak_usb_disconnect(intf);
-			break;
+			dev_err(&intf->dev, "couldn't register CAN device: %d\n",
+				err);
+			goto lbl_disconnect;
 		}
+		set_bit(PCAN_USB_STATE_REGISTERED, &dev->state);
+
+		netdev_info(dev->netdev,
+			    "attached to %s channel %u (device 0x%08X)\n",
+			    peak_usb_adapter->name, dev->ctrl_idx,
+			    dev->can_channel_id);
 	}
 
+	return 0;
+
+lbl_disconnect:
+	/* unregister (if needed) and free already created devices */
+	peak_usb_disconnect(intf);
+
 	return err;
 }
 
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_core.h b/drivers/net/can/usb/peak_usb/pcan_usb_core.h
index 234d20f81154..bed2b3c70f82 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_core.h
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_core.h
@@ -108,6 +108,7 @@ struct peak_tx_urb_context {
  */
 #define PCAN_USB_STATE_CONNECTED	0
 #define PCAN_USB_STATE_STARTED		1
+#define PCAN_USB_STATE_REGISTERED	2
 
 /* PEAK-System USB device */
 struct peak_usb_device {

-- 
2.53.0

