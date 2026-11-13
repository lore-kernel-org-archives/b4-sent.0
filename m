From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:39:35 +0000
Subject: [PATCH v3 2/2] usb: hub: Retry SuperSpeed for a device stuck on
 its USB 2.0 peer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-usb-port-pairing-v3-2-d6c6edb4341c@gmail.com>
References: <20261113-usb-port-pairing-v3-0-d6c6edb4341c@gmail.com>
In-Reply-To: <20261113-usb-port-pairing-v3-0-d6c6edb4341c@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587973; l=6207;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=KZkpXeJ+A+10K+SJK6nZ9OKWG0+DhiLSkdGEp7dOl5Q=;
 b=yw9V659rAr6/ZIYNNftVxkesa9H4cYunzIo/YouNAGbb7e+IVglEYnnsl4BQphSttUDkDAYbT
 LbQnVEAopmWB6xFvG5ON82n3jAzISNbXEshVGquw37jhum9qhUe13cr
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A SuperSpeed device that finds no SuperSpeed link at power-up connects at
high speed, and tries SuperSpeed again only after a VBUS cycle or a USB
2.0 bus reset. When a connector's two halves are on different host
controllers and VBUS is always on, as on the Orange Pi 5 USB 3 Type-A
port, a device present at boot connects to the EHCI before the
SuperSpeed-only xHCI is up and stays at 480 Mb/s.

When such a SuperSpeed root hub starts, reset once a SuperSpeed-capable
device that sits at high speed on a USB 2.0 peer port. Hubs are skipped:
the USB 2.0 half of a USB 3 hub stays at high speed. Resume and reset of
the root hub don't do this; a device suspended with the system can't be
reset.

The device leaves the USB 2.0 port, so whatever uses it by then (a
mounted disk) sees a disconnect.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/core/hub.c | 109 +++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/hub.h |   1 +
 2 files changed, 110 insertions(+)

diff --git a/drivers/usb/core/hub.c b/drivers/usb/core/hub.c
index 199d3f535a89..6bbe5fe2c0b5 100644
--- a/drivers/usb/core/hub.c
+++ b/drivers/usb/core/hub.c
@@ -1076,6 +1076,105 @@ int usb_remove_device(struct usb_device *udev)
 	return 0;
 }
 
+/*
+ * A device present at boot may have connected at high speed to the USB 2.0
+ * peer before this SuperSpeed root hub was up; a USB 2.0 reset makes it retry.
+ */
+static void hub_reset_peer_child(struct usb_device *peer_hdev, int peer_port1)
+{
+	struct usb_hub *peer_hub;
+	struct usb_device *udev;
+
+	/* Wait for an enumeration in progress on the peer port to finish */
+	usb_lock_device(peer_hdev);
+	peer_hub = usb_hub_to_struct_hub(peer_hdev);
+	if (!peer_hub || peer_port1 > peer_hdev->maxchild)
+		goto out;
+
+	udev = peer_hub->ports[peer_port1 - 1]->child;
+	if (!udev || udev->speed != USB_SPEED_HIGH)
+		goto out;
+
+	/*
+	 * The USB 2.0 half of a USB 3 hub stays at high speed next to its
+	 * SuperSpeed half, and resetting it would disconnect its children.
+	 */
+	if (udev->descriptor.bDeviceClass == USB_CLASS_HUB)
+		goto out;
+
+	usb_lock_device(udev);
+	if (udev->state != USB_STATE_NOTATTACHED &&
+	    udev->bos && udev->bos->ss_cap) {
+		dev_info(&udev->dev,
+			 "SuperSpeed peer port available, resetting\n");
+		usb_reset_device(udev);
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
+		if (port1 > hdev->maxchild) {
+			mutex_unlock(&usb_port_peer_mutex);
+			break;
+		}
+		port_dev = hub->ports[port1 - 1];
+		if (port_dev->connector_peer && port_dev->peer) {
+			peer_hdev = to_usb_device(port_dev->peer->dev.parent->parent);
+			peer_port1 = port_dev->peer->portnum;
+			/* Only root hub ports of another host controller */
+			if (peer_hdev->parent ||
+			    peer_hdev->bus->controller == hdev->bus->controller)
+				peer_hdev = NULL;
+			else
+				usb_get_dev(peer_hdev);
+		}
+		mutex_unlock(&usb_port_peer_mutex);
+
+		if (peer_hdev) {
+			hub_reset_peer_child(peer_hdev, peer_port1);
+			usb_put_dev(peer_hdev);
+		}
+	}
+
+	usb_autopm_put_interface_async(to_usb_interface(hub->intfdev));
+	hub_put(hub);
+}
+
+/* Called when a SuperSpeed root hub has started */
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
+	/* Keep the hub active until the work is done; hub_quiesce() cancels it */
+	usb_autopm_get_interface_no_resume(intf);
+	hub_get(hub);
+	if (!queue_work(hub_wq, &hub->peer_reset_work)) {
+		usb_autopm_put_interface_async(intf);
+		hub_put(hub);
+	}
+}
+
 enum hub_activation_type {
 	HUB_INIT, HUB_INIT2, HUB_INIT3,		/* INITs must come first */
 	HUB_POST_RESET, HUB_RESUME, HUB_RESET_RESUME,
@@ -1346,6 +1445,11 @@ static void hub_activate(struct usb_hub *hub, enum hub_activation_type type)
 
 	/* Scan all ports that need attention */
 	kick_hub_wq(hub);
+
+	/* Let devices stuck at high speed on a connector peer move over */
+	if (!hdev->parent && hub_is_superspeed(hdev) &&
+	    (type == HUB_INIT2 || type == HUB_INIT3))
+		hub_queue_peer_reset(hub);
  abort:
 	if (type == HUB_INIT2 || type == HUB_INIT3) {
 		/* Allow autosuspend if it was suppressed */
@@ -1419,6 +1523,10 @@ static void hub_quiesce(struct usb_hub *hub, enum hub_quiescing_type type)
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
@@ -1978,6 +2086,7 @@ static int hub_probe(struct usb_interface *intf, const struct usb_device_id *id)
 	INIT_DELAYED_WORK(&hub->leds, led_work);
 	INIT_DELAYED_WORK(&hub->init_work, NULL);
 	INIT_DELAYED_WORK(&hub->post_resume_work, hub_post_resume);
+	INIT_WORK(&hub->peer_reset_work, hub_peer_reset_work);
 	INIT_WORK(&hub->events, hub_event);
 	INIT_LIST_HEAD(&hub->onboard_devs);
 	spin_lock_init(&hub->irq_urb_lock);
diff --git a/drivers/usb/core/hub.h b/drivers/usb/core/hub.h
index 6b55216c7da0..1dccfd5ea4ae 100644
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

