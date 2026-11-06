From: Jing Lin <kayano050408@gmail.com>
To: syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com
Cc: linux-usb@vger.kernel.org, syzkaller-bugs@googlegroups.com, kayano050408@gmail.com
Subject: [PATCH RFC] usb: gadget: gadgetfs: dequeue pending ep0 request before freeing
Date: Fri, 06 Nov 2026 23:55:16 +0900
Message-ID: <179397691694.27761.9543494907127681190.gadgetfs-ep0-patch-test@gmail.com>
In-Reply-To: <6a6944f5.e3659fcc.2a40b8.0021.GAE@google.com>
References: <6a6944f5.e3659fcc.2a40b8.0021.GAE@google.com>
X-Mailer: b4 0.16.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793976917; l=8547;
 i=kayano050408@gmail.com; s=20261106-gadgetfs-gmail;
 h=from:subject:message-id; bh=ZsZ5biew09cfhtwJZXclaOy5dDe90VlJtG365y91MM8=;
 b=mLhfXvSdvDS0SCjI1dpw8a/bt4FAzniGCzHYiO5G9sC/hLi60xbXw4Lp5+y/coiwHl3uE+TXi
 5x0l1SWHmxSBN1Ndn4wvWNJXLDZMxTss5HmRBNC0Ch/Hx/X8bJRxuYH
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=DtAI52kU3F0sVbAiS4n+5b4UKMnVF398eKHlj3H9KBY=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261106-gadgetfs-gmail with auth_id=1433
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Please test this gadgetfs ep0 request lifetime fix
The unpatched base reproduces the warning and use-after-free locally
on arm64 QEMU with dummy_hcd and KASAN

#syz test: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git f66469d9905b39d2c260a15d7d6db450f4db67c1

gadgetfs_unbind() frees the preallocated ep0 request after disconnecting
the gadget, assuming that no I/O remains active

With dummy_hcd, disconnecting does not necessarily drain ep0, so a delayed
userspace response can leave dev->req queued when it is freed
This triggers the warning in dummy_free_request() and a use-after-free
when dummy_udc_stop() subsequently drains the endpoint queue

Track dev->req from submission through completion under dev->lock and
reject reuse while it is busy
After waiting for active UDC users to finish, dequeue a pending request
before freeing it and clearing ep0->driver_data
Drop dev->lock around dequeue because the completion callback takes it
Only dequeue pending requests to avoid errors from UDCs that reject
cancellation of an unqueued request

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Reported-by: syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=c73e1942197af9f54ca3
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
Local validation on arm64 QEMU with dummy_hcd, KASAN and lockdep:
- The unpatched kernel reproduces the warning and use-after-free
- The patched kernel runs the C reproducer and rebind/concurrency workload
  without the warning, a KASAN report or a lockdep report
- W=1 compilation of inode.o and the Image build completed successfully

AI tools assisted with patch development, the commit description, review
and local QEMU validation

Related syzbot RFC:
https://lore.kernel.org/all/161c70c4-a363-469d-8665-64f71763f84b@mail.kernel.org/
This version tracks pending requests and guards reuse while they are busy
---
 drivers/usb/gadget/legacy/inode.c | 55 ++++++++++++++++++++++++++++++++-------
 1 file changed, 46 insertions(+), 9 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index 7f6d84601..d60df4ad3 100644
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
 
@@ -1023,7 +1035,7 @@ static int setup_req (struct usb_ep *ep, struct usb_request *req, u16 len)
 {
 	struct dev_data	*dev = ep->driver_data;
 
-	if (dev->setup_out_ready) {
+	if (dev->setup_out_ready || dev->ep0_req_queued) {
 		DBG (dev, "ep0 request busy!\n");
 		return -EBUSY;
 	}
@@ -1073,13 +1085,20 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
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
@@ -1270,6 +1289,7 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 			retval = setup_req (dev->gadget->ep0, dev->req, len);
 			if (retval == 0) {
 				dev->state = STATE_DEV_CONNECTED;
+				dev->ep0_req_queued = true;
 				++dev->udc_usage;
 				spin_unlock_irq (&dev->lock);
 				if (copy_from_user (dev->req->buf, buf, len))
@@ -1284,6 +1304,7 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 				spin_lock_irq(&dev->lock);
 				--dev->udc_usage;
 				if (retval < 0) {
+					dev->ep0_req_queued = false;
 					clean_req (dev->gadget->ep0, dev->req);
 				} else
 					retval = len;
@@ -1508,6 +1529,11 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	} else if (dev->state == STATE_DEV_SETUP)
 		dev->setup_abort = 1;
 
+	if (dev->ep0_req_queued) {
+		spin_unlock(&dev->lock);
+		return -EBUSY;
+	}
+
 	req->buf = dev->rbuf;
 	req->context = NULL;
 	switch (ctrl->bRequest) {
@@ -1626,6 +1652,7 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 				if (value < 0)
 					break;
 
+				dev->ep0_req_queued = true;
 				++dev->udc_usage;
 				spin_unlock (&dev->lock);
 				value = usb_ep_queue (gadget->ep0, dev->req,
@@ -1633,6 +1660,7 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 				spin_lock (&dev->lock);
 				--dev->udc_usage;
 				if (value < 0) {
+					dev->ep0_req_queued = false;
 					clean_req (gadget->ep0, dev->req);
 					break;
 				}
@@ -1664,16 +1692,18 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
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
 
@@ -1771,6 +1801,7 @@ static void
 gadgetfs_unbind (struct usb_gadget *gadget)
 {
 	struct dev_data		*dev = get_gadget_data (gadget);
+	bool			queued;
 
 	DBG (dev, "%s\n", __func__);
 
@@ -1781,15 +1812,20 @@ gadgetfs_unbind (struct usb_gadget *gadget)
 		usleep_range(1000, 2000);
 		spin_lock_irq(&dev->lock);
 	}
+	queued = dev->ep0_req_queued;
 	spin_unlock_irq (&dev->lock);
 
+	if (dev->req) {
+		if (queued)
+			usb_ep_dequeue(gadget->ep0, dev->req);
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
@@ -1816,11 +1852,12 @@ static int gadgetfs_bind(struct usb_gadget *gadget,
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

