From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Mon, 02 Nov 2026 08:33:55 +0000
Subject: [PATCH v2 1/2] iio: test: iio-test-format: check that nothing is
 written past the string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-iio-test-format-char-v2-1-926100689e62@gmail.com>
References: <20261102-iio-test-format-char-v2-0-926100689e62@gmail.com>
In-Reply-To: <20261102-iio-test-format-char-v2-0-926100689e62@gmail.com>
To: Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793608466; l=4542;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=mjGIohs+VaxRspg/JVuGZhyysVoHzY7PwFWoazBDiao=;
 b=DrTAHWoJIjQ+wh1ssogPCRVkdw1Bbyuy081yyAvJWDELLz95kHWclXNAGif7zElEYfZxW+KtC
 TjqyUyOLGLOBiWgzyfpkce/FNXwOB13qegAR50hoa991LyOS8AMwzCI
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
 drivers/iio/test/iio-test-format.c | 50 +++++++++++++++++++++++++-------------
 1 file changed, 33 insertions(+), 17 deletions(-)

diff --git a/drivers/iio/test/iio-test-format.c b/drivers/iio/test/iio-test-format.c
index e5d0a2ac4670..35b30420d995 100644
--- a/drivers/iio/test/iio-test-format.c
+++ b/drivers/iio/test/iio-test-format.c
@@ -6,20 +6,42 @@
 
 #include <kunit/test.h>
 #include <linux/iio/iio.h>
+#include <linux/string.h>
 
-#define IIO_TEST_FORMAT_EXPECT_EQ(_test, _buf, _ret, _val) do { \
-		KUNIT_EXPECT_EQ(_test, strlen(_buf), _ret); \
-		KUNIT_EXPECT_STREQ(_test, (_buf), (_val)); \
+#define IIO_TEST_FORMAT_POISON	0x5a
+
+/*
+ * Check the formatted string including its NUL terminator, and that nothing
+ * beyond it was written. _val must be a string literal. The buffer is poisoned
+ * again afterwards for the next check.
+ */
+#define IIO_TEST_FORMAT_EXPECT_EQ(_test, _buf, _ret, _val) do {		\
+		KUNIT_EXPECT_EQ(_test, _ret, (ssize_t)sizeof(_val) - 1);	\
+		KUNIT_EXPECT_MEMEQ(_test, _buf, _val, sizeof(_val));		\
+		KUNIT_EXPECT_NULL(_test, memchr_inv((_buf) + sizeof(_val),	\
+						    IIO_TEST_FORMAT_POISON,	\
+						    PAGE_SIZE - sizeof(_val)));	\
+		memset(_buf, IIO_TEST_FORMAT_POISON, PAGE_SIZE);		\
 	} while (0)
 
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
+
 static void iio_test_iio_format_value_integer(struct kunit *test)
 {
 	char *buf;
 	int val;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	val = 42;
 	ret = iio_format_value(buf, IIO_VAL_INT, 1, &val);
@@ -48,8 +70,7 @@ static void iio_test_iio_format_value_fixedpoint(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	/* positive >= 1 */
 	values[0] = 1;
@@ -109,8 +130,7 @@ static void iio_test_iio_format_value_fractional(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	/* positive < 1 */
 	values[0] = 1;
@@ -149,8 +169,7 @@ static void iio_test_iio_format_value_fractional_log2(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	/* positive < 1 */
 	values[0] = 123;
@@ -189,8 +208,7 @@ static void iio_test_iio_format_value_multiple(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	ret = iio_format_value(buf, IIO_VAL_INT_MULTIPLE,
 			       ARRAY_SIZE(values), values);
@@ -203,8 +221,7 @@ static void iio_test_iio_format_value_integer_64(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	iio_val_s64_decompose(24, &values[0], &values[1]);
 	ret = iio_format_value(buf, IIO_VAL_INT_64, ARRAY_SIZE(values), values);
@@ -241,8 +258,7 @@ static void iio_test_iio_format_value_decimal_64(struct kunit *test)
 	char *buf;
 	int ret;
 
-	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
-	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	buf = iio_test_format_alloc_buf(test);
 
 	/* DECIMAL64_MILLI: positive >= 1, value 1.234 */
 	iio_val_s64_decompose(1234, &values[0], &values[1]);

-- 
2.56.0

