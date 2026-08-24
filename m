From: "Ji-Ze Hong (Peter Hong)" <peter_hong@fintek.com.tw>
Date: Mon, 24 Aug 2026 21:18:14 +0800
Subject: [PATCH v2] can: usb: f81604: fix struct f81604_int_data size
 mismatch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-f81604-fix-v2-1-fc9be5581394@fintek.com.tw>
X-B4-Tracking: v=1; b=H4sIAJVEjGoC/1WMyw7CIBBFf6WZtRAgFdFV/8MYQ+lQ0BQawEfS9
 N+lunIxuTk3d84CGZPHDKdmgYRPn30MFcSuAeN0GJH4oTIIJiRToiVWcclq+DfRGvuB21Ygk1A
 f5oS1/srOlx/nR39DUzbDtrApTqS4hPpPWu+wV/TIuSKczFgwXV0MY2d9KHinJk60vGBdP7+so
 p6vAAAA
X-Change-ID: 20260824-f81604-fix-aaebd1f42e06
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, "Dynetrex, Admin" <admin@dynetrex.com>, 
 "Ji-Ze Hong (Peter Hong)" <peter_hong@fintek.com.tw>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787577513; l=2109;
 i=peter_hong@fintek.com.tw; s=20260824; h=from:subject:message-id;
 bh=A/8jIUxJ46OgWF9VTd5CR2kRPJceYM0zgcKPipnmPJA=;
 b=fxLV2EfZZNHmnn2yfRfy1y5DN9RKGDTeDpiVKwJPxa7kBT1XFJQVpvn+wJuBa8uHhrz+2ccA4
 CpHVrwUXFjCAGXKNN/DXFoxh4QHcWwL+A/8loZYtj+sdK6a43IKvbdD
X-Developer-Key: i=peter_hong@fintek.com.tw; a=ed25519;
 pk=8sYixQfVOzNMM+g53fxG9d3MHOFC02ZggNS0OhG5LMA=
X-Endpoint-Received: by B4 Relay for peter_hong@fintek.com.tw/20260824 with auth_id=973
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The struct f81604_int_data defines 9 bytes of interrupt data:
- Byte 0: Status register (sr)
- Byte 1: Interrupt register (isrc)
- Byte 2: Interrupt enable register (ier)
- Byte 3: Arbitration lost capture (alc)
- Byte 4: Error code capture (ecc)
- Byte 5: Error warning limit register (ewlr)
- Byte 6: RX error counter (rxerr)
- Byte 7: TX error counter (txerr)
- Byte 8: Reserved (val)

The hardware sends exactly 9 bytes for the interrupt endpoint.
However, the struct was defined with __aligned(4) attribute which
caused the compiler to pad the struct to 12 bytes.

This causes a problem in f81604_read_int_callback() where the short
URB check compares urb->actual_length against sizeof(*data). When
sizeof(struct f81604_int_data) is 12 but the hardware only sends 9
bytes, the check fails and valid interrupt messages are discarded.

This results in the driver only being able to transmit once because
the TX complete interrupt is never processed.

Fix this by removing the __aligned(4) attribute so the struct size
matches the actual hardware data size of 9 bytes.

Fixes: 7299b1b39a25 ("can: usb: f81604: handle short interrupt urb messages properly")
Cc: stable@vger.kernel.org
Reported-by: Dynetrex, Admin <admin@dynetrex.com>
Closes: https://lore.kernel.org/all/A3834A07-5639-4779-844F-C5843DFC3928@dynetrex.com/
Signed-off-by: Ji-Ze Hong (Peter Hong) <peter_hong@fintek.com.tw>
---
v2:
- Added Reported-by and Remove mismatched Fixes tags
---
 drivers/net/can/usb/f81604.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/can/usb/f81604.c b/drivers/net/can/usb/f81604.c
index f12318268e46..4c147b9d6d69 100644
--- a/drivers/net/can/usb/f81604.c
+++ b/drivers/net/can/usb/f81604.c
@@ -169,7 +169,7 @@ struct f81604_int_data {
 	u8 rxerr;
 	u8 txerr;
 	u8 val;
-} __packed __aligned(4);
+} __packed;
 
 struct f81604_sff {
 	__be16 id;

---
base-commit: a13c140cc289c0b7b3770bce5b3ad42ab35074aa
change-id: 20260824-f81604-fix-aaebd1f42e06

Best regards,
--  
Ji-Ze Hong (Peter Hong) <peter_hong@fintek.com.tw>

