From: Jing Lin <kayano050408@gmail.com>
Date: Thu, 26 Nov 2026 14:37:09 +0800
Subject: [PATCH v9 6/6] usb: gadget: gadgetfs: avoid writing through the
 const setup pointer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-gadgetfs-ep0-v9-6-81b464c6e641@gmail.com>
References: <20261126-gadgetfs-ep0-v9-0-81b464c6e641@gmail.com>
In-Reply-To: <20261126-gadgetfs-ep0-v9-0-81b464c6e641@gmail.com>
To: Neill Kapron <nkapron@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Alan Stern <stern@rowland.harvard.edu>, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+c73e1942197af9f54ca3@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Jing Lin <kayano050408@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795675025; l=1670;
 i=kayano050408@gmail.com; s=20261126; h=from:subject:message-id;
 bh=ZBmJwrzWJL9P5eP6VSC8U6h5A7VH0l7p13ihjdZGb7w=;
 b=3TXpwFa6U/3EMgBjYxWlYlpC3kgKe550IuQahTxs9KNubb+wEiuOBntzrx8jvJ3i/KgqT9ejT
 OW11N1b1shKCWEB+wsWUjf18Ih9QdiFZti7nxyzUkJl0KsvpWuXxu9+
X-Developer-Key: i=kayano050408@gmail.com; a=ed25519;
 pk=40M3hugIx++9w3nkAoFXGcN/vLWsPMGDYdbduV+lUlI=
X-Endpoint-Received: by B4 Relay for kayano050408@gmail.com/20261126 with auth_id=1648
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gadgetfs_setup() receives the setup packet as const, but clamps an
oversized control-IN request by casting away the constness and writing
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
index bd77d0848db2..eb8b0d152d4f 100644
--- a/drivers/usb/gadget/legacy/inode.c
+++ b/drivers/usb/gadget/legacy/inode.c
@@ -1648,10 +1648,6 @@ gadgetfs_do_setup(struct dev_data *dev, const struct usb_ctrlrequest *ctrl,
 
 	if (w_length > RBUF_SIZE) {
 		if (ctrl->bRequestType & USB_DIR_IN) {
-			/* Cast away the const, we are going to overwrite on purpose. */
-			__le16 *temp = (__le16 *)&ctrl->wLength;
-
-			*temp = cpu_to_le16(RBUF_SIZE);
 			w_length = RBUF_SIZE;
 		} else {
 			return value;
@@ -1804,6 +1800,8 @@ gadgetfs_do_setup(struct dev_data *dev, const struct usb_ctrlrequest *ctrl,
 			/* state changes when reader collects event */
 			event = next_event (dev, GADGETFS_SETUP);
 			event->u.setup = *ctrl;
+			/* Report the length we can actually handle */
+			event->u.setup.wLength = cpu_to_le16(w_length);
 			ep0_readable (dev);
 			/*
 			 * Return USB_GADGET_DELAYED_STATUS as a workaround to

-- 
Git-155)

