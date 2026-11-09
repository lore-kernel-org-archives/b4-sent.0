From: Jing Lin <kayano050408@gmail.com>
Date: Mon, 09 Nov 2026 14:50:53 +0800
Subject: [PATCH v6 3/3] usb: gadget: gadgetfs: avoid writing through the
 const setup pointer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-b4-gadgetfs-ep0-v6-3-b410e3dced89@gmail.com>
References: <20261109-b4-gadgetfs-ep0-v6-0-b410e3dced89@gmail.com>
In-Reply-To: <20261109-b4-gadgetfs-ep0-v6-0-b410e3dced89@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Jing Lin <kayano050408@gmail.com>, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Alan Stern <stern@rowland.harvard.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794207052; l=1801;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=9gntn5pJSxQT5e2Y/4zkYZFLdwaAw07YatIbT0ly3no=;
 b=L35vU2atDiVedsXt7QL6s/PalmX3AvXYJCrkKDxMmffspgzYvGtndAP2HSJNSekHzgGEy3RZM
 XpJnzFELSpkDVzctHAHU6oD4qUIhDG8UU62wDMBzketYY5tH1cyokbX
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=pr6i8RN1WEON1jbXPdghSglxaBSzfuJjXNGFknX//+A=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/default with auth_id=1441
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gadgetfs_setup() receives the setup packet as const, but clamps an
oversized control IN request by casting away the constness and writing
the truncated length back into the caller's wLength field.

The setup() callback has no business modifying the setup packet.  Use a
local copy of the request for the clamped length instead.  Userspace
still observes the truncated wLength in the GADGETFS_SETUP event, and
the queued request length is unchanged.

Suggested-by: Alan Stern <stern@rowland.harvard.edu>
Signed-off-by: Jing Lin <kayano050408@gmail.com>
---
 drivers/usb/gadget/legacy/inode.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/usb/gadget/legacy/inode.c b/drivers/usb/gadget/legacy/inode.c
index d8dfc1897..7c48214ba 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -1543,6 +1543,7 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	struct usb_request		*req = dev->req;
 	int				value = -EOPNOTSUPP;
 	struct usb_gadgetfs_event	*event;
+	struct usb_ctrlrequest		ctrl_buf;
 	u16				w_value = le16_to_cpu(ctrl->wValue);
 	u16				w_length = le16_to_cpu(ctrl->wLength);
 
@@ -1552,10 +1553,10 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 
 	if (w_length > RBUF_SIZE) {
 		if (ctrl->bRequestType & USB_DIR_IN) {
-			/* Cast away the const, we are going to overwrite on purpose. */
-			__le16 *temp = (__le16 *)&ctrl->wLength;
-
-			*temp = cpu_to_le16(RBUF_SIZE);
+			/* Report the length we can actually handle to userspace. */
+			ctrl_buf = *ctrl;
+			ctrl_buf.wLength = cpu_to_le16(RBUF_SIZE);
+			ctrl = &ctrl_buf;
 			w_length = RBUF_SIZE;
 		} else {
 			spin_unlock(&dev->lock);

-- 
Git-155)

