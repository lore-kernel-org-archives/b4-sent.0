From: =?utf-8?q?Bence_Cs=C3=B3k=C3=A1s?= <bence98@sch.bme.hu>
Date: Sun, 15 Mar 2026 12:24:44 +0100
Subject: [PATCH v2] USB: core: Use krealloc() in usb_cache_string()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260315-usb-krealloc-v2-1-32f83e090409@sch.bme.hu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNzQqDMBCEX0Vy7opZxWJPfY/iIUk3Tag/ZVelR
 Xz3RqGHwlw+mJlvVUIcSdQlWxXTEiWOQwI8ZcoFMzwI4j2xwgLrotQaZrHwZDJdNzqoqNKlx7I
 xjVdp8mLy8X3c3drE1giBZTO4sJ/0RibivRiiTCN/Du2i9/rPgP+GRYMGf65tgylVgVdxIbc95
 WFW7bZtX7kHnaHCAAAA
X-Change-ID: 20260311-usb-krealloc-4e413f239a9f
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Bence_Cs=C3=B3k=C3=A1s?= <bence98@sch.bme.hu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773573897; l=4191;
 i=bence98@sch.bme.hu; s=20260213; h=from:subject:message-id;
 bh=2kZ+PbbmbSbJa9UFioo3zinMoPidNiiYW8i/CUabtoE=;
 b=U4YeXma1jMRkhsd3BfahbVB9heC7qc9cqfIEry8ybQADDtelwJmnR+tnml/DXzp6zuJcD6oog
 205Pr+HIxvVAK5cFPVsE5iPIMXVfD0ERUyLdQ9UGNwJKMGCoHti4pVV
X-Developer-Key: i=bence98@sch.bme.hu; a=ed25519;
 pk=rtWE8PtqZ5ZMyUVCckDq8i1ASLxgUbV2fwDA8KaOli8=
X-Endpoint-Received: by B4 Relay for bence98@sch.bme.hu/20260213 with auth_id=636
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of "shrinking" the allocation by kmalloc()ing a new, smaller
buffer, utilize krealloc() to shrink the existing allocation. This saves
a memcpy(), as well as eliminates the temporary `smallbuf` allocation,
which guards against allocation failure under extreme memory pressure.

Signed-off-by: Bence Csókás <bence98@sch.bme.hu>
---
Tested on an AthlonII X2 PC running Arch userland with Plasma.

  $ sudo lsusb -vvv | grep -P 'i(Product|Manu)'
  can't get debug descriptor: Resource temporarily unavailable
    iManufacturer           3 Linux 7.0.0-rc3-00355-g94926a68d237 ohci_hcd
    iProduct                2 OHCI PCI host controller
    iManufacturer           1 Hewlett-Packard Company
    iProduct                2 HP USB Smart Card Keyboard
  can't get device qualifier: Resource temporarily unavailable
  can't get debug descriptor: Resource temporarily unavailable
    iManufacturer           1 PIXART
    iProduct                2 USB OPTICAL MOUSE
  can't get debug descriptor: Resource temporarily unavailable
  can't get device qualifier: Resource temporarily unavailable
  can't get debug descriptor: Resource temporarily unavailable
    iManufacturer           3 Linux 7.0.0-rc3-00355-g94926a68d237 ehci_hcd
    iProduct                2 EHCI Host Controller
    iManufacturer           3 Linux 7.0.0-rc3-00355-g94926a68d237 ehci_hcd
  can't get device qualifier: Resource temporarily unavailable
  can't get debug descriptor: Resource temporarily unavailable
    iProduct                2 EHCI Host Controller
  can't get debug descriptor: Resource temporarily unavailable
    iManufacturer           1 USB
    iProduct                2 Disk 2.0
    iManufacturer           3 Linux 7.0.0-rc3-00355-g94926a68d237 ehci_hcd
    iProduct                2 EHCI Host Controller
  can't get device qualifier: Resource temporarily unavailable
  can't get debug descriptor: Resource temporarily unavailable
  can't get debug descriptor: Resource temporarily unavailable
    iManufacturer           3 Linux 7.0.0-rc3-00355-g94926a68d237 ohci_hcd
    iProduct                2 OHCI PCI host controller
    iManufacturer           3 Linux 7.0.0-rc3-00355-g94926a68d237 ohci_hcd
    iProduct                2 OHCI PCI host controller
  can't get debug descriptor: Resource temporarily unavailable
  can't get debug descriptor: Resource temporarily unavailable
    iManufacturer           3 Linux 7.0.0-rc3-00355-g94926a68d237 ohci_hcd
    iProduct                2 OHCI PCI host controller
---
Changes in v2:
- Update msg, remove backticks
- Add testing results
- Remove ?:
- Link to v1: https://lore.kernel.org/r/20260312-usb-krealloc-v1-1-f76b92b92402@sch.bme.hu
---
 drivers/usb/core/message.c | 20 +++++++++++---------
 1 file changed, 11 insertions(+), 9 deletions(-)

diff --git a/drivers/usb/core/message.c b/drivers/usb/core/message.c
index ea970ddf8879..a0c77709aa36 100644
--- a/drivers/usb/core/message.c
+++ b/drivers/usb/core/message.c
@@ -1005,7 +1005,7 @@ int usb_string(struct usb_device *dev, int index, char *buf, size_t size)
 }
 EXPORT_SYMBOL_GPL(usb_string);
 
-/* one UTF-8-encoded 16-bit character has at most three bytes */
+/* one 16-bit character, when UTF-8-encoded, has at most three bytes */
 #define MAX_USB_STRING_SIZE (127 * 3 + 1)
 
 /**
@@ -1026,16 +1026,18 @@ char *usb_cache_string(struct usb_device *udev, int index)
 		return NULL;
 
 	buf = kmalloc(MAX_USB_STRING_SIZE, GFP_NOIO);
-	if (buf) {
-		len = usb_string(udev, index, buf, MAX_USB_STRING_SIZE);
-		if (len > 0) {
-			smallbuf = kmalloc(++len, GFP_NOIO);
-			if (!smallbuf)
-				return buf;
-			memcpy(smallbuf, buf, len);
-		}
+	if (!buf)
+		return NULL;
+
+	len = usb_string(udev, index, buf, MAX_USB_STRING_SIZE);
+	if (len <= 0) {
 		kfree(buf);
+		return NULL;
 	}
+
+	smallbuf = krealloc(buf, len + 1, GFP_NOIO);
+	if (unlikely(!smallbuf))
+		return buf;
 	return smallbuf;
 }
 EXPORT_SYMBOL_GPL(usb_cache_string);

---
base-commit: 1c9982b4961334c1edb0745a04cabd34bc2de675
change-id: 20260311-usb-krealloc-4e413f239a9f

Best regards,
-- 
Bence Csókás <bence98@sch.bme.hu>

