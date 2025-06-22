From: Dominique Martinet <asmadeus@codewreck.org>
Date: Sun, 22 Jun 2025 22:39:56 +0900
Subject: [PATCH v3] net/9p: Fix buffer overflow in USB transport layer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250622-9p-usb_overflow-v3-1-ab172691b946@codewreck.org>
X-B4-Tracking: v=1; b=H4sIAKsHWGgC/22OzQ6CMBAGX8X0bEl/oAZPvIchppQFVoGSVouG8
 O4W4sGDx9lk5tuFeHAInpwPC3EQ0KMdI8jjgZhOjy1QrCMTwUTGlGA0n+jTV1cbwDW9nanIqsZ
 kkFfQSBKtyUGDr714KSN36B/WvfeBwLfrt8UVlyKTeaJkKlPKaa1H9DeMo0U7aOwTYweyJYL40
 f68EES0mVBGcZabk+aFsTXMDsw9sa4l5bquH0JV0cjpAAAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3088;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=uRA+tj1CGV3hDEWLR7ul9klUmiXd1el2FvT0X0zpwug=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBoWAexM97EqqDps4uLE21H9hDjaDGpdSirjktFo
 j7iGJVVIYmJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaFgHsQAKCRCrTpvsapjm
 cEMWD/44v6jhy3s94nL9wsfiMpO26Of4JpPM+LjflzPMLbWWJAVoQnS7qsy/Kb7napyi4cki2X/
 jPPBfmt11kd5SWWGD1V07N/EMB1E2RwLAdWIroP+QUmOC1xjJ+zy+z3MUIp6fVFQX8NMWnKprLD
 XJdy8jSwcLjJDP51zZvqXttcYffvn5f/ph9fIeMNBUbpJ7aqYldW9afXD43//fpcy0qCR8Q1PrQ
 AhUlIZGuuzGcxTJhmsDietbjMz6uXDwyghu6N2G2X0oo5C6jT3HjAJ7B1kaUTUHNB7DKT0dX0yq
 OT962DE2EQTUaPOAH+n6HescgdUK7pktU6EKzdiUwSQCakTN7LophVtJiBbSILAvo9QdBCHHq0u
 N3/tD3evkVq2Y/hSSkUy9T5xuHv+IufLlhX0R0sQUKeAtzel53p+TeEIkp9aW/D6cLd/NZS6LjD
 ZWZao9VlbAoy7KRVFyiqDQ9MfMM8P65j0vVVBwGnwlFgQTwwyikmaIkYZQDkH0hCmuls98byVlB
 M/sIcbUGpbpVhS6R+Kdc+amkjT+uUpj2d7T0GdsmsQnr6XAZOy2JP9xHMX0UWu2kAqvyatDA6SB
 m0rrjgfsOpiSZJ3NUXL/o4l/S5Jf7eqP70mGqeoLNyq3dQd0zfGRovnTxumXni1CHPs0HwakhM0
 WHRuZ6CViWFMsPg==
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
(still not actually tested, can't get dummy_hcd/gt to create a device
listed by p9_fwd.py/useable in qemu, I give up..)

Changes in v3:
- fix typo s/req_sizel/req_size/ -- sorry for that, module wasn't
  built...
- Link to v2: https://lore.kernel.org/r/20250620-9p-usb_overflow-v2-1-026c6109c7a1@codewreck.org

Changes in v2:
- run through p9_client_cb() on error
- Link to v1: https://lore.kernel.org/r/20250616132539.63434-1-danisjiang@gmail.com
---
 net/9p/trans_usbg.c | 16 +++++++++++++---
 1 file changed, 13 insertions(+), 3 deletions(-)

diff --git a/net/9p/trans_usbg.c b/net/9p/trans_usbg.c
index 6b694f117aef296a66419fed5252305e7a1d0936..468f7e8f0277b9ae5f1bb3c94c649fca97d28857 100644
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
+	p9_rx_req->rc.size = req_size;
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

