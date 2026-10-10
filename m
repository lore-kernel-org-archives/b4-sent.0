From: Joe Finzel <joe@sudmix.de>
Date: Sun, 11 Oct 2026 01:15:38 +0200
Subject: [PATCH] usb: core: sysfs: show product, manufacturer and serial
 without the device lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-usb-string-attrs-v1-1-81c01b035237@sudmix.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0ND3dLiJN3ikqLMvHTdxJKSomJdc5PEpORkiyQDQ0tTJaC2gqLUtMw
 KsJHRsbW1AK/2+spiAAAA
X-Change-ID: 20261011-usb-string-attrs-74abcc8b0195
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joe Finzel <joe@sudmix.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791674165; l=3659;
 i=joe@sudmix.de; s=default; h=from:subject:message-id;
 bh=LEiZ3lipNkBDeej5oGGzhDg0xp3CXis9f9pyWGU3Azk=;
 b=xDiGdSpez3KbgFv5iw8xei9b210OS1Ui8sJ+qEH4Ndtx1luVcc6L1Y6eoOvYc7FZNwniLGEQ5
 tF/WltXOTGTBedUBqezxHfs0AyMa54/6ylVnyBtlaG6jCI8BAzewX+z
X-Developer-Key: i=joe@sudmix.de; a=ed25519;
 pk=vaX11uVm57me/1N8otNmzMMnsE+f0U3/Hi9TCPbnvZM=
X-Endpoint-Received: by B4 Relay for joe@sudmix.de/default with auth_id=1151
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reading the product, manufacturer or serial attribute of a USB device
takes the device lock. A hub holds its lock in hub_event() while it
enumerates all of its ports, including the debounce and reset delays of
every child, so a reader of the hub's strings waits until the last port
is done -- seconds on a hub with several devices.

udev reads these strings for every USB device (the usb_id builtin, run
from 50-udev-default.rules). Its worker blocks SIGTERM, so when systemd
stops udevd in the initrd before switching root, it waits for that
worker. On a desktop with a few hubs this delays every boot:

  i7-13700K, ASUS ROG STRIX Z790-F, four hubs with HID devices behind
  them: udevd took 1.7 s to stop, while the hubs were still enumerating.

  QEMU, qemu-xhci with 8 usb-hubs of 8 HID devices each, second boot,
  three runs: udevd stops in 2.55-2.58 s (switch-root at 5.56-5.59 s);
  with this patch in 11-12 ms (switch-root at 3.02 s). Without usb_id in
  the udev rules, it stops in 9 ms as well.

  -device qemu-xhci,id=xhci,p2=8,p3=8
  -device usb-hub,bus=xhci.0,port=N       (N = 1..8)
  -device usb-kbd,bus=xhci.0,port=N.M   (M = 1..8; also mouse, tablet)

The lock is not needed: usb_enumerate_device() sets the strings once,
before device_add() makes the attributes visible, and usb_release_dev()
frees them only after the attributes are gone. Nothing changes them in
between: authorizing or deauthorizing a device no longer touches them
since Wireless USB, for which they could appear and disappear, was
removed. dev_string_attrs_are_visible() already reads them unlocked.

Andy Whitcroft reported the same boot stall in 2010 ("khubd -- switch
USB product/manufacturer/serial handling to RCU"); back then the strings
could still change under Wireless USB.

Signed-off-by: Joe Finzel <joe@sudmix.de>
---
Found while looking into a 1.7 s stall at the end of the initrd on a
desktop with several USB hubs; reproducible in QEMU (see the commit
message). Tested on 7.2.9 with the QEMU reproduction; applies to
usb-next.
---
 drivers/usb/core/sysfs.c | 19 +++++++++----------
 1 file changed, 9 insertions(+), 10 deletions(-)

diff --git a/drivers/usb/core/sysfs.c b/drivers/usb/core/sysfs.c
index d22dc7845..52e0a227c 100644
--- a/drivers/usb/core/sysfs.c
+++ b/drivers/usb/core/sysfs.c
@@ -120,21 +120,20 @@ static ssize_t devspec_show(struct device *dev, struct device_attribute *attr,
 static DEVICE_ATTR_RO(devspec);
 #endif
 
-/* String fields */
+/*
+ * String fields. usb_enumerate_device() reads them once, before the device
+ * is added, and they are freed only when it is released, so showing them
+ * needs no lock -- dev_string_attrs_are_visible() reads them unlocked, too.
+ * The device lock would make readers wait while a hub holds it to enumerate
+ * all of its ports.
+ */
 #define usb_string_attr(name)						\
 static ssize_t  name##_show(struct device *dev,				\
 		struct device_attribute *attr, char *buf)		\
 {									\
-	struct usb_device *udev;					\
-	int retval;							\
+	struct usb_device *udev = to_usb_device(dev);			\
 									\
-	udev = to_usb_device(dev);					\
-	retval = usb_lock_device_interruptible(udev);			\
-	if (retval < 0)							\
-		return -EINTR;						\
-	retval = sysfs_emit(buf, "%s\n", udev->name);			\
-	usb_unlock_device(udev);					\
-	return retval;							\
+	return sysfs_emit(buf, "%s\n", udev->name);			\
 }									\
 static DEVICE_ATTR_RO(name)
 

---
base-commit: 42bcac323cc3b16566fed8c5b250318ad02a0de0
change-id: 20261011-usb-string-attrs-74abcc8b0195

Best regards,
-- 
Joe Finzel <joe@sudmix.de>

