From: Anuj Bolewar <bolewara@gmail.com>
Date: Tue, 04 Aug 2026 12:39:05 +0530
Subject: [PATCH v2] usb: raw_gadget: fix use-after-free when UDC is removed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-raw-gadget-ep0-uaf-v2-1-3a5ded46ab50@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQ6CMBBEf4X07Jq2ihBP/ofhsLRLWSOUtIAaw
 r9b8G7m9JKZeYuIFJiiuGaLCDRzZN8n0IdMmBZ7R8A2sdBSX2QpzxDwBQ6toxFokDBhA0piqWt
 rMa+NSMMhUMPv/fRe/ThO9YPMuD1tjZbj6MNnt85q6/0VzAoUyKJMKU4WVX5zHfLzaHwnqnVdv
 zydfnbGAAAA
X-Change-ID: 20260804-raw-gadget-ep0-uaf-10a82bdda5bc
To: Andrey Konovalov <andreyknvl@gmail.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+9aacea11bc70c3ddaff2@syzkaller.appspotmail.com, 
 Anuj Bolewar <bolewara@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785827344; l=3579;
 i=bolewara@gmail.com; s=20260802; h=from:subject:message-id;
 bh=bFLKavspgBu4le5fmIl2M8+XfOkXMsCr6XLI9iZ/YEY=;
 b=HoqsHxICbaaGKnQbjAthWTJ3ov/SGc/VCwEenAFi/eI7NjhzOebxQ1mqPBZbp/hUzijtLsqp2
 A9MAibfT9YLDGRu9imG7RCiKTtSUoONZe5gHllPKWOclAJhrYwW4XoF
X-Developer-Key: i=bolewara@gmail.com; a=ed25519;
 pk=XxcXxqFWk9xQziyNEfhS6NRJQR1shqHRRYzkbaYamm0=
X-Endpoint-Received: by B4 Relay for bolewara@gmail.com/20260802 with auth_id=907
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the UDC is removed (e.g. dummy_hcd unbind via sysfs) while the raw
gadget fd is still open, usb_del_gadget() destroys the gadget device
and its name. raw_gadget keeps a dangling pointer in dev->gadget, and
ioctls dereference it after releasing dev->lock, leading to a
use-after-free in dev_err() when usb_ep_queue() fails.

Take a gadget reference in gadget_bind() and drop it in dev_free() so
the gadget device and its name stay alive for as long as the fd is open
and an ioctl may still dereference dev->gadget. gadget_unbind() only
marks the device as failed under dev->lock; the reference is dropped in
dev_free(), which runs only after the fd is closed and no ioctl can be
in flight.

Reported-by: syzbot+9aacea11bc70c3ddaff2@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=9aacea11bc70c3ddaff2
Fixes: f2c2e717642c ("usb: gadget: add raw-gadget interface")
Signed-off-by: Anuj Bolewar <bolewara@gmail.com>
---
The gadget device embedded in the UDC is destroyed when the UDC is
removed while the raw gadget fd is still open (e.g. unbinding dummy_hcd
via sysfs). raw_gadget keeps a dangling pointer in dev->gadget and
ioctls dereference it after dropping dev->lock, which KASAN reports as a
slab use-after-free in raw_process_ep0_io() (dev_err with a freed device
name).

Fix it by holding a gadget reference for the raw device lifetime:
gadget_bind() takes it, gadget_unbind() only marks the device as failed
under dev->lock, and the reference is dropped in dev_free() once the fd
is closed and no ioctl can still be in flight.
---
Changes in v2:
- Reworked per review: the gadget reference is now held for the raw
  device lifetime (bind until dev_free()) instead of the bind/unbind
  window, since ioctls dereference dev->gadget after releasing dev->lock
  and the UDC core owns the gadget's lifetime during bind/unbind.
- gadget_unbind() now only marks the device as failed under dev->lock;
  the reference is dropped in dev_free() after the fd is closed.
- Dropped the now-unneeded comment and switched the spinlock to guard().
- Link to v1: https://patch.msgid.link/20260804-raw-gadget-ep0-uaf-v1-1-07878773da15@gmail.com
---
 drivers/usb/gadget/legacy/raw_gadget.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/gadget/legacy/raw_gadget.c b/drivers/usb/gadget/legacy/raw_gadget.c
index 4febf8dac7c..d6341823f90 100644
--- a/drivers/usb/gadget/legacy/raw_gadget.c
+++ b/drivers/usb/gadget/legacy/raw_gadget.c
@@ -226,6 +226,7 @@ static void dev_free(struct kref *kref)
 		kfree(dev->eps[i].ep->desc);
 		dev->eps[i].state = STATE_EP_DISABLED;
 	}
+	usb_put_gadget(dev->gadget);
 	kfree(dev);
 }
 
@@ -302,7 +303,7 @@ static int gadget_bind(struct usb_gadget *gadget,
 	dev->req = req;
 	dev->req->context = dev;
 	dev->req->complete = gadget_ep0_complete;
-	dev->gadget = gadget;
+	dev->gadget = usb_get_gadget(gadget);
 	gadget_for_each_ep(ep, dev->gadget) {
 		dev->eps[i].ep = ep;
 		dev->eps[i].addr = get_ep_addr(ep->name);
@@ -329,6 +330,10 @@ static void gadget_unbind(struct usb_gadget *gadget)
 {
 	struct raw_dev *dev = get_gadget_data(gadget);
 
+	{
+		guard(spinlock_irqsave)(&dev->lock);
+		dev->state = STATE_DEV_FAILED;
+	}
 	set_gadget_data(gadget, NULL);
 	/* Matches kref_get() in gadget_bind(). */
 	kref_put(&dev->count, dev_free);

---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260804-raw-gadget-ep0-uaf-10a82bdda5bc

Best regards,
--  
Anuj Bolewar <bolewara@gmail.com>

