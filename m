From: Jing Lin <kayano050408@gmail.com>
Date: Sat, 07 Nov 2026 17:56:10 +0800
Subject: [PATCH v3 2/2] usb: gadget: gadgetfs: prevent ep0 event counter
 underflow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-b4-gadgetfs-ep0-v3-2-62089dc0ec07@gmail.com>
References: <20261107-b4-gadgetfs-ep0-v3-0-62089dc0ec07@gmail.com>
In-Reply-To: <20261107-b4-gadgetfs-ep0-v3-0-62089dc0ec07@gmail.com>
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jing Lin <kayano050408@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794045369; l=2870;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=gg6AtEtNRozQ3dqRLHDDz9k+7o2eiciGbgBgfvIVd7I=;
 b=/jJ/G3VRaOusJLupXWFdQ1XqtIFzjosJwkBySKwNE4/Kvefe3k27vULCS9+lNwIdSqOBhuX25
 P8FwJf8VjJZDM+PRaDO6hAXhUAH9EPEsynQpG1IjtgWzi8QaXWwDGrY
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ep0_read() snapshots dev->ev_next, drops dev->lock while copy_to_user()
runs, and subtracts the snapshot afterwards. A concurrent disconnect,
connect, or another reader can reset or consume the queue in that
window. If the new value is smaller than the snapshot, the unsigned
subtraction wraps and the next read walks past dev->event[N_EVENT] or
the event purge memmove uses a huge length.

Count queue purges with a generation counter and skip the consumption
when the queue was purged while userspace was copying. Clamp the
subtraction for any other concurrent decrease.

Fixes: 1da177e4c3f41 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index 87aff568a..6db3b7879 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -126,6 +126,7 @@ struct dev_data {
 	enum ep0_state			state;		/* P: lock */
 	struct usb_gadgetfs_event	event [N_EVENT];
 	unsigned			ev_next;
+	unsigned int			ev_generation;
 	struct fasync_struct		*fasync;
 	u8				current_config;
 
@@ -1174,7 +1175,7 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 scan:
 	/* return queued events right away */
 	if (dev->ev_next != 0) {
-		unsigned		i, n;
+		unsigned int		i, n, generation;
 
 		n = len / sizeof (struct usb_gadgetfs_event);
 		if (dev->ev_next < n)
@@ -1188,6 +1189,7 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 				break;
 			}
 		}
+		generation = dev->ev_generation;
 		spin_unlock_irq (&dev->lock);
 		len = n * sizeof (struct usb_gadgetfs_event);
 		if (copy_to_user (buf, &dev->event, len))
@@ -1199,12 +1201,16 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
 			 * concurrent ep0 readers may lose events.
 			 */
 			spin_lock_irq (&dev->lock);
-			if (dev->ev_next > n) {
-				memmove(&dev->event[0], &dev->event[n],
-					sizeof (struct usb_gadgetfs_event)
-						* (dev->ev_next - n));
+			if (dev->ev_generation == generation) {
+				if (dev->ev_next > n) {
+					memmove(&dev->event[0], &dev->event[n],
+						sizeof(struct usb_gadgetfs_event)
+							* (dev->ev_next - n));
+					dev->ev_next -= n;
+				} else {
+					dev->ev_next = 0;
+				}
 			}
-			dev->ev_next -= n;
 			spin_unlock_irq (&dev->lock);
 		}
 		return retval;
@@ -1252,6 +1258,7 @@ next_event (struct dev_data *dev, enum usb_gadgetfs_event_type type)
 		fallthrough;
 	case GADGETFS_CONNECT:
 		dev->ev_next = 0;
+		dev->ev_generation++;
 		break;
 	case GADGETFS_SETUP:		/* previous request timed out */
 	case GADGETFS_SUSPEND:		/* same effect */

-- 
Git-155)

