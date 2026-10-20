From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Tue, 20 Oct 2026 15:30:44 +0200
Subject: [PATCH v5 05/10] can: peak_usb: replace open-coded bitmask
 operations with bitops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261020-canfd_check_channel_idx-v5-5-a62b35b867f0@peak-system.fr>
References: <20261020-canfd_check_channel_idx-v5-0-a62b35b867f0@peak-system.fr>
In-Reply-To: <20261020-canfd_check_channel_idx-v5-0-a62b35b867f0@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, Dan Carpenter <error27@gmail.com>, 
 Wolfgang Grandegger <wg@grandegger.com>
Cc: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 linux-can@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792503050; l=6592;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=nQyQ44v+InsbZVERsOlgObbCokwsrHOkh2r9DVOCK+4=;
 b=oskgEEZBfAkDRzcqvFhanKj3YUeOmOg3YhUHcMbBTmr1OdnGf8oW8pqyiHepTCpfIfUWqTc4g
 Ahe0bm1O3+SDufQvAI4EW48odfUEBDfcKbxtajuYyZz91QdxWqMOYLO
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PCAN_USB_STATE_* flags of struct peak_usb_device are set, cleared
and tested from different contexts (ndo_open/ndo_stop, USB disconnect,
URB completion) with non-atomic open-coded bitmask operations.

Turn these flags into bit numbers, make the state field an unsigned
long and use set_bit(), clear_bit() and test_bit() instead, so that
updating one flag can no longer overwrite a concurrent update of
another one. The next patch relies on this to clear CONNECTED while a
channel may be opened.

dev->state is zeroed by alloc_candev(), so setting CONNECTED with
set_bit() at creation is equivalent to the former assignment.

Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb.c      |  4 ++--
 drivers/net/can/usb/peak_usb/pcan_usb_core.c | 10 +++++-----
 drivers/net/can/usb/peak_usb/pcan_usb_core.h |  9 ++++++---
 drivers/net/can/usb/peak_usb/pcan_usb_fd.c   |  2 +-
 drivers/net/can/usb/peak_usb/pcan_usb_pro.c  |  6 +++---
 5 files changed, 17 insertions(+), 14 deletions(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb.c b/drivers/net/can/usb/peak_usb/pcan_usb.c
index 5da91d5dc67a..93da0fd4f10e 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb.c
@@ -158,7 +158,7 @@ static int pcan_usb_send_cmd(struct peak_usb_device *dev, u8 f, u8 n, u8 *p)
 	int actual_length;
 
 	/* usb device unregistered? */
-	if (!(dev->state & PCAN_USB_STATE_CONNECTED))
+	if (!test_bit(PCAN_USB_STATE_CONNECTED, &dev->state))
 		return 0;
 
 	dev->cmd_buf[PCAN_USB_CMD_FUNC] = f;
@@ -188,7 +188,7 @@ static int pcan_usb_wait_rsp(struct peak_usb_device *dev, u8 f, u8 n, u8 *p)
 	int actual_length;
 
 	/* usb device unregistered? */
-	if (!(dev->state & PCAN_USB_STATE_CONNECTED))
+	if (!test_bit(PCAN_USB_STATE_CONNECTED, &dev->state))
 		return 0;
 
 	/* first, send command */
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_core.c b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
index 55aad01cd8ca..a1b17e1e6fea 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_core.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
@@ -263,7 +263,7 @@ static void peak_usb_read_bulk_callback(struct urb *urb)
 	/* protect from any incoming empty msgs */
 	if ((urb->actual_length > 0) && (dev->adapter->dev_decode_buf)) {
 		/* handle these kinds of msgs only if _start callback called */
-		if (dev->state & PCAN_USB_STATE_STARTED) {
+		if (test_bit(PCAN_USB_STATE_STARTED, &dev->state)) {
 			err = dev->adapter->dev_decode_buf(dev, urb);
 			if (err)
 				pcan_dump_mem("received usb message",
@@ -537,7 +537,7 @@ static int peak_usb_start(struct peak_usb_device *dev)
 			goto err_adapter;
 	}
 
-	dev->state |= PCAN_USB_STATE_STARTED;
+	set_bit(PCAN_USB_STATE_STARTED, &dev->state);
 
 	/* can set bus on now */
 	if (dev->adapter->dev_set_bus) {
@@ -631,7 +631,7 @@ static int peak_usb_ndo_stop(struct net_device *netdev)
 {
 	struct peak_usb_device *dev = netdev_priv(netdev);
 
-	dev->state &= ~PCAN_USB_STATE_STARTED;
+	clear_bit(PCAN_USB_STATE_STARTED, &dev->state);
 	netif_stop_queue(netdev);
 
 	close_candev(netdev);
@@ -941,7 +941,7 @@ static int peak_usb_create_dev(const struct peak_usb_adapter *peak_usb_adapter,
 	dev->netdev = netdev;
 	dev->adapter = peak_usb_adapter;
 	dev->ctrl_idx = ctrl_idx;
-	dev->state = PCAN_USB_STATE_CONNECTED;
+	set_bit(PCAN_USB_STATE_CONNECTED, &dev->state);
 
 	dev->ep_msg_in = peak_usb_adapter->ep_msg_in;
 	dev->ep_msg_out = peak_usb_adapter->ep_msg_out[ctrl_idx];
@@ -1044,7 +1044,7 @@ static void peak_usb_disconnect(struct usb_interface *intf)
 		char name[IFNAMSIZ];
 
 		dev_prev_siblings = dev->prev_siblings;
-		dev->state &= ~PCAN_USB_STATE_CONNECTED;
+		clear_bit(PCAN_USB_STATE_CONNECTED, &dev->state);
 		strscpy(name, netdev->name, IFNAMSIZ);
 
 		unregister_candev(netdev);
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_core.h b/drivers/net/can/usb/peak_usb/pcan_usb_core.h
index 9ad7d31d2720..cb8777c3e08e 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_core.h
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_core.h
@@ -109,15 +109,18 @@ struct peak_tx_urb_context {
 	struct urb *urb;
 };
 
-#define PCAN_USB_STATE_CONNECTED	0x00000001
-#define PCAN_USB_STATE_STARTED		0x00000002
+/* bit numbers for struct peak_usb_device::state (used with set_bit()/
+ * clear_bit()/test_bit() for atomic read-modify-write across contexts)
+ */
+#define PCAN_USB_STATE_CONNECTED	0
+#define PCAN_USB_STATE_STARTED		1
 
 /* PEAK-System USB device */
 struct peak_usb_device {
 	struct can_priv can;
 	const struct peak_usb_adapter *adapter;
 	unsigned int ctrl_idx;
-	u32 state;
+	unsigned long state;
 
 	struct usb_device *udev;
 	struct net_device *netdev;
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_fd.c b/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
index 82502594a409..15d275d6a127 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
@@ -202,7 +202,7 @@ static int pcan_usb_fd_send_cmd(struct peak_usb_device *dev, void *cmd_tail)
 	ptrdiff_t cmd_len;
 
 	/* usb device unregistered? */
-	if (!(dev->state & PCAN_USB_STATE_CONNECTED))
+	if (!test_bit(PCAN_USB_STATE_CONNECTED, &dev->state))
 		return 0;
 
 	/* if a packet is not filled completely by commands, the command list
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
index 4c3d89a160af..cbc23953ce61 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
@@ -210,7 +210,7 @@ static int pcan_usb_pro_send_cmd(struct peak_usb_device *dev,
 	int err;
 
 	/* usb device unregistered? */
-	if (!(dev->state & PCAN_USB_STATE_CONNECTED))
+	if (!test_bit(PCAN_USB_STATE_CONNECTED, &dev->state))
 		return 0;
 
 	err = usb_bulk_msg(dev->udev,
@@ -234,7 +234,7 @@ static int pcan_usb_pro_wait_rsp(struct peak_usb_device *dev,
 	int i, err = 0;
 
 	/* usb device unregistered? */
-	if (!(dev->state & PCAN_USB_STATE_CONNECTED))
+	if (!test_bit(PCAN_USB_STATE_CONNECTED, &dev->state))
 		return 0;
 
 	req_data_type = pum->u.rec_buffer[4];
@@ -318,7 +318,7 @@ int pcan_usb_pro_send_req(struct peak_usb_device *dev, int req_id,
 	unsigned int p;
 
 	/* usb device unregistered? */
-	if (!(dev->state & PCAN_USB_STATE_CONNECTED))
+	if (!test_bit(PCAN_USB_STATE_CONNECTED, &dev->state))
 		return 0;
 
 	req_type = USB_TYPE_VENDOR | USB_RECIP_OTHER;

-- 
2.53.0

