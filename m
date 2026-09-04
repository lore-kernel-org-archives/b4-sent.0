From: Johann Fischer <johann.fischer@nordicsemi.no>
Date: Sat, 05 Sep 2026 00:24:08 +0200
Subject: [PATCH] Bluetooth: btusb: do not probe non-HCI interfaces
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-btusb-skip-non-hci-ifaces-v1-1-32dda494122f@nordicsemi.no>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrB1Igz+1VxEXmXSsUyFKRkUQ7
 25sl9/ivQOUo7DCKzsg8iYqU0h45Bn4wYUPo7yTwRpbmcYUSMuqhDrKjGEKOHhB6Z1nRSotO9s
 8q7omSP0cuZf99267v3WlL/vlHsJ5XnnktPR9AAAA
X-Change-ID: 20260904-btusb-skip-non-hci-ifaces-b52ea298677b
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Johann Fischer <johann.fischer@nordicsemi.no>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1109;
 i=johann.fischer@nordicsemi.no; h=from:subject:message-id;
 bh=N9bMTaAocKK1v8xDH8TgTymZY5ojzij51J8enWGWLwY=;
 b=owEBbQKS/ZANAwAKAYSE5whenKmxAcsmYgBqm0UZ9dRRF5Qie8QtQ3kv0opJyLtOVGhp78COk
 rMYHFv7SfyJAjMEAAEKAB0WIQRX82HLlVW1Jm9YMr+EhOcIXpypsQUCaptFGQAKCRCEhOcIXpyp
 seC/EACvELEj4cxv8kO2tR9jfXdVyszVPCZ8e+4YQdBtTrUcroSwb8Wp9J9JmrdkIQsTrs93Uyp
 P4QG64asNL+z1uuAwdi1HwQBGVlNUFzTmTVRLhC2U1GQYoapmtWDI7L3xbhvW1jhynxbZFPHIqO
 KnV0xYoGj4oOSDHWmMyY/HESTqKQHY9m4thSDjze6eg0xK/CjHMZep6Z8azi84oXhcAm2Ums8Fc
 +VeAU81ERiprydS0gEanuzXrGaznZC7Ygmn1/LfJkAbOA+ZZh3G0SaYugNuuGf4EyriAnIT4V/a
 uohIlY3w1q5wAZ5jM9g85G5KiI3VtWejxaNj4LXebwOCM4XpkA1eWN2+r9iwfDFadx6fkHUrXSV
 r7/9yNcIR8WH19pSoDFNuhuxg9cn3R4bt9XaUbE55jdQ8wCKChslEFoNa64ZOM43WItuWc2gqCc
 /pYrb2QTa+WtYwokE65bs05EuoiGZeHqcDFjtpgIGBXPiMdzP0gKqafCSuxZd0IK0pj0L8cq68x
 eDHXVpqU4yMKC5oR22sF4URK5gcUxuc77509y7MLqqjRNUi9ZSXFk0yILSKSVpykWPouASy7kIK
 aJJEWyovgqKZtq/bLtVgPHYoi1tNS1PRfUFCRQFvJbrc1V0geNs65754B101kzfNHj57LSxQwBp
 PmMZaJMpL9RUdkQ==
X-Developer-Key: i=johann.fischer@nordicsemi.no; a=openpgp;
 fpr=57F361CB9555B5266F5832BF8484E7085E9CA9B1
X-Endpoint-Received: by B4 Relay for johann.fischer@nordicsemi.no/default with auth_id=1003
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the driver selects BTUSB_PROTO_H4, the second interface (voice
channels) remains unclaimed. Then, the btusb_probe() is called for the
second interface. It misidentifies the interface as one that supports
legacy mode and fails with "failed to enumerate endpoints".

Signed-off-by: Johann Fischer <johann.fischer@nordicsemi.no>
---
 drivers/bluetooth/btusb.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/bluetooth/btusb.c b/drivers/bluetooth/btusb.c
index dfefb43fb792..44f0db347643 100644
--- a/drivers/bluetooth/btusb.c
+++ b/drivers/bluetooth/btusb.c
@@ -4293,6 +4293,11 @@ static int btusb_probe(struct usb_interface *intf,
 			return -ENODEV;
 	}
 
+	/*  Skip interfaces that do not implement the HCI transport */
+	if (usb_find_common_endpoints(intf->cur_altsetting,
+				      &bulk_rx_ep, &bulk_tx_ep, &intr_ep, NULL))
+		return -ENODEV;
+
 	data = kzalloc_obj(*data);
 	if (!data)
 		return -ENOMEM;

---
base-commit: 88a8184cb44c8952e6a6fd21e250445300d1c7aa
change-id: 20260904-btusb-skip-non-hci-ifaces-b52ea298677b

Best regards,
--  
Johann

