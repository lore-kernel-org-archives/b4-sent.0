From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Date: Thu, 23 Jul 2026 18:27:10 +0700
Subject: [PATCH 3/4] Input: edt-ft5x06 - allow reading the touch frame one
 register at a time
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-ft5426-v1-3-d4b4e32be042@gmail.com>
References: <20260723-b4-ft5426-v1-0-d4b4e32be042@gmail.com>
In-Reply-To: <20260723-b4-ft5426-v1-0-d4b4e32be042@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784806028; l=3201;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=/kaGFdHU8xM8Uq6yxPXvl4M3ZEPYoY2WUk9xAjehqNs=;
 b=bFJymW0Lwb9/tVbTBZZmejp1iA5i0JTyYdsXw5zot/D2NvYcilOHZlzNroDe6yl9cUyu92Wio
 DxGLEO7K12CA99RMH5aJ0e2C3BpGkkttZH0gV2vw4YWcNkPEEzFaFGL
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Teguh Sobirin <teguh@sobir.in>

Every touch interrupt reads the whole touch frame in a single i2c block
read via regmap_bulk_read(). On some boards the i2c controller the panel
is wired to cannot sustain that multi-byte transfer: on the AYANEO Pocket
DS the FocalTech FT5426 sits on a marginal Qualcomm GENI bus that
intermittently aborts a long read with -EAGAIN or -ETIMEDOUT, and the
GENI controller has no bus recovery, so the block read fails on nearly
every interrupt and the panel is unusable.

Honour the "no-regmap-bulk-read" property. When set, the driver reads the
frame one register at a time with a short retry on the transient bus
errors, keeping each transfer small enough to complete. Boards on a
healthy bus keep using the single bulk transfer and are unaffected.

Signed-off-by: Teguh Sobirin <teguh@sobir.in>
Co-developed-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
 drivers/input/touchscreen/edt-ft5x06.c | 37 ++++++++++++++++++++++++++++++++--
 1 file changed, 35 insertions(+), 2 deletions(-)

diff --git a/drivers/input/touchscreen/edt-ft5x06.c b/drivers/input/touchscreen/edt-ft5x06.c
index d6c3d033b83d..ac61ac44fd64 100644
--- a/drivers/input/touchscreen/edt-ft5x06.c
+++ b/drivers/input/touchscreen/edt-ft5x06.c
@@ -146,6 +146,7 @@ struct edt_ft5x06_ts_data {
 	enum edt_ver version;
 	unsigned int crc_errors;
 	unsigned int header_errors;
+	bool no_regmap_bulk_read;
 };
 
 struct edt_i2c_chip_data {
@@ -295,6 +296,31 @@ static const struct regmap_config edt_M06_i2c_regmap_config = {
 	.write = edt_M06_i2c_write,
 };
 
+static int edt_ft5x06_bulk_read(struct regmap *map, unsigned int start,
+				void *val, size_t len)
+{
+	u8 *dst = val;
+	size_t off;
+
+	for (off = 0; off < len; off++) {
+		unsigned int v;
+		int ret, tries;
+
+		for (tries = 0; tries < 3; tries++) {
+			ret = regmap_read(map, start + off, &v);
+			if (!ret)
+				break;
+			if (ret == -ETIMEDOUT || ret == -EAGAIN)
+				usleep_range(2000, 4000);
+		}
+		if (ret)
+			return ret;
+		dst[off] = v;
+	}
+
+	return 0;
+}
+
 static irqreturn_t edt_ft5x06_ts_isr(int irq, void *dev_id)
 {
 	struct edt_ft5x06_ts_data *tsdata = dev_id;
@@ -304,8 +330,12 @@ static irqreturn_t edt_ft5x06_ts_isr(int irq, void *dev_id)
 	int error;
 
 	memset(rdbuf, 0, sizeof(rdbuf));
-	error = regmap_bulk_read(tsdata->regmap, tsdata->tdata_cmd, rdbuf,
-				 tsdata->tdata_len);
+	if (tsdata->no_regmap_bulk_read)
+		error = edt_ft5x06_bulk_read(tsdata->regmap, tsdata->tdata_cmd,
+					     rdbuf, tsdata->tdata_len);
+	else
+		error = regmap_bulk_read(tsdata->regmap, tsdata->tdata_cmd,
+					 rdbuf, tsdata->tdata_len);
 	if (error) {
 		dev_err_ratelimited(dev, "Unable to fetch data, error: %d\n",
 				    error);
@@ -1212,6 +1242,9 @@ static int edt_ft5x06_ts_probe(struct i2c_client *client)
 		return error;
 	}
 
+	tsdata->no_regmap_bulk_read =
+		device_property_read_bool(&client->dev, "no-regmap-bulk-read");
+
 	/*
 	 * Check which sleep modes we can support. Power-off requires the
 	 * reset-pin to ensure correct power-down/power-up behaviour. Start with

-- 
2.55.0

