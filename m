From: Jing Lin <kayano050408@gmail.com>
Date: Sat, 07 Nov 2026 17:56:09 +0800
Subject: [PATCH v3 1/2] usb: gadget: gadgetfs: fix ep0 request lifetime on
 disconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-b4-gadgetfs-ep0-v3-1-62089dc0ec07@gmail.com>
References: <20261107-b4-gadgetfs-ep0-v3-0-62089dc0ec07@gmail.com>
In-Reply-To: <20261107-b4-gadgetfs-ep0-v3-0-62089dc0ec07@gmail.com>
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jing Lin <kayano050408@gmail.com>, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794045369; l=8889;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=rsBq+10RUWFh86HXFEblBPbgMfIaAZfNXOPHzZexFE0=;
 b=j168a4c/+2Aa8MYTScUbfy7p4z3ZpncrdQlX+wy4VJEeIHnZ/hL31vl68isi68X/Q5i07NDpX
 +ApvNM62uTECETR0Td4005kX/s7T3g9T/ZdWRKtx3WQ9+CrKe99ygEf
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gadgetfs_unbind() frees the preallocated ep0 request after disconnecting
the gadget, assuming that no I/O remains active.

With dummy_hcd, disconnecting does not necessarily drain ep0, so a delayed
userspace response can leave dev->req queued when it is freed. This
triggers the warning in dummy_free_request() and a use-after-free when
dummy_udc_stop() subsequently drains the endpoint queue.

gadgetfs_setup() also reuses dev->req for a new control request while the
completed delegated OUT transfer still has setup_out_ready set waiting
for ep0_read() to copy the payload to userspace. Reusing the request
overwrites req->buf with a descriptor pointer, so the later clean_req()
frees the descriptor buffer instead of the request buffer and the gadget
keeps using freed memory.

Keep the pending OUT payload in a separate buffer so the request can be
reused immediately, and clear the pending state from ep0_read(). Track
whether dev->req is queued and dequeue it without dev->lock before
freeing it in gadgetfs_unbind(). Do not reject new control requests while
data is pending, since that leaves ep0 permanently busy after a
zero-length status stage.

Fixes: 1da177e4c3f41 ("Linux-2.6.12-rc2")
Reported-by: syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=c73e1942197af9f54ca3
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 83 ++++++++++++++++++++++++++++++---------
 1 file changed, 64 insertions(+), 19 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index 7f6d84601..87aff568a 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -140,6 +140,8 @@ struct dev_data {
 					setup_abort : 1,
 					gadget_registered : 1;
 	unsigned			setup_wLength;
+	unsigned int			setup_out_len;
+	bool				ep0_req_queued;
 
 	/* the rest is basically write-once */
 	struct usb_config_descriptor	*config, *hs_config;
@@ -153,6 +155,7 @@ struct dev_data {
 
 	/* except this scratch i/o buffer for ep0 */
 	u8				rbuf[RBUF_SIZE];
+	u8				setup_buf[RBUF_SIZE];
 };
 
 static inline void get_dev (struct dev_data *data)
@@ -984,12 +987,23 @@ static inline void ep0_readable (struct dev_data *dev)
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
 
 	if (req->buf != dev->rbuf) {
-		kfree(req->buf);
+		if (req->buf != dev->setup_buf)
+			kfree(req->buf);
 		req->buf = dev->rbuf;
 	}
 	req->complete = epio_complete;
@@ -1004,12 +1018,18 @@ static void ep0_complete (struct usb_ep *ep, struct usb_request *req)
 
 	/* for control OUT, data must still get to userspace */
 	spin_lock_irqsave(&dev->lock, flags);
+	dev->ep0_req_queued = false;
 	if (!dev->setup_in) {
-		dev->setup_out_error = (req->status != 0);
-		if (!dev->setup_out_error)
-			free = 0;
-		dev->setup_out_ready = 1;
-		ep0_readable (dev);
+		/* a zero-length status stage carries no data */
+		if (dev->setup_wLength) {
+			dev->setup_out_error = (req->status != 0);
+			dev->setup_out_len = dev->setup_out_error
+						? 0 : req->actual;
+			dev->setup_out_ready = 1;
+			ep0_readable(dev);
+		}
+		req->buf = dev->rbuf;
+		free = 0;
 	}
 
 	/* clean up as appropriate */
@@ -1023,12 +1043,10 @@ static int setup_req (struct usb_ep *ep, struct usb_request *req, u16 len)
 {
 	struct dev_data	*dev = ep->driver_data;
 
-	if (dev->setup_out_ready) {
-		DBG (dev, "ep0 request busy!\n");
-		return -EBUSY;
-	}
 	if (len > sizeof (dev->rbuf))
 		req->buf = kmalloc(len, GFP_ATOMIC);
+	else
+		req->buf = dev->rbuf;
 	if (req->buf == NULL) {
 		req->buf = dev->rbuf;
 		return -ENOMEM;
@@ -1045,6 +1063,7 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 	struct dev_data			*dev = fd->private_data;
 	ssize_t				retval;
 	enum ep0_state			state;
+	u8				tmp[RBUF_SIZE];
 
 	spin_lock_irq (&dev->lock);
 	if (dev->state <= STATE_DEV_OPENED) {
@@ -1074,10 +1093,15 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 
 			if ((retval = setup_req (ep, req, 0)) == 0) {
 				++dev->udc_usage;
+				dev->ep0_req_queued = true;
 				spin_unlock_irq (&dev->lock);
 				retval = usb_ep_queue (ep, req, GFP_KERNEL);
 				spin_lock_irq (&dev->lock);
 				--dev->udc_usage;
+				if (retval < 0) {
+					dev->ep0_req_queued = false;
+					clean_req(ep, req);
+				}
 			}
 			dev->state = STATE_DEV_CONNECTED;
 
@@ -1115,19 +1139,24 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 			}
 			dev->state = STATE_DEV_CONNECTED;
 
-			if (dev->setup_out_error)
+			if (dev->setup_out_error) {
+				dev->setup_out_ready = 0;
+				dev->setup_out_error = 0;
+				dev->setup_out_len = 0;
 				retval = -EIO;
-			else {
-				len = min (len, (size_t)dev->req->actual);
+			} else {
+				len = min_t(size_t, len, dev->setup_out_len);
+				memcpy(tmp, dev->setup_buf, len);
+				dev->setup_out_ready = 0;
+				dev->setup_out_len = 0;
 				++dev->udc_usage;
 				spin_unlock_irq(&dev->lock);
-				if (copy_to_user (buf, dev->req->buf, len))
+				if (copy_to_user(buf, tmp, len))
 					retval = -EFAULT;
 				else
 					retval = len;
 				spin_lock_irq(&dev->lock);
 				--dev->udc_usage;
-				clean_req (dev->gadget->ep0, dev->req);
 				/* NOTE userspace can't yet choose to stall */
 			}
 		}
@@ -1271,6 +1300,7 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 			if (retval == 0) {
 				dev->state = STATE_DEV_CONNECTED;
 				++dev->udc_usage;
+				dev->ep0_req_queued = true;
 				spin_unlock_irq (&dev->lock);
 				if (copy_from_user (dev->req->buf, buf, len))
 					retval = -EFAULT;
@@ -1284,6 +1314,7 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 				spin_lock_irq(&dev->lock);
 				--dev->udc_usage;
 				if (retval < 0) {
+					dev->ep0_req_queued = false;
 					clean_req (dev->gadget->ep0, dev->req);
 				} else
 					retval = len;
@@ -1618,6 +1649,7 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 			dev->setup_wLength = w_length;
 			dev->setup_out_ready = 0;
 			dev->setup_out_error = 0;
+			dev->setup_out_len = 0;
 
 			/* read DATA stage for OUT right away */
 			if (unlikely (!dev->setup_in && w_length)) {
@@ -1626,13 +1658,16 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 				if (value < 0)
 					break;
 
+				dev->req->buf = dev->setup_buf;
 				++dev->udc_usage;
+				dev->ep0_req_queued = true;
 				spin_unlock (&dev->lock);
 				value = usb_ep_queue (gadget->ep0, dev->req,
 							GFP_KERNEL);
 				spin_lock (&dev->lock);
 				--dev->udc_usage;
 				if (value < 0) {
+					dev->ep0_req_queued = false;
 					clean_req (gadget->ep0, dev->req);
 					break;
 				}
@@ -1663,17 +1698,21 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	if (value >= 0 && dev->state != STATE_DEV_SETUP) {
 		req->length = value;
 		req->zero = value < w_length;
+		req->complete = dev_req_complete;
 
 		++dev->udc_usage;
+		dev->ep0_req_queued = true;
 		spin_unlock (&dev->lock);
 		value = usb_ep_queue (gadget->ep0, req, GFP_KERNEL);
 		spin_lock(&dev->lock);
 		--dev->udc_usage;
-		spin_unlock(&dev->lock);
 		if (value < 0) {
+			dev->ep0_req_queued = false;
+			req->complete = epio_complete;
 			DBG (dev, "ep_queue --> %d\n", value);
 			req->status = 0;
 		}
+		spin_unlock(&dev->lock);
 		return value;
 	}
 
@@ -1771,6 +1810,7 @@ static void
 gadgetfs_unbind (struct usb_gadget *gadget)
 {
 	struct dev_data		*dev = get_gadget_data (gadget);
+	bool			queued;
 
 	DBG (dev, "%s\n", __func__);
 
@@ -1781,15 +1821,20 @@ gadgetfs_unbind (struct usb_gadget *gadget)
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

-- 
Git-155)

