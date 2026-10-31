From: Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
Date: Sat, 31 Oct 2026 13:16:17 +0100
Subject: [PATCH 3/3] Bluetooth: btusb: Disable broken LE extended scan on
 Barrot controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-barrot-le-fixes-v1-v1-3-30e2089882bf@tambosi.tn.it>
References: <20261031-barrot-le-fixes-v1-v1-0-30e2089882bf@tambosi.tn.it>
In-Reply-To: <20261031-barrot-le-fixes-v1-v1-0-30e2089882bf@tambosi.tn.it>
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793448994; l=2029;
 i=ernesto.salvetti@tambosi.tn.it; s=20261031; h=from:subject:message-id;
 bh=Fo2F/LHMZlxUCU94fy+cZtcQarZ+SAzum0VbRoH027c=;
 b=veY8SItlpCgGAwnU3X9Ogf0M1oE2m3jCTQ/d76N/IcfE0CkaC2Q+LTNIJ9pn8kr3SBvuCxDxE
 yALEr2ZmKrWCfFmwG+yuPYbm7NJVTYf1SnU2rg3FJNgoDfc2hTLoqrL
X-Developer-Key: i=ernesto.salvetti@tambosi.tn.it; a=ed25519;
 pk=OLNiuyRbYD4dcNYoAvM99nt/1KZTKeM316r91BCQDUs=
X-Endpoint-Received: by B4 Relay for ernesto.salvetti@tambosi.tn.it/20261031 with auth_id=1370
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Barrot controller in the UGREEN Bluetooth 5.4 dongle (33fa:0010)
reports support for LE Set Extended Scan Parameters/Enable and LE
Extended Create Connection, but stops answering commands as soon as
extended scanning is used. btusb then resets the device, it
re-enumerates and the same thing happens again, in a loop every ~4
seconds whenever a scan is started (e.g. to connect to an LE device):

  Bluetooth: hci0: Opcode 0x2041 failed: -110
  Bluetooth: hci0: command 0x2041 tx timeout
  usb 9-7: USB disconnect, device number 13
  usb 9-7: new full-speed USB device number 14 using xhci_hcd

Set HCI_QUIRK_BROKEN_EXT_SCAN and HCI_QUIRK_BROKEN_EXT_CREATE_CONN so
that only the legacy LE commands are used. Extended create connection
has to go as well, since legacy and extended commands can't be mixed.

This depends on the previous two patches: without them scanning fails
with Command Disallowed and LE connections are dropped right after
they are established.

Tested with 33fa:0010 (bcdDevice 88.91) and an Xbox Wireless
Controller: scanning, LE Secure Connections pairing and HID input work.
33fa:0012 shares the BTUSB_BARROT flag but was not tested.

Assisted-by: LLM
Signed-off-by: Ernesto Salvetti <ernesto.salvetti@tambosi.tn.it>
---
 drivers/bluetooth/btusb_main.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/bluetooth/btusb_main.c b/drivers/bluetooth/btusb_main.c
index 92a78a7e6039..d5f18134ee3a 100644
--- a/drivers/bluetooth/btusb_main.c
+++ b/drivers/bluetooth/btusb_main.c
@@ -4735,6 +4735,12 @@ static int btusb_probe(struct usb_interface *intf,
 		hci_set_quirk(hdev, HCI_QUIRK_BROKEN_WRITE_AUTH_PAYLOAD_TIMEOUT);
 	}
 
+	if (id->driver_info & BTUSB_BARROT) {
+		/* Support is advertised, but the controller hangs on it */
+		hci_set_quirk(hdev, HCI_QUIRK_BROKEN_EXT_SCAN);
+		hci_set_quirk(hdev, HCI_QUIRK_BROKEN_EXT_CREATE_CONN);
+	}
+
 	if (!reset)
 		hci_set_quirk(hdev, HCI_QUIRK_RESET_ON_CLOSE);
 

-- 
2.53.0.697.g625c4fb2daa

