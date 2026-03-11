From: =?utf-8?q?Bence_Cs=C3=B3k=C3=A1s?= <bence98@sch.bme.hu>
Date: Thu, 12 Mar 2026 00:06:35 +0100
Subject: [PATCH] USB: core: Use `krealloc()` in `usb_cache_string()`
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260312-usb-krealloc-v1-1-f76b92b92402@sch.bme.hu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MwQqDMAyA4VeRnBewrQzcq8gOaZfOMFclURmI7
 75ux+/w/wcYq7DBrTlAeReTuVS4SwNppPJklEc1+NZf2+AcbhbxpUzTNCfsuHMh+9BTn6Emi3K
 Wz3833KsjGWNUKmn8Td5kKyuc5xcU/ug4dwAAAA==
X-Change-ID: 20260311-usb-krealloc-4e413f239a9f
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Bence_Cs=C3=B3k=C3=A1s?= <bence98@sch.bme.hu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773270407; l=1845;
 i=bence98@sch.bme.hu; s=20260213; h=from:subject:message-id;
 bh=ryeZKOW7CoNcTvHQhdlplcN1pMIWzqbmCO+DbTrOUHo=;
 b=TQXh95Qshna5DUlvdb+3cekUBsb7EGBbjdiOEEpRVdGjKu6uCnWEJ6F4M+n8xqlupNwBMgqIk
 uDLpQEFx+8DAwBBrbkN3uqDNpMaYsnT+UqcAEygIWIgk9Vtrtj9nuHU
X-Developer-Key: i=bence98@sch.bme.hu; a=ed25519;
 pk=rtWE8PtqZ5ZMyUVCckDq8i1ASLxgUbV2fwDA8KaOli8=
X-Endpoint-Received: by B4 Relay for bence98@sch.bme.hu/20260213 with auth_id=636
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of "shrinking" the allocation by `kmalloc()`ing a new, smaller
buffer, utilize `krealloc()` to shrink the existing allocation. This saves
a `memcpy()`, as well as guards against `smallbuf` allocation failure.

Signed-off-by: Bence Csókás <bence98@sch.bme.hu>
---
Using `krealloc()` makes this code from 2005 more readable as well as
robust. Nested `if`s were also unrolled.
---
 drivers/usb/core/message.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/usb/core/message.c b/drivers/usb/core/message.c
index ea970ddf8879..dfe61d8b913b 100644
--- a/drivers/usb/core/message.c
+++ b/drivers/usb/core/message.c
@@ -1005,7 +1005,7 @@ int usb_string(struct usb_device *dev, int index, char *buf, size_t size)
 }
 EXPORT_SYMBOL_GPL(usb_string);
 
-/* one UTF-8-encoded 16-bit character has at most three bytes */
+/* one 16-bit character, when UTF-8-encoded, has at most three bytes */
 #define MAX_USB_STRING_SIZE (127 * 3 + 1)
 
 /**
@@ -1026,17 +1026,17 @@ char *usb_cache_string(struct usb_device *udev, int index)
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
-	return smallbuf;
+
+	smallbuf = krealloc(buf, len + 1, GFP_NOIO);
+	return smallbuf ? : buf;
 }
 EXPORT_SYMBOL_GPL(usb_cache_string);
 

---
base-commit: 80234b5ab240f52fa45d201e899e207b9265ef91
change-id: 20260311-usb-krealloc-4e413f239a9f

Best regards,
-- 
Bence Csókás <bence98@sch.bme.hu>

