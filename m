From: Janne Grunau <j@jannau.net>
Date: Fri, 22 Mar 2024 08:47:05 +0100
Subject: [PATCH v3 2/6] usb: xhci: Set up endpoints for the first 2
 interfaces
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240322-asahi-keyboards-v3-2-3106dd4c4e19@jannau.net>
References: <20240322-asahi-keyboards-v3-0-3106dd4c4e19@jannau.net>
In-Reply-To: <20240322-asahi-keyboards-v3-0-3106dd4c4e19@jannau.net>
To: Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marex@denx.de>, 
 Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Joe Hershberger <joe.hershberger@ni.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3588; i=j@jannau.net;
 h=from:subject:message-id; bh=C+QptQG0I4SLRE163S23N4sr3v3/vF84MwYBdfUC3T0=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtS/5i3LGzknN1UftLUKXbzwXLKCj0GibOvD5V9TtwomT
 bo939G0o5SFQYyLQVZMkSVJ+2UHw+oaxZjaB2Ewc1iZQIYwcHEKwERklzIyzA0/uY11t0TUzP4p
 zXX+j9v9O1gvL7fifG9793oip4JnCMP/bOHeR2I882u+1iYVR25Yk3mi0zHn/Y1jVntmOVwOzG/
 iBQA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The xhci driver currently only does the necessary initialization for
endpoints found in the first interface descriptor. Apple USB keyboards
(released 2021) use the second interface descriptor for the HID keyboard
boot protocol. To allow USB drivers to use endpoints from other
interface descriptors the xhci driver needs to ensure these endpoints
are initialized as well.
Use USB_MAX_ACTIVE_INTERFACES to control how many interface descriptors
are considered during endpoint initialisation.
For now define it to 2 as that is sufficient for supporting the Apple
keyboards.

Reviewed-by: Marek Vasut <marex@denx.de>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/usb/host/xhci.c | 31 +++++++++++++++++++------------
 include/usb.h           |  6 ++++++
 2 files changed, 25 insertions(+), 12 deletions(-)

diff --git a/drivers/usb/host/xhci.c b/drivers/usb/host/xhci.c
index 534c4b973f..741e186ee0 100644
--- a/drivers/usb/host/xhci.c
+++ b/drivers/usb/host/xhci.c
@@ -606,24 +606,28 @@ static int xhci_set_configuration(struct usb_device *udev)
 	int slot_id = udev->slot_id;
 	struct xhci_virt_device *virt_dev = ctrl->devs[slot_id];
 	struct usb_interface *ifdesc;
+	unsigned int ifnum;
+	unsigned int max_ifnum = min((unsigned int)USB_MAX_ACTIVE_INTERFACES,
+				     (unsigned int)udev->config.no_of_if);
 
 	out_ctx = virt_dev->out_ctx;
 	in_ctx = virt_dev->in_ctx;
 
-	num_of_ep = udev->config.if_desc[0].no_of_ep;
-	ifdesc = &udev->config.if_desc[0];
-
 	ctrl_ctx = xhci_get_input_control_ctx(in_ctx);
 	/* Initialize the input context control */
 	ctrl_ctx->add_flags = cpu_to_le32(SLOT_FLAG);
 	ctrl_ctx->drop_flags = 0;
 
-	/* EP_FLAG gives values 1 & 4 for EP1OUT and EP2IN */
-	for (cur_ep = 0; cur_ep < num_of_ep; cur_ep++) {
-		ep_flag = xhci_get_ep_index(&ifdesc->ep_desc[cur_ep]);
-		ctrl_ctx->add_flags |= cpu_to_le32(1 << (ep_flag + 1));
-		if (max_ep_flag < ep_flag)
-			max_ep_flag = ep_flag;
+	for (ifnum = 0; ifnum < max_ifnum; ifnum++) {
+		ifdesc = &udev->config.if_desc[ifnum];
+		num_of_ep = ifdesc->no_of_ep;
+		/* EP_FLAG gives values 1 & 4 for EP1OUT and EP2IN */
+		for (cur_ep = 0; cur_ep < num_of_ep; cur_ep++) {
+			ep_flag = xhci_get_ep_index(&ifdesc->ep_desc[cur_ep]);
+			ctrl_ctx->add_flags |= cpu_to_le32(1 << (ep_flag + 1));
+			if (max_ep_flag < ep_flag)
+				max_ep_flag = ep_flag;
+		}
 	}
 
 	xhci_inval_cache((uintptr_t)out_ctx->bytes, out_ctx->size);
@@ -637,9 +641,12 @@ static int xhci_set_configuration(struct usb_device *udev)
 	xhci_endpoint_copy(ctrl, in_ctx, out_ctx, 0);
 
 	/* filling up ep contexts */
-	err = xhci_init_ep_contexts_if(udev, ctrl, virt_dev, ifdesc);
-	if (err < 0)
-		return err;
+	for (ifnum = 0; ifnum < max_ifnum; ifnum++) {
+		ifdesc = &udev->config.if_desc[ifnum];
+		err = xhci_init_ep_contexts_if(udev, ctrl, virt_dev, ifdesc);
+		if (err < 0)
+			return err;
+	}
 
 	return xhci_configure_endpoints(udev, false);
 }
diff --git a/include/usb.h b/include/usb.h
index 09e3f0cb30..3aafdc8bfd 100644
--- a/include/usb.h
+++ b/include/usb.h
@@ -49,6 +49,12 @@ extern bool usb_started; /* flag for the started/stopped USB status */
  */
 #define USB_TIMEOUT_MS(pipe) (usb_pipebulk(pipe) ? 5000 : 1000)
 
+/*
+ * The xhcd hcd driver prepares only a limited number interfaces / endpoints.
+ * Define this limit so that drivers do not exceed it.
+ */
+#define USB_MAX_ACTIVE_INTERFACES	2
+
 /* device request (setup) */
 struct devrequest {
 	__u8	requesttype;

-- 
2.44.0

