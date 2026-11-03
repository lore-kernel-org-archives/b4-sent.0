From: =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>
Date: Tue, 03 Nov 2026 13:30:26 +0100
Subject: [PATCH v8 10/14] can: peak_usb: dump undecodable URBs once and
 rate limit decode errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-canfd_check_channel_idx-v8-10-4e8b2c0a8806@peak-system.fr>
References: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
In-Reply-To: <20261103-canfd_check_channel_idx-v8-0-4e8b2c0a8806@peak-system.fr>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Wolfgang Grandegger <wg@grandegger.com>, 
 =?utf-8?q?St=C3=A9phane_Grosjean?= <s.grosjean@peak-system.fr>, 
 Dan Carpenter <error27@gmail.com>, Lukas Magel <lukas.magel@posteo.net>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Tristan Madani <tristmd@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793709024; l=8030;
 i=s.grosjean@peak-system.fr; s=20261020; h=from:subject:message-id;
 bh=Y9OLOJORiCyS6rJxBFXyhFDzhdH7ugYnKhRkwMDPtvM=;
 b=rxwBWpot0zA6HNdasofO0PDg8Ff/a35IbQ1cKXtsE/xDJZRoXwlsamVE4tJnuU1/oG0785iWL
 cNmO5qsYnO1ANlX/ZrA+vE2+3XQ0RozjeQkpZMzupY1FP6zQv45TMPL
X-Developer-Key: i=s.grosjean@peak-system.fr; a=ed25519;
 pk=bP7QV2zvvAKAfConZlUOGKGEcXL64SNUpVUm++Ai+/c=
X-Endpoint-Received: by B4 Relay for s.grosjean@peak-system.fr/20261020 with auth_id=1250
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the decoding of a received URB fails, peak_usb_read_bulk_callback()
dumps the whole RX buffer to the kernel log. The buffer is allocated with
kmalloc() and its size is the adapter RX buffer size (up to 2048 bytes),
so the bytes beyond urb->actual_length are uninitialized memory or
leftovers from previous transfers.

Moreover, the PCAN-USB Pro and PCAN-USB FD decoders already dump the
received bytes themselves before returning the error, so the same URB is
dumped twice. Neither these dumps nor the error messages printed by the
decoders are rate limited, while a faulty or malicious device can make
every transfer fail to decode, or carry unknown records.

Dump only the urb->actual_length bytes received, from
peak_usb_read_bulk_callback() only, and rate limit this dump as well as
the error messages the decoders print about the received data.

The dump and these messages are rate limited separately, so during a
burst one of them may be printed without the other. Drop the trailing
colon of the PCAN-USB Pro "got unsupported rec in usb msg" message,
which announced a dump that may no longer follow it.

The dumps and messages of the adapter decoders were pointed out by
Sashiko AI review.

Fixes: bb4785551f64 ("can: usb: PEAK-System Technik USB adapters driver core")
Assisted-by: LLM
Signed-off-by: Stéphane Grosjean <s.grosjean@peak-system.fr>
---
 drivers/net/can/usb/peak_usb/pcan_usb.c      |  8 +++++---
 drivers/net/can/usb/peak_usb/pcan_usb_core.c |  4 ++--
 drivers/net/can/usb/peak_usb/pcan_usb_fd.c   | 27 ++++++++++++-------------
 drivers/net/can/usb/peak_usb/pcan_usb_pro.c  | 30 ++++++++++++++--------------
 4 files changed, 35 insertions(+), 34 deletions(-)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb.c b/drivers/net/can/usb/peak_usb/pcan_usb.c
index 451d08421504..ff1921779065 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb.c
@@ -637,7 +637,8 @@ static int pcan_usb_decode_status(struct pcan_usb_msg_context *mc,
 			return err;
 		break;
 	default:
-		netdev_err(mc->netdev, "unexpected function %u\n", f);
+		if (net_ratelimit())
+			netdev_err(mc->netdev, "unexpected function %u\n", f);
 		break;
 	}
 
@@ -776,8 +777,9 @@ static int pcan_usb_decode_buf(struct peak_usb_device *dev, struct urb *urb)
 			urb->actual_length);
 
 	} else if (urb->actual_length > 0) {
-		netdev_err(dev->netdev, "usb message length error (%u)\n",
-			urb->actual_length);
+		if (net_ratelimit())
+			netdev_err(dev->netdev, "usb message length error (%u)\n",
+				   urb->actual_length);
 		err = -EINVAL;
 	}
 
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_core.c b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
index e5198ec5c760..1d306160fa35 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_core.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_core.c
@@ -266,10 +266,10 @@ static void peak_usb_read_bulk_callback(struct urb *urb)
 		/* handle these kinds of msgs only if _start callback called */
 		if (test_bit(PCAN_USB_STATE_STARTED, &dev->state)) {
 			err = dev->adapter->dev_decode_buf(dev, urb);
-			if (err)
+			if (err && net_ratelimit())
 				pcan_dump_mem("received usb message",
 					      urb->transfer_buffer,
-					      urb->transfer_buffer_length);
+					      urb->actual_length);
 		}
 	}
 
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_fd.c b/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
index a9f81fb12738..b9bf2fefbaff 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
@@ -796,15 +796,17 @@ static int pcan_usb_fd_decode_buf(struct peak_usb_device *dev, struct urb *urb)
 
 		/* check if the record goes out of current packet */
 		if (rx_msg_size > msg_end - msg_ptr) {
-			netdev_err(netdev,
-				   "got frag rec: should inc usb rx buf sze\n");
+			if (net_ratelimit())
+				netdev_err(netdev,
+					   "got frag rec: should inc usb rx buf sze\n");
 			err = -EBADMSG;
 			break;
 		}
 
 		rx_msg_min_size = pcan_usb_fd_rx_msg_min_size(rx_msg_type);
 		if (rx_msg_size < rx_msg_min_size) {
-			netdev_err(netdev, "got short rec\n");
+			if (net_ratelimit())
+				netdev_err(netdev, "got short rec\n");
 			err = -EBADMSG;
 			break;
 		}
@@ -813,7 +815,7 @@ static int pcan_usb_fd_decode_buf(struct peak_usb_device *dev, struct urb *urb)
 		case PUCAN_MSG_CAN_RX:
 			err = pcan_usb_fd_decode_canmsg(usb_if, rx_msg);
 			if (err < 0)
-				goto fail;
+				return err;
 			break;
 
 		case PCAN_UFD_MSG_CALIBRATION:
@@ -823,35 +825,32 @@ static int pcan_usb_fd_decode_buf(struct peak_usb_device *dev, struct urb *urb)
 		case PUCAN_MSG_ERROR:
 			err = pcan_usb_fd_decode_error(usb_if, rx_msg);
 			if (err < 0)
-				goto fail;
+				return err;
 			break;
 
 		case PUCAN_MSG_STATUS:
 			err = pcan_usb_fd_decode_status(usb_if, rx_msg);
 			if (err < 0)
-				goto fail;
+				return err;
 			break;
 
 		case PCAN_UFD_MSG_OVERRUN:
 			err = pcan_usb_fd_decode_overrun(usb_if, rx_msg);
 			if (err < 0)
-				goto fail;
+				return err;
 			break;
 
 		default:
-			netdev_err(netdev,
-				   "unhandled msg type 0x%02x (%d): ignored\n",
-				   rx_msg_type, rx_msg_type);
+			if (net_ratelimit())
+				netdev_err(netdev,
+					   "unhandled msg type 0x%02x (%d): ignored\n",
+					   rx_msg_type, rx_msg_type);
 			break;
 		}
 
 		msg_ptr += rx_msg_size;
 	}
 
-fail:
-	if (err)
-		pcan_dump_mem("received msg",
-			      urb->transfer_buffer, urb->actual_length);
 	return err;
 }
 
diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
index 88d21806207b..840658723648 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_pro.c
@@ -741,7 +741,9 @@ static int pcan_usb_pro_decode_buf(struct peak_usb_device *dev, struct urb *urb)
 	rec_ptr = pcan_msg_init(&usb_msg, urb->transfer_buffer,
 					urb->actual_length);
 	if (!rec_ptr) {
-		netdev_err(netdev, "bad msg hdr len %d\n", urb->actual_length);
+		if (net_ratelimit())
+			netdev_err(netdev, "bad msg hdr len %d\n",
+				   urb->actual_length);
 		return -EINVAL;
 	}
 
@@ -760,16 +762,18 @@ static int pcan_usb_pro_decode_buf(struct peak_usb_device *dev, struct urb *urb)
 
 		sizeof_rec = pcan_usb_pro_sizeof_rec[pr->data_type];
 		if (!sizeof_rec) {
-			netdev_err(netdev,
-				   "got unsupported rec in usb msg:\n");
+			if (net_ratelimit())
+				netdev_err(netdev,
+					   "got unsupported rec in usb msg\n");
 			err = -ENOTSUPP;
 			break;
 		}
 
 		/* check if the record goes out of current packet */
 		if (rec_ptr + sizeof_rec > msg_end) {
-			netdev_err(netdev,
-				"got frag rec: should inc usb rx buf size\n");
+			if (net_ratelimit())
+				netdev_err(netdev,
+					   "got frag rec: should inc usb rx buf size\n");
 			err = -EBADMSG;
 			break;
 		}
@@ -781,13 +785,13 @@ static int pcan_usb_pro_decode_buf(struct peak_usb_device *dev, struct urb *urb)
 		case PCAN_USBPRO_RXRTR:
 			err = pcan_usb_pro_handle_canmsg(usb_if, &pr->rx_msg);
 			if (err < 0)
-				goto fail;
+				return err;
 			break;
 
 		case PCAN_USBPRO_RXSTATUS:
 			err = pcan_usb_pro_handle_error(usb_if, &pr->rx_status);
 			if (err < 0)
-				goto fail;
+				return err;
 			break;
 
 		case PCAN_USBPRO_RXTS:
@@ -795,20 +799,16 @@ static int pcan_usb_pro_decode_buf(struct peak_usb_device *dev, struct urb *urb)
 			break;
 
 		default:
-			netdev_err(netdev,
-				   "unhandled rec type 0x%02x (%d): ignored\n",
-				   pr->data_type, pr->data_type);
+			if (net_ratelimit())
+				netdev_err(netdev,
+					   "unhandled rec type 0x%02x (%d): ignored\n",
+					   pr->data_type, pr->data_type);
 			break;
 		}
 
 		rec_ptr += sizeof_rec;
 	}
 
-fail:
-	if (err)
-		pcan_dump_mem("received msg",
-			      urb->transfer_buffer, urb->actual_length);
-
 	return err;
 }
 

-- 
2.53.0

