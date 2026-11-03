From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Tue, 03 Nov 2026 21:17:07 +0000
Subject: [PATCH v3 1/2] iio: test: iio-test-format: check that nothing is
 written past the string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-iio-test-format-char-v3-1-d44074ecca70@gmail.com>
References: <20261103-iio-test-format-char-v3-0-d44074ecca70@gmail.com>
In-Reply-To: <20261103-iio-test-format-char-v3-0-d44074ecca70@gmail.com>
To: Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793740628; l=4652;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=11qfsxnC6C/M3CIJ94SWhENFa+Zey9Wn6fupPxQmHYA=;
 b=yurxFVgmlRO3NPeO8zZ9K5jm5HlMJEdp/2GfBvQWwhhdDiajhGTuYNbx4qiCyfUYM7RI9rx5L
 5a/roi0fzdxCfuAdG9MqqryPuZHQHRosFIgQVncX4r/B+mQQFRR/WPI
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IIO_TEST_FORMAT_EXPECT_EQ() compares the buffer only up to the first NUL
character. It does not notice if iio_format_value() writes past the end
of the formatted string, and it cannot check output that contains a NUL.

Poison the buffer before each call. Check the expected bytes, including
the NUL terminator, with KUNIT_EXPECT_MEMEQ(), and check that the rest of
the page still holds the poison value. Take the expected length from the
string literal instead of calling strlen() on the buffer.

Suggested-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/iio/test/iio-test-format.c | 54 +++++++++++++++++++++++++-------------
 1 file changed, 36 insertions(+), 18 deletions(-)

diff --git a/drivers/iio/test/iio-test-format.c b/drivers/iio/test/iio-test-format.c
index e5d0a2ac4670..90cd23f25fd9 100644
--- a/drivers/iio/test/iio-test-format.c
+++ b/drivers/iio/test/iio-test-format.c
@@ -6,11 +6,36 @@
 
 #include <kunit/test.h>
 #include <linux/iio/iio.h>
+#include <linux/string.h>
 
-#define IIO_TEST_FORMAT_EXPECT_EQ(_test, _buf, _ret, _val) do { \
-		KUNIT_EXPECT_EQ(_test, strlen(_buf), _ret); \
-		KUNIT_EXPECT_STREQ(_test, (_buf), (_val)); \
-	} while (0)
+#define IIO_TEST_FORMAT_POISON	0x5a
+
+/*
+ * Check the formatted string including its NUL terminator, and that nothing
+ * beyond it was written. _val must be a string literal. The buffer is poisoned
+ * again afterwards for the next check.
+ */
+#define IIO_TEST_FORMAT_EXPECT_EQ(_test, _buf, _ret, _val)			  \
+do {										  \
+	size_t sz = sizeof(_val);						  \
+										  \
+	KUNIT_EXPECT_EQ(_test, _ret, (ssize_t)sz - 1);				  \
+	KUNIT_EXPECT_MEMEQ(_test, _buf, _val, sz);				  \
+	KUNIT_EXPECT_NULL(_test,						  \
+		memchr_inv((_buf) + sz, IIO_TEST_FORMAT_POISON, PAGE_SIZE - sz)); \
+	memset(_buf, IIO_TEST_FORMAT_POISON, PAGE_SIZE);			  \
+} while (0)
+
+static char *iio_test_format_alloc_buf(struct kunit *test)
+{
+	char *buf;
+
+	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	memset(buf, IIO_TEST_FORMAT_POISON, PAGE_SIZE);
+
+	return buf;
+}
 
 static void iio_test_iio_format_value_integer(struct kunit *test)
 {
@@ -18,8 +43,7 @@ static void iio_test_iio_format_value_integer(struct kunit *test)
 	int val;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	val = 42;
 	ret = iio_format_value(buf, IIO_VAL_INT, 1, &val);
@@ -48,8 +72,7 @@ static void iio_test_iio_format_value_fixedpoint(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	/* positive >= 1 */
 	values[0] = 1;
@@ -109,8 +132,7 @@ static void iio_test_iio_format_value_fractional(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	/* positive < 1 */
 	values[0] = 1;
@@ -149,8 +171,7 @@ static void iio_test_iio_format_value_fractional_log2(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	/* positive < 1 */
 	values[0] = 123;
@@ -189,8 +210,7 @@ static void iio_test_iio_format_value_multiple(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	ret = iio_format_value(buf, IIO_VAL_INT_MULTIPLE,
 			       ARRAY_SIZE(values), values);
@@ -203,8 +223,7 @@ static void iio_test_iio_format_value_integer_64(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	iio_val_s64_decompose(24, &values[0], &values[1]);
 	ret = iio_format_value(buf, IIO_VAL_INT_64, ARRAY_SIZE(values), values);
@@ -241,8 +260,7 @@ static void iio_test_iio_format_value_decimal_64(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	/* DECIMAL64_MILLI: positive >= 1, value 1.234 */
 	iio_val_s64_decompose(1234, &values[0], &values[1]);

-- 
2.56.0

