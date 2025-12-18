From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Thu, 18 Dec 2025 09:11:26 +0100
Subject: [PATCH] Input: apple_z2: Fix reading incorrect reports after
 exiting sleep
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251218-z2-init-fix-v1-1-48e3aa239caf@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0Nz3Soj3cy8zBLdtMwKXeMkQ5PUNJNkMwtLAyWgjoKiVKAw2LTo2Np
 aAMagJqddAAAA
X-Change-ID: 20251217-z2-init-fix-3b14ef4c6890
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 pitust <piotr@stelmaszek.com>, Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766045498; l=1783;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=OF8WOCZRA9+JnU6tzC4FoVlFYz2Y9tJ9S+rCxmTtWYo=;
 b=9M/jobQWeFJaXDS54JFsLzWEHIDl+bbiBoVgcNi8y9zH0dzwiavKzcvWquVuCv2w6S35QyEFs
 /Tty1VBEmetC5P+Ey1YYZq8Io8EkRjNjS2pn7tc70FvVJ/n48GX7n+q
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Under certain conditions (more prevalent after a suspend/resume cycle),
the touchscreen controller can send the "boot complete" interrupt before
it actually finished booting. In those cases, attempting to read touch
data resuls in a stream of "not ready" messages being read and
interpreted as a touch report. Check that the response is in fact a
touch report and discard it otherwise.

Reported-by: pitust <piotr@stelmaszek.com>
Closes: https://oftc.catirclogs.org/asahi/2025-12-17#34878715;
Fixes: 471a92f8a21a ("Input: apple_z2 - add a driver for Apple Z2 touchscreens")
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/input/touchscreen/apple_z2.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/input/touchscreen/apple_z2.c b/drivers/input/touchscreen/apple_z2.c
index 0de161eae59a..271ababf0ad5 100644
--- a/drivers/input/touchscreen/apple_z2.c
+++ b/drivers/input/touchscreen/apple_z2.c
@@ -21,6 +21,7 @@
 #define APPLE_Z2_TOUCH_STARTED           3
 #define APPLE_Z2_TOUCH_MOVED             4
 #define APPLE_Z2_CMD_READ_INTERRUPT_DATA 0xEB
+#define APPLE_Z2_REPLY_INTERRUPT_DATA    0xE1
 #define APPLE_Z2_HBPP_CMD_BLOB           0x3001
 #define APPLE_Z2_FW_MAGIC                0x5746325A
 #define LOAD_COMMAND_INIT_PAYLOAD        0
@@ -142,6 +143,9 @@ static int apple_z2_read_packet(struct apple_z2 *z2)
 	if (error)
 		return error;
 
+	if (z2->rx_buf[0] != APPLE_Z2_REPLY_INTERRUPT_DATA)
+		return 0;
+
 	pkt_len = (get_unaligned_le16(z2->rx_buf + 1) + 8) & 0xfffffffc;
 
 	error = spi_read(z2->spidev, z2->rx_buf, pkt_len);

---
base-commit: ea1013c1539270e372fc99854bc6e4d94eaeff66
change-id: 20251217-z2-init-fix-3b14ef4c6890

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

