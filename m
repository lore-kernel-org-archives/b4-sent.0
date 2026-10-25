From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Date: Sun, 25 Oct 2026 16:59:41 +0000
Subject: [PATCH] iio: test: iio-test-format: add test case for char format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-iio-test-format-char-v1-1-e2c208f90e87@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrB1IAq3aq4iLqBMdQSMzaSmId
 zetyw/e+w9QEiaFV3GA0IeV45ZhywKG2W8TIY/Z4Ix7WuMeyBwxkSYMUVafMK8Ea2+r0IfGO2M
 hX3ehwN9/tu1u67tfaEi/FpznBdGu6/R4AAAA
X-Change-ID: 20261025-iio-test-format-char-8a17fbf9a201
To: Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792947624; l=2121;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=uYIGztgLiYRny/7kylD4MRCRKqn6ok2BmKnYkqfKVcI=;
 b=xBDuRUL+yDkde1Lwh9CMrp33F0cJH9ggpOK2GKUdDyWWatBvnmFIWACQ3CzvcSdm/a8Rao18T
 DiA2jJLpvZ0ByTE3W8YmcmNq4CskLZRb6u7LVZ3J6OlAbTJ0qu0kVwm
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IIO_VAL_CHAR is used by thermocouple drivers to report the
thermocouple type, but iio_format_value() has no test for it.

Add a test case that checks a single character is printed followed
by a newline.

Assisted-by: LLM
Signed-off-by: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
---
Tested with KUnit on arm64 QEMU: all 8 iio-format cases pass.
---
 drivers/iio/test/iio-test-format.c | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/drivers/iio/test/iio-test-format.c b/drivers/iio/test/iio-test-format.c
index e5d0a2ac4670..701c362695f3 100644
--- a/drivers/iio/test/iio-test-format.c
+++ b/drivers/iio/test/iio-test-format.c
@@ -197,6 +197,28 @@ static void iio_test_iio_format_value_multiple(struct kunit *test)
 	IIO_TEST_FORMAT_EXPECT_EQ(test, buf, ret, "1 -2 3 -4 5 \n");
 }
 
+static void iio_test_iio_format_value_char(struct kunit *test)
+{
+	char *buf;
+	int val;
+	int ret;
+
+	buf = kunit_kmalloc(test, PAGE_SIZE, GFP_KERNEL);
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+
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
+}
+
 static void iio_test_iio_format_value_integer_64(struct kunit *test)
 {
 	int values[2];
@@ -308,6 +330,7 @@ static struct kunit_case iio_format_test_cases[] = {
 		KUNIT_CASE(iio_test_iio_format_value_fractional),
 		KUNIT_CASE(iio_test_iio_format_value_fractional_log2),
 		KUNIT_CASE(iio_test_iio_format_value_multiple),
+		KUNIT_CASE(iio_test_iio_format_value_char),
 		KUNIT_CASE(iio_test_iio_format_value_integer_64),
 		KUNIT_CASE(iio_test_iio_format_value_decimal_64),
 		{ }

---
base-commit: c9dbe2a47f635465c9985b7af74d2ae310e98125
change-id: 20261025-iio-test-format-char-8a17fbf9a201

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

