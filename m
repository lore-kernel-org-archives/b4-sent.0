From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 10:03:24 +0000
Subject: [PATCH v6 2/3] usb: core: Prefer the graph for a dwc3 SuperSpeed
 port's connect_type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-usb-port-pairing-v6-2-32bd7e36e426@gmail.com>
References: <20261119-usb-port-pairing-v6-0-32bd7e36e426@gmail.com>
In-Reply-To: <20261119-usb-port-pairing-v6-0-32bd7e36e426@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Alan Stern <stern@rowland.harvard.edu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mathias Nyman <mathias.nyman@intel.com>, Chen-Yu Tsai <wenst@chromium.org>, 
 Rob Herring <robh@kernel.org>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795082602; l=5240;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=KsWtuLjWwsm/3S5b9Wgk8+L57380sZNHdrIzJU6t3W8=;
 b=QzujBTqJRDwZncyjvg1KFzQi54QwpLQgf68LE08txdEMyaex74DgOdxWmKKrzz3pUg2C1E1zo
 RAWRXVGs3hoDCd/7oO0K4JzwlDhN6jxbXg6CIZqpqSUktyB+yrdrA9Z
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A SuperSpeed root port not found by its controller port number gets the
connect_type of its root hub port number, as before this series. On a
dwc3 that is 1, and a child node with reg 1 is the USB 2.0 device there,
so a SuperSpeed port with port@1 to a connector reads "hardwired", and
its devices are "fixed" and authorized as internal.

In that fallback, port@1 leading to an available node means "hotplug".
This changes rk3576-lckfb-tspi-3m and sc7180-ecs-liva-qc710.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/usb/core/of.c   | 51 +++++++++++++++++++++++++++++++++----------------
 drivers/usb/core/port.c |  6 ++++--
 include/linux/usb/of.h  |  5 +++++
 3 files changed, 44 insertions(+), 18 deletions(-)

diff --git a/drivers/usb/core/of.c b/drivers/usb/core/of.c
index eebfc9cd0c88..5596936c5605 100644
--- a/drivers/usb/core/of.c
+++ b/drivers/usb/core/of.c
@@ -90,6 +90,38 @@ static bool usb_of_has_devices_or_graph(const struct usb_device *hub)
 	return false;
 }
 
+/**
+ * usb_of_port_is_hotplug() - check for a hotplug port in the OF graph
+ * @hub: hub to which port is for @port1
+ * @port1: graph port of the port
+ *
+ * Hotplug ports are connected to an available remote node, e.g.
+ * usb-a-connector compatible node, in the OF graph.
+ *
+ * Return: true if @port1 leads to an available node in the graph.
+ */
+bool usb_of_port_is_hotplug(struct usb_device *hub, int port1)
+{
+	struct device_node *np = hub->dev.of_node;
+	struct device_node *ep, *remote_np;
+	bool ret;
+
+	if (!of_graph_is_present(np))
+		return false;
+
+	ep = of_graph_get_endpoint_by_regs(np, port1, -1);
+	if (!ep)
+		return false;
+
+	remote_np = of_graph_get_remote_port_parent(ep);
+	of_node_put(ep);
+	ret = of_device_is_available(remote_np);
+	of_node_put(remote_np);
+
+	return ret;
+}
+EXPORT_SYMBOL_GPL(usb_of_port_is_hotplug);
+
 /**
  * usb_of_get_connect_type() - get a USB hub's port connect_type
  * @hub: hub to which port is for @port1
@@ -106,7 +138,7 @@ static bool usb_of_has_devices_or_graph(const struct usb_device *hub)
  */
 enum usb_port_connect_type usb_of_get_connect_type(struct usb_device *hub, int port1)
 {
-	struct device_node *np, *child, *ep, *remote_np;
+	struct device_node *child;
 	enum usb_port_connect_type connect_type;
 
 	/* Only set connect_type if binding has ports/hardwired devices. */
@@ -116,21 +148,8 @@ enum usb_port_connect_type usb_of_get_connect_type(struct usb_device *hub, int p
 	/* Assume port is unused if there's a graph or a child node. */
 	connect_type = USB_PORT_NOT_USED;
 
-	np = hub->dev.of_node;
-	/*
-	 * Hotplug ports are connected to an available remote node, e.g.
-	 * usb-a-connector compatible node, in the OF graph.
-	 */
-	if (of_graph_is_present(np)) {
-		ep = of_graph_get_endpoint_by_regs(np, port1, -1);
-		if (ep) {
-			remote_np = of_graph_get_remote_port_parent(ep);
-			of_node_put(ep);
-			if (of_device_is_available(remote_np))
-				connect_type = USB_PORT_CONNECT_TYPE_HOT_PLUG;
-			of_node_put(remote_np);
-		}
-	}
+	if (usb_of_port_is_hotplug(hub, port1))
+		connect_type = USB_PORT_CONNECT_TYPE_HOT_PLUG;
 
 	/*
 	 * Hard-wired ports are child nodes with a reg property corresponding
diff --git a/drivers/usb/core/port.c b/drivers/usb/core/port.c
index 154f6bfc0805..2cb23fa9f75f 100644
--- a/drivers/usb/core/port.c
+++ b/drivers/usb/core/port.c
@@ -836,9 +836,11 @@ int usb_hub_create_port_device(struct usb_hub *hub, int port1)
 
 	graph_id = usb_port_graph_id(hdev, port1);
 	port_dev->connect_type = usb_of_get_connect_type(hdev, graph_id);
-	/* dwc3 graphs give the SuperSpeed port port@1 */
+	/* dwc3: port@1 is the SuperSpeed port, child reg 1 the USB 2.0 one */
 	if (port_dev->connect_type == USB_PORT_NOT_USED && graph_id != port1)
-		port_dev->connect_type = usb_of_get_connect_type(hdev, port1);
+		port_dev->connect_type = usb_of_port_is_hotplug(hdev, port1) ?
+					 USB_PORT_CONNECT_TYPE_HOT_PLUG :
+					 usb_of_get_connect_type(hdev, port1);
 	hub->ports[port1 - 1] = port_dev;
 	port_dev->portnum = port1;
 	set_bit(port1, hub->power_bits);
diff --git a/include/linux/usb/of.h b/include/linux/usb/of.h
index 4be581bd2758..6de8029749b4 100644
--- a/include/linux/usb/of.h
+++ b/include/linux/usb/of.h
@@ -18,6 +18,7 @@ enum usb_dr_mode of_usb_get_dr_mode_by_phy(struct device_node *np, int arg0);
 bool of_usb_host_tpl_support(struct device_node *np);
 int of_usb_update_otg_caps(struct device_node *np,
 			struct usb_otg_caps *otg_caps);
+bool usb_of_port_is_hotplug(struct usb_device *hub, int port1);
 enum usb_port_connect_type usb_of_get_connect_type(struct usb_device *hub, int port1);
 struct device_node *usb_of_get_device_node(struct usb_device *hub, int port1);
 struct device_node *usb_of_get_connector_peer(struct usb_device *hub, u32 port,
@@ -41,6 +42,10 @@ static inline int of_usb_update_otg_caps(struct device_node *np,
 {
 	return 0;
 }
+static inline bool usb_of_port_is_hotplug(struct usb_device *hub, int port1)
+{
+	return false;
+}
 static inline enum usb_port_connect_type
 usb_of_get_connect_type(const struct usb_device *hub, int port1)
 {

-- 
2.55.0

