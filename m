From: Sam Day <me@samcday.com>
Date: Fri, 19 Jun 2026 10:28:49 +1000
Subject: [PATCH] usbip: vudc: fix NULL deref in vep_dequeue()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260619-usbip-vudc-deque-fix-v1-1-9021463b1903@samcday.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MywqAIBAAfyX23IIPEOpXokO1W+3FTFEC6d+Tj
 jMwUyFxFE4wdhUiF0ly+Qa672A7F38wCjUGo4xTTg+Y0yoBS6YNie/MuMuDZLUjtmR37aClIXL
 T/3aa3/cDPmYkymYAAAA=
X-Change-ID: 20260619-usbip-vudc-deque-fix-d316de3d3f16
To: Valentina Manea <valentina.manea.m@gmail.com>, 
 Shuah Khan <shuah@kernel.org>, Hongren Zheng <i@zenithal.me>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Krzysztof Opasiak <k.opasiak@samsung.com>, 
 Igor Kotrasinski <i.kotrasinsk@samsung.com>, Karol Kosik <karo9@interia.eu>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781828934; l=1715;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=JVJhd3pJhD1WvH0uTHxGI5DtrMLVc93YCbkxWy2vbjU=;
 b=mCvH0QQzyVr4xaU1WgxDh4XXu3UvflWoTXd75tyXz6TTb4J5HwEzGc1+dNKLWe//gJhRa2cag
 9xZhwOm4ohiBZkvFeuZBqf8O0nIE2mEjFFls/Xt6x+f0Y9fMt8Wggj4
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vep_alloc_request() wasn't initializing vrequest->udc, so cancellations
on the FunctionFS AIO path were arriving in vep_dequeue without a valid
UDC reference.

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
Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/usb/usbip/vudc_dev.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/usb/usbip/vudc_dev.c b/drivers/usb/usbip/vudc_dev.c
index c5f079c5a1ea..2f1f141909b2 100644
--- a/drivers/usb/usbip/vudc_dev.c
+++ b/drivers/usb/usbip/vudc_dev.c
@@ -279,15 +279,18 @@ static int vep_disable(struct usb_ep *_ep)
 static struct usb_request *vep_alloc_request(struct usb_ep *_ep,
 		gfp_t mem_flags)
 {
+	struct vep *ep;
 	struct vrequest *req;
 
 	if (!_ep)
 		return NULL;
+	ep = to_vep(_ep);
 
 	req = kzalloc_obj(*req, mem_flags);
 	if (!req)
 		return NULL;
 
+	req->udc = ep_to_vudc(ep);
 	INIT_LIST_HEAD(&req->req_entry);
 
 	return &req->req;

---
base-commit: 5cd1731cc883a9914d91e3b93d4597317b5b5339
change-id: 20260619-usbip-vudc-deque-fix-d316de3d3f16

Best regards,
-- 
Sam Day <me@samcday.com>

