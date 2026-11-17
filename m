From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Tue, 17 Nov 2026 07:55:14 +0000
Subject: [PATCH RFC] regmap: kunit: add tests for values wider than
 val_bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-regmap-kunit-val-bits-v1-1-a1cd02063217@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBAAv0L27CYtRTBeTXiAV8OhxQVXpZBuI
 SaEv1vlOJPMrCAUmATO2QqBFhYefQJ9yKB9WN8T8j0x5CovtdYVBuoHO+Fr9hxxsW90HAXLojJ
 GHUmdjIPUToE6/vy/N7jWF2h2KbN7Uht/R9i2L9Ah5bl+AAAA
X-Change-ID: 20261117-regmap-kunit-val-bits-6473305e083b
To: Mark Brown <broonie@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>
Cc: Andy Shevchenko <andriy.shevchenko@intel.com>, 
 Jonathan Cameron <jic23@kernel.org>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, driver-core@lists.linux.dev, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794902116; l=5896;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=sa63Aup+aU28axygQ8eJYjxlMYwC6XzaZSpCzUHWHO8=;
 b=K6oYsRALgdvBPyAAmXvIrsv6TEUhkPOLaUS1pYxsmI2JTDFmXQcH+tBpdSPYps4XXFNnwp7zC
 6oyXoSXtRRQBNeVRJR/dVqelTiahE1fkbHr5cNPcAnhkpadJUO3VgV1
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two test cases writing 0xffffff0f with regmap_write() to a regmap
with val_bits = 16:

- write_wider_than_val_bits uses the RAM regmap, a bus that only
  provides reg_write()/reg_read();
- raw_write_wider_than_val_bits uses the raw RAM regmap, which goes
  through the value formatters.

Both expect that only the low 16 bits reach the bus and can be read
back. The raw test passes, since regmap_format_16_*() only store 16
bits. The RAM test currently fails: _regmap_bus_reg_write() hands the
value to bus->reg_write() unmodified, so the bus sees 0xffffff0f. With
the rbtree cache the value is in addition truncated in the cache only,
so the cache and the bus disagree.

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
regmap_write() takes an unsigned int, also for regmaps with
val_bits < 32. What happens to the bits above val_bits currently
depends on the bus and on the cache type:

- buses with raw write() go through the value formatters, which
  silently drop the upper bits;
- buses with only reg_write() get the value unmodified. regmap-i2c's
  SMBus backends and regmap-fsi then return -EINVAL, others (like
  regmap-ram here) take the full value;
- with a reg_write() bus and the rbtree cache, the cache stores the
  truncated value while the bus got the full one.

This was found in the adux1020 IIO driver, which writes ~u16 (promoted
to int) to a 16-bit register. It works on I2C adapters and fails with
-EINVAL on SMBus-only ones [1]. I am raising it here as other drivers
can hit the same thing.

The tests in this patch expect masking to val_bits on both kinds of
buses, so the reg_write one fails today. This is only to show the
difference: should regmap_write() mask the value to val_bits for
reg_write() buses, or should it reject such values consistently for all
buses? I can send a patch for whichever is preferred and adjust the
tests accordingly.

I prepared this patch with the help of an AI coding assistant, and
reviewed and tested it myself.

[1] https://lore.kernel.org/linux-iio/20261109-adux1020-measure-fixes-v1-1-fe1ba63f28bc@gmail.com/
---
 drivers/base/regmap/regmap-kunit.c | 62 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 62 insertions(+)

diff --git a/drivers/base/regmap/regmap-kunit.c b/drivers/base/regmap/regmap-kunit.c
index c78772b660d6..ed51a98efeb0 100644
--- a/drivers/base/regmap/regmap-kunit.c
+++ b/drivers/base/regmap/regmap-kunit.c
@@ -319,6 +319,33 @@ static void basic_read_write(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, config.cache_type == REGCACHE_NONE, data->read[0]);
 }
 
+static void write_wider_than_val_bits(struct kunit *test)
+{
+	const struct regmap_test_param *param = test->param_value;
+	struct regmap *map;
+	struct regmap_config config;
+	struct regmap_ram_data *data;
+	unsigned int rval;
+
+	config = test_regmap_config;
+	config.val_bits = 16;
+
+	map = gen_regmap(test, &config, &data);
+	KUNIT_ASSERT_FALSE(test, IS_ERR(map));
+	if (IS_ERR(map))
+		return;
+
+	/* Write a value with bits set above val_bits */
+	KUNIT_EXPECT_EQ(test, 0, regmap_write(map, param->from_reg, 0xffffff0f));
+
+	/* The bus should only have seen the low val_bits bits */
+	KUNIT_EXPECT_EQ(test, 0xff0f, data->vals[param->from_reg]);
+
+	/* And that is what we should read back */
+	KUNIT_EXPECT_EQ(test, 0, regmap_read(map, param->from_reg, &rval));
+	KUNIT_EXPECT_EQ(test, 0xff0f, rval);
+}
+
 static void bulk_write(struct kunit *test)
 {
 	struct regmap *map;
@@ -1984,6 +2011,39 @@ static void raw_write_read_single(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, val, rval);
 }
 
+static void raw_write_wider_than_val_bits(struct kunit *test)
+{
+	struct regmap *map;
+	struct regmap_config config;
+	struct regmap_ram_data *data;
+	u16 *hw_buf;
+	unsigned int rval;
+
+	config = raw_regmap_config;
+
+	map = gen_raw_regmap(test, &config, &data);
+	KUNIT_ASSERT_FALSE(test, IS_ERR(map));
+	if (IS_ERR(map))
+		return;
+
+	hw_buf = (u16 *)data->vals;
+
+	/* Write a value with bits set above val_bits */
+	KUNIT_EXPECT_EQ(test, 0, regmap_write(map, 0, 0xffffff0f));
+
+	/* The "hardware" should only have seen the low val_bits bits */
+	if (config.val_format_endian == REGMAP_ENDIAN_BIG)
+		KUNIT_EXPECT_EQ(test, 0xff0f,
+				be16_to_cpu((__force __be16)hw_buf[0]));
+	else
+		KUNIT_EXPECT_EQ(test, 0xff0f,
+				le16_to_cpu((__force __le16)hw_buf[0]));
+
+	/* And that is what we should read back */
+	KUNIT_EXPECT_EQ(test, 0, regmap_read(map, 0, &rval));
+	KUNIT_EXPECT_EQ(test, 0xff0f, rval);
+}
+
 static void raw_write(struct kunit *test)
 {
 	struct regmap *map;
@@ -2229,6 +2289,7 @@ static void raw_ranges(struct kunit *test)
 
 static struct kunit_case regmap_test_cases[] = {
 	KUNIT_CASE_PARAM(basic_read_write, regcache_types_gen_params),
+	KUNIT_CASE_PARAM(write_wider_than_val_bits, regcache_types_gen_params),
 	KUNIT_CASE_PARAM(read_bypassed, real_cache_types_gen_params),
 	KUNIT_CASE_PARAM(read_bypassed_volatile, real_cache_types_gen_params),
 	KUNIT_CASE_PARAM(bulk_write, regcache_types_gen_params),
@@ -2265,6 +2326,7 @@ static struct kunit_case regmap_test_cases[] = {
 	KUNIT_CASE_PARAM(raw_read_defaults_single, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_read_defaults, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_write_read_single, raw_test_types_gen_params),
+	KUNIT_CASE_PARAM(raw_write_wider_than_val_bits, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_write, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_noinc_write, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_sync, raw_test_cache_types_gen_params),

---
base-commit: 666539eecdf4db623f5e3c3e55cf9f2dfad24aa4
change-id: 20261117-regmap-kunit-val-bits-6473305e083b

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

