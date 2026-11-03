From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Tue, 03 Nov 2026 21:17:08 +0000
Subject: [PATCH v3 2/2] iio: test: iio-test-format: add test case for char
 format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-iio-test-format-char-v3-2-d44074ecca70@gmail.com>
References: <20261103-iio-test-format-char-v3-0-d44074ecca70@gmail.com>
In-Reply-To: <20261103-iio-test-format-char-v3-0-d44074ecca70@gmail.com>
To: Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793740628; l=3409;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=j6hp8T4Cjj/hWoDuvMg1i82+SSxt038YUR09cQQDDKc=;
 b=WLm3iidZxvUdA1MiDT4VYRulYg8QP01l9ov1EBzX2cFq5dj2IhiYIGd4eBnAACcf5yyZ75Nqg
 Yw/Y38FIv04CfiZDJqCbXejkm5FWMH4w8TpQK81oAerZw2/rWLHH8OV
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IIO_VAL_CHAR is used by thermocouple drivers to report the
thermocouple type, but iio_format_value() has no test for it.

Add a test case covering printable, special and non-printable
characters, a NUL character, and values that do not fit in a char.

Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
 drivers/iio/test/iio-test-format.c | 67 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 67 insertions(+)

diff --git a/drivers/iio/test/iio-test-format.c b/drivers/iio/test/iio-test-format.c
index 90cd23f25fd9..781ead359bab 100644
--- a/drivers/iio/test/iio-test-format.c
+++ b/drivers/iio/test/iio-test-format.c
@@ -217,6 +217,72 @@ static void iio_test_iio_format_value_multiple(struct kunit *test)
 	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "1 -2 3 -4 5 \n");
 }
 
+static void iio_test_iio_format_value_char(struct kunit *test)
+{
+	char *buf;
+	int val;
+	int ret;
+
+	buf = iio_test_format_alloc_buf(test);
+
+	/* Printable characters, e.g. a thermocouple type */
+	val = 'K';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "K\n");
+
+	val = 'j';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "j\n");
+
+	val = '0';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "0\n");
+
+	/* Special characters are printed as is */
+	val = ' ';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "\x20\n");
+
+	val = '%';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "%\n");
+
+	val = '\\';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "\\\n");
+
+	/* Non-printable characters are printed as is */
+	val = '\n';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "\n\n");
+
+	val = '\t';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "\t\n");
+
+	val = 0x7f;
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "\x7f\n");
+
+	val = 0xff;
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "\xff\n");
+
+	/* A NUL character is emitted and counted like any other */
+	val = '\0';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "\0\n");
+
+	/* Only the low byte of the value is used */
+	val = 0x100 + 'K';
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "K\n");
+
+	val = -1;
+	ret = iio_format_value(buf, IIO_VAL_CHAR, 1, &val);
+	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "\xff\n");
+}
+
 static void iio_test_iio_format_value_integer_64(struct kunit *test)
 {
 	int values[2];
@@ -326,6 +392,7 @@ static struct kunit_case iio_format_test_cases[] = {
 		KUNIT_CASE(iio_test_iio_format_value_fractional),
 		KUNIT_CASE(iio_test_iio_format_value_fractional_log2),
 		KUNIT_CASE(iio_test_iio_format_value_multiple),
+		KUNIT_CASE(iio_test_iio_format_value_char),
 		KUNIT_CASE(iio_test_iio_format_value_integer_64),
 		KUNIT_CASE(iio_test_iio_format_value_decimal_64),
 		{ }

-- 
2.56.0

