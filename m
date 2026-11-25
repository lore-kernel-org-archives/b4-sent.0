From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Wed, 25 Nov 2026 08:09:31 +0000
Subject: [PATCH v2 2/3] regmap: mask values to val_bits on write
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-regmap-kunit-val-bits-v2-2-81db3b79cd3f@gmail.com>
References: <20261125-regmap-kunit-val-bits-v2-0-81db3b79cd3f@gmail.com>
In-Reply-To: <20261125-regmap-kunit-val-bits-v2-0-81db3b79cd3f@gmail.com>
To: Mark Brown <broonie@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Liam Girdwood <lgirdwood@gmail.com>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-sound@vger.kernel.org, Neo Chang <YLCHANG2@nuvoton.com>, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795594173; l=3996;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=CpFxrUBFq4HChQ2hs185G3VYqsVjVNBbMpd8HrGPNY8=;
 b=I98w6ILxy/+xwRNqwo1EZi+6UekgRn4J/gmM3RWF2aO03gLHzHFrmSATpLsUk8jl/gW97Shur
 2kwXzlL3HSqBCXvpBr/TrL9ucAeTdMPymb+CoYd2snqOthrFepT1gkA
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

regmap_write() takes an unsigned int, also for regmaps with val_bits
smaller than 32. What happens to the bits above val_bits depends on the
bus and on the cache type:

- buses with a raw write() go through the value formatters, which drop
  the bits that do not fit in the formatted value;
- buses and users with only reg_write() get the value unmodified. Some
  of them, like the SMBus backends of regmap-i2c, then return -EINVAL;
- the cache may store a value that differs from the one written to the
  device.

For example the adux1020 driver writes ~u16, which is promoted to int,
to a 16-bit register. This works on I2C adapters and fails with -EINVAL
on SMBus-only ones.

Mask the value to val_bits in _regmap_write(), before updating the
cache, so that all buses and cache types behave the same. Do the same
for the values cached by _regmap_multi_reg_write(), which does not use
_regmap_write() on devices supporting multi register writes.

val_bits is documented as mandatory, but some users providing their own
reg_read() and reg_write() leave it at 0, for example because their
registers have different sizes. Do not mask values for these.

Suggested-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/base/regmap/internal.h |  1 +
 drivers/base/regmap/regmap.c   | 14 +++++++++++++-
 2 files changed, 14 insertions(+), 1 deletion(-)

diff --git a/drivers/base/regmap/internal.h b/drivers/base/regmap/internal.h
index ea375cc8ae87..6a7efb10127b 100644
--- a/drivers/base/regmap/internal.h
+++ b/drivers/base/regmap/internal.h
@@ -33,6 +33,7 @@ struct regmap_format {
 	size_t reg_bytes;
 	size_t pad_bytes;
 	size_t val_bytes;
+	unsigned int val_mask;
 	s8 reg_shift;
 	void (*format_write)(struct regmap *map,
 			     unsigned int reg, unsigned int val);
diff --git a/drivers/base/regmap/regmap.c b/drivers/base/regmap/regmap.c
index 45b5b4f76b0c..eab1bd2043ce 100644
--- a/drivers/base/regmap/regmap.c
+++ b/drivers/base/regmap/regmap.c
@@ -6,6 +6,7 @@
 //
 // Author: Mark Brown <broonie@opensource.wolfsonmicro.com>
 
+#include <linux/bits.h>
 #include <linux/device.h>
 #include <linux/slab.h>
 #include <linux/export.h>
@@ -1082,6 +1083,12 @@ struct regmap *__regmap_init(struct device *dev,
 	map->format.reg_shift = config->reg_shift;
 	map->format.reg_bytes = BITS_TO_BYTES(config->reg_bits);
 	map->format.val_bytes = BITS_TO_BYTES(config->val_bits);
+	/* Some users with their own register accessors don't set val_bits */
+	if (config->val_bits > 0 &&
+	    config->val_bits < BITS_PER_TYPE(map->format.val_mask))
+		map->format.val_mask = GENMASK(config->val_bits - 1, 0);
+	else
+		map->format.val_mask = UINT_MAX;
 	map->format.buf_size = BITS_TO_BYTES(config->reg_bits + config->val_bits + config->pad_bits);
 	if (config->reg_stride)
 		map->reg_stride = config->reg_stride;
@@ -1986,6 +1993,9 @@ int _regmap_write(struct regmap *map, unsigned int reg,
 	if (!regmap_writeable(map, reg))
 		return -EIO;
 
+	/* Make sure that the cache and the device see the same value */
+	val &= map->format.val_mask;
+
 	if (!map->cache_bypass && !map->defer_caching) {
 		ret = regcache_write(map, reg, val);
 		if (ret != 0)
@@ -2014,6 +2024,8 @@ int _regmap_write(struct regmap *map, unsigned int reg,
  * @reg: Register to write to
  * @val: Value to be written
  *
+ * If the regmap_config sets val_bits, any bits of @val above it are ignored.
+ *
  * A value of zero will be returned on success, a negative errno will
  * be returned in error cases.
  */
@@ -2611,7 +2623,7 @@ static int _regmap_multi_reg_write(struct regmap *map,
 
 	if (!map->cache_bypass) {
 		for (i = 0; i < num_regs; i++) {
-			unsigned int val = regs[i].def;
+			unsigned int val = regs[i].def & map->format.val_mask;
 			unsigned int reg = regs[i].reg;
 			ret = regcache_write(map, reg, val);
 			if (ret) {

-- 
2.56.0

