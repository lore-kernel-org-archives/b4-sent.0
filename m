From: Dominique Martinet <asmadeus@codewreck.org>
Date: Fri, 20 Jun 2025 06:22:03 +0900
Subject: [PATCH v2] net/9p: Fix buffer overflow in USB transport layer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250620-9p-usb_overflow-v2-1-026c6109c7a1@codewreck.org>
X-B4-Tracking: v=1; b=H4sIAHp/VGgC/y2NWw6CMBQFt0LutyV90Cb45T4MMQVu4RqgpFXUk
 O7dSvyck5yZHSIGwgjnYoeAG0XySwZ5KqAb7TIgoz4zSC41N5KzemXP2N78hsFN/sWkbl2nsW7
 RKcivNaCj92G8NplHig8fPkdgE7/17xJGKKlVXRpVqYoJ1tuF4p1y9DLMlqay8zM0KaUvVTFZO
 6UAAAA=
X-Change-ID: 20250620-9p-usb_overflow-25bfc5e9bef3
To: Eric Van Hensbergen <ericvh@kernel.org>, 
 Latchesar Ionkov <lucho@ionkov.net>, 
 Christian Schoenebeck <linux_oss@crudebyte.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Michael Grzeschik <m.grzeschik@pengutronix.de>
Cc: stable@vger.kernel.org, Yuhao Jiang <danisjiang@gmail.com>, 
 security@kernel.org, v9fs@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Dominique Martinet <asmadeus@codewreck.org>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=2874;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=sd75KIQYdSHcNYSxHvOsd/ZrBkByS+On5VAz8Wg9id0=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBoVH98nfmseHzKhOwth426LG3xCNHGuKrMrPYIS
 6knofnzWnuJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaFR/fAAKCRCrTpvsapjm
 cKyeD/oCJfejbpmPwkb/cnIW8YPsRFbmsDmvntEQHaill6n6KcyQB3v3oKHUGopejHFtiUl8TYQ
 NToXHtB3AKIWS7xpi4nHpHT+0QBUKW8TADf4peHz6SC9Mtnz3tUGLcrDMEFEjOBz9z+dQMfzEXT
 cLulWcIkJfGJQzNr0WON4ekRHI/EH0KSETffLJ5uedpG15CJPSypltjzs2RYIBtHyYiR6rcfSx6
 /snUGfZrEbSz/XfTLB3LOdxrFPEk6Ue/lJ7i2A4ANJGxL9SNKoF7iOnzPBjqhvgENnn/XgWi1Td
 +eq24+g3eeygU8qsaYnmtRHZYGa9Tm6ea8a1yG7wBS234sgRNMOfKTjH5nbLmvTDM9uQrbYdb+W
 vMeOdDJfeTh9ebLmRxdHGBkdZvliQKm/l0uU6G/wJ8DRmprt+sun73E7h90Zd53/u39mH3kj/3i
 i1l2jIGgVbBCjbxa9Nhdo0cfQcv1EdYRviS7m5azPRYRwKrRxaVXEc0sx9ef3X/iYNpZiewb6J9
 hxTVpZIe+YgQ1CTyAUlMWpv79xb/B8Ondu6yAX83B1+bfoZlJCRoThx2jtyR10yNjvRg11gY4Bj
 EDmfB3Zd6juPxcftwIgFSKK8fE1WgtERblihLOmKiO7xz+qjINPl/nurkKs7eF+xY7Zju1y4GX0
 Vq4Nxjjs6kH9Neg==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A buffer overflow vulnerability exists in the USB 9pfs transport layer
where inconsistent size validation between packet header parsing and
actual data copying allows a malicious USB host to overflow heap buffers.

The issue occurs because:
- usb9pfs_rx_header() validates only the declared size in packet header
- usb9pfs_rx_complete() uses req->actual (actual received bytes) for
memcpy

This allows an attacker to craft packets with small declared size
(bypassing validation) but large actual payload (triggering overflow
in memcpy).

Add validation in usb9pfs_rx_complete() to ensure req->actual does not
exceed the buffer capacity before copying data.

Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Closes: https://lkml.kernel.org/r/20250616132539.63434-1-danisjiang@gmail.com
Fixes: a3be076dc174 ("net/9p/usbg: Add new usb gadget function transport")
Cc: stable@vger.kernel.org
Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
Not actually tested, I'll try to find time to figure out how to run with
qemu for real this time...

Changes in v2:
- run through p9_client_cb() on error
- Link to v1: https://lore.kernel.org/r/20250616132539.63434-1-danisjiang@gmail.com
---
 net/9p/trans_usbg.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/net/9p/trans_usbg.c b/net/9p/trans_usbg.c
index 6b694f117aef296a66419fed5252305e7a1d0936..43078e0d4ca3f4063660f659d28452c81bef10b4 100644
--- a/net/9p/trans_usbg.c
+++ b/net/9p/trans_usbg.c
@@ -231,6 +231,8 @@ static void usb9pfs_rx_complete(struct usb_ep *ep, struct usb_request *req)
 	struct f_usb9pfs *usb9pfs = ep->driver_data;
 	struct usb_composite_dev *cdev = usb9pfs->function.config->cdev;
 	struct p9_req_t *p9_rx_req;
+	unsigned int req_size = req->actual;
+	int status = REQ_STATUS_RCVD;
 
 	if (req->status) {
 		dev_err(&cdev->gadget->dev, "%s usb9pfs complete --> %d, %d/%d\n",
@@ -242,11 +244,19 @@ static void usb9pfs_rx_complete(struct usb_ep *ep, struct usb_request *req)
 	if (!p9_rx_req)
 		return;
 
-	memcpy(p9_rx_req->rc.sdata, req->buf, req->actual);
+	if (req_size > p9_rx_req->rc.capacity) {
+		dev_err(&cdev->gadget->dev,
+			"%s received data size %u exceeds buffer capacity %zu\n",
+			ep->name, req_size, p9_rx_req->rc.capacity);
+		req_size = 0;
+		status = REQ_STATUS_ERROR;
+	}
 
-	p9_rx_req->rc.size = req->actual;
+	memcpy(p9_rx_req->rc.sdata, req->buf, req_size);
 
-	p9_client_cb(usb9pfs->client, p9_rx_req, REQ_STATUS_RCVD);
+	p9_rx_req->rc.size = req_sizel;
+
+	p9_client_cb(usb9pfs->client, p9_rx_req, status);
 	p9_req_put(usb9pfs->client, p9_rx_req);
 
 	complete(&usb9pfs->received);

---
base-commit: 74b4cc9b8780bfe8a3992c9ac0033bf22ac01f19
change-id: 20250620-9p-usb_overflow-25bfc5e9bef3

Best regards,
-- 
Dominique Martinet <asmadeus@codewreck.org>

