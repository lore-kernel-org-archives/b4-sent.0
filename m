From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 03:56:44 +0000
Subject: [PATCH] can: peak_usb: pcan_usb_fd: check that the channel has a
 device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-pcan-usb-fd-nodev-v1-1-fc11effbfafa@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPuV8moC/x3MTQqAIBBA4avErBtI7Y+uEi1Mx5qNilIE0t2Tl
 t/ivQKZElOGpSmQ6ObMwVeItgFzan8Qsq0G2clRCNFhNNrjlXd0Fn2wdONs9KSUHOTYK6hdTOT
 4+Z/r9r4fEPs1gWMAAAA=
To: mkl@pengutronix.de, mailhol@kernel.org, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794283003; l=3048;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=Unyy5Y2//kCaARk7Mh5QLhPHaGmOGCPoVXqetVMtAwA=;
 b=jyuCXnde+AGMc0XAGaTNWp5ioRE4QCXdmeIWNWdNHkCnZjjaT7ebhmhjdJUzAzAJmezYst+XO
 6hW0Eu/QegcCeI+B3yEZKMF+YPMIIpc7fBKP+MBe5rr++w4MFI+988J
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rx decoders of the pcan_usb_fd driver take the channel index from
the message sent by the device and use it to look up the per-channel
device:

	if (pucan_msg_get_channel(rm) >= ARRAY_SIZE(usb_if->dev))
		return -ENOMEM;

	dev = usb_if->dev[pucan_msg_get_channel(rm)];
	netdev = dev->netdev;

usb_if->dev[] has PCAN_USB_MAX_CHANNEL (2) entries, but an entry is
only set for the channels the adapter really has.  The single channel
adapters (PCAN-USB FD, PCAN-Chip USB) leave usb_if->dev[1] NULL.  A
device that identifies as one of them and sends a CAN rx, status, error
or overrun message for channel 1 while the interface is up passes the
range check and makes the driver dereference a NULL pointer in the URB
completion handler.

Check the looked up device in all four decoders and fail the decoding
of the buffer if the channel does not exist.

Found by LLM-assisted source review.

Fixes: 0a25e1f4f185 ("can: peak_usb: add support for PEAK new CANFD USB adapters")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
This issue was found with the help of an LLM-based code review tool
(Claude).  I checked the code paths by hand against v7.4-rc3 and
reviewed the fix myself.  It is build-tested only (W=1, arm64); I do
not have the hardware to test it at runtime.
---
 drivers/net/can/usb/peak_usb/pcan_usb_fd.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/net/can/usb/peak_usb/pcan_usb_fd.c b/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
index 39f0740421c3..c42cac212640 100644
--- a/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
+++ b/drivers/net/can/usb/peak_usb/pcan_usb_fd.c
@@ -540,6 +540,9 @@ static int pcan_usb_fd_decode_canmsg(struct pcan_usb_fd_if *usb_if,
 		return -ENOMEM;
 
 	dev = usb_if->dev[pucan_msg_get_channel(rm)];
+	if (!dev)
+		return -ENODEV;
+
 	netdev = dev->netdev;
 
 	if (rx_msg_flags & PUCAN_MSG_EXT_DATA_LEN) {
@@ -609,6 +612,9 @@ static int pcan_usb_fd_decode_status(struct pcan_usb_fd_if *usb_if,
 		return -ENOMEM;
 
 	dev = usb_if->dev[pucan_stmsg_get_channel(sm)];
+	if (!dev)
+		return -ENODEV;
+
 	pdev = container_of(dev, struct pcan_usb_fd_device, dev);
 	netdev = dev->netdev;
 
@@ -666,6 +672,9 @@ static int pcan_usb_fd_decode_error(struct pcan_usb_fd_if *usb_if,
 		return -EINVAL;
 
 	dev = usb_if->dev[pucan_ermsg_get_channel(er)];
+	if (!dev)
+		return -ENODEV;
+
 	pdev = container_of(dev, struct pcan_usb_fd_device, dev);
 
 	/* keep a trace of tx and rx error counters for later use */
@@ -689,6 +698,9 @@ static int pcan_usb_fd_decode_overrun(struct pcan_usb_fd_if *usb_if,
 		return -EINVAL;
 
 	dev = usb_if->dev[pufd_omsg_get_channel(ov)];
+	if (!dev)
+		return -ENODEV;
+
 	netdev = dev->netdev;
 
 	/* allocate an skb to store the error frame */

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-pcan-usb-fd-nodev-8ca733252643

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

