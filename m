From: Jing Lin <kayano050408@gmail.com>
Date: Mon, 09 Nov 2026 13:55:41 +0800
Subject: [PATCH v5 3/3] usb: gadget: gadgetfs: avoid writing through the
 const setup pointer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-b4-gadgetfs-ep0-v5-3-f16d0b648bc2@gmail.com>
References: <20261109-b4-gadgetfs-ep0-v5-0-f16d0b648bc2@gmail.com>
In-Reply-To: <20261109-b4-gadgetfs-ep0-v5-0-f16d0b648bc2@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Neill Kapron <nkapron@google.com>
Cc: Jing Lin <kayano050408@gmail.com>, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 Alan Stern <stern@rowland.harvard.edu>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, linux-usb@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794203739; l=1685;
 i=kayano050408@gmail.com; s=default; h=from:subject:message-id;
 bh=b6MoNxME4f44lJnt8mP7Bi+ISns5QSLf02GNPFd9pf4=;
 b=ippID2JFWPISCSEuMYPgtr32/xjHzFRd56V+ja8sr0eTSIw1bsTRCyHB2YPmak+ot9LGZ7vNc
 vw/8H2pC0N6DZFkBz/vCPszw7xGWWvwgiSww3DxRTFalt+mmKpsxg7I
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
index 4635a603e..23a36d556 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -1510,15 +1510,16 @@ gadgetfs_setup (struct usb_gadget *gadget, const struct usb_ctrlrequest *ctrl)
 	struct usb_request		*req = dev->req;
 	int				value = -EOPNOTSUPP;
 	struct usb_gadgetfs_event	*event;
+	struct usb_ctrlrequest		ctrl_buf;
 	u16				w_value = le16_to_cpu(ctrl->wValue);
 	u16				w_length = le16_to_cpu(ctrl->wLength);
 
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
 			return value;

-- 
Git-155)

