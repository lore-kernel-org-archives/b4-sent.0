From: Jing Lin <kayano050408@gmail.com>
Date: Thu, 26 Nov 2026 21:44:54 +0900
Subject: [PATCH v10 4/6] usb: gadget: gadgetfs: NAK new setups until
 control-OUT data is read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-gadgetfs-ep0-v10-4-8add6d9cace2@gmail.com>
References: <20261126-gadgetfs-ep0-v10-0-8add6d9cace2@gmail.com>
In-Reply-To: <20261126-gadgetfs-ep0-v10-0-8add6d9cace2@gmail.com>
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Jing Lin <kayano050408@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795697092; l=14204;
 i=kayano050408@gmail.com; s=20261106-gadgetfs-gmail;
 h=from:subject:message-id; bh=Py4xREetHs00U99XG3ye+mv7Pvc1NbgocC7r0FmcWu8=;
 b=R7kd/7HSd4qzzfMJ2RmHCoGa7Ia2yU3LIxdRSdg0q0m6Ej8NMvpHgWF81zOr9eE2X4BUuVNvx
 qvgyYSOHzYyB3g50ULyfREsexa+CIRr/XuMECubOy0PPiT4JaHs97vQ
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=DtAI52kU3F0sVbAiS4n+5b4UKMnVF398eKHlj3H9KBY=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261106-gadgetfs-gmail with auth_id=1433
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For a delegated 3-stage control-OUT transfer, gadgetfs_setup() submits
the data-stage request immediately and the controller acknowledges the
transfer to the host as soon as it completes, before userspace calls
ep0_read() to collect the payload.  If another control transfer arrives
in the meantime, aborting the earlier state erases the completed
transfer before userspace ever receives it, and reuses dev->req and
dev->rbuf while ep0_read() may be copying to userspace.

When a new setup packet arrives while a properly completed control-OUT
payload has not yet been read by userspace, save the setup packet in
dev->pending_setup and return without submitting an ep0 request so the
controller NAKs the new transfer until ep0_read() finishes copying the
completed payload.  Once the copy completes, replay dev->pending_setup
and stall ep0 with usb_ep_set_halt() if it fails while still on that
request.

Track the active control-OUT request with dev->setup_out_generation so
ep0_complete() ignores requests superseded before completion, and
recheck dev->state and dev->setup_generation after queue_ep0_req()
re-acquires dev->lock so stale GADGETFS_SETUP events are not queued
after a concurrent disconnect, unbind, or newer setup.

Also check dev->setup_wLength == 0 for zero-length status acknowledgments
in ep0_read() and complete them with dev_req_complete() so zero-length
transfers never set setup_out_ready.

Fixes: 1da177e4c3f41 ("Linux-2.6.12-rc2")
Suggested-by: Alan Stern <stern@rowland.harvard.edu>
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 206 ++++++++++++++++++++++++++++++--------
 1 file changed, 164 insertions(+), 42 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index 2de46b0c5..2d96320cb 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -143,6 +143,11 @@ struct dev_data {
 	bool				ep0_req_queued;
 	void				*ep0_req_buf;
 	unsigned int			setup_generation;
+	unsigned int			setup_out_generation;
+	unsigned int			setup_out_len;
+	bool				setup_out_copying;
+	bool				setup_pending;
+	struct usb_ctrlrequest		pending_setup;
 
 	/* the rest is basically write-once */
 	struct usb_config_descriptor	*config, *hs_config;
@@ -1021,23 +1026,26 @@ static void ep0_complete(struct usb_ep *ep, struct usb_request *req)
 {
 	struct dev_data		*dev = req->context;
 	unsigned long		flags;
-	int			free = 1;
 
 	/* for control OUT, data must still get to userspace */
 	spin_lock_irqsave(&dev->lock, flags);
-	if (!dev->setup_in) {
+	if ((dev->state == STATE_DEV_CONNECTED ||
+	     dev->state == STATE_DEV_SETUP) &&
+	    dev->setup_generation == dev->setup_out_generation) {
 		dev->setup_out_error = (req->status != 0);
-		if (!dev->setup_out_error)
-			free = 0;
+		if (dev->setup_out_error) {
+			dev->setup_out_len = 0;
+			clean_req(ep, req);
+		} else {
+			dev->setup_out_len = min_t(unsigned int, req->actual,
+						   sizeof(dev->rbuf));
+			req->complete = dev_req_complete;
+		}
 		dev->setup_out_ready = 1;
 		ep0_readable(dev);
-	}
-
-	/* clean up as appropriate */
-	if (free)
+	} else {
 		clean_req(ep, req);
-	else
-		req->complete = dev_req_complete;
+	}
 	dev->ep0_req_queued = false;
 	wake_up(&dev->wait);
 	spin_unlock_irqrestore(&dev->lock, flags);
@@ -1047,7 +1055,8 @@ static int setup_req(struct usb_ep *ep, struct usb_request *req, u16 len)
 {
 	struct dev_data	*dev = ep->driver_data;
 
-	if (dev->setup_out_ready || dev->ep0_req_queued) {
+	if (dev->setup_out_ready || dev->setup_out_copying ||
+	    dev->ep0_req_queued) {
 		DBG(dev, "ep0 request busy!\n");
 		return -EBUSY;
 	}
@@ -1113,6 +1122,43 @@ static bool ep0_check_abort(struct dev_data *dev)
 	return true;
 }
 
+static int gadgetfs_do_setup(struct dev_data *dev,
+			     const struct usb_ctrlrequest *ctrl,
+			     bool process_ctx);
+
+/*
+ * Replay a SETUP packet that was NAKed while userspace had not yet read
+ * a completed control-OUT data stage.  Called with dev->lock held from
+ * process context (IRQs disabled).
+ */
+static void ep0_process_pending_setup(struct dev_data *dev)
+{
+	struct usb_ctrlrequest	ctrl;
+	unsigned int		expected_gen;
+	int			status;
+
+	if (!dev->setup_pending)
+		return;
+
+	ctrl = dev->pending_setup;
+	dev->setup_pending = false;
+	if (dev->state != STATE_DEV_CONNECTED &&
+	    dev->state != STATE_DEV_UNCONNECTED)
+		return;
+
+	expected_gen = dev->setup_generation + 1;
+	status = gadgetfs_do_setup(dev, &ctrl, true);
+	if (status < 0 && dev->setup_generation == expected_gen &&
+	    (dev->state == STATE_DEV_CONNECTED ||
+	     dev->state == STATE_DEV_UNCONNECTED)) {
+		++dev->udc_usage;
+		spin_unlock_irq(&dev->lock);
+		(void)usb_ep_set_halt(dev->gadget->ep0);
+		spin_lock_irq(&dev->lock);
+		--dev->udc_usage;
+	}
+}
+
 static ssize_t
 ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 {
@@ -1141,14 +1187,20 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 			retval = -EL2HLT;
 			dev->state = STATE_DEV_CONNECTED;
 
-		} else if (len == 0) {		/* ack SET_CONFIGURATION etc */
-			struct usb_ep		*ep = dev->gadget->ep0;
+		} else if (dev->setup_wLength == 0) {	/* ack SET_CONFIGURATION etc */
 			struct usb_request	*req = dev->req;
 
-			retval = setup_req(ep, req, 0);
+			if (dev->setup_out_ready || dev->setup_out_copying ||
+			    dev->ep0_req_queued) {
+				retval = -EBUSY;
+				goto done;
+			}
+			req->buf = dev->rbuf;
+			req->complete = dev_req_complete;
+			req->length = 0;
+			req->zero = 0;
 			dev->state = STATE_DEV_CONNECTED;
-			if (retval == 0)
-				retval = queue_ep0_req(dev, true);
+			retval = queue_ep0_req(dev, true);
 
 			/* assume that was SET_CONFIGURATION */
 			if (dev->current_config) {
@@ -1164,6 +1216,8 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 			}
 
 		} else {			/* collect OUT data */
+			unsigned int generation = dev->setup_generation;
+
 			if ((fd->f_flags & O_NONBLOCK) != 0
 					&& !dev->setup_out_ready) {
 				retval = -EAGAIN;
@@ -1171,32 +1225,49 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 			}
 			spin_unlock_irq (&dev->lock);
 			retval = wait_event_interruptible (dev->wait,
-					dev->setup_out_ready != 0);
+					dev->setup_out_ready ||
+					dev->setup_abort ||
+					dev->setup_generation != generation ||
+					dev->state != STATE_DEV_SETUP);
 
-			/* FIXME state could change from under us */
 			spin_lock_irq (&dev->lock);
 			if (retval)
 				goto done;
 
-			if (dev->state != STATE_DEV_SETUP) {
+			if (ep0_check_abort(dev)) {
+				retval = -EIDRM;
+				goto done;
+			}
+			if (dev->state != STATE_DEV_SETUP ||
+			    dev->setup_generation != generation ||
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
+				dev->setup_out_ready = 0;
+				dev->setup_out_len = 0;
+				dev->setup_out_copying = true;
 				++dev->udc_usage;
 				spin_unlock_irq(&dev->lock);
-				if (copy_to_user (buf, dev->req->buf, len))
+				if (copy_to_user(buf, dev->rbuf, len))
 					retval = -EFAULT;
 				else
 					retval = len;
 				spin_lock_irq(&dev->lock);
 				--dev->udc_usage;
-				clean_req (dev->gadget->ep0, dev->req);
+				dev->setup_out_copying = false;
+				if (dev->req)
+					clean_req(dev->gadget->ep0, dev->req);
+				ep0_process_pending_setup(dev);
 				/* NOTE userspace can't yet choose to stall */
 			}
 		}
@@ -1376,7 +1447,8 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 				kfree(kbuf);
 				return -ECANCELED;
 			}
-			if (dev->setup_out_ready || dev->ep0_req_queued) {
+			if (dev->setup_out_ready || dev->setup_out_copying ||
+			    dev->ep0_req_queued) {
 				kfree(kbuf);
 				return -EBUSY;
 			}
@@ -1469,6 +1541,8 @@ ep0_poll (struct file *fd, poll_table *wait)
 	if (dev->state == STATE_DEV_SETUP) {
 		if (dev->setup_in || dev->setup_can_stall)
 			mask = EPOLLOUT;
+		else if (dev->setup_out_ready)
+			mask = EPOLLIN;
 	} else {
 		if (dev->ev_next != 0)
 			mask = EPOLLIN;
@@ -1560,19 +1634,24 @@ config_buf (struct dev_data *dev, u8 type, unsigned index)
 	return len;
 }
 
+/* Called with dev->lock held. */
 static int
-gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
+gadgetfs_do_setup(struct dev_data *dev, const struct usb_ctrlrequest *ctrl,
+		  bool process_ctx)
 {
-	struct dev_data			*dev = get_gadget_data (gadget);
+	struct usb_gadget		*gadget = dev->gadget;
 	struct usb_request		*req = dev->req;
 	int				value = -EOPNOTSUPP;
 	struct usb_gadgetfs_event	*event;
 	u16				w_value = le16_to_cpu(ctrl->wValue);
 	u16				w_length = le16_to_cpu(ctrl->wLength);
+	unsigned int			generation;
 
-	spin_lock(&dev->lock);
 	/* invalidate userspace copies started for an older control request */
-	dev->setup_generation++;
+	generation = ++dev->setup_generation;
+	dev->setup_out_ready = 0;
+	dev->setup_out_error = 0;
+	dev->setup_out_len = 0;
 
 	/*
 	 * If userspace has not collected a previous GADGETFS_SETUP event,
@@ -1600,20 +1679,16 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 			*temp = cpu_to_le16(RBUF_SIZE);
 			w_length = RBUF_SIZE;
 		} else {
-			spin_unlock(&dev->lock);
 			return value;
 		}
 	}
-	if (dev->ep0_req_queued) {
-		spin_unlock(&dev->lock);
+	if (dev->ep0_req_queued)
 		return -EBUSY;
-	}
 	if (dev->state == STATE_DEV_UNCONNECTED) {
 		if (gadget_is_dualspeed(gadget)
 				&& gadget->speed == USB_SPEED_HIGH
 				&& dev->hs_config == NULL) {
-			spin_unlock(&dev->lock);
-			ERROR (dev, "no high speed config??\n");
+			ERROR(dev, "no high speed config??\n");
 			return -EINVAL;
 		}
 
@@ -1734,6 +1809,7 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 			dev->setup_wLength = w_length;
 			dev->setup_out_ready = 0;
 			dev->setup_out_error = 0;
+			dev->setup_out_len = 0;
 
 			/* read DATA stage for OUT right away */
 			if (unlikely(!dev->setup_in && w_length)) {
@@ -1742,19 +1818,22 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 				if (value < 0)
 					break;
 
-				value = queue_ep0_req(dev, false);
-				if (value < 0)
-					break;
-
 				/* we can't currently stall these */
 				dev->setup_can_stall = 0;
+				dev->setup_out_generation = generation;
+
+				value = queue_ep0_req(dev, process_ctx);
+				if (dev->state != STATE_DEV_CONNECTED ||
+				    dev->setup_generation != generation)
+					return 0;
+				if (value < 0)
+					break;
 			}
 
 			/* state changes when reader collects event */
 			event = next_event (dev, GADGETFS_SETUP);
 			event->u.setup = *ctrl;
 			ep0_readable (dev);
-			spin_unlock (&dev->lock);
 			/*
 			 * Return USB_GADGET_DELAYED_STATUS as a workaround to
 			 * stop some UDC drivers (e.g. dwc3) from automatically
@@ -1774,17 +1853,46 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 		req->zero = value < w_length;
 		req->complete = dev_req_complete;
 
-		value = queue_ep0_req(dev, false);
+		value = queue_ep0_req(dev, process_ctx);
+		if (dev->state != STATE_DEV_CONNECTED ||
+		    dev->setup_generation != generation)
+			return 0;
 		if (value < 0) {
 			DBG(dev, "ep_queue --> %d\n", value);
 			req->status = 0;
 		}
-		spin_unlock(&dev->lock);
 		return value;
 	}
 
 	/* device stalls when value < 0 */
 	req->buf = dev->rbuf;
+	return value;
+}
+
+static int
+gadgetfs_setup(struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
+{
+	struct dev_data		*dev = get_gadget_data(gadget);
+	u16			w_length = le16_to_cpu(ctrl->wLength);
+	int			value;
+
+	spin_lock(&dev->lock);
+	/*
+	 * A properly completed control-OUT transfer has already been
+	 * acknowledged to the host; do not let a new SETUP erase it
+	 * before userspace reads the payload.  Leave ep0 without a
+	 * queued request so the controller NAKs the new transfer until
+	 * ep0_read() finishes collecting the data.
+	 */
+	if ((dev->setup_out_ready && !dev->setup_out_error) ||
+	    dev->setup_out_copying) {
+		dev->pending_setup = *ctrl;
+		dev->setup_pending = true;
+		spin_unlock(&dev->lock);
+		return w_length == 0 ? USB_GADGET_DELAYED_STATUS : 0;
+	}
+	dev->setup_pending = false;
+	value = gadgetfs_do_setup(dev, ctrl, false);
 	spin_unlock(&dev->lock);
 	return value;
 }
@@ -1884,6 +1992,11 @@ gadgetfs_unbind (struct usb_gadget *gadget)
 
 	spin_lock_irq (&dev->lock);
 	dev->state = STATE_DEV_UNBOUND;
+	dev->setup_generation++;
+	dev->setup_out_ready = 0;
+	dev->setup_out_error = 0;
+	dev->setup_out_len = 0;
+	dev->setup_pending = false;
 	while (dev->udc_usage > 0) {
 		spin_unlock_irq(&dev->lock);
 		usleep_range(1000, 2000);
@@ -1978,6 +2091,11 @@ gadgetfs_disconnect (struct usb_gadget *gadget)
 		goto exit;
 
 	INFO (dev, "disconnected\n");
+	dev->setup_generation++;
+	dev->setup_out_ready = 0;
+	dev->setup_out_error = 0;
+	dev->setup_out_len = 0;
+	dev->setup_pending = false;
 	next_event (dev, GADGETFS_DISCONNECT);
 	dev->state = STATE_DEV_UNCONNECTED;
 	ep0_readable (dev);
@@ -2183,6 +2301,10 @@ gadget_dev_open (struct inode *inode, struct file *fd)
 	if (dev->state == STATE_DEV_DISABLED) {
 		dev->ev_next = 0;
 		dev->setup_abort = 0;
+		dev->setup_out_ready = 0;
+		dev->setup_out_error = 0;
+		dev->setup_out_len = 0;
+		dev->setup_pending = false;
 		dev->state = STATE_DEV_OPENED;
 		fd->private_data = dev;
 		get_dev (dev);

-- 
Git-155)

