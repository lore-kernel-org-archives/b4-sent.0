From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 14 Oct 2025 17:11:41 +0100
Subject: [PATCH] iio: dac: ad5446: Add AD5542 to the spi id table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251014-dev-add-ad5542-v1-1-cfd197db03a0@analog.com>
X-B4-Tracking: v=1; b=H4sIADx27mgC/x2MQQqAIBQFrxJ/naCmYF0lWoj/VX9joRBBdPekx
 SxmMfNQRRFUmrqHCi6pcuQmpu8o7TFvUMLNyWrrjTZOMS4VmRveO6tCCuPgGEED1KKzYJX7H87
 L+356bfBzYAAAAA==
X-Change-ID: 20251014-dev-add-ad5542-8c8934de80ee
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760458303; l=1036;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=zjLKzS1W0/5HBFY1YTVVWSk3p4EDX/9So7On4WYstjk=;
 b=E1C/CYMOFW2iu4rNfmmBcdVfvqnYKSbiuMTO2Kfp7Hlp7me3gNPymAl0zp6cxMayDHQTASval
 sHV/BReLDxPCJurJxSXBtcTTDwHfdbMtuAJixwwySr3H1n+uIJUx9zt
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Hennerich <michael.hennerich@analog.com>

This adds support for the AD5542 single channel Current Source and
Voltage Output DACs.

It is similar to the AD5542A model so just use the same id.

Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index ad304b0fec08..6e4103f4afcb 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -422,6 +422,7 @@ static const struct spi_device_id ad5446_spi_ids[] = {
 	{"ad5512a", ID_AD5512A},
 	{"ad5541a", ID_AD5541A},
 	{"ad5542a", ID_AD5541A}, /* ad5541a and ad5542a are compatible */
+	{"ad5542", ID_AD5541A}, /* ad5541a and ad5542a are compatible */
 	{"ad5543", ID_AD5541A}, /* ad5541a and ad5543 are compatible */
 	{"ad5553", ID_AD5553},
 	{"ad5600", ID_AD5600},

---
base-commit: 4b17a60d1e1c2d9d2ccbd58642f6f4ac2fa364ba
change-id: 20251014-dev-add-ad5542-8c8934de80ee
--

Thanks!
- Nuno Sá

