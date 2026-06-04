From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 04 Jun 2026 10:59:03 +0100
Subject: [PATCH v16 09/14] iio: test: iio-test-format: add test case for
 decimal format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-adf41513-iio-driver-v16-9-1a7d09143bc2@analog.com>
References: <20260604-adf41513-iio-driver-v16-0-1a7d09143bc2@analog.com>
In-Reply-To: <20260604-adf41513-iio-driver-v16-0-1a7d09143bc2@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, linux@analog.com
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Andrew Morton <akpm@linux-foundation.org>, Petr Mladek <pmladek@suse.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780567181; l=6896;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=hzJoGujhATtf6gCUbu5gJeZzi6x/rX3Pp1g7bNPBJLw=;
 b=NemKaW8JR1fhTzPFpZL4ThI7YbGu9NKFGANK1nfswwXZK9wXNnqk5L9CxESGHv3rSE9h//6PQ
 6YUoMZKf/F6AoLfgsvBev8jNeTuik6r79RmrF7lTDiqzikNRE1dyYQk
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add iio_test_iio_format_value_decimal_64() kunit test case for decimal
value formatting, exploring different scales types. Also, the same
iio_val_s64_decompose() helper used to populate local array is used in
iio_test_iio_format_value_integer_64().

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/test/iio-test-format.c | 97 +++++++++++++++++++++++++++++---------
 1 file changed, 75 insertions(+), 22 deletions(-)

diff --git a/drivers/iio/test/iio-test-format.c b/drivers/iio/test/iio-test-format.c
index 872dd8582003..e5d0a2ac4670 100644
--- a/drivers/iio/test/iio-test-format.c
+++ b/drivers/iio/test/iio-test-format.c
@@ -200,56 +200,108 @@ static void iio_test_iio_format_value_multiple(struct kunit *test)
 static void iio_test_iio_format_value_integer_64(struct kunit *test)
 {
 	int values[2];
-	s64 value;
 	char *buf;
 	int ret;
 
 	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
 
-	value = 24;
-	values[0] = lower_32_bits(value);
-	values[1] = upper_32_bits(value);
+	iio_val_s64_decompose(24, &values[0], &values[1]);
 	ret = iio_format_value(buf, IIO_VAL_INT_64, ARRAY_SIZE(values), values);
 	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "24\n");
 
-	value = -24;
-	values[0] = lower_32_bits(value);
-	values[1] = upper_32_bits(value);
+	iio_val_s64_decompose(-24, &values[0], &values[1]);
 	ret = iio_format_value(buf, IIO_VAL_INT_64, ARRAY_SIZE(values), values);
 	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "-24\n");
 
-	value = 0;
-	values[0] = lower_32_bits(value);
-	values[1] = upper_32_bits(value);
+	iio_val_s64_decompose(0, &values[0], &values[1]);
 	ret = iio_format_value(buf, IIO_VAL_INT_64, ARRAY_SIZE(values), values);
 	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "0\n");
 
-	value = UINT_MAX;
-	values[0] = lower_32_bits(value);
-	values[1] = upper_32_bits(value);
+	iio_val_s64_decompose(UINT_MAX, &values[0], &values[1]);
 	ret = iio_format_value(buf, IIO_VAL_INT_64, ARRAY_SIZE(values), values);
 	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "4294967295\n");
 
-	value = -((s64)UINT_MAX);
-	values[0] = lower_32_bits(value);
-	values[1] = upper_32_bits(value);
+	iio_val_s64_decompose(-((s64)UINT_MAX), &values[0], &values[1]);
 	ret = iio_format_value(buf, IIO_VAL_INT_64, ARRAY_SIZE(values), values);
 	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "-4294967295\n");
 
-	value = LLONG_MAX;
-	values[0] = lower_32_bits(value);
-	values[1] = upper_32_bits(value);
+	iio_val_s64_decompose(LLONG_MAX, &values[0], &values[1]);
 	ret = iio_format_value(buf, IIO_VAL_INT_64, ARRAY_SIZE(values), values);
 	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "9223372036854775807\n");
 
-	value = LLONG_MIN;
-	values[0] = lower_32_bits(value);
-	values[1] = upper_32_bits(value);
+	iio_val_s64_decompose(LLONG_MIN, &values[0], &values[1]);
 	ret = iio_format_value(buf, IIO_VAL_INT_64, ARRAY_SIZE(values), values);
 	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "-9223372036854775808\n");
 }
 
+static void iio_test_iio_format_value_decimal_64(struct kunit *test)
+{
+	int values[2];
+	char *buf;
+	int ret;
+
+	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+
+	/* DECIMAL64_MILLI: positive >= 1, value 1.234 */
+	iio_val_s64_decompose(1234, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_MILLI, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "1.234\n");
+
+	/* DECIMAL64_MICRO: positive >= 1, value 3.141592 */
+	iio_val_s64_decompose(3141592, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_MICRO, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "3.141592\n");
+
+	/* DECIMAL64_MILLI: positive < 1, value 0.042 */
+	iio_val_s64_decompose(42, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_MILLI, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "0.042\n");
+
+	/* DECIMAL64_MILLI: negative <= -1, value -1.234 */
+	iio_val_s64_decompose(-1234, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_MILLI, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "-1.234\n");
+
+	/* DECIMAL64_MILLI: negative > -1, value -0.123 */
+	iio_val_s64_decompose(-123, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_MILLI, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "-0.123\n");
+
+	/* DECIMAL64_MILLI: zero */
+	iio_val_s64_decompose(0, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_MILLI, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "0.000\n");
+
+	/* DECIMAL64_NANO: value 1.000000001 */
+	iio_val_s64_decompose(1000000001, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_NANO, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "1.000000001\n");
+
+	/* DECIMAL64_MICRO: large value using upper 32 bits */
+	iio_val_s64_decompose(5000000000000042LL, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_MICRO, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "5000000000.000042\n");
+
+	/* limits */
+	iio_val_s64_decompose(LLONG_MAX, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_PICO, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "9223372.036854775807\n");
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_NANO, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "9223372036.854775807\n");
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_MICRO, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "9223372036854.775807\n");
+
+	iio_val_s64_decompose(LLONG_MIN, &values[0], &values[1]);
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_PICO, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "-9223372.036854775808\n");
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_NANO, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "-9223372036.854775808\n");
+	ret = iio_format_value(buf, IIO_VAL_DECIMAL64_MICRO, ARRAY_SIZE(values), values);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "-9223372036854.775808\n");
+}
+
 static struct kunit_case iio_format_test_cases[] = {
 		KUNIT_CASE(iio_test_iio_format_value_integer),
 		KUNIT_CASE(iio_test_iio_format_value_fixedpoint),
@@ -257,6 +309,7 @@ static struct kunit_case iio_format_test_cases[] = {
 		KUNIT_CASE(iio_test_iio_format_value_fractional_log2),
 		KUNIT_CASE(iio_test_iio_format_value_multiple),
 		KUNIT_CASE(iio_test_iio_format_value_integer_64),
+		KUNIT_CASE(iio_test_iio_format_value_decimal_64),
 		{ }
 };
 

-- 
2.43.0

