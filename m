From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 15:35:07 +0000
Subject: [PATCH v4 02/12] iio: dac: ad5446: Use DMA safe buffer for
 transfers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-dev-add-ad5542-v4-2-6fe35458bf8c@analog.com>
References: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
In-Reply-To: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762270508; l=1997;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=46famHhMqK6pdPFGxx4pY0sifQUpnrHIY3AH+TPxpr8=;
 b=ALDlYE1NquYKGgazTyb0hXprmbuPRP7TCR9ISRMcP4MU62GqaEyD04k3URvM0kGcyzmUfKnxS
 wBxSGEmTqAtCaiKcRBC8prYyY1Rxn0rqG+WxHhvrLBZPJ2g7pnUXgPB
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make sure to use DMA safe buffer. While for i2c we could be fine without
them, we need it for spi anyways.

As we now have DMA safe buffers, use i2c_master_send_dmasafe().

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 19 +++++++++++--------
 1 file changed, 11 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index ad304b0fec08..de5e4e0e397e 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -47,6 +47,10 @@ struct ad5446_state {
 	unsigned			pwr_down_mode;
 	unsigned			pwr_down;
 	struct mutex			lock;
+	union {
+		__be16 d16;
+		u8 d24[3];
+	} __aligned(IIO_DMA_MINALIGN);
 };
 
 /**
@@ -265,19 +269,18 @@ static int ad5446_probe(struct device *dev, const char *name,
 static int ad5446_write(struct ad5446_state *st, unsigned val)
 {
 	struct spi_device *spi = to_spi_device(st->dev);
-	__be16 data = cpu_to_be16(val);
+	st->d16 = cpu_to_be16(val);
 
-	return spi_write(spi, &data, sizeof(data));
+	return spi_write(spi, &st->d16, sizeof(st->d16));
 }
 
 static int ad5660_write(struct ad5446_state *st, unsigned val)
 {
 	struct spi_device *spi = to_spi_device(st->dev);
-	uint8_t data[3];
 
-	put_unaligned_be24(val, &data[0]);
+	put_unaligned_be24(val, &st->d24[0]);
 
-	return spi_write(spi, data, sizeof(data));
+	return spi_write(spi, st->d24, sizeof(st->d24));
 }
 
 /*
@@ -489,13 +492,13 @@ static inline void ad5446_spi_unregister_driver(void) { }
 static int ad5622_write(struct ad5446_state *st, unsigned val)
 {
 	struct i2c_client *client = to_i2c_client(st->dev);
-	__be16 data = cpu_to_be16(val);
+	st->d16 = cpu_to_be16(val);
 	int ret;
 
-	ret = i2c_master_send(client, (char *)&data, sizeof(data));
+	ret = i2c_master_send_dmasafe(client, (char *)&st->d16, sizeof(st->d16));
 	if (ret < 0)
 		return ret;
-	if (ret != sizeof(data))
+	if (ret != sizeof(st->d16))
 		return -EIO;
 
 	return 0;

-- 
2.51.0

