From: Jing Lin <kayano050408@gmail.com>
Date: Mon, 09 Nov 2026 14:50:51 +0800
Subject: [PATCH v6 1/3] usb: gadget: gadgetfs: fix ep0 request lifetime on
 disconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-b4-gadgetfs-ep0-v6-1-b410e3dced89@gmail.com>
References: <20261109-b4-gadgetfs-ep0-v6-0-b410e3dced89@gmail.com>
In-Reply-To: <20261109-b4-gadgetfs-ep0-v6-0-b410e3dced89@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Jing Lin <kayano050408@gmail.com>, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794207052; l=18089;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=nIWji7L0I66NP9pSdbXN6pggSDW1snNqVzCuXJ2cSoE=;
 b=8L4OYqK6ZbHf77xtd2n0tVSOkwlFyE4ShH0/fsvkF39Ba8AGNMzUogdKqb7WE+PQAV0jE9N9j
 bdmKCMxaUqsCyt7/2Ks92t3BUS+ll85U/BIZNcv41nL3vrWYi/DsbN6
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gadgetfs_unbind() frees the preallocated ep0 request after disconnecting
the gadget, assuming that no I/O remains active.

With dummy_hcd, disconnecting does not necessarily drain ep0, so a delayed
userspace response can leave dev->req queued when it is freed.  This
triggers the warning in dummy_free_request() and a use-after-free when
dummy_udc_stop() subsequently drains the endpoint queue.

gadgetfs_setup() and the userspace copy helpers also race on dev->req and
req->buf:

1. ep0_read() versus gadgetfs_setup().  A delegated control OUT request
   is queued by gadgetfs_setup() and completed by ep0_complete(), which
   leaves the payload in dev->req->buf and sets setup_out_ready.
   ep0_read() copies that payload with copy_to_user() after dropping
   dev->lock, so the copy can fault and sleep.  If a new control transfer
   arrives during that window, gadgetfs_setup() reuses dev->req for it;
   for example, GET_DESCRIPTOR(config) points req->buf at dev->config.
   When ep0_read() resumes, clean_req() frees whatever req->buf points to
   at that moment, which is now dev->config.  The following
   GET_DESCRIPTOR(config) dereferences the freed descriptor.

2. ep0_write() versus gadgetfs_setup().  For a delegated control IN
   request, ep0_write() prepares dev->req and copies the response from
   userspace with copy_from_user() after dropping dev->lock.  A control
   request that arrives during that copy can point req->buf at dev->dev
   or dev->config, so the userspace copy overwrites a descriptor buffer,
   or it can reset req->buf to dev->rbuf, so the request is queued with
   the wrong buffer.  Completion then calls clean_req() on the wrong
   object.

Copy completed control OUT payloads into a separate setup_buf in
ep0_complete(), copy control IN payloads from userspace into a stack
buffer before preparing dev->req in ep0_write(), and reset req->buf when
control transfers finish.  Track whether dev->req is queued, reject reuse
while it is queued, and dequeue it without dev->lock before freeing it in
gadgetfs_unbind().

Only the buffer allocated by setup_req() belongs to the request, while
descriptor responses point req->buf into dev->buf.  Track the allocation
explicitly so clean_req() cannot free a descriptor buffer when a request
is destroyed while an in-kernel GET_DESCRIPTOR response is active, and
wait for the asynchronous usb_ep_dequeue() completion before freeing the
request.

Count setup callbacks and recheck the count in ep0_write() after
copy_from_user(), so a control request that arrives while dev->lock is
dropped invalidates the stale response instead of having it queued for
the new transfer.

Wake an ep0_read() that waits for a delegated OUT data stage when a new
setup aborts it, and include setup_abort in the wait condition so the
abort is not missed.

Consume setup_abort through one helper that returns to
STATE_DEV_CONNECTED only when the state is still STATE_DEV_SETUP.  This
keeps the following event read out of the control data path without
overwriting STATE_DEV_UNBOUND when gadgetfs_unbind() ran concurrently.

The setup() callback runs in interrupt context and may not sleep, so a
mutex cannot be used to serialize it against ep0_read() and ep0_write().
The shared request state is protected by dev->lock and the payloads are
handed off through private buffers instead.

Fixes: 1da177e4c3f41 ("Linux-2.6.12-rc2")
Reported-by: syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=c73e1942197af9f54ca3
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 230 ++++++++++++++++++++++++++++----------
 1 file changed, 174 insertions(+), 56 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index 7f6d84601..1277982f1 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -140,6 +140,10 @@ struct dev_data {
 					setup_abort : 1,
 					gadget_registered : 1;
 	unsigned			setup_wLength;
+	unsigned int			setup_out_len;
+	bool				ep0_req_queued;
+	void				*ep0_req_buf;
+	unsigned int			setup_generation;
 
 	/* the rest is basically write-once */
 	struct usb_config_descriptor	*config, *hs_config;
@@ -153,6 +157,7 @@ struct dev_data {
 
 	/* except this scratch i/o buffer for ep0 */
 	u8				rbuf[RBUF_SIZE];
+	u8				setup_buf[RBUF_SIZE];
 };
 
 static inline void get_dev (struct dev_data *data)
@@ -984,54 +989,82 @@ static inline void ep0_readable (struct dev_data *dev)
 	kill_fasync (&dev->fasync, SIGIO, POLL_IN);
 }
 
-static void clean_req (struct usb_ep *ep, struct usb_request *req)
+static void dev_req_complete(struct usb_ep *ep, struct usb_request *req);
+
+static void clean_req(struct usb_ep *ep, struct usb_request *req)
 {
 	struct dev_data		*dev = ep->driver_data;
 
-	if (req->buf != dev->rbuf) {
-		kfree(req->buf);
-		req->buf = dev->rbuf;
-	}
-	req->complete = epio_complete;
-	dev->setup_out_ready = 0;
+	/*
+	 * req->buf may also point into dev->buf, which holds the
+	 * descriptors; only the buffer allocated by setup_req() belongs
+	 * to the request and may be freed here.
+	 */
+	kfree(dev->ep0_req_buf);
+	dev->ep0_req_buf = NULL;
+	req->buf = dev->rbuf;
+	req->complete = dev_req_complete;
+}
+
+static void dev_req_complete(struct usb_ep *ep, struct usb_request *req)
+{
+	struct dev_data		*dev = ep->driver_data;
+	unsigned long		flags;
+
+	spin_lock_irqsave(&dev->lock, flags);
+	clean_req(ep, req);
+	dev->ep0_req_queued = false;
+	spin_unlock_irqrestore(&dev->lock, flags);
+
+	/* gadgetfs_unbind() waits for this before freeing the request */
+	wake_up(&dev->wait);
 }
 
 static void ep0_complete (struct usb_ep *ep, struct usb_request *req)
 {
 	struct dev_data		*dev = ep->driver_data;
 	unsigned long		flags;
-	int			free = 1;
 
 	/* for control OUT, data must still get to userspace */
 	spin_lock_irqsave(&dev->lock, flags);
-	if (!dev->setup_in) {
+	if (!dev->setup_in && dev->setup_wLength) {
 		dev->setup_out_error = (req->status != 0);
-		if (!dev->setup_out_error)
-			free = 0;
+		if (dev->setup_out_error) {
+			dev->setup_out_len = 0;
+		} else {
+			dev->setup_out_len = min_t(unsigned int, req->actual,
+						   sizeof(dev->setup_buf));
+			memcpy(dev->setup_buf, req->buf, dev->setup_out_len);
+		}
 		dev->setup_out_ready = 1;
-		ep0_readable (dev);
+		ep0_readable(dev);
 	}
 
-	/* clean up as appropriate */
-	if (free && req->buf != &dev->rbuf)
-		clean_req (ep, req);
-	req->complete = epio_complete;
+	clean_req(ep, req);
+	dev->ep0_req_queued = false;
 	spin_unlock_irqrestore(&dev->lock, flags);
+
+	/* gadgetfs_unbind() waits for this before freeing the request */
+	wake_up(&dev->wait);
 }
 
 static int setup_req (struct usb_ep *ep, struct usb_request *req, u16 len)
 {
 	struct dev_data	*dev = ep->driver_data;
 
-	if (dev->setup_out_ready) {
+	if (dev->ep0_req_queued) {
 		DBG (dev, "ep0 request busy!\n");
 		return -EBUSY;
 	}
-	if (len > sizeof (dev->rbuf))
-		req->buf = kmalloc(len, GFP_ATOMIC);
-	if (req->buf == NULL) {
+	if (len > sizeof(dev->rbuf)) {
+		dev->ep0_req_buf = kmalloc(len, GFP_ATOMIC);
+		if (!dev->ep0_req_buf) {
+			req->buf = dev->rbuf;
+			return -ENOMEM;
+		}
+		req->buf = dev->ep0_req_buf;
+	} else {
 		req->buf = dev->rbuf;
-		return -ENOMEM;
 	}
 	req->complete = ep0_complete;
 	req->length = len;
@@ -1039,12 +1072,30 @@ static int setup_req (struct usb_ep *ep, struct usb_request *req, u16 len)
 	return 0;
 }
 
+/*
+ * Consume a pending setup abort and report it to userspace.  Called with
+ * dev->lock held.  Return to the connected state so that the next event
+ * read is not misdirected into the control data path, but leave a state
+ * that gadgetfs_unbind() already changed alone.
+ */
+static bool ep0_check_abort(struct dev_data *dev)
+{
+	if (!dev->setup_abort)
+		return false;
+
+	dev->setup_abort = 0;
+	if (dev->state == STATE_DEV_SETUP)
+		dev->state = STATE_DEV_CONNECTED;
+	return true;
+}
+
 static ssize_t
 ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 {
 	struct dev_data			*dev = fd->private_data;
 	ssize_t				retval;
 	enum ep0_state			state;
+	u8				tmp[RBUF_SIZE];
 
 	spin_lock_irq (&dev->lock);
 	if (dev->state <= STATE_DEV_OPENED) {
@@ -1053,8 +1104,7 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 	}
 
 	/* report fd mode change before acting on it */
-	if (dev->setup_abort) {
-		dev->setup_abort = 0;
+	if (ep0_check_abort(dev)) {
 		retval = -EIDRM;
 		goto done;
 	}
@@ -1073,13 +1123,20 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 			struct usb_request	*req = dev->req;
 
 			if ((retval = setup_req (ep, req, 0)) == 0) {
+				dev->state = STATE_DEV_CONNECTED;
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
+			} else {
+				dev->state = STATE_DEV_CONNECTED;
 			}
-			dev->state = STATE_DEV_CONNECTED;
 
 			/* assume that was SET_CONFIGURATION */
 			if (dev->current_config) {
@@ -1102,32 +1159,43 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 			}
 			spin_unlock_irq (&dev->lock);
 			retval = wait_event_interruptible (dev->wait,
-					dev->setup_out_ready != 0);
+					dev->setup_out_ready ||
+					dev->setup_abort);
 
 			/* FIXME state could change from under us */
 			spin_lock_irq (&dev->lock);
 			if (retval)
 				goto done;
 
-			if (dev->state != STATE_DEV_SETUP) {
+			if (ep0_check_abort(dev)) {
+				retval = -EIDRM;
+				goto done;
+			}
+			if (dev->state != STATE_DEV_SETUP ||
+			    dev->setup_in || !dev->setup_out_ready) {
 				retval = -ECANCELED;
 				goto done;
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
@@ -1258,8 +1326,7 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 	ssize_t			retval = -ESRCH;
 
 	/* report fd mode change before acting on it */
-	if (dev->setup_abort) {
-		dev->setup_abort = 0;
+	if (ep0_check_abort(dev)) {
 		retval = -EIDRM;
 
 	/* data and/or status stage for control request */
@@ -1267,29 +1334,45 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 
 		len = min_t(size_t, len, dev->setup_wLength);
 		if (dev->setup_in) {
-			retval = setup_req (dev->gadget->ep0, dev->req, len);
+			u8	tmp[RBUF_SIZE];
+			bool	zero = len < dev->setup_wLength;
+			unsigned int generation = dev->setup_generation;
+
+			dev->state = STATE_DEV_CONNECTED;
+			spin_unlock_irq(&dev->lock);
+			if (copy_from_user(tmp, buf, len)) {
+				spin_lock_irq(&dev->lock);
+				return -EFAULT;
+			}
+			spin_lock_irq(&dev->lock);
+			/*
+			 * A control request that arrived while dev->lock was
+			 * dropped supersedes this data stage; do not queue the
+			 * stale response for it.
+			 */
+			if (dev->setup_generation != generation)
+				return -EIDRM;
+			if (dev->state != STATE_DEV_CONNECTED)
+				return -ECANCELED;
+			retval = setup_req(dev->gadget->ep0, dev->req, len);
 			if (retval == 0) {
-				dev->state = STATE_DEV_CONNECTED;
+				memcpy(dev->req->buf, tmp, len);
+				dev->req->zero = zero;
 				++dev->udc_usage;
-				spin_unlock_irq (&dev->lock);
-				if (copy_from_user (dev->req->buf, buf, len))
-					retval = -EFAULT;
-				else {
-					if (len < dev->setup_wLength)
-						dev->req->zero = 1;
-					retval = usb_ep_queue (
-						dev->gadget->ep0, dev->req,
-						GFP_KERNEL);
-				}
+				dev->ep0_req_queued = true;
+				spin_unlock_irq(&dev->lock);
+				retval = usb_ep_queue(
+					dev->gadget->ep0, dev->req,
+					GFP_KERNEL);
 				spin_lock_irq(&dev->lock);
 				--dev->udc_usage;
 				if (retval < 0) {
+					dev->ep0_req_queued = false;
 					clean_req (dev->gadget->ep0, dev->req);
 				} else
 					retval = len;
-
-				return retval;
 			}
+			return retval;
 
 		/* can stall some OUT transfers */
 		} else if (dev->setup_can_stall) {
@@ -1360,8 +1443,7 @@ ep0_poll (struct file *fd, poll_table *wait)
 	spin_lock_irq(&dev->lock);
 
 	/* report fd mode change before acting on it */
-	if (dev->setup_abort) {
-		dev->setup_abort = 0;
+	if (ep0_check_abort(dev)) {
 		mask = EPOLLHUP;
 		goto out;
 	}
@@ -1470,6 +1552,10 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	u16				w_value = le16_to_cpu(ctrl->wValue);
 	u16				w_length = le16_to_cpu(ctrl->wLength);
 
+	spin_lock(&dev->lock);
+	/* invalidate userspace copies started for an older control request */
+	dev->setup_generation++;
+
 	if (w_length > RBUF_SIZE) {
 		if (ctrl->bRequestType & USB_DIR_IN) {
 			/* Cast away the const, we are going to overwrite on purpose. */
@@ -1478,11 +1564,15 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 			*temp = cpu_to_le16(RBUF_SIZE);
 			w_length = RBUF_SIZE;
 		} else {
+			spin_unlock(&dev->lock);
 			return value;
 		}
 	}
 
-	spin_lock (&dev->lock);
+	if (dev->ep0_req_queued) {
+		spin_unlock(&dev->lock);
+		return -EBUSY;
+	}
 	dev->setup_abort = 0;
 	if (dev->state == STATE_DEV_UNCONNECTED) {
 		if (gadget_is_dualspeed(gadget)
@@ -1505,8 +1595,11 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	 * then ep0_{read,write} will report the wrong status. controller
 	 * driver will have aborted pending i/o.
 	 */
-	} else if (dev->state == STATE_DEV_SETUP)
+	} else if (dev->state == STATE_DEV_SETUP) {
 		dev->setup_abort = 1;
+		/* wake an ep0_read() waiting for the aborted data stage */
+		ep0_readable(dev);
+	}
 
 	req->buf = dev->rbuf;
 	req->context = NULL;
@@ -1618,6 +1711,7 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 			dev->setup_wLength = w_length;
 			dev->setup_out_ready = 0;
 			dev->setup_out_error = 0;
+			dev->setup_out_len = 0;
 
 			/* read DATA stage for OUT right away */
 			if (unlikely (!dev->setup_in && w_length)) {
@@ -1627,12 +1721,14 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 					break;
 
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
@@ -1663,21 +1759,26 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
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
+			req->buf = dev->rbuf;
 			DBG (dev, "ep_queue --> %d\n", value);
 			req->status = 0;
 		}
+		spin_unlock(&dev->lock);
 		return value;
 	}
 
 	/* device stalls when value < 0 */
+	req->buf = dev->rbuf;
 	spin_unlock (&dev->lock);
 	return value;
 }
@@ -1771,6 +1872,7 @@ static void
 gadgetfs_unbind (struct usb_gadget *gadget)
 {
 	struct dev_data		*dev = get_gadget_data (gadget);
+	bool			queued;
 
 	DBG (dev, "%s\n", __func__);
 
@@ -1781,15 +1883,29 @@ gadgetfs_unbind (struct usb_gadget *gadget)
 		usleep_range(1000, 2000);
 		spin_lock_irq(&dev->lock);
 	}
+	queued = dev->ep0_req_queued;
 	spin_unlock_irq (&dev->lock);
 
+	if (dev->req) {
+		if (queued) {
+			usb_ep_dequeue(gadget->ep0, dev->req);
+			/*
+			 * usb_ep_dequeue() may return before the completion
+			 * routine runs.  Do not free the request until the
+			 * controller has given it back.
+			 */
+			wait_event(dev->wait, !dev->ep0_req_queued);
+		}
+		dev->req->buf = dev->rbuf;
+		clean_req(gadget->ep0, dev->req);
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
@@ -1816,11 +1932,13 @@ static int gadgetfs_bind(struct usb_gadget *gadget,
 	get_dev (dev);
 
 	/* preallocate control response and buffer */
+	dev->ep0_req_queued = false;
 	dev->req = usb_ep_alloc_request (gadget->ep0, GFP_KERNEL);
 	if (!dev->req)
 		goto enomem;
 	dev->req->context = NULL;
-	dev->req->complete = epio_complete;
+	dev->req->complete = dev_req_complete;
+	dev->req->buf = dev->rbuf;
 
 	if (activate_ep_files (dev) < 0)
 		goto enomem;

-- 
Git-155)

