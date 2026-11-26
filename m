From: Jing Lin <kayano050408@gmail.com>
Date: Thu, 26 Nov 2026 14:37:05 +0800
Subject: [PATCH v9 2/6] usb: gadget: gadgetfs: isolate ep0_write() buffer
 and reduce setup race
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-gadgetfs-ep0-v9-2-81b464c6e641@gmail.com>
References: <20261126-gadgetfs-ep0-v9-0-81b464c6e641@gmail.com>
In-Reply-To: <20261126-gadgetfs-ep0-v9-0-81b464c6e641@gmail.com>
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Jing Lin <kayano050408@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795675024; l=4414;
 i=kayano050408@gmail.com; s=20261126; h=from:subject:message-id;
 bh=RVJHc4be5aHnDrJZDAsXTiK0Nae84ZkXu+4RgSSPN6g=;
 b=id5dB3M9gxzBvZHwPBSRQRxNiNEwG+LFhj8s6VK4M20GcXueT43mG9LqYxtPOcdfOTHS8Zonz
 ihi8n949GjnDsTjZAuUdW0tTiUiYBLFsyb6BrXq56CXXBARKDt/LMiZ
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=40M3hugIx++9w3nkAoFXGcN/vLWsPMGDYdbduV+lUlI=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261126 with auth_id=1648
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For a delegated control-IN request, ep0_write() prepares dev->req and
copies the response from userspace with copy_from_user() after dropping
dev->lock.  A control request that arrives during that unlocked copy can
point req->buf at dev->dev or dev->config, letting copy_from_user()
overwrite a descriptor buffer, or supersede the transfer that userspace
is responding to.

Copy non-empty control-IN payloads from userspace into a private buffer
with memdup_user() before leaving STATE_DEV_SETUP or modifying dev->req,
and count setup callbacks in dev->setup_generation so ep0_write() can
discard a superseded response after retaking dev->lock.  This eliminates
the copy_from_user() race window, leaving only the unavoidable window
after dev->lock is dropped to call usb_ep_queue().

Fixes: 1da177e4c3f41 ("Linux-2.6.12-rc2")
Suggested-by: Alan Stern <stern@rowland.harvard.edu>
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 65 +++++++++++++++++++++++++++------------
 1 file changed, 46 insertions(+), 19 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index 911419a4e1a3..a0dc350a7a0d 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -142,6 +142,7 @@ struct dev_data {
 	unsigned			setup_wLength;
 	bool				ep0_req_queued;
 	void				*ep0_req_buf;
+	unsigned int			setup_generation;
 
 	/* the rest is basically write-once */
 	struct usb_config_descriptor	*config, *hs_config;
@@ -1319,27 +1320,50 @@ ep0_write (struct file *fd, const char __user *buf, size_t len, loff_t *ptr)
 
 		len = min_t(size_t, len, dev->setup_wLength);
 		if (dev->setup_in) {
-			retval = setup_req (dev->gadget->ep0, dev->req, len);
-			if (retval == 0) {
-				dev->state = STATE_DEV_CONNECTED;
-				++dev->udc_usage;
+			unsigned int	generation = dev->setup_generation;
+			bool		zero = len < dev->setup_wLength;
+			void		*kbuf = NULL;
+
+			if (len > 0) {
 				spin_unlock_irq(&dev->lock);
-				if (copy_from_user(dev->req->buf, buf, len))
-					retval = -EFAULT;
+				kbuf = memdup_user(buf, len);
 				spin_lock_irq(&dev->lock);
-				--dev->udc_usage;
-				if (retval < 0) {
-					clean_req(dev->gadget->ep0, dev->req);
-				} else {
-					if (len < dev->setup_wLength)
-						dev->req->zero = 1;
-					retval = queue_ep0_req(dev, true);
-					if (retval == 0)
-						retval = len;
-				}
+				if (IS_ERR(kbuf))
+					return PTR_ERR(kbuf);
+			}
 
-				return retval;
+			/*
+			 * Reject the write if a new control request arrived
+			 * while dev->lock was dropped for memdup_user().
+			 */
+			if (dev->setup_generation != generation) {
+				kfree(kbuf);
+				if (dev->setup_abort) {
+					dev->setup_abort = 0;
+					if (dev->state == STATE_DEV_SETUP)
+						dev->state = STATE_DEV_CONNECTED;
+				}
+				return -EIDRM;
+			}
+			if (dev->state != STATE_DEV_SETUP || !dev->setup_in) {
+				kfree(kbuf);
+				return -ECANCELED;
 			}
+			if (dev->setup_out_ready || dev->ep0_req_queued) {
+				kfree(kbuf);
+				return -EBUSY;
+			}
+
+			dev->state = STATE_DEV_CONNECTED;
+			dev->ep0_req_buf = kbuf;
+			dev->req->buf = len ? kbuf : dev->rbuf;
+			dev->req->length = len;
+			dev->req->zero = zero;
+			dev->req->complete = dev_req_complete;
+			retval = queue_ep0_req(dev, true);
+			if (retval == 0)
+				retval = len;
+			return retval;
 
 		/* can stall some OUT transfers */
 		} else if (dev->setup_can_stall) {
@@ -1520,6 +1544,10 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	u16				w_value = le16_to_cpu(ctrl->wValue);
 	u16				w_length = le16_to_cpu(ctrl->wLength);
 
+	spin_lock(&dev->lock);
+	/* invalidate userspace copies started for an older control request */
+	dev->setup_generation++;
+
 	if (w_length > RBUF_SIZE) {
 		if (ctrl->bRequestType & USB_DIR_IN) {
 			/* Cast away the const, we are going to overwrite on purpose. */
@@ -1528,11 +1556,10 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 			*temp = cpu_to_le16(RBUF_SIZE);
 			w_length = RBUF_SIZE;
 		} else {
+			spin_unlock(&dev->lock);
 			return value;
 		}
 	}
-
-	spin_lock(&dev->lock);
 	if (dev->ep0_req_queued) {
 		spin_unlock(&dev->lock);
 		return -EBUSY;

-- 
Git-155)

