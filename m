From: Jing Lin <kayano050408@gmail.com>
Date: Tue, 10 Nov 2026 12:13:25 +0800
Subject: [PATCH v8 4/4] usb: gadget: gadgetfs: avoid writing through the
 const setup pointer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-gadgetfs-ep0-v8-v8-4-8f90434574fe@gmail.com>
References: <20261110-gadgetfs-ep0-v8-v8-0-8f90434574fe@gmail.com>
In-Reply-To: <20261110-gadgetfs-ep0-v8-v8-0-8f90434574fe@gmail.com>
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Jing Lin <kayano050408@gmail.com>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alan Stern <stern@rowland.harvard.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794284002; l=1652;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=si1G1+f7e2FG0Kdc6yaUjRpBdhJGWuq2tBRVF9N7SWs=;
 b=4X2b14KJGYKqkiqdu1sgSPXlx+ejPt1MvYgZojmzkj8+bKmetmZyJvGRKuWPwo9/t34QG+Djr
 gEv13KDn/IgA92rZ+4fThWONhvQFYcja0z3yRk8HU1MroZ96sovS6ty
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gadgetfs_setup() receives the setup packet as const, but clamps an
oversized control IN request by casting away the constness and writing
the truncated length back into the caller's wLength field.

The setup() callback has no business modifying the setup packet, and
ctrl->wLength is only used afterwards when initializing event->u.setup.
Store the clamped w_length into event->u.setup.wLength directly instead.

Suggested-by: Alan Stern <stern@rowland.harvard.edu>
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index d15739df2..12f04329b 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -1616,10 +1616,6 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 
 	if (w_length > RBUF_SIZE) {
 		if (ctrl->bRequestType & USB_DIR_IN) {
-			/* Cast away the const, we are going to overwrite on purpose. */
-			__le16 *temp = (__le16 *)&ctrl->wLength;
-
-			*temp = cpu_to_le16(RBUF_SIZE);
 			w_length = RBUF_SIZE;
 		} else {
 			spin_unlock(&dev->lock);
@@ -1777,6 +1773,8 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 			/* state changes when reader collects event */
 			event = next_event (dev, GADGETFS_SETUP);
 			event->u.setup = *ctrl;
+			/* Report the length we can actually handle */
+			event->u.setup.wLength = cpu_to_le16(w_length);
 			ep0_readable (dev);
 			spin_unlock (&dev->lock);
 			/*

-- 
Git-155)

