From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 15 Jun 2026 13:20:51 -0500
Subject: [PATCH v3 1/2] Input: apple_z2 - bound the device-reported packet
 length
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-b4-disp-05943ee1-v3-1-bbfe1b651613@proton.me>
References: <20260615-b4-disp-05943ee1-v3-0-bbfe1b651613@proton.me>
In-Reply-To: <20260615-b4-disp-05943ee1-v3-0-bbfe1b651613@proton.me>
To: Sasha Finkelstein <k@chaosmail.tech>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Neal Gompa <neal@gompa.dev>, asahi@lists.linux.dev, 
 Sven Peter <sven@kernel.org>, linux-input@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781547650; l=2446;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=0disTE6FLcmJRgyM/FHjVXBLuUuCv501SYEb1c85Kas=;
 b=+f1rkqMagRllETr38DyiMSMBldd07Ev1yHnQc0RGV3vV+DweLYAlWjnOCARVzGzjvvuTw9pN3
 mOQVdD2hyLdB1jKC8zLiX+HQFNHszsBUBn3QlmHzK5Lvv/MbnOYmdd1
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

apple_z2_read_packet() takes a 16-bit length from the touch controller's
interrupt-data reply (rx_buf[1..2]) and, only rounded down to a multiple of
four, uses it as the size of the second SPI transfer into the fixed-size
rx_buf:

	pkt_len = (get_unaligned_le16(z2->rx_buf + 1) + 8) & 0xfffffffc;
	error = spi_read(z2->spidev, z2->rx_buf, pkt_len);

rx_buf is a fixed 4000-byte buffer, but pkt_len is fully controlled by the
device and is never checked against it, so a malicious, malfunctioning or
counterfeit controller (or an interposer on the SPI bus) that reports a
large length makes spi_read() write up to 65540 device-supplied bytes into
the 4000-byte buffer -- a controller-driven heap out-of-bounds write of up
to about 61 KiB.  The recently added reply-type check only validates
rx_buf[0], not the length.

Reject any packet whose length exceeds the receive buffer.

Fixes: 471a92f8a21a ("Input: apple_z2 - add a driver for Apple Z2 touchscreens")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
Reviewed-by: Sasha Finkelstein <k@chaosmail.tech>
---
 drivers/input/touchscreen/apple_z2.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/input/touchscreen/apple_z2.c b/drivers/input/touchscreen/apple_z2.c
index 271ababf0ad5..ff9ff97be185 100644
--- a/drivers/input/touchscreen/apple_z2.c
+++ b/drivers/input/touchscreen/apple_z2.c
@@ -22,6 +22,7 @@
 #define APPLE_Z2_TOUCH_MOVED             4
 #define APPLE_Z2_CMD_READ_INTERRUPT_DATA 0xEB
 #define APPLE_Z2_REPLY_INTERRUPT_DATA    0xE1
+#define APPLE_Z2_MAX_PACKET              4000
 #define APPLE_Z2_HBPP_CMD_BLOB           0x3001
 #define APPLE_Z2_FW_MAGIC                0x5746325A
 #define LOAD_COMMAND_INIT_PAYLOAD        0
@@ -147,6 +148,8 @@ static int apple_z2_read_packet(struct apple_z2 *z2)
 		return 0;
 
 	pkt_len = (get_unaligned_le16(z2->rx_buf + 1) + 8) & 0xfffffffc;
+	if (pkt_len > APPLE_Z2_MAX_PACKET)
+		return -EMSGSIZE;
 
 	error = spi_read(z2->spidev, z2->rx_buf, pkt_len);
 	if (error)
@@ -363,7 +366,7 @@ static int apple_z2_probe(struct spi_device *spi)
 	if (!z2->tx_buf)
 		return -ENOMEM;
 	/* 4096 will end up being rounded up to 8192 due to devres header */
-	z2->rx_buf = devm_kzalloc(dev, 4000, GFP_KERNEL);
+	z2->rx_buf = devm_kzalloc(dev, APPLE_Z2_MAX_PACKET, GFP_KERNEL);
 	if (!z2->rx_buf)
 		return -ENOMEM;
 

-- 
2.43.0

