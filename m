From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Wed, 04 Nov 2026 21:03:01 +0000
Subject: [PATCH] media: rc: redrat3: fix use-after-free of input device
 name/phys strings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-redrat3-input-uaf-v1-1-b882e43d9803@gmail.com>
X-B4-Tracking: v=1; b=H4sIAISd62oC/x3MPQqAMAxA4atIZgOtlfpzFXGoNmqWKqmKIL27x
 fEb3nshkjBF6IsXhG6OvIcMXRYwby6shOyzoVKV1VrVKOTFnQY5HNeJl1twst40bUfWzB3k7hB
 a+Pmfw5jSB8kKYj1jAAAA
To: Sean Young <sean@mess.org>, Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 syzbot+aec1962419768c5caf88@syzkaller.appspotmail.com, 
 Joas Antonio dos Santos <joasantonio108@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793826180; l=3240;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=c68HohiFSurQ192KfXE2Kl4zIbGHGZyY1chc3A+cUM8=;
 b=ILJCTmi2LPNHZiDhY7hZLunAi84A/UWCfPjunPtMwwTdAoHe90uITNQ1TaMibVa9A+Mm4AS8A
 AhGIDO/2g90AiLeApxlWYYeWMLde/tj808aR2QUoaXzpVg9dvNpcH6k
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

redrat3_init_rc_dev() sets rc->device_name and rc->input_phys to point
at the name[] and phys[] arrays embedded in struct redrat3_dev.
rc_prepare_rx_device() then copies these pointers into input_dev->name
and input_dev->phys without duplicating the strings.

When redrat3_dev_disconnect() runs, it calls redrat3_delete() which
kfrees the redrat3_dev struct, freeing the embedded name and phys
arrays.  If an evdev client still holds the input device open, a
subsequent EVIOCGNAME or EVIOCGPHYS ioctl calls str_to_user() which
reads the freed string via strlen(), triggering a KASAN
slab-use-after-free on the freed kmalloc-2k object.

Fix by allocating the name and phys strings with devm_kasprintf() and
devm_kzalloc() respectively, tied to the USB interface device lifetime.
This ensures the strings outlive the input device, since the USB
interface device (and its devres) is not released until all references
to it are dropped.

Found by LLM-assisted code review of syzbot-reported crash patterns.

Reported-by: syzbot+aec1962419768c5caf88@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=aec1962419768c5caf88
Fixes: 2154be651bfd ("[media] redrat3: new driver")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
redrat3_init_rc_dev() stores pointers to the name[] and phys[] arrays
embedded in struct redrat3_dev into rc->device_name and rc->input_phys.
These are copied into input_dev->name/phys without duplication.

When the device disconnects, kfree(rr3) frees the strings while evdev
may still hold the input device open.  A subsequent EVIOCGNAME ioctl
dereferences the freed string via str_to_user() -> strlen(), triggering
a KASAN slab-use-after-free.

syzbot link: https://syzkaller.appspot.com/bug?extid=aec1962419768c5caf88
---
 drivers/media/rc/redrat3.c | 17 +++++++++++------
 1 file changed, 11 insertions(+), 6 deletions(-)

diff --git a/drivers/media/rc/redrat3.c b/drivers/media/rc/redrat3.c
index 3e82b5e66..d9e37ede2 100644
--- a/drivers/media/rc/redrat3.c
+++ b/drivers/media/rc/redrat3.c
@@ -229,8 +229,8 @@ struct redrat3_dev {
 
 	u32 carrier;
 
-	char name[64];
-	char phys[64];
+	char *name;
+	char *phys;
 };
 
 static void redrat3_dump_fw_error(struct redrat3_dev *rr3, int code)
@@ -943,11 +943,16 @@ static struct rc_dev *redrat3_init_rc_dev(struct redrat3_dev *rr3)
 	if (!rc)
 		return NULL;
 
-	snprintf(rr3->name, sizeof(rr3->name),
-		 "RedRat3%s Infrared Remote Transceiver",
-		 prod == USB_RR3IIUSB_PRODUCT_ID ? "-II" : "");
+	rr3->name = devm_kasprintf(rr3->dev, GFP_KERNEL,
+				   "RedRat3%s Infrared Remote Transceiver",
+				   prod == USB_RR3IIUSB_PRODUCT_ID ? "-II" : "");
+	if (!rr3->name)
+		goto out;
 
-	usb_make_path(rr3->udev, rr3->phys, sizeof(rr3->phys));
+	rr3->phys = devm_kzalloc(rr3->dev, 64, GFP_KERNEL);
+	if (!rr3->phys)
+		goto out;
+	usb_make_path(rr3->udev, rr3->phys, 64);
 
 	rc->device_name = rr3->name;
 	rc->input_phys = rr3->phys;

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261104-redrat3-input-uaf-b6d3789e63c9

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

