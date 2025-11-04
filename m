From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 15:35:16 +0000
Subject: [PATCH v4 11/12] iio: dac: ad5446: Fix coding style issues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-dev-add-ad5542-v4-11-6fe35458bf8c@analog.com>
References: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
In-Reply-To: <20251104-dev-add-ad5542-v4-0-6fe35458bf8c@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762270508; l=2276;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=wp+ds6Uvm1OufbfcraCAfstJKrBi0o/vRLt8tzG3osc=;
 b=Ra8MnTbB19a9ryIbzdigMOXBDH64qNT1ZIlMTbB2Kyk759J3dEEV2BFnv0CTPXE2Nm/RBuWsT
 VtfnqS7NwfzBY9q2OdOB8T40jzBwCWDbCaNtVQYTaVQbXe6AFop4eIM
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix style issues as reported by checkpatch.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 23 +++++++++++------------
 1 file changed, 11 insertions(+), 12 deletions(-)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index 0556ce78c2f6..46a2eadb1d9b 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -28,7 +28,8 @@ static const char * const ad5446_powerdown_modes[] = {
 };
 
 static int ad5446_set_powerdown_mode(struct iio_dev *indio_dev,
-	const struct iio_chan_spec *chan, unsigned int mode)
+				     const struct iio_chan_spec *chan,
+				     unsigned int mode)
 {
 	struct ad5446_state *st = iio_priv(indio_dev);
 
@@ -38,7 +39,7 @@ static int ad5446_set_powerdown_mode(struct iio_dev *indio_dev,
 }
 
 static int ad5446_get_powerdown_mode(struct iio_dev *indio_dev,
-	const struct iio_chan_spec *chan)
+				     const struct iio_chan_spec *chan)
 {
 	struct ad5446_state *st = iio_priv(indio_dev);
 
@@ -53,9 +54,9 @@ static const struct iio_enum ad5446_powerdown_mode_enum = {
 };
 
 static ssize_t ad5446_read_dac_powerdown(struct iio_dev *indio_dev,
-					   uintptr_t private,
-					   const struct iio_chan_spec *chan,
-					   char *buf)
+					 uintptr_t private,
+					 const struct iio_chan_spec *chan,
+					 char *buf)
 {
 	struct ad5446_state *st = iio_priv(indio_dev);
 
@@ -63,9 +64,9 @@ static ssize_t ad5446_read_dac_powerdown(struct iio_dev *indio_dev,
 }
 
 static ssize_t ad5446_write_dac_powerdown(struct iio_dev *indio_dev,
-					    uintptr_t private,
-					    const struct iio_chan_spec *chan,
-					    const char *buf, size_t len)
+					  uintptr_t private,
+					  const struct iio_chan_spec *chan,
+					  const char *buf, size_t len)
 {
 	struct ad5446_state *st = iio_priv(indio_dev);
 	unsigned int shift;
@@ -147,10 +148,8 @@ static int ad5446_write_dac_raw(struct iio_dev *indio_dev,
 }
 
 static int ad5446_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			    struct iio_chan_spec const *chan, int val,
+			    int val2, long mask)
 {
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:

-- 
2.51.0

