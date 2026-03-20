From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 20 Mar 2026 16:27:29 +0000
Subject: [PATCH v9 4/9] iio: test: add kunit test for fixed-point parsing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-adf41513-iio-driver-v9-4-132f0d076374@analog.com>
References: <20260320-adf41513-iio-driver-v9-0-132f0d076374@analog.com>
In-Reply-To: <20260320-adf41513-iio-driver-v9-0-132f0d076374@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
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
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Andy Shevchenko <andriy.shevchenko@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774024051; l=18700;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=aKsekr6aADN0JdXC+aRNm76ghLJgEvDTC4O1L0cOpOQ=;
 b=u7DZsDCOiQ1W1o+hptm/z8CNw0Wki87zAfWgfQLyJlWNDnEsu4TEdNQ0PEAEN6IbqRyoC7Ops
 0sGWr4GXwbGCa2McMgmO5IGrDe0knUBkXsj1q9tmhn+DOnzMwD8gsUn
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add kunit test cases that aims to verify expected behavior for
iio_str_to_fixpoint() and iio_str_to_fixpoint64().
To run the test, create a .kunitconfig file with:

CONFIG_KUNIT=y
CONFIG_IIO=y
CONFIG_IIO_FIXPOINT_PARSE_KUNIT_TEST=y

and run the command:
./tools/testing/kunit/kunit.py run --kunitconfig=.kunitconfig

Reviewed-by: Andy Shevchenko <andriy.shevchenko@intel.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 MAINTAINERS                                |   6 +
 drivers/iio/test/Kconfig                   |  12 +
 drivers/iio/test/Makefile                  |   1 +
 drivers/iio/test/iio-test-fixpoint-parse.c | 470 +++++++++++++++++++++++++++++
 4 files changed, 489 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index e3568f08ea55..3acfee7a66cd 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -12455,6 +12455,12 @@ F:	include/dt-bindings/iio/
 F:	include/linux/iio/
 F:	tools/iio/
 
+IIO FIXED POINT PARSE TEST
+M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Maintained
+F:	drivers/iio/test/iio-test-fixpoint-parse.c
+
 IIO UNIT CONVERTER
 M:	Peter Rosin <peda@axentia.se>
 L:	linux-iio@vger.kernel.org
diff --git a/drivers/iio/test/Kconfig b/drivers/iio/test/Kconfig
index 4fc17dd0dcd7..c60dff504bc2 100644
--- a/drivers/iio/test/Kconfig
+++ b/drivers/iio/test/Kconfig
@@ -29,6 +29,18 @@ config IIO_RESCALE_KUNIT_TEST
 
 	  If unsure, say N.
 
+config IIO_FIXPOINT_PARSE_KUNIT_TEST
+	tristate "Test IIO fixpoint parsing functions" if !KUNIT_ALL_TESTS
+	depends on KUNIT
+	default KUNIT_ALL_TESTS
+	help
+	  build unit tests for the IIO fixpoint parsing functions.
+
+	  For more information on KUnit and unit tests in general, please refer
+	  to the KUnit documentation in Documentation/dev-tools/kunit/.
+
+	  If unsure, say N.
+
 config IIO_FORMAT_KUNIT_TEST
 	tristate "Test IIO formatting functions" if !KUNIT_ALL_TESTS
 	depends on KUNIT
diff --git a/drivers/iio/test/Makefile b/drivers/iio/test/Makefile
index 0c846bc21acd..0c31aaeed755 100644
--- a/drivers/iio/test/Makefile
+++ b/drivers/iio/test/Makefile
@@ -5,6 +5,7 @@
 
 # Keep in alphabetical order
 obj-$(CONFIG_IIO_RESCALE_KUNIT_TEST) += iio-test-rescale.o
+obj-$(CONFIG_IIO_FIXPOINT_PARSE_KUNIT_TEST) += iio-test-fixpoint-parse.o
 obj-$(CONFIG_IIO_FORMAT_KUNIT_TEST) += iio-test-format.o
 obj-$(CONFIG_IIO_GTS_KUNIT_TEST) += iio-test-gts.o
 obj-$(CONFIG_IIO_MULTIPLY_KUNIT_TEST) += iio-test-multiply.o
diff --git a/drivers/iio/test/iio-test-fixpoint-parse.c b/drivers/iio/test/iio-test-fixpoint-parse.c
new file mode 100644
index 000000000000..69715d22d7ec
--- /dev/null
+++ b/drivers/iio/test/iio-test-fixpoint-parse.c
@@ -0,0 +1,470 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* Unit tests for IIO fixpoint parsing functions
+ *
+ * Copyright 2026 Analog Devices Inc.
+ */
+
+#include <kunit/test.h>
+#include <linux/errno.h>
+#include <linux/iio/iio.h>
+#include <linux/limits.h>
+#include <linux/math.h>
+#include <linux/types.h>
+
+#define PRECISION(x)	(int_pow(10, (x) - 1))
+
+/* Test iio_str_to_fixpoint64() with valid positive integers */
+static void iio_test_str_to_fixpoint64_positive_integers(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* Simple positive integer */
+	ret = iio_str_to_fixpoint64("42", 0, &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 42);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+
+	/* Positive integer with leading + */
+	ret = iio_str_to_fixpoint64("+10", 0, &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 10);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+
+	/* Large positive integer */
+	ret = iio_str_to_fixpoint64("123456789", 0, &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 123456789);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+}
+
+/* Test iio_str_to_fixpoint64() with valid negative integers */
+static void iio_test_str_to_fixpoint64_negative_integers(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* Simple negative integer */
+	ret = iio_str_to_fixpoint64("-23", 0, &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, -23);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+
+	/* Large negative integer */
+	ret = iio_str_to_fixpoint64("-987654321", 0, &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, -987654321);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+}
+
+/* Test iio_str_to_fixpoint64() with zero */
+static void iio_test_str_to_fixpoint64_zero(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* Zero */
+	ret = iio_str_to_fixpoint64("0", 0, &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+
+	/* Zero with decimal */
+	ret = iio_str_to_fixpoint64("0.0", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+
+	/* leading zeros */
+	ret = iio_str_to_fixpoint64("00000000000000000000042", 0, &integer,
+				    &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 42);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+}
+
+/* Test iio_str_to_fixpoint64() with valid decimal numbers */
+static void iio_test_str_to_fixpoint64_positive_decimals(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* Positive decimal */
+	ret = iio_str_to_fixpoint64("3.14", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 3);
+	KUNIT_EXPECT_EQ(test, fract, 140000);
+
+	/* Decimal less than 1 */
+	ret = iio_str_to_fixpoint64("0.5", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, 500000);
+
+	/* Decimal with trailing zeros */
+	ret = iio_str_to_fixpoint64("+123.000", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 123);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+
+	/* High precision decimal */
+	ret = iio_str_to_fixpoint64("1.123456789", PRECISION(9), &integer,
+				    &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 1);
+	KUNIT_EXPECT_EQ(test, fract, 123456789);
+
+	/* Small decimal */
+	ret = iio_str_to_fixpoint64("0.000000001", PRECISION(9), &integer,
+				    &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, 1);
+}
+
+/* Test iio_str_to_fixpoint64() with negative decimals */
+static void iio_test_str_to_fixpoint64_negative_decimals(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* Negative decimal */
+	ret = iio_str_to_fixpoint64("-2.71", PRECISION(5), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, -2);
+	KUNIT_EXPECT_EQ(test, fract, 71000);
+
+	/* Negative decimal less than -1 */
+	ret = iio_str_to_fixpoint64("-0.5", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, -500000);
+
+	/* Negative with high precision */
+	ret = iio_str_to_fixpoint64("-0.000000001", PRECISION(9), &integer,
+				    &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, -1);
+}
+
+/* Test iio_str_to_fixpoint64() with precision edge cases */
+static void iio_test_str_to_fixpoint64_precision_edge_cases(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* More digits than precision - should truncate */
+	ret = iio_str_to_fixpoint64("1.23456", PRECISION(3), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 1);
+	KUNIT_EXPECT_EQ(test, fract, 234);
+
+	/* Fewer digits than precision - should pad with zeros */
+	ret = iio_str_to_fixpoint64("1.23", PRECISION(7), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 1);
+	KUNIT_EXPECT_EQ(test, fract, 2300000);
+
+	/* Single digit fractional with high precision */
+	ret = iio_str_to_fixpoint64("5.1", PRECISION(9), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 5);
+	KUNIT_EXPECT_EQ(test, fract, 100000000);
+}
+
+/* Test iio_str_to_fixpoint64() with newline characters */
+static void iio_test_str_to_fixpoint64_with_newline(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* Integer with newline */
+	ret = iio_str_to_fixpoint64("-42\n", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, -42);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+
+	/* Decimal with newline */
+	ret = iio_str_to_fixpoint64("3.141\n", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 3);
+	KUNIT_EXPECT_EQ(test, fract, 141000);
+}
+
+/* Test iio_str_to_fixpoint64() with edge cases */
+static void iio_test_str_to_fixpoint64_edge_cases(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* Leading decimal point */
+	ret = iio_str_to_fixpoint64(".5", PRECISION(4), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, 5000);
+
+	/* Leading decimal with sign */
+	ret = iio_str_to_fixpoint64("-.5", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, -500000);
+
+	ret = iio_str_to_fixpoint64("+.5", PRECISION(3), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, 500);
+}
+
+/* Test iio_str_to_fixpoint64() with invalid inputs */
+static void iio_test_str_to_fixpoint64_invalid(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* Empty string */
+	ret = iio_str_to_fixpoint64("", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Just a sign */
+	ret = iio_str_to_fixpoint64("-", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	ret = iio_str_to_fixpoint64("+", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Just a decimal point */
+	ret = iio_str_to_fixpoint64(".", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Non-numeric characters */
+	ret = iio_str_to_fixpoint64("abc", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	ret = iio_str_to_fixpoint64("12a", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	ret = iio_str_to_fixpoint64("3.4x", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	ret = iio_str_to_fixpoint64("0xff", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Multiple decimal points */
+	ret = iio_str_to_fixpoint64("12.34.56", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Trailing decimal without digits */
+	ret = iio_str_to_fixpoint64("42.", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Trailing spaces */
+	ret = iio_str_to_fixpoint64("42 ", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Too many digits in fractional part */
+	ret = iio_str_to_fixpoint64("1.123456789012345678901", PRECISION(21),
+				    &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL); /* fails when checking precision */
+}
+
+/* Test iio_str_to_fixpoint() with valid inputs */
+static void iio_test_str_to_fixpoint_valid(struct kunit *test)
+{
+	int integer, fract;
+	int ret;
+
+	/* Test with 6 decimal places */
+	ret = iio_str_to_fixpoint("10.001234", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 10);
+	KUNIT_EXPECT_EQ(test, fract, 1234);
+
+	ret = iio_str_to_fixpoint("-0.5", PRECISION(3), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, -500);
+
+	/* Test with 9 decimal places */
+	ret = iio_str_to_fixpoint("5.123456789", PRECISION(9), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 5);
+	KUNIT_EXPECT_EQ(test, fract, 123456789);
+
+	ret = iio_str_to_fixpoint("1.0", PRECISION(9), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 1);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+
+	/* Test with 3 decimal places */
+	ret = iio_str_to_fixpoint("-7.8", PRECISION(3), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, -7);
+	KUNIT_EXPECT_EQ(test, fract, 800);
+
+	/* Truncation with 2 decimal places */
+	ret = iio_str_to_fixpoint("3.1415", PRECISION(2), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 3);
+	KUNIT_EXPECT_EQ(test, fract, 14);
+
+	/* Integer with 6 decimal places */
+	ret = iio_str_to_fixpoint("42", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 42);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+}
+
+/* Test both functions with overflow cases */
+static void iio_test_str_to_fixpoint_overflow(struct kunit *test)
+{
+	s64 integer64, fract64;
+	int integer, fract;
+	int ret;
+
+	/* integer overflow - value exceeds U64_MAX */
+	ret = iio_str_to_fixpoint64("18446744073709551616", PRECISION(6),
+				    &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, -ERANGE);
+
+	/* integer underflow - value less than S64_MIN */
+	ret = iio_str_to_fixpoint64("-9223372036854775809", PRECISION(6),
+				    &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, -ERANGE);
+
+	/* fractional underflow */
+	ret = iio_str_to_fixpoint64("-0.9223372036854775810", PRECISION(19),
+				    &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, -ERANGE);
+
+	/* Integer overflow - value exceeds U32_MAX */
+	ret = iio_str_to_fixpoint("4294967296", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -ERANGE);
+
+	/* Integer underflow - value less than INT_MIN */
+	ret = iio_str_to_fixpoint("-2147483649", PRECISION(6), &integer,
+				  &fract);
+	KUNIT_EXPECT_EQ(test, ret, -ERANGE);
+
+	/* fractional overflow */
+	ret = iio_str_to_fixpoint("0.4294967296", PRECISION(10), &integer,
+				  &fract);
+	KUNIT_EXPECT_EQ(test, ret, -ERANGE);
+
+	/* fractional underflow */
+	ret = iio_str_to_fixpoint("-0.2147483649", PRECISION(10), &integer,
+				  &fract);
+	KUNIT_EXPECT_EQ(test, ret, -ERANGE);
+}
+
+/* Test iio_str_to_fixpoint() with invalid inputs */
+static void iio_test_str_to_fixpoint_invalid(struct kunit *test)
+{
+	int integer, fract;
+	int ret;
+
+	/* Empty string */
+	ret = iio_str_to_fixpoint("", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_NE(test, ret, 0);
+
+	/* Non-numeric */
+	ret = iio_str_to_fixpoint("abc", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_NE(test, ret, 0);
+
+	/* Invalid characters */
+	ret = iio_str_to_fixpoint("12.34x", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+}
+
+/* Test both functions with boundary values */
+static void iio_test_fixpoint_boundary_values(struct kunit *test)
+{
+	s64 integer64, fract64;
+	int integer32, fract32;
+	int ret;
+
+	/* S32_MAX */
+	ret = iio_str_to_fixpoint("2147483647", PRECISION(6), &integer32,
+				  &fract32);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer32, S32_MAX);
+	KUNIT_EXPECT_EQ(test, fract32, 0);
+
+	/* U32_MAX */
+	ret = iio_str_to_fixpoint("4294967295", PRECISION(6), &integer32,
+				  &fract32);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, (u32)integer32, U32_MAX);
+	KUNIT_EXPECT_EQ(test, fract32, 0);
+
+	/* S32_MIN */
+	ret = iio_str_to_fixpoint("-2147483648", PRECISION(6), &integer32,
+				  &fract32);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer32, S32_MIN);
+	KUNIT_EXPECT_EQ(test, fract32, 0);
+
+	/* S32_MIN with fractional part */
+	ret = iio_str_to_fixpoint("-2147483648.2147483647", PRECISION(10),
+				  &integer32, &fract32);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer32, S32_MIN);
+	KUNIT_EXPECT_EQ(test, fract32, S32_MAX);
+
+	/* S64_MAX */
+	ret = iio_str_to_fixpoint64("9223372036854775807", PRECISION(6),
+				    &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer64, S64_MAX);
+	KUNIT_EXPECT_EQ(test, fract64, 0);
+
+	/* U64_MAX */
+	ret = iio_str_to_fixpoint64("18446744073709551615", PRECISION(6),
+				    &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, (u64)integer64, U64_MAX);
+	KUNIT_EXPECT_EQ(test, fract64, 0);
+
+	/* S64_MIN */
+	ret = iio_str_to_fixpoint64("-9223372036854775808", PRECISION(6),
+				    &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer64, S64_MIN);
+	KUNIT_EXPECT_EQ(test, fract64, 0);
+
+	/* S64_MIN with fractional part */
+	ret = iio_str_to_fixpoint64("-9223372036854775808.9223372036854775807",
+				    PRECISION(19), &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer64, S64_MIN);
+	KUNIT_EXPECT_EQ(test, fract64, S64_MAX);
+}
+
+static struct kunit_case iio_fixpoint_parse_test_cases[] = {
+	KUNIT_CASE(iio_test_str_to_fixpoint64_positive_integers),
+	KUNIT_CASE(iio_test_str_to_fixpoint64_negative_integers),
+	KUNIT_CASE(iio_test_str_to_fixpoint64_zero),
+	KUNIT_CASE(iio_test_str_to_fixpoint64_positive_decimals),
+	KUNIT_CASE(iio_test_str_to_fixpoint64_negative_decimals),
+	KUNIT_CASE(iio_test_str_to_fixpoint64_precision_edge_cases),
+	KUNIT_CASE(iio_test_str_to_fixpoint64_with_newline),
+	KUNIT_CASE(iio_test_str_to_fixpoint64_edge_cases),
+	KUNIT_CASE(iio_test_str_to_fixpoint64_invalid),
+	KUNIT_CASE(iio_test_str_to_fixpoint_valid),
+	KUNIT_CASE(iio_test_str_to_fixpoint_overflow),
+	KUNIT_CASE(iio_test_str_to_fixpoint_invalid),
+	KUNIT_CASE(iio_test_fixpoint_boundary_values),
+	{ }
+};
+
+static struct kunit_suite iio_fixpoint_parse_test_suite = {
+	.name = "iio-fixpoint-parse",
+	.test_cases = iio_fixpoint_parse_test_cases,
+};
+
+kunit_test_suite(iio_fixpoint_parse_test_suite);
+
+MODULE_AUTHOR("Rodrigo Alencar <rodrigo.alencar@analog.com>");
+MODULE_AUTHOR("IIO Kunit Test");
+MODULE_DESCRIPTION("Test IIO fixpoint parsing functions");
+MODULE_LICENSE("GPL");

-- 
2.43.0

