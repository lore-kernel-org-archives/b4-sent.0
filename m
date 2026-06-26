From: Sam Day <me@samcday.com>
Date: Fri, 26 Jun 2026 14:29:10 +1000
Subject: [PATCH v3] usbip: vudc: fix NULL deref in vep_dequeue()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260626-usbip-vudc-deque-fix-v3-1-98c2dc4d6a48@samcday.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XNPQ7CMAyG4augzBjFSRUpTNwDMSSxSzP0h4ZGV
 FXvTtoJBsT4fpIfLyLxGDmJ82ERI+eYYt+V0MeDCI3r7gyRSgsllZEGLUzJxwHyRAGIHxNDHV9
 AGg2xJl2jEeV0GLnMO3u9lW5ievbjvH/JuK1/wIyAYKXCymiPVupLcm0gN59C34qNzOqDUfIHo
 wpDaFE7XxlE/82s6/oG0hAlegEBAAA=
X-Change-ID: 20260619-usbip-vudc-deque-fix-d316de3d3f16
To: Valentina Manea <valentina.manea.m@gmail.com>, 
 Shuah Khan <shuah@kernel.org>, Hongren Zheng <i@zenithal.me>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Krzysztof Opasiak <k.opasiak@samsung.com>, 
 Igor Kotrasinski <i.kotrasinsk@samsung.com>, Karol Kosik <karo9@interia.eu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782448150; l=2890;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=neQMtpDUn+Tb292nmorqxLCrhXmpUlbU1uEoKayin80=;
 b=fXe7ZVNiA+ONYXErqzrCbCpW0UvfMFf7jgr+0YobJolLDZ1wwwkSb+Dxwaxgvfh3vGXHpmCYn
 7MdryQmAM1aAdZm+1cAdEm0bXdEfJ4o9TCOQeWf92uWhxOC4mzxzyO0
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vep_alloc_request() wasn't initializing vrequest->udc, so cancellations
on the FunctionFS AIO path were arriving in vep_dequeue without a valid
UDC reference.

Since vrequest->udc is never actually properly used anywhere, we opt to
remove it, and update vep_dequeue to obtain a reference to the udc with
ep_to_vudc(), consistent with the other vep_ ops.

AFAICT this bug has existed for ~10 years. Seems that nobody has really
stressed the FunctionFS AIO path on usbip's vudc.

I tested this fix in a QEMU aarch64 guest driving FunctionFS endpoints
via AIO. Before the fix, running `usbip attach` from the host would
cause the guest to oops with the following backtrace:

Call trace:
 vep_dequeue+0x1c/0xe4 (P)
 usb_ep_dequeue+0x14/0x20
 ffs_aio_cancel+0x24/0x34
 __arm64_sys_io_cancel+0xb0/0x124
 do_el0_svc+0x68/0x100
 el0_svc+0x18/0x5c
 el0t_64_sync_handler+0x98/0xdc
 el0t_64_sync+0x154/0x158

Assisted-by: opencode:openai/gpt-5.5
Fixes: b6a0ca111867 ("usbip: vudc: Add UDC specific ops")
Reviewed-by: Igor Kotrasinski <i.kotrasinsk@samsung.com>
Signed-off-by: Sam Day <me@samcday.com>
---
Changes in v3:
- vep_dequeue(): remove `struct vrequest` usage from vep_dequeue entirely
- Link to v2: https://lore.kernel.org/r/20260620-usbip-vudc-deque-fix-v2-1-d1913ab4611b@samcday.com

Changes in v2:
- vep_dequeue(): Reworked to remove vrequest->udc entirely, preferring a
  call to ep_to_vudc() instead
- Link to v1: https://lore.kernel.org/r/20260619-usbip-vudc-deque-fix-v1-1-9021463b1903@samcday.com
---
 drivers/usb/usbip/vudc.h     | 1 -
 drivers/usb/usbip/vudc_dev.c | 4 +---
 2 files changed, 1 insertion(+), 4 deletions(-)

diff --git a/drivers/usb/usbip/vudc.h b/drivers/usb/usbip/vudc.h
index faf61c9c6a989..5ef0e7d9b23ad 100644
--- a/drivers/usb/usbip/vudc.h
+++ b/drivers/usb/usbip/vudc.h
@@ -38,7 +38,6 @@ struct vep {
 
 struct vrequest {
 	struct usb_request req;
-	struct vudc *udc;
 	struct list_head req_entry; /* Request queue */
 };
 
diff --git a/drivers/usb/usbip/vudc_dev.c b/drivers/usb/usbip/vudc_dev.c
index c5f079c5a1ea5..5ef88117965d1 100644
--- a/drivers/usb/usbip/vudc_dev.c
+++ b/drivers/usb/usbip/vudc_dev.c
@@ -333,7 +333,6 @@ static int vep_queue(struct usb_ep *_ep, struct usb_request *_req,
 static int vep_dequeue(struct usb_ep *_ep, struct usb_request *_req)
 {
 	struct vep *ep;
-	struct vrequest *req;
 	struct vudc *udc;
 	struct vrequest *lst;
 	unsigned long flags;
@@ -343,8 +342,7 @@ static int vep_dequeue(struct usb_ep *_ep, struct usb_request *_req)
 		return ret;
 
 	ep = to_vep(_ep);
-	req = to_vrequest(_req);
-	udc = req->udc;
+	udc = ep_to_vudc(ep);
 
 	if (!udc->driver)
 		return -ESHUTDOWN;

---
base-commit: 30ffa8de54e5cc80d93fd211ca134d1764a7011f
change-id: 20260619-usbip-vudc-deque-fix-d316de3d3f16

Best regards,
-- 
Sam Day <me@samcday.com>

