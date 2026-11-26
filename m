From: Jing Lin <kayano050408@gmail.com>
Date: Thu, 26 Nov 2026 21:44:53 +0900
Subject: [PATCH v10 3/6] usb: gadget: gadgetfs: fix ep0 setup_abort
 tracking and reporting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-gadgetfs-ep0-v10-3-8add6d9cace2@gmail.com>
References: <20261126-gadgetfs-ep0-v10-0-8add6d9cace2@gmail.com>
In-Reply-To: <20261126-gadgetfs-ep0-v10-0-8add6d9cace2@gmail.com>
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Jing Lin <kayano050408@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795697092; l=8977;
 i=kayano050408@gmail.com; s=20261106-gadgetfs-gmail;
 h=from:subject:message-id; bh=5C0D9ysmCbPz6S2LHkxBb9aJscALWiiDKsaMNJm6WcU=;
 b=IQ4QpizuFvlDWhlT4fIyEtn/JWdydj44/+BXYx1P4uuDYyy33DOoksoN/tlcTFiwiJGNUzXlc
 nQ1ekI1mT8PA51iNMJUz5CCcZVm6WQ3c7WWFaR8vUto7krOnHemW7Jr
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=DtAI52kU3F0sVbAiS4n+5b4UKMnVF398eKHlj3H9KBY=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261106-gadgetfs-gmail with auth_id=1433
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Several ep0 state transitions lose setup_abort notifications or leave
dev->state stuck in STATE_DEV_SETUP:

1. ep0_poll() clears dev->setup_abort when reporting EPOLLHUP, so the
   following ep0_read() or ep0_write() never sees -EIDRM.

2. gadgetfs_disconnect() sets dev->state to STATE_DEV_UNCONNECTED before
   calling next_event(GADGETFS_DISCONNECT), skipping the STATE_DEV_SETUP
   check that sets dev->setup_abort.

3. gadgetfs_setup() skips setting dev->setup_abort on early returns,
   leaves an uncollected GADGETFS_SETUP event queued when a non-delegated
   request supersedes it, and leaves dev->state in STATE_DEV_SETUP when
   aborting an active delegated transfer so in-kernel responses are not
   queued.

4. ep0_read() sleeping on event delivery wakes only on dev->ev_next and
   jumps straight to scan: without re-checking setup_abort or dev->state,
   which can consume a subsequent GADGETFS_SETUP event while setup_abort
   remains set.

Report EPOLLHUP in ep0_poll() without clearing setup_abort, consume
setup_abort via ep0_check_abort() in ep0_read() and ep0_write()
(including after waking from the ep0_read() event wait), update
dev->state after next_event() in gadgetfs_disconnect(), and discard any
stale GADGETFS_SETUP event and record setup_abort at the start of
gadgetfs_setup().

Fixes: 1da177e4c3f41 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 114 +++++++++++++++++++++++++-------------
 1 file changed, 76 insertions(+), 38 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index a0dc350a7..2de46b0c5 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -1096,6 +1096,23 @@ static int queue_ep0_req(struct dev_data *dev, bool process_ctx)
 	return ret;
 }
 
+/*
+ * Consume a pending setup abort and report it to userspace.  Called with
+ * dev->lock held.  Return to the connected state so that the next event
+ * read is not misdirected into the control data path, without overwriting
+ * a state that disconnect or unbind already changed.
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
@@ -1110,8 +1127,7 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 	}
 
 	/* report fd mode change before acting on it */
-	if (dev->setup_abort) {
-		dev->setup_abort = 0;
+	if (ep0_check_abort(dev)) {
 		retval = -EIDRM;
 		goto done;
 	}
@@ -1249,11 +1265,20 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 		DBG (dev, "%s wait\n", __func__);
 
 		/* wait for events */
-		retval = wait_event_interruptible (dev->wait,
-				dev->ev_next != 0);
+		retval = wait_event_interruptible(dev->wait,
+				dev->ev_next != 0 || dev->setup_abort);
 		if (retval < 0)
 			return retval;
 		spin_lock_irq (&dev->lock);
+		if (ep0_check_abort(dev)) {
+			retval = -EIDRM;
+			goto done;
+		}
+		state = dev->state;
+		if (state == STATE_DEV_SETUP) {
+			retval = -ECANCELED;
+			goto done;
+		}
 		goto scan;
 	}
 
@@ -1262,11 +1287,29 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 	return retval;
 }
 
+/* Called with dev->lock held.  Drop a queued event of @type, if any. */
+static void ep0_discard_event(struct dev_data *dev,
+			      enum usb_gadgetfs_event_type type)
+{
+	unsigned int			i;
+
+	for (i = 0; i != dev->ev_next; i++) {
+		if (dev->event[i].type != type)
+			continue;
+		DBG(dev, "discard old event[%d] %d\n", i, type);
+		dev->ev_next--;
+		if (i == dev->ev_next)
+			break;
+		/* indices start at zero, for simplicity */
+		memmove(&dev->event[i], &dev->event[i + 1],
+			sizeof(struct usb_gadgetfs_event) * (dev->ev_next - i));
+	}
+}
+
 static struct usb_gadgetfs_event *
 next_event (struct dev_data *dev, enum usb_gadgetfs_event_type type)
 {
 	struct usb_gadgetfs_event	*event;
-	unsigned			i;
 
 	switch (type) {
 	/* these events purge the queue */
@@ -1280,18 +1323,7 @@ next_event (struct dev_data *dev, enum usb_gadgetfs_event_type type)
 	case GADGETFS_SETUP:		/* previous request timed out */
 	case GADGETFS_SUSPEND:		/* same effect */
 		/* these events can't be repeated */
-		for (i = 0; i != dev->ev_next; i++) {
-			if (dev->event [i].type != type)
-				continue;
-			DBG(dev, "discard old event[%d] %d\n", i, type);
-			dev->ev_next--;
-			if (i == dev->ev_next)
-				break;
-			/* indices start at zero, for simplicity */
-			memmove (&dev->event [i], &dev->event [i + 1],
-				sizeof (struct usb_gadgetfs_event)
-					* (dev->ev_next - i));
-		}
+		ep0_discard_event(dev, type);
 		break;
 	default:
 		BUG ();
@@ -1311,8 +1343,7 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 	ssize_t			retval = -ESRCH;
 
 	/* report fd mode change before acting on it */
-	if (dev->setup_abort) {
-		dev->setup_abort = 0;
+	if (ep0_check_abort(dev)) {
 		retval = -EIDRM;
 
 	/* data and/or status stage for control request */
@@ -1336,13 +1367,9 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 			 * Reject the write if a new control request arrived
 			 * while dev->lock was dropped for memdup_user().
 			 */
-			if (dev->setup_generation != generation) {
+			if (ep0_check_abort(dev) ||
+			    dev->setup_generation != generation) {
 				kfree(kbuf);
-				if (dev->setup_abort) {
-					dev->setup_abort = 0;
-					if (dev->state == STATE_DEV_SETUP)
-						dev->state = STATE_DEV_CONNECTED;
-				}
 				return -EIDRM;
 			}
 			if (dev->state != STATE_DEV_SETUP || !dev->setup_in) {
@@ -1433,9 +1460,8 @@ ep0_poll (struct file *fd, poll_table *wait)
 
 	spin_lock_irq(&dev->lock);
 
-	/* report fd mode change before acting on it */
+	/* report fd mode change without consuming it before read/write */
 	if (dev->setup_abort) {
-		dev->setup_abort = 0;
 		mask = EPOLLHUP;
 		goto out;
 	}
@@ -1548,6 +1574,24 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	/* invalidate userspace copies started for an older control request */
 	dev->setup_generation++;
 
+	/*
+	 * If userspace has not collected a previous GADGETFS_SETUP event,
+	 * this SETUP supersedes it; drop it before any early return or
+	 * in-kernel handling so ep0_read() cannot enter STATE_DEV_SETUP
+	 * for an abandoned transfer.
+	 */
+	ep0_discard_event(dev, GADGETFS_SETUP);
+
+	/*
+	 * Record abort of an active delegated transfer and return to the
+	 * connected state before any early return or in-kernel response.
+	 */
+	if (dev->state == STATE_DEV_SETUP) {
+		dev->setup_abort = 1;
+		dev->state = STATE_DEV_CONNECTED;
+		ep0_readable(dev);
+	}
+
 	if (w_length > RBUF_SIZE) {
 		if (ctrl->bRequestType & USB_DIR_IN) {
 			/* Cast away the const, we are going to overwrite on purpose. */
@@ -1564,7 +1608,6 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 		spin_unlock(&dev->lock);
 		return -EBUSY;
 	}
-	dev->setup_abort = 0;
 	if (dev->state == STATE_DEV_UNCONNECTED) {
 		if (gadget_is_dualspeed(gadget)
 				&& gadget->speed == USB_SPEED_HIGH
@@ -1580,14 +1623,7 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 		event = next_event (dev, GADGETFS_CONNECT);
 		event->u.speed = gadget->speed;
 		ep0_readable (dev);
-
-	/* host may have given up waiting for response.  we can miss control
-	 * requests handled lower down (device/endpoint status and features);
-	 * then ep0_{read,write} will report the wrong status. controller
-	 * driver will have aborted pending i/o.
-	 */
-	} else if (dev->state == STATE_DEV_SETUP)
-		dev->setup_abort = 1;
+	}
 
 	req->buf = dev->rbuf;
 	switch (ctrl->bRequest) {
@@ -1937,12 +1973,13 @@ gadgetfs_disconnect (struct usb_gadget *gadget)
 	unsigned long		flags;
 
 	spin_lock_irqsave (&dev->lock, flags);
-	if (dev->state == STATE_DEV_UNCONNECTED)
+	if (dev->state == STATE_DEV_UNCONNECTED ||
+	    dev->state == STATE_DEV_UNBOUND)
 		goto exit;
-	dev->state = STATE_DEV_UNCONNECTED;
 
 	INFO (dev, "disconnected\n");
 	next_event (dev, GADGETFS_DISCONNECT);
+	dev->state = STATE_DEV_UNCONNECTED;
 	ep0_readable (dev);
 exit:
 	spin_unlock_irqrestore (&dev->lock, flags);
@@ -2145,6 +2182,7 @@ gadget_dev_open (struct inode *inode, struct file *fd)
 	spin_lock_irq(&dev->lock);
 	if (dev->state == STATE_DEV_DISABLED) {
 		dev->ev_next = 0;
+		dev->setup_abort = 0;
 		dev->state = STATE_DEV_OPENED;
 		fd->private_data = dev;
 		get_dev (dev);

-- 
Git-155)

