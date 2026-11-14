From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sat, 14 Nov 2026 14:09:57 +0000
Subject: [PATCH v6 5/7] iio: test: rescale: compare scales against the
 precision of the output
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-e-notation-v6-5-205ca9a1438a@analog.com>
References: <20261114-e-notation-v6-0-205ca9a1438a@analog.com>
In-Reply-To: <20261114-e-notation-v6-0-205ca9a1438a@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794665398; l=5689;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=MYurB/fu0EGmpzdutFErjw1ab4qsWqsloaJ03rKS+2A=;
 b=MJQvpM3blgIooooDJYURY226+G2pg+ZULwn8/WUZgkj+MYUQSoWQS22Ylou1yyaDPCXXLKon+
 LjmRfWUI5cIBIcfchq7CZvduknBr9Nq4QgW8t7WeKoWc/DplGnWR7ed
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The scale tests format the rescaled value with iio_format_value(), which
prints at most nano precision, and require the relative error to the
expected value to be below 1 ppm. Both strings are parsed back with
iio_str_to_fixpoint() at nano precision, so for the small scale cases the
check only passes because the expected value, like the formatted one, is
truncated to nano. For example, "0.000000033594" is parsed as 33 nano,
equal to the formatted "0.000000033", although the actual error is about
1.8%. If the expected value were rounded instead, it would be parsed as
34 nano and the test would fail even though the output is as accurate as
the format allows.

Parse both values with kstrtodec64() at a scale of 10, one digit more
than the output precision, so the expected value keeps the digits lost
when formatting. Scale 10 is the largest that still fits the overflow
cases (about 2.1e8) in an s64. Compute the relative error with
mul_u64_u64_div_u64(), as the product with 10^6 no longer fits in 64 bits
for those cases.

Then allow a relative error up to the relative size of one nano of the
expected value, the precision of the formatted output. This is 0 ppm for
values of 0.01 and above, so those cases are checked as before, and it
accepts the formatting error for the small scale cases.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/test/iio-test-rescale.c | 60 ++++++++++++++-----------------------
 1 file changed, 23 insertions(+), 37 deletions(-)

diff --git a/drivers/iio/test/iio-test-rescale.c b/drivers/iio/test/iio-test-rescale.c
index de4a09f432c0..e37a20ea1ca6 100644
--- a/drivers/iio/test/iio-test-rescale.c
+++ b/drivers/iio/test/iio-test-rescale.c
@@ -6,6 +6,8 @@
  */
 
 #include <linux/gcd.h>
+#include <linux/kstrtox.h>
+#include <linux/math64.h>
 #include <linux/overflow.h>
 
 #include <linux/iio/afe/rescale.h>
@@ -581,55 +583,37 @@ static void case_to_desc(const struct rescale_tc_data *t, char *desc)
 KUNIT_ARRAY_PARAM(iio_rescale_scale, scale_cases, case_to_desc);
 KUNIT_ARRAY_PARAM(iio_rescale_offset, offset_cases, case_to_desc);
 
-/**
- * iio_str_to_nano() - Parse a fixed-point string to get an
- *                      IIO_VAL_INT_PLUS_NANO value
- * @str: The string to parse
- * @nano: The number as an integer
- *
- * Returns 0 on success, or a negative error code if the string could not be
- * parsed.
+/*
+ * iio_format_value() prints scales with up to nano precision. Parse values
+ * with one more digit, so the expected values keep the precision lost there.
+ * Scale 10 is the largest that fits the overflow test cases in an s64.
  */
-static int iio_str_to_nano(const char *str, s64 *nano)
-{
-	int tmp, tmp2;
-	int ret = 0;
-
-	/*
-	 * iio_str_to_fixpoint() uses 10^8 here instead of 10^9 as fract_mult is
-	 * the multiplier for the first decimal place.
-	 */
-	ret = iio_str_to_fixpoint(str, 100000000, &tmp, &tmp2);
-	if (ret < 0)
-		return ret;
-
-	if (tmp < 0)
-		tmp2 *= -1;
-
-	*nano = (s64)tmp * 1000000000UL + tmp2;
-
-	return ret;
-}
+#define IIO_TEST_EXTRA_DEC_SCALE	1
+#define IIO_TEST_DEC_SCALE		(9 + IIO_TEST_EXTRA_DEC_SCALE)
+#define IIO_TEST_NANO_PER_DEC_SCALE	int_pow(10, IIO_TEST_EXTRA_DEC_SCALE)
 
 /**
  * iio_test_relative_error_ppm() - Compute relative error (in parts-per-million)
  *                                 between two fixed-point strings
  * @real_str: The real value as a string
  * @exp_str: The expected value as a string
+ * @max_ppm: The relative size (in parts-per-million) of one nano of the
+ *           expected value, the precision of iio_format_value()
  *
  * Returns a negative error code if the strings could not be parsed, or the
  * relative error in parts-per-million.
  */
-static int iio_test_relative_error_ppm(const char *real_str, const char *exp_str)
+static int iio_test_relative_error_ppm(const char *real_str, const char *exp_str,
+				       int *max_ppm)
 {
-	s64 real, exp, err;
+	s64 real, exp;
 	int ret;
 
-	ret = iio_str_to_nano(real_str, &real);
+	ret = kstrtodec64(real_str, IIO_TEST_DEC_SCALE, &real);
 	if (ret < 0)
 		return ret;
 
-	ret = iio_str_to_nano(exp_str, &exp);
+	ret = kstrtodec64(exp_str, IIO_TEST_DEC_SCALE, &exp);
 	if (ret < 0)
 		return ret;
 
@@ -638,9 +622,9 @@ static int iio_test_relative_error_ppm(const char *real_str, const char *exp_str
 		return -EINVAL;
 	}
 
-	err = 1000000UL * abs(exp - real);
+	*max_ppm = (int)div64_u64(IIO_TEST_NANO_PER_DEC_SCALE * 1000000ULL, abs(exp));
 
-	return (int)div64_u64(err, abs(exp));
+	return (int)mul_u64_u64_div_u64(abs(exp - real), 1000000, abs(exp));
 }
 
 static void iio_rescale_test_scale(struct kunit *test)
@@ -650,6 +634,7 @@ static void iio_rescale_test_scale(struct kunit *test)
 	struct rescale rescale;
 	int values[2];
 	int rel_ppm;
+	int max_ppm;
 	int ret;
 
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buff);
@@ -666,10 +651,11 @@ static void iio_rescale_test_scale(struct kunit *test)
 	ret = iio_format_value(buff, ret, 2, values);
 	KUNIT_EXPECT_EQ(test, (int)strlen(buff), ret);
 
-	rel_ppm = iio_test_relative_error_ppm(buff, t->expected);
-	KUNIT_EXPECT_GE_MSG(test, rel_ppm, 0, "failed to compute ppm\n");
+	rel_ppm = iio_test_relative_error_ppm(buff, t->expected, &max_ppm);
+	KUNIT_ASSERT_GE_MSG(test, rel_ppm, 0, "failed to compute ppm\n");
 
-	KUNIT_EXPECT_EQ_MSG(test, rel_ppm, 0,
+	/* allow the error of the nano precision used to format the value */
+	KUNIT_EXPECT_LE_MSG(test, rel_ppm, max_ppm,
 			    "\t    real=%s"
 			    "\texpected=%s\n",
 			    buff, t->expected);

-- 
2.43.0

