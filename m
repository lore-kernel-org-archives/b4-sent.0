From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Wed, 25 Nov 2026 08:09:32 +0000
Subject: [PATCH v2 3/3] regmap: kunit: add tests for values wider than
 val_bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-regmap-kunit-val-bits-v2-3-81db3b79cd3f@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795594173; l=3961;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=O/bSq8ATRnJpAzSNzffwCRkaLe7Q98YDcHwxyFy4JF4=;
 b=/DGtjIuBeVus/HvctOSVZo7v3yNnwtSu8S2bLD2z51pi9Aq59jfoUKZXMhVKmbx1eJSpVIjji
 /ED7tGdJQv7BFN6cmpr9Y1GEh6acoxal5dRyO9Uff+8/WI+TB0aUPYc
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two test cases writing 0xffffff0f with regmap_write() to a regmap
with val_bits = 16, and check that only the low 16 bits reach the bus
and can be read back:

- write_wider_than_val_bits uses the RAM regmap, a bus that only
  provides reg_write()/reg_read();
- raw_write_wider_than_val_bits uses the raw RAM regmap, which goes
  through the value formatters.

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/base/regmap/regmap-kunit.c | 60 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 60 insertions(+)

diff --git a/drivers/base/regmap/regmap-kunit.c b/drivers/base/regmap/regmap-kunit.c
index c948219f46a3..b8b14995a548 100644
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
@@ -2004,6 +2031,37 @@ static void raw_write_read_single(struct kunit *test)
 	KUNIT_EXPECT_EQ(test, val, rval);
 }
 
+static void raw_write_wider_than_val_bits(struct kunit *test)
+{
+	struct regmap *map;
+	struct regmap_config config;
+	struct regmap_ram_data *data;
+	void *hw_val;
+	unsigned int rval;
+
+	config = raw_regmap_config;
+
+	map = gen_raw_regmap(test, &config, &data);
+	KUNIT_ASSERT_FALSE(test, IS_ERR(map));
+	if (IS_ERR(map))
+		return;
+
+	hw_val = data->vals;
+
+	/* Write a value with bits set above val_bits */
+	KUNIT_EXPECT_EQ(test, 0, regmap_write(map, 0, 0xffffff0f));
+
+	/* The "hardware" should only have seen the low val_bits bits */
+	if (config.val_format_endian == REGMAP_ENDIAN_BIG)
+		KUNIT_EXPECT_EQ(test, 0xff0f, be16_to_cpup(hw_val));
+	else
+		KUNIT_EXPECT_EQ(test, 0xff0f, le16_to_cpup(hw_val));
+
+	/* And that is what we should read back */
+	KUNIT_EXPECT_EQ(test, 0, regmap_read(map, 0, &rval));
+	KUNIT_EXPECT_EQ(test, 0xff0f, rval);
+}
+
 static void raw_write(struct kunit *test)
 {
 	struct regmap *map;
@@ -2249,6 +2307,7 @@ static void raw_ranges(struct kunit *test)
 
 static struct kunit_case regmap_test_cases[] = {
 	KUNIT_CASE_PARAM(basic_read_write, regcache_types_gen_params),
+	KUNIT_CASE_PARAM(write_wider_than_val_bits, regcache_types_gen_params),
 	KUNIT_CASE_PARAM(read_bypassed, real_cache_types_gen_params),
 	KUNIT_CASE_PARAM(read_bypassed_volatile, real_cache_types_gen_params),
 	KUNIT_CASE_PARAM(bulk_write, regcache_types_gen_params),
@@ -2286,6 +2345,7 @@ static struct kunit_case regmap_test_cases[] = {
 	KUNIT_CASE_PARAM(raw_read_defaults_single, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_read_defaults, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_write_read_single, raw_test_types_gen_params),
+	KUNIT_CASE_PARAM(raw_write_wider_than_val_bits, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_write, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_noinc_write, raw_test_types_gen_params),
 	KUNIT_CASE_PARAM(raw_sync, raw_test_cache_types_gen_params),

-- 
2.56.0

