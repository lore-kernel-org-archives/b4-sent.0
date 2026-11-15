From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:57:19 +0000
Subject: [PATCH v4 2/2] usb: hub: Retry SuperSpeed for a device stuck on
 its USB 2.0 peer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-usb-port-pairing-v4-2-25d3c9adcc21@gmail.com>
References: <20261115-usb-port-pairing-v4-0-25d3c9adcc21@gmail.com>
In-Reply-To: <20261115-usb-port-pairing-v4-0-25d3c9adcc21@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Rob Herring <robh@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794733037; l=7016;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=x/pl7VUYVHlXCr7FPF6ufBBZfBXL4EZGgC4W7auwWNo=;
 b=PzNmA+xnt1Q6ecY32F8qyFfy/5dLFatcPOUs2XnNFLyRCSEmuQfpsiA/C2L+CidGXFmlvcdTt
 a/71/2xw7EXBM+ijrPd9c/Cp9NQlBXmXLgx2hpbnlTQCawCYQRSqmUp
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A SuperSpeed device that finds no SuperSpeed link at power-up connects
at high speed and retries SuperSpeed only after a VBUS cycle or a USB
2.0 bus reset. With VBUS always on and the connector's halves on
different host controllers (Orange Pi 5 USB 3 Type-A port), a device
present at boot reaches the EHCI before the SuperSpeed-only xHCI is up
and stays at 480 Mb/s.

When such a SuperSpeed root hub starts, reset the USB 2.0 peer port of
a SuperSpeed-capable device once; hubs are skipped. A device that
appears on the SuperSpeed port within 1 s is disconnected from the USB
2.0 port. One that stays at high speed is restored with
usb_reset_device() and keeps its drivers bound (they don't see the
first reset).

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/core/hub.c | 132 +++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/hub.h |   1 +
 2 files changed, 133 insertions(+)

diff --git a/drivers/usb/core/hub.c b/drivers/usb/core/hub.c
index 199d3f535a89..b56ee90e55f0 100644
--- a/drivers/usb/core/hub.c
+++ b/drivers/usb/core/hub.c
@@ -144,6 +144,8 @@ EXPORT_SYMBOL_GPL(ehci_cf_port_reset_rwsem);
 
 static int usb_reset_and_verify_device(struct usb_device *udev);
 static int hub_port_disable(struct usb_hub *hub, int port1, int set_state);
+static void hub_queue_peer_reset(struct usb_hub *hub);
+static void hub_peer_reset_work(struct work_struct *ws);
 static bool hub_port_warm_reset_required(struct usb_hub *hub, int port1,
 		u16 portstatus);
 
@@ -1346,6 +1348,10 @@ static void hub_activate(struct usb_hub *hub, enum hub_activation_type type)
 
 	/* Scan all ports that need attention */
 	kick_hub_wq(hub);
+
+	if (!hdev->parent && hub_is_superspeed(hdev) &&
+	    (type == HUB_INIT2 || type == HUB_INIT3))
+		hub_queue_peer_reset(hub);
  abort:
 	if (type == HUB_INIT2 || type == HUB_INIT3) {
 		/* Allow autosuspend if it was suppressed */
@@ -1419,6 +1425,10 @@ static void hub_quiesce(struct usb_hub *hub, enum hub_quiescing_type type)
 	/* Stop hub_wq and related activity */
 	timer_delete_sync(&hub->irq_urb_retry);
 	flush_delayed_work(&hub->post_resume_work);
+	if (cancel_work_sync(&hub->peer_reset_work)) {
+		usb_autopm_put_interface_no_suspend(to_usb_interface(hub->intfdev));
+		hub_put(hub);
+	}
 	usb_kill_urb(hub->urb);
 	if (hub->has_indicators)
 		cancel_delayed_work_sync(&hub->leds);
@@ -1978,6 +1988,7 @@ static int hub_probe(struct usb_interface *intf, const struct usb_device_id *id)
 	INIT_DELAYED_WORK(&hub->leds, led_work);
 	INIT_DELAYED_WORK(&hub->init_work, NULL);
 	INIT_DELAYED_WORK(&hub->post_resume_work, hub_post_resume);
+	INIT_WORK(&hub->peer_reset_work, hub_peer_reset_work);
 	INIT_WORK(&hub->events, hub_event);
 	INIT_LIST_HEAD(&hub->onboard_devs);
 	spin_lock_init(&hub->irq_urb_lock);
@@ -3278,6 +3289,127 @@ static void usb_unlock_port(struct usb_port *port_dev)
 	__release(&port_dev->status_lock);
 }
 
+static void hub_reset_peer_child(struct usb_hub *hub, int port1,
+				 struct usb_device *peer_hdev, int peer_port1)
+{
+	struct usb_hub *peer_hub;
+	struct usb_device *udev;
+
+	usb_lock_device(peer_hdev);
+	if (hub->quiescing)
+		goto out;
+	peer_hub = usb_hub_to_struct_hub(peer_hdev);
+	if (!peer_hub || peer_port1 > peer_hdev->maxchild)
+		goto out;
+
+	udev = peer_hub->ports[peer_port1 - 1]->child;
+	if (!udev || udev->speed != USB_SPEED_HIGH)
+		goto out;
+
+	if (udev->descriptor.bDeviceClass == USB_CLASS_HUB)
+		goto out;
+
+	usb_lock_device(udev);
+	if (udev->state != USB_STATE_NOTATTACHED &&
+	    udev->bos && udev->bos->ss_cap &&
+	    usb_autoresume_device(udev) == 0) {
+		struct usb_port *port_dev = peer_hub->ports[peer_port1 - 1];
+		u16 portstatus, portchange;
+		int i, ret;
+
+		dev_info(&udev->dev,
+			 "SuperSpeed peer port available, resetting\n");
+		/* A second reset hands the EHCI port to its companion */
+		usb_lock_port(port_dev);
+		ret = hub_port_reset(peer_hub, peer_port1, NULL,
+				     HUB_ROOT_RESET_TIME, false);
+		for (i = 0; !ret && i < 20; i++) {
+			msleep(50);
+			ret = hub->quiescing ? -ENODEV :
+				usb_hub_port_status(hub, port1, &portstatus,
+						    &portchange);
+			if (!ret && (portstatus & USB_PORT_STAT_CONNECTION))
+				ret = -ENOTCONN;
+		}
+		if (ret)
+			hub_port_logical_disconnect(peer_hub, peer_port1);
+		/* Else hub_wq resets the port again */
+		for (i = 0; ret == -ENOTCONN && i < 20; i++) {
+			if (usb_hub_port_status(peer_hub, peer_port1, &portstatus,
+						&portchange) ||
+			    !(portstatus & USB_PORT_STAT_CONNECTION))
+				break;
+			msleep(50);
+		}
+		usb_unlock_port(port_dev);
+
+		if (!ret)
+			usb_reset_device(udev);
+		usb_autosuspend_device(udev);
+	}
+	usb_unlock_device(udev);
+out:
+	usb_unlock_device(peer_hdev);
+}
+
+static void hub_peer_reset_work(struct work_struct *ws)
+{
+	struct usb_hub *hub = container_of(ws, struct usb_hub, peer_reset_work);
+	struct usb_device *hdev = hub->hdev;
+	int port1;
+
+	for (port1 = 1; ; port1++) {
+		struct usb_device *peer_hdev = NULL;
+		struct usb_port *port_dev;
+		int peer_port1 = 0;
+
+		mutex_lock(&usb_port_peer_mutex);
+		if (port1 > hdev->maxchild || hub->quiescing) {
+			mutex_unlock(&usb_port_peer_mutex);
+			break;
+		}
+		port_dev = hub->ports[port1 - 1];
+		if (port_dev->connector_peer && port_dev->peer) {
+			peer_hdev = to_usb_device(port_dev->peer->dev.parent->parent);
+			peer_port1 = port_dev->peer->portnum;
+			if (peer_hdev->parent ||
+			    peer_hdev->bus->controller == hdev->bus->controller)
+				peer_hdev = NULL;
+			else
+				usb_get_dev(peer_hdev);
+		}
+		mutex_unlock(&usb_port_peer_mutex);
+
+		if (peer_hdev) {
+			hub_reset_peer_child(hub, port1, peer_hdev, peer_port1);
+			usb_put_dev(peer_hdev);
+		}
+	}
+
+	usb_autopm_put_interface_async(to_usb_interface(hub->intfdev));
+	hub_put(hub);
+}
+
+static void hub_queue_peer_reset(struct usb_hub *hub)
+{
+	struct usb_interface *intf = to_usb_interface(hub->intfdev);
+	int port1;
+
+	for (port1 = 1; port1 <= hub->hdev->maxchild; port1++) {
+		if (hub->ports[port1 - 1]->connector_peer)
+			break;
+	}
+	if (port1 > hub->hdev->maxchild)
+		return;
+
+	usb_autopm_get_interface_no_resume(intf);
+	hub_get(hub);
+	if (!queue_work(hub_wq, &hub->peer_reset_work)) {
+		usb_autopm_put_interface_async(intf);
+		hub_put(hub);
+	}
+}
+
 #ifdef	CONFIG_PM
 
 /* Check if a port is suspended(USB2.0 port) or in U3 state(USB3.0 port) */
diff --git a/drivers/usb/core/hub.h b/drivers/usb/core/hub.h
index ab80164b4b46..f6387b99c708 100644
--- a/drivers/usb/core/hub.h
+++ b/drivers/usb/core/hub.h
@@ -71,6 +71,7 @@ struct usb_hub {
 	struct delayed_work	leds;
 	struct delayed_work	init_work;
 	struct delayed_work	post_resume_work;
+	struct work_struct	peer_reset_work;
 	struct work_struct      events;
 	spinlock_t		irq_urb_lock;
 	struct timer_list	irq_urb_retry;

-- 
2.55.0

