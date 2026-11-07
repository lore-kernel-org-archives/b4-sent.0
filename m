From: Jing Lin <kayano050408@gmail.com>
Date: Sat, 07 Nov 2026 09:13:23 +0900
Subject: [PATCH v2] usb: gadget: gadgetfs: dequeue pending ep0 request
 before freeing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-b4-gadgetfs-ep0-v2-1-d8896e1ad517@gmail.com>
X-B4-Tracking: v=1; b=H4sIACJt7moC/1WOS27DMAxErxJoXbmiokphV71HkYWs0DKL+gNRD
 RIEvnutdNXlmyEf5qGECpOo98NDFbqy8DLvYF8OKo1xzqT5srOyxnoA43XvdI6XTHUQTavRwwl
 cAhcgRFT711po4NvT+Hn+Y/npvyjVpmkXfRTSfYlzGlu0FM48v05RKpXWjyx1KffnpCs0j4KAR
 wwewaPrbAgeOnxzR4cOTQAb/AkATfdv2BprGnUlqR95ivzdpWVS523bfgHeg3wP9AAAAA==
X-Change-ID: 20261106-b4-gadgetfs-ep0-f814c14717a9
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 syzkaller-bugs@googlegroups.com, stable@vger.kernel.org, 
 Jing Lin <kayano050408@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794010402; l=8972;
 i=kayano050408@gmail.com; s=20261106-gadgetfs-gmail;
 h=from:subject:message-id; bh=6vi0zhlir65l8tCHpG2Hbu6i0egiQtfmgMHdAHBVI60=;
 b=2AhwBgkaw9+i6uOU3HJV3zxkKZah8m+Wmhc0ntbqqzE+VWyDszoSL82vWzkGUMmx1VTYRuJzr
 /pzUx02mYBIAeYpyd65QYlnPV+azjPkz2xkneWNWlXOxcFt1f79VtFe
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=DtAI52kU3F0sVbAiS4n+5b4UKMnVF398eKHlj3H9KBY=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261106-gadgetfs-gmail with auth_id=1433
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gadgetfs_unbind() frees the preallocated ep0 request after disconnecting
the gadget, assuming that no I/O remains active.

With dummy_hcd, disconnecting does not necessarily drain ep0, so a delayed
userspace response can leave dev->req queued when it is freed. This
triggers the warning in dummy_free_request() and a use-after-free when
dummy_udc_stop() subsequently drains the endpoint queue.

In addition, gadgetfs_setup() can reuse dev->req while a completed
delegated control OUT transfer still has dev->setup_out_ready set waiting
for ep0_read() to copy the payload to userspace and call clean_req(),
which can overwrite req->buf with descriptor pointers and trigger an
invalid kfree() in clean_req().

Track dev->req from submission through completion under dev->lock and
reject reuse in both setup_req() and gadgetfs_setup() while either
dev->setup_out_ready or dev->ep0_req_queued is set. Reset req->buf to
dev->rbuf in setup_req() when len fits in dev->rbuf. In gadgetfs_unbind(),
after waiting for active UDC users to finish, dequeue a pending request
with dev->lock dropped and clean up any unread control OUT buffer before
freeing dev->req and clearing ep0->driver_data.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Reported-by: syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=c73e1942197af9f54ca3
Tested-by: syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
Changes in v2:
- Also check dev->setup_out_ready in gadgetfs_setup() so a new SETUP
  request cannot reuse dev->req or overwrite req->buf while ep0_read()
  still has unread or in-progress control OUT data.
- Reset req->buf to dev->rbuf in setup_req() when len <= sizeof(dev->rbuf)
  and clean up unread control OUT buffer in gadgetfs_unbind().
- Remove RFC syzbot test commands from the commit description and add the
  syzbot Tested-by tag.
- Link to v1: https://patch.msgid.link/179397691694.27761.9543494907127681190.gadgetfs-ep0-patch-test@gmail.com
---
 drivers/usb/gadget/legacy/inode.c | 59 +++++++++++++++++++++++++++++++++------
 1 file changed, 50 insertions(+), 9 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index 7f6d84601..9b74476dd 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -140,6 +140,7 @@ struct dev_data {
 					setup_abort : 1,
 					gadget_registered : 1;
 	unsigned			setup_wLength;
+	bool				ep0_req_queued;
 
 	/* the rest is basically write-once */
 	struct usb_config_descriptor	*config, *hs_config;
@@ -984,6 +985,16 @@ static inline void ep0_readable (struct dev_data *dev)
 	kill_fasync (&dev->fasync, SIGIO, POLL_IN);
 }
 
+static void dev_req_complete(struct usb_ep *ep, struct usb_request *req)
+{
+	struct dev_data		*dev = ep->driver_data;
+	unsigned long		flags;
+
+	spin_lock_irqsave(&dev->lock, flags);
+	dev->ep0_req_queued = false;
+	spin_unlock_irqrestore(&dev->lock, flags);
+}
+
 static void clean_req (struct usb_ep *ep, struct usb_request *req)
 {
 	struct dev_data		*dev = ep->driver_data;
@@ -992,7 +1003,7 @@ static void clean_req (struct usb_ep *ep, struct usb_request *req)
 		kfree(req->buf);
 		req->buf = dev->rbuf;
 	}
-	req->complete = epio_complete;
+	req->complete = dev_req_complete;
 	dev->setup_out_ready = 0;
 }
 
@@ -1004,6 +1015,7 @@ static void ep0_complete (struct usb_ep *ep, struct usb_request *req)
 
 	/* for control OUT, data must still get to userspace */
 	spin_lock_irqsave(&dev->lock, flags);
+	dev->ep0_req_queued = false;
 	if (!dev->setup_in) {
 		dev->setup_out_error = (req->status != 0);
 		if (!dev->setup_out_error)
@@ -1015,7 +1027,7 @@ static void ep0_complete (struct usb_ep *ep, struct usb_request *req)
 	/* clean up as appropriate */
 	if (free && req->buf != &dev->rbuf)
 		clean_req (ep, req);
-	req->complete = epio_complete;
+	req->complete = dev_req_complete;
 	spin_unlock_irqrestore(&dev->lock, flags);
 }
 
@@ -1023,12 +1035,14 @@ static int setup_req (struct usb_ep *ep, struct usb_request *req, u16 len)
 {
 	struct dev_data	*dev = ep->driver_data;
 
-	if (dev->setup_out_ready) {
+	if (dev->setup_out_ready || dev->ep0_req_queued) {
 		DBG (dev, "ep0 request busy!\n");
 		return -EBUSY;
 	}
 	if (len > sizeof (dev->rbuf))
 		req->buf = kmalloc(len, GFP_ATOMIC);
+	else
+		req->buf = dev->rbuf;
 	if (req->buf == NULL) {
 		req->buf = dev->rbuf;
 		return -ENOMEM;
@@ -1073,13 +1087,20 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 			struct usb_request	*req = dev->req;
 
 			if ((retval = setup_req (ep, req, 0)) == 0) {
+				dev->state = STATE_DEV_CONNECTED;
+				dev->ep0_req_queued = true;
 				++dev->udc_usage;
 				spin_unlock_irq (&dev->lock);
 				retval = usb_ep_queue (ep, req, GFP_KERNEL);
 				spin_lock_irq (&dev->lock);
 				--dev->udc_usage;
+				if (retval < 0) {
+					dev->ep0_req_queued = false;
+					clean_req(ep, req);
+				}
+			} else {
+				dev->state = STATE_DEV_CONNECTED;
 			}
-			dev->state = STATE_DEV_CONNECTED;
 
 			/* assume that was SET_CONFIGURATION */
 			if (dev->current_config) {
@@ -1270,6 +1291,7 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 			retval = setup_req (dev->gadget->ep0, dev->req, len);
 			if (retval == 0) {
 				dev->state = STATE_DEV_CONNECTED;
+				dev->ep0_req_queued = true;
 				++dev->udc_usage;
 				spin_unlock_irq (&dev->lock);
 				if (copy_from_user (dev->req->buf, buf, len))
@@ -1284,6 +1306,7 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 				spin_lock_irq(&dev->lock);
 				--dev->udc_usage;
 				if (retval < 0) {
+					dev->ep0_req_queued = false;
 					clean_req (dev->gadget->ep0, dev->req);
 				} else
 					retval = len;
@@ -1508,6 +1531,11 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	} else if (dev->state == STATE_DEV_SETUP)
 		dev->setup_abort = 1;
 
+	if (dev->setup_out_ready || dev->ep0_req_queued) {
+		spin_unlock(&dev->lock);
+		return -EBUSY;
+	}
+
 	req->buf = dev->rbuf;
 	req->context = NULL;
 	switch (ctrl->bRequest) {
@@ -1626,6 +1654,7 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 				if (value < 0)
 					break;
 
+				dev->ep0_req_queued = true;
 				++dev->udc_usage;
 				spin_unlock (&dev->lock);
 				value = usb_ep_queue (gadget->ep0, dev->req,
@@ -1633,6 +1662,7 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 				spin_lock (&dev->lock);
 				--dev->udc_usage;
 				if (value < 0) {
+					dev->ep0_req_queued = false;
 					clean_req (gadget->ep0, dev->req);
 					break;
 				}
@@ -1664,16 +1694,18 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 		req->length = value;
 		req->zero = value < w_length;
 
+		dev->ep0_req_queued = true;
 		++dev->udc_usage;
 		spin_unlock (&dev->lock);
 		value = usb_ep_queue (gadget->ep0, req, GFP_KERNEL);
 		spin_lock(&dev->lock);
 		--dev->udc_usage;
-		spin_unlock(&dev->lock);
 		if (value < 0) {
+			dev->ep0_req_queued = false;
 			DBG (dev, "ep_queue --> %d\n", value);
 			req->status = 0;
 		}
+		spin_unlock(&dev->lock);
 		return value;
 	}
 
@@ -1771,6 +1803,7 @@ static void
 gadgetfs_unbind (struct usb_gadget *gadget)
 {
 	struct dev_data		*dev = get_gadget_data (gadget);
+	bool			queued;
 
 	DBG (dev, "%s\n", __func__);
 
@@ -1781,15 +1814,22 @@ gadgetfs_unbind (struct usb_gadget *gadget)
 		usleep_range(1000, 2000);
 		spin_lock_irq(&dev->lock);
 	}
+	queued = dev->ep0_req_queued;
 	spin_unlock_irq (&dev->lock);
 
+	if (dev->req) {
+		if (queued)
+			usb_ep_dequeue(gadget->ep0, dev->req);
+		if (dev->setup_out_ready)
+			clean_req(gadget->ep0, dev->req);
+		usb_ep_free_request(gadget->ep0, dev->req);
+		dev->req = NULL;
+	}
+
 	destroy_ep_files (dev);
 	gadget->ep0->driver_data = NULL;
 	set_gadget_data (gadget, NULL);
 
-	/* we've already been disconnected ... no i/o is active */
-	if (dev->req)
-		usb_ep_free_request (gadget->ep0, dev->req);
 	DBG (dev, "%s done\n", __func__);
 	put_dev (dev);
 }
@@ -1816,11 +1856,12 @@ static int gadgetfs_bind(struct usb_gadget *gadget,
 	get_dev (dev);
 
 	/* preallocate control response and buffer */
+	dev->ep0_req_queued = false;
 	dev->req = usb_ep_alloc_request (gadget->ep0, GFP_KERNEL);
 	if (!dev->req)
 		goto enomem;
 	dev->req->context = NULL;
-	dev->req->complete = epio_complete;
+	dev->req->complete = dev_req_complete;
 
 	if (activate_ep_files (dev) < 0)
 		goto enomem;

---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261106-b4-gadgetfs-ep0-f814c14717a9

Best regards,
--  
Jing Lin <kayano050408@gmail.com>

