From: Jing Lin <kayano050408@gmail.com>
Date: Mon, 09 Nov 2026 14:50:52 +0800
Subject: [PATCH v6 2/3] usb: gadget: gadgetfs: prevent ep0 event counter
 underflow
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-b4-gadgetfs-ep0-v6-2-b410e3dced89@gmail.com>
References: <20261109-b4-gadgetfs-ep0-v6-0-b410e3dced89@gmail.com>
In-Reply-To: <20261109-b4-gadgetfs-ep0-v6-0-b410e3dced89@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Jing Lin <kayano050408@gmail.com>, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794207052; l=2063;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=qJqyRAvVJu+nflKNzM3pQLellrP4zWiqHlZjBdga29A=;
 b=HiI/GdoLs3Lzx5sZwk9gEEz4/PvlASCWwFEiZbtoFFIRN+SIpzf92ZMPz2OJbD0BXNyAdLVg2
 lnkwWZmV/2DCMTKN5vWknj+aO4ACBghIlkWnMoLj1Ioff2vbU9g9fiE
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
index 1277982f1..d8dfc1897 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -1227,25 +1227,19 @@ ep0_read (struct file *fd, char __user *buf, size_t len, loff_t *ptr)
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

