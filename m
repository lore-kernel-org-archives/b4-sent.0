From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 10:03:25 +0000
Subject: [PATCH v6 3/3] usb: hub: Retry SuperSpeed for a device stuck on
 its USB 2.0 peer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-usb-port-pairing-v6-3-32bd7e36e426@gmail.com>
References: <20261119-usb-port-pairing-v6-0-32bd7e36e426@gmail.com>
In-Reply-To: <20261119-usb-port-pairing-v6-0-32bd7e36e426@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Rob Herring <robh@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795082602; l=8610;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=d47nNsAzhvRam4BdchKKGLM7aOoXnMSuKEo35+H2g20=;
 b=m+Laz/p0oKpO61I9TTuTU1u3bOb6xbWpugS9AAxSFWNL4Ix4YkOpDn/zbPfGaqMLDUUlb3Bva
 9nPh78DsDbBA5WXLVnxxL+tBx6F5lFuqjgkn8yiZIf6MomfPFGnVLdk
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With VBUS always on, a USB 3 device present at boot connects to the EHCI
before the SuperSpeed-only xHCI is up, and stays at 480 Mb/s until a USB
2.0 bus reset.

When such a SuperSpeed root hub starts, reset the USB 2.0 peer port of a
SuperSpeed-capable device (not a hub) once with usb_reset_device(). If
the device appears on the SuperSpeed port within 1 s, the USB 2.0 device
is disconnected; otherwise the reset completes at high speed.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/core/hub.c | 158 +++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/hub.h |   3 +
 2 files changed, 161 insertions(+)

diff --git a/drivers/usb/core/hub.c b/drivers/usb/core/hub.c
index 199d3f535a89..65d0728d4330 100644
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
@@ -3278,6 +3289,116 @@ static void usb_unlock_port(struct usb_port *port_dev)
 	__release(&port_dev->status_lock);
 }
 
+static void hub_reset_peer_child(struct usb_hub *hub, int port1,
+				 struct usb_device *peer_hdev, int peer_port1)
+{
+	struct usb_port *ss_port = hub->ports[port1 - 1];
+	struct usb_port *port_dev;
+	struct usb_hub *peer_hub;
+	struct usb_device *udev;
+	u16 portstatus, portchange;
+
+	/* Keep hub_wq off the SuperSpeed port until the USB 2.0 device is gone */
+	mutex_lock_nested(&ss_port->status_lock, SINGLE_DEPTH_NESTING);
+	usb_lock_device(peer_hdev);
+	if (hub->quiescing)
+		goto out;
+	peer_hub = usb_hub_to_struct_hub(peer_hdev);
+	if (!peer_hub || peer_port1 > peer_hdev->maxchild)
+		goto out;
+
+	port_dev = peer_hub->ports[peer_port1 - 1];
+	udev = port_dev->child;
+	if (!udev || udev->speed != USB_SPEED_HIGH ||
+	    udev->descriptor.bDeviceClass == USB_CLASS_HUB)
+		goto out;
+
+	if (usb_hub_port_status(hub, port1, &portstatus, &portchange) ||
+	    (portstatus & USB_PORT_STAT_CONNECTION))
+		goto out;
+
+	usb_lock_device(udev);
+	if (udev->state != USB_STATE_NOTATTACHED &&
+	    udev->bos && udev->bos->ss_cap) {
+		dev_info(&udev->dev,
+			 "SuperSpeed peer port available, resetting\n");
+		port_dev->ss_retry = ss_port;
+		usb_reset_device(udev);
+		port_dev->ss_retry = NULL;
+	}
+	usb_unlock_device(udev);
+
+	/* As hub_port_connect() would */
+	if (udev->state == USB_STATE_NOTATTACHED) {
+		struct usb_hcd *hcd = bus_to_hcd(peer_hdev->bus);
+
+		if (hcd->usb_phy)
+			usb_phy_notify_disconnect(hcd->usb_phy, udev->speed);
+		usb_disconnect(&port_dev->child);
+	}
+out:
+	usb_unlock_device(peer_hdev);
+	mutex_unlock(&ss_port->status_lock);
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
@@ -4899,6 +5020,37 @@ static int get_bMaxPacketSize0(struct usb_device *udev,
 
 #define GET_DESCRIPTOR_BUFSIZE	64
 
+/* -ENOTCONN if the device moved to its SuperSpeed peer port */
+static int hub_wait_ss_retry(struct usb_hub *hub, int port1,
+			     struct usb_port *ss_port)
+{
+	struct usb_device *ss_hdev = to_usb_device(ss_port->dev.parent->parent);
+	struct usb_hub *ss_hub = usb_hub_to_struct_hub(ss_hdev);
+	u16 portstatus, portchange;
+	int i;
+
+	for (i = 0; i < 20; i++) {
+		msleep(50);
+		if (!ss_hub ||
+		    usb_hub_port_status(ss_hub, ss_port->portnum, &portstatus,
+					&portchange))
+			return 0;
+		if (portstatus & USB_PORT_STAT_CONNECTION)
+			break;
+	}
+	if (i == 20)
+		return 0;
+
+	/* Else hub_wq resets the port again */
+	for (i = 0; i < 20; i++) {
+		if (usb_hub_port_status(hub, port1, &portstatus, &portchange) ||
+		    !(portstatus & USB_PORT_STAT_CONNECTION))
+			break;
+		msleep(50);
+	}
+	return -ENOTCONN;
+}
+
 /* Reset device, (re)assign address, get device descriptor.
  * Device connection must be stable, no more debouncing needed.
  * Returns device in USB_STATE_ADDRESS, except on error.
@@ -4959,6 +5111,12 @@ hub_port_init(struct usb_hub *hub, struct usb_device *udev, int port1,
 		goto fail;
 	/* success, speed is known */
 
+	if (port_dev->ss_retry) {
+		retval = hub_wait_ss_retry(hub, port1, port_dev->ss_retry);
+		if (retval)
+			goto fail;
+	}
+
 	retval = -ENODEV;
 
 	/* Don't allow speed changes at reset, except usb 3.0 to faster */
diff --git a/drivers/usb/core/hub.h b/drivers/usb/core/hub.h
index ab80164b4b46..70241024e169 100644
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
@@ -98,12 +99,14 @@ struct usb_hub {
  * @early_stop: whether port initialization will be stopped earlier.
  * @ignore_event: whether events of the port are ignored.
  * @connector_peer: peer found through a connector.
+ * @ss_retry: SuperSpeed port a device may move to on reset.
  */
 struct usb_port {
 	struct usb_device *child;
 	struct device dev;
 	struct usb_dev_state *port_owner;
 	struct usb_port *peer;
+	struct usb_port *ss_retry;
 	struct typec_connector *connector;
 	struct dev_pm_qos_request *req;
 	enum usb_port_connect_type connect_type;

-- 
2.55.0

