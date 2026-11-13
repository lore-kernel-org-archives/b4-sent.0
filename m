From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:39:34 +0000
Subject: [PATCH v3 1/2] usb: core: Pair ports of different hubs through
 their connector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-usb-port-pairing-v3-1-d6c6edb4341c@gmail.com>
References: <20261113-usb-port-pairing-v3-0-d6c6edb4341c@gmail.com>
In-Reply-To: <20261113-usb-port-pairing-v3-0-d6c6edb4341c@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794587973; l=9572;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=sbuAYiPAT5lKGtgYSFiTntfB+mIyzcPYe62fONSyJck=;
 b=V7L20a5FjJnbNChjcmibGDcnHnemKQVc4cwWdmlrYwftAAzzm8yQU69S2OQTN5b1/5G4iAw6F
 9LUBFoxbntNBRVX+5WBwJvgJyrynpoqzAqnSZQq1CsFIFgbL/nMQMmd
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The USB core pairs the USB 2.0 and SuperSpeed ports of a USB 3 connector
by port number within one xHCI, or by ACPI location. On the RK3588, USB
3.0 host 2 is SuperSpeed-only and the connector's USB 2.0 lines go to a
separate EHCI: the SuperSpeed port is paired with a dead USB 2.0 port and
the EHCI port has no peer.

A usb-connector has its USB 2.0 lines on graph port 0 and its SuperSpeed
lanes on graph port 1. When the two lead to different hubs or host
controllers, pair the two ports through the connector. Root hub ports are
found in the graph by the controller's port number, as in ACPI.

This also applies the peer runtime PM rules to such connectors.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/core/hub.h  |  2 +
 drivers/usb/core/of.c   | 98 +++++++++++++++++++++++++++++++++++++++++++++++++
 drivers/usb/core/port.c | 67 +++++++++++++++++++++++++++++++--
 include/linux/usb/of.h  |  8 ++++
 4 files changed, 171 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/core/hub.h b/drivers/usb/core/hub.h
index 9ebc5ef54a32..6b55216c7da0 100644
--- a/drivers/usb/core/hub.h
+++ b/drivers/usb/core/hub.h
@@ -97,6 +97,7 @@ struct usb_hub {
  * @usb3_lpm_u2_permit: whether USB3 U2 LPM is permitted.
  * @early_stop: whether port initialization will be stopped earlier.
  * @ignore_event: whether events of the port are ignored.
+ * @connector_peer: the peer is chosen by a connector, not by port number.
  */
 struct usb_port {
 	struct usb_device *child;
@@ -118,6 +119,7 @@ struct usb_port {
 	unsigned int is_superspeed:1;
 	unsigned int usb3_lpm_u1_permit:1;
 	unsigned int usb3_lpm_u2_permit:1;
+	unsigned int connector_peer:1;
 };
 
 #define to_usb_port(_dev) \
diff --git a/drivers/usb/core/of.c b/drivers/usb/core/of.c
index a6ee20d8774e..1b26d2083525 100644
--- a/drivers/usb/core/of.c
+++ b/drivers/usb/core/of.c
@@ -145,6 +145,104 @@ enum usb_port_connect_type usb_of_get_connect_type(struct usb_device *hub, int p
 }
 EXPORT_SYMBOL_GPL(usb_of_get_connect_type);
 
+static bool usb_of_is_connector(const struct device_node *np)
+{
+	return of_device_is_compatible(np, "usb-a-connector") ||
+	       of_device_is_compatible(np, "usb-b-connector") ||
+	       of_device_is_compatible(np, "usb-c-connector");
+}
+
+/*
+ * Return the node owning the far end of @con's endpoint on @con_port, and in
+ * @port the graph port of that end.
+ */
+static struct device_node *usb_of_connector_remote(struct device_node *con,
+						   u32 con_port, u32 *port)
+{
+	struct device_node *ep, *remote;
+	struct of_endpoint endpoint;
+
+	ep = of_graph_get_endpoint_by_regs(con, con_port, -1);
+	if (!ep)
+		return NULL;
+
+	remote = of_graph_get_remote_endpoint(ep);
+	of_node_put(ep);
+	if (!remote)
+		return NULL;
+
+	if (of_graph_parse_endpoint(remote, &endpoint)) {
+		of_node_put(remote);
+		return NULL;
+	}
+	*port = endpoint.port;
+
+	ep = remote;
+	remote = of_graph_get_port_parent(ep);
+	of_node_put(ep);
+
+	return remote;
+}
+
+/**
+ * usb_of_get_connector_peer() - find a port's peer through its connector
+ * @hub: hub to which the port belongs
+ * @port: graph port of the port: the controller's port number on a root hub,
+ *	  else the hub port number
+ * @superspeed: whether @hub is a SuperSpeed hub
+ * @peer_port: returns the graph port of the peer
+ *
+ * A USB connector has its USB 2.0 lines on graph port 0 and its SuperSpeed
+ * lanes on graph port 1. Some SoCs route the two to different host
+ * controllers; the two ports can then only be paired through the connector.
+ *
+ * Return: the node of the hub or host controller with the peer port, with its
+ * refcount incremented, if @port is the @superspeed half of a connector whose
+ * other half leads to a different node. NULL otherwise.
+ */
+struct device_node *usb_of_get_connector_peer(struct usb_device *hub, u32 port,
+					      bool superspeed, u32 *peer_port)
+{
+	struct device_node *np = hub->dev.of_node;
+	struct device_node *ep, *con, *remote, *peer = NULL;
+	u32 remote_port;
+
+	if (!np || !of_graph_is_present(np))
+		return NULL;
+
+	ep = of_graph_get_endpoint_by_regs(np, port, -1);
+	if (!ep)
+		return NULL;
+
+	con = of_graph_get_remote_port_parent(ep);
+	of_node_put(ep);
+	if (!con)
+		return NULL;
+
+	if (!usb_of_is_connector(con) || !of_device_is_available(con))
+		goto out;
+
+	/* The connector's half for our speed must lead back to this port */
+	remote = usb_of_connector_remote(con, superspeed ? 1 : 0, &remote_port);
+	if (!remote)
+		goto out;
+	of_node_put(remote);
+	if (remote != np || remote_port != port)
+		goto out;
+
+	/* Peers on the same node are paired without the connector's help */
+	peer = usb_of_connector_remote(con, superspeed ? 0 : 1, peer_port);
+	if (peer && (peer == np || !*peer_port ||
+		     !of_device_is_available(peer))) {
+		of_node_put(peer);
+		peer = NULL;
+	}
+out:
+	of_node_put(con);
+	return peer;
+}
+EXPORT_SYMBOL_GPL(usb_of_get_connector_peer);
+
 /**
  * usb_of_get_interface_node() - get a USB interface node
  * @udev: USB device of interface
diff --git a/drivers/usb/core/port.c b/drivers/usb/core/port.c
index b4452b665f59..6a65dc6f14e7 100644
--- a/drivers/usb/core/port.c
+++ b/drivers/usb/core/port.c
@@ -649,10 +649,52 @@ static int match_location(struct usb_device *peer_hdev, void *p)
 	return 0;
 }
 
+/* Root hub graph ports use the controller's port number, as in ACPI */
+static u32 usb_port_graph_id(struct usb_device *hdev, int port1)
+{
+	if (hdev->parent)
+		return port1;
+	return usb_hcd_find_raw_port_number(bus_to_hcd(hdev->bus), port1);
+}
+
+struct usb_connector_peer {
+	struct usb_port *port_dev;
+	struct device_node *np;
+	u32 port;
+};
+
+/* Link the port to @peer_hdev's port at graph port cp->port, if it has one */
+static int match_connector_peer(struct usb_device *peer_hdev, void *p)
+{
+	struct usb_connector_peer *cp = p;
+	struct usb_hub *peer_hub = usb_hub_to_struct_hub(peer_hdev);
+	struct usb_port *peer;
+	int port1;
+
+	if (!peer_hub || peer_hdev->dev.of_node != cp->np ||
+	    hub_is_superspeed(peer_hdev) == cp->port_dev->is_superspeed)
+		return 0;
+
+	for (port1 = 1; port1 <= peer_hdev->maxchild; port1++) {
+		if (usb_port_graph_id(peer_hdev, port1) == cp->port)
+			break;
+	}
+	if (port1 > peer_hdev->maxchild)
+		return 0;
+
+	/* No connect_type check: the connector shows the port is used */
+	peer = peer_hub->ports[port1 - 1];
+	if (!peer)
+		return 0;
+
+	link_peers_report(cp->port_dev, peer);
+	return 1; /* done */
+}
+
 /*
  * Find the peer port either via explicit platform firmware "location"
- * data, the peer hcd for root hubs, or the upstream peer relationship
- * for all other hubs.
+ * data, a connector described in the device tree, the peer hcd for root
+ * hubs, or the upstream peer relationship for all other hubs.
  */
 static void find_and_link_peer(struct usb_hub *hub, int port1)
 {
@@ -660,6 +702,7 @@ static void find_and_link_peer(struct usb_hub *hub, int port1)
 	struct usb_device *hdev = hub->hdev;
 	struct usb_device *peer_hdev;
 	struct usb_hub *peer_hub;
+	struct usb_connector_peer cp;
 
 	/*
 	 * If location data is available then we can only peer this port
@@ -671,7 +714,23 @@ static void find_and_link_peer(struct usb_hub *hub, int port1)
 		/* we link the peer in match_location() if found */
 		usb_for_each_dev(port_dev, match_location);
 		return;
-	} else if (!hdev->parent) {
+	}
+
+	/*
+	 * If a connector routes the two halves of this port to different
+	 * hubs or host controllers, the connector alone decides the peer.
+	 */
+	cp.np = usb_of_get_connector_peer(hdev, usb_port_graph_id(hdev, port1),
+					  port_dev->is_superspeed, &cp.port);
+	if (cp.np) {
+		cp.port_dev = port_dev;
+		port_dev->connector_peer = 1;
+		usb_for_each_dev(&cp, match_connector_peer);
+		of_node_put(cp.np);
+		return;
+	}
+
+	if (!hdev->parent) {
 		struct usb_hcd *hcd = bus_to_hcd(hdev->bus);
 		struct usb_hcd *peer_hcd = hcd->shared_hcd;
 
@@ -703,7 +762,7 @@ static void find_and_link_peer(struct usb_hub *hub, int port1)
 	 * does not have location data
 	 */
 	peer = peer_hub->ports[port1 - 1];
-	if (peer && peer->location == 0)
+	if (peer && peer->location == 0 && !peer->connector_peer)
 		link_peers_report(port_dev, peer);
 }
 
diff --git a/include/linux/usb/of.h b/include/linux/usb/of.h
index de42f14bd280..4be581bd2758 100644
--- a/include/linux/usb/of.h
+++ b/include/linux/usb/of.h
@@ -20,6 +20,8 @@ int of_usb_update_otg_caps(struct device_node *np,
 			struct usb_otg_caps *otg_caps);
 enum usb_port_connect_type usb_of_get_connect_type(struct usb_device *hub, int port1);
 struct device_node *usb_of_get_device_node(struct usb_device *hub, int port1);
+struct device_node *usb_of_get_connector_peer(struct usb_device *hub, u32 port,
+					      bool superspeed, u32 *peer_port);
 bool usb_of_has_combined_node(struct usb_device *udev);
 struct device_node *usb_of_get_interface_node(struct usb_device *udev,
 		u8 config, u8 ifnum);
@@ -49,6 +51,12 @@ usb_of_get_device_node(struct usb_device *hub, int port1)
 {
 	return NULL;
 }
+static inline struct device_node *
+usb_of_get_connector_peer(struct usb_device *hub, u32 port, bool superspeed,
+			  u32 *peer_port)
+{
+	return NULL;
+}
 static inline bool usb_of_has_combined_node(struct usb_device *udev)
 {
 	return false;

-- 
2.55.0

