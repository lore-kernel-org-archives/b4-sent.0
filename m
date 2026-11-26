From: Jing Lin <kayano050408@gmail.com>
Date: Thu, 26 Nov 2026 21:44:55 +0900
Subject: [PATCH v10 5/6] usb: gadget: gadgetfs: prevent ep0 event counter
 underflow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-gadgetfs-ep0-v10-5-8add6d9cace2@gmail.com>
References: <20261126-gadgetfs-ep0-v10-0-8add6d9cace2@gmail.com>
In-Reply-To: <20261126-gadgetfs-ep0-v10-0-8add6d9cace2@gmail.com>
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Jing Lin <kayano050408@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795697092; l=2643;
 i=kayano050408@gmail.com; s=20261106-gadgetfs-gmail;
 h=from:subject:message-id; bh=gnhARaBCg06mbwKKexBvzjAqQQE3d8915jbK+awmKUM=;
 b=fxiFwfcVN6cs8Z4fC37d0SMTe4B0bNapyNXvym6M30SEJv219Ac9rT9cQ8He8l+Y9Ejn5REXP
 OxPXLBsPk/kBkCPOqNvyYhRV37KBVlAqXcppUWjCbGuLY96PAqPglxd
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=DtAI52kU3F0sVbAiS4n+5b4UKMnVF398eKHlj3H9KBY=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261106-gadgetfs-gmail with auth_id=1433
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ep0_read() snapshots dev->ev_next, drops dev->lock while copy_to_user()
runs directly from dev->event[], and subtracts the snapshot afterwards.
A concurrent disconnect, connect, setup, or another reader can reset,
deduplicate, or consume the queue in that window.  This races on
dev->event[], can drop newly arrived GADGETFS_SETUP events, and wraps
dev->ev_next if the queue shrinks below the snapshot.

Dequeue the events into a local buffer and update dev->ev_next before
dropping dev->lock for copy_to_user().

Fixes: 1da177e4c3f41 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 33 ++++++++++++++-------------------
 1 file changed, 14 insertions(+), 19 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index 2d96320cb..ed26cef30 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -1285,39 +1285,34 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 scan:
 	/* return queued events right away */
 	if (dev->ev_next != 0) {
-		unsigned		i, n;
+		struct usb_gadgetfs_event	events[N_EVENT];
+		unsigned int			i, n;
 
-		n = len / sizeof (struct usb_gadgetfs_event);
+		n = len / sizeof(struct usb_gadgetfs_event);
 		if (dev->ev_next < n)
 			n = dev->ev_next;
 
 		/* ep0 i/o has special semantics during STATE_DEV_SETUP */
 		for (i = 0; i < n; i++) {
-			if (dev->event [i].type == GADGETFS_SETUP) {
+			if (dev->event[i].type == GADGETFS_SETUP) {
 				dev->state = STATE_DEV_SETUP;
 				n = i + 1;
 				break;
 			}
 		}
-		spin_unlock_irq (&dev->lock);
-		len = n * sizeof (struct usb_gadgetfs_event);
-		if (copy_to_user (buf, &dev->event, len))
+		len = n * sizeof(struct usb_gadgetfs_event);
+		memcpy(events, &dev->event, len);
+		if (dev->ev_next > n) {
+			memmove(&dev->event[0], &dev->event[n],
+				sizeof(struct usb_gadgetfs_event)
+					* (dev->ev_next - n));
+		}
+		dev->ev_next -= n;
+		spin_unlock_irq(&dev->lock);
+		if (copy_to_user(buf, events, len))
 			retval = -EFAULT;
 		else
 			retval = len;
-		if (len > 0) {
-			/* NOTE this doesn't guard against broken drivers;
-			 * concurrent ep0 readers may lose events.
-			 */
-			spin_lock_irq (&dev->lock);
-			if (dev->ev_next > n) {
-				memmove(&dev->event[0], &dev->event[n],
-					sizeof (struct usb_gadgetfs_event)
-						* (dev->ev_next - n));
-			}
-			dev->ev_next -= n;
-			spin_unlock_irq (&dev->lock);
-		}
 		return retval;
 	}
 	if (fd->f_flags & O_NONBLOCK) {

-- 
Git-155)

