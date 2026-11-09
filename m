From: Jing Lin <kayano050408@gmail.com>
Date: Mon, 09 Nov 2026 13:55:40 +0800
Subject: [PATCH v5 2/3] usb: gadget: gadgetfs: prevent ep0 event counter
 underflow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-b4-gadgetfs-ep0-v5-2-f16d0b648bc2@gmail.com>
References: <20261109-b4-gadgetfs-ep0-v5-0-f16d0b648bc2@gmail.com>
In-Reply-To: <20261109-b4-gadgetfs-ep0-v5-0-f16d0b648bc2@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Jing Lin <kayano050408@gmail.com>, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 Alan Stern <stern@rowland.harvard.edu>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, linux-usb@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794203739; l=2063;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=vqwB+Wlcpj/WeJeMyvBHLGgJ+JSJZK1Q6iHMWRJUsu0=;
 b=jP/KXYyXBBEv1X8X/NIF7qL7n36OvBHWCi/dJEuX/gS8U9WtJygerBK8rmYPA14uTGd2i1xZ9
 yyjiZof0HrADZslBDPG3A+P6v1IjQvfb0iS13CVMQn20Duy8MEex7A1
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ep0_read() snapshots dev->ev_next, drops dev->lock while copy_to_user()
runs directly from dev->event[], and subtracts the snapshot afterwards.
A concurrent disconnect, connect, setup, or another reader can reset,
deduplicate, or consume the queue in that window. This races on
dev->event[], can drop newly arrived GADGETFS_SETUP events, and wraps
dev->ev_next if the queue shrinks below the snapshot.

Dequeue the events into the local buffer and update dev->ev_next before
dropping dev->lock for copy_to_user().

Fixes: 1da177e4c3f41 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 26 ++++++++++----------------
 1 file changed, 10 insertions(+), 16 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index e9380538e..4635a603e 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -1196,25 +1196,19 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 				break;
 			}
 		}
-		spin_unlock_irq (&dev->lock);
-		len = n * sizeof (struct usb_gadgetfs_event);
-		if (copy_to_user (buf, &dev->event, len))
+		len = n * sizeof(struct usb_gadgetfs_event);
+		memcpy(tmp, &dev->event, len);
+		if (dev->ev_next > n) {
+			memmove(&dev->event[0], &dev->event[n],
+				sizeof(struct usb_gadgetfs_event)
+					* (dev->ev_next - n));
+		}
+		dev->ev_next -= n;
+		spin_unlock_irq(&dev->lock);
+		if (copy_to_user(buf, tmp, len))
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

