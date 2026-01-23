From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 23 Jan 2026 15:53:08 +0000
Subject: [PATCH v5 3/8] iio: test: add kunit test for fixed-point parsing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260123-adf41513-iio-driver-v5-3-2dce812a2dda@analog.com>
References: <20260123-adf41513-iio-driver-v5-0-2dce812a2dda@analog.com>
In-Reply-To: <20260123-adf41513-iio-driver-v5-0-2dce812a2dda@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769183636; l=17198;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=rtEhREE7ZkzMoCTlvhh3uZ2ieeBAB9M5TfKzeYIHvfc=;
 b=5Zc7lNkErjs4H5lHUb4+AJo+SisUwHo3k3oWKZmql1I/tWH9+UxQV/Whb2S4IZNbTMtnMIbSs
 GcW5WYV42ezCkEStSLsoxEhvZDAmflqRrGj/2okykwO9uNb1uLw07Ss
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add kunit test cases that aims to verify expected behavior for
iio_str_to_fixpoint() and iio_str_to_fixpoint64().

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 MAINTAINERS                                |   1 +
 drivers/iio/test/Kconfig                   |  12 +
 drivers/iio/test/Makefile                  |   1 +
 drivers/iio/test/iio-test-fixpoint-parse.c | 437 +++++++++++++++++++++++++++++
 4 files changed, 451 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 095af34e234e..f6383f2724aa 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1624,6 +1624,7 @@ L:	linux-iio@vger.kernel.org
 S:	Supported
 W:	https://ez.analog.com/linux-software-drivers
 F:	Documentation/devicetree/bindings/iio/frequency/adi,adf41513.yaml
+F:	drivers/iio/test/iio-test-fixpoint-parse.c
 
 ANALOG DEVICES INC ADF4377 DRIVER
 M:	Antoniu Miclaus <antoniu.miclaus@analog.com>
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
index 000000000000..281e8c906523
--- /dev/null
+++ b/drivers/iio/test/iio-test-fixpoint-parse.c
@@ -0,0 +1,437 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* Unit tests for IIO fixpoint parsing functions
+ *
+ * Copyright (c) 2026
+ */
+
+#include <kunit/test.h>
+#include <linux/iio/iio.h>
+#include <linux/math.h>
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
+	ret = iio_str_to_fixpoint64("123.000", PRECISION(6), &integer, &fract);
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
+	/* Very small decimal */
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
+	ret = iio_str_to_fixpoint64("-2.71", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, -2);
+	KUNIT_EXPECT_EQ(test, fract, 710000);
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
+	ret = iio_str_to_fixpoint64("1.23456", 100, &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 1);
+	KUNIT_EXPECT_EQ(test, fract, 234);
+
+	/* Fewer digits than precision - should pad with zeros */
+	ret = iio_str_to_fixpoint64("1.23", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 1);
+	KUNIT_EXPECT_EQ(test, fract, 230000);
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
+	ret = iio_str_to_fixpoint64("42\n", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 42);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+
+	/* Decimal with newline */
+	ret = iio_str_to_fixpoint64("3.14\n", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 3);
+	KUNIT_EXPECT_EQ(test, fract, 140000);
+}
+
+/* Test iio_str_to_fixpoint64() with edge cases */
+static void iio_test_str_to_fixpoint64_edge_cases(struct kunit *test)
+{
+	s64 integer, fract;
+	int ret;
+
+	/* Leading decimal point */
+	ret = iio_str_to_fixpoint64(".5", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, 500000);
+
+	/* Leading decimal with sign */
+	ret = iio_str_to_fixpoint64("-.5", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, -500000);
+
+	ret = iio_str_to_fixpoint64("+.5", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 0);
+	KUNIT_EXPECT_EQ(test, fract, 500000);
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
+	KUNIT_EXPECT_NE(test, ret, 0);
+
+	/* Just a sign */
+	ret = iio_str_to_fixpoint64("-", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_NE(test, ret, 0);
+
+	ret = iio_str_to_fixpoint64("+", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_NE(test, ret, 0);
+
+	/* Trailing decimal without digits */
+	ret = iio_str_to_fixpoint64("42.", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Non-numeric characters */
+	ret = iio_str_to_fixpoint64("abc", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_NE(test, ret, 0);
+
+	ret = iio_str_to_fixpoint64("12a", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	ret = iio_str_to_fixpoint64("3.4x", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Multiple decimal points */
+	ret = iio_str_to_fixpoint64("12.34.56", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Trailing spaces */
+	ret = iio_str_to_fixpoint64("42 ", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Too many digits in integer part */
+	ret = iio_str_to_fixpoint64("123456789012345678901", PRECISION(6),
+				    &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+
+	/* Too many digits in fractional part */
+	ret = iio_str_to_fixpoint64("1.123456789012345678901", PRECISION(6),
+				    &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
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
+	ret = iio_str_to_fixpoint("5.5", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 5);
+	KUNIT_EXPECT_EQ(test, fract, 500000);
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
+	/* Test with 2 decimal places */
+	ret = iio_str_to_fixpoint("7.8", PRECISION(2), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, 7);
+	KUNIT_EXPECT_EQ(test, fract, 80);
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
+
+	ret = iio_str_to_fixpoint("-15", PRECISION(2), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer, -15);
+	KUNIT_EXPECT_EQ(test, fract, 0);
+}
+
+/* Test iio_str_to_fixpoint() with overflow cases */
+static void iio_test_str_to_fixpoint_overflow(struct kunit *test)
+{
+	int integer, fract;
+	int ret;
+
+	/* Integer overflow - value exceeds INT_MAX */
+	ret = iio_str_to_fixpoint("2147483648", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -ERANGE);
+
+	/* Integer underflow - value less than INT_MIN */
+	ret = iio_str_to_fixpoint("-2147483649", PRECISION(6), &integer,
+				  &fract);
+	KUNIT_EXPECT_EQ(test, ret, -ERANGE);
+
+	/* fractional overflow */
+	ret = iio_str_to_fixpoint("0.2147483648", PRECISION(10), &integer,
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
+	/* Trailing decimal */
+	ret = iio_str_to_fixpoint("42.", PRECISION(6), &integer, &fract);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
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
+	/* INT_MAX */
+	ret = iio_str_to_fixpoint("2147483647", PRECISION(6), &integer32,
+				  &fract32);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer32, INT_MAX);
+	KUNIT_EXPECT_EQ(test, fract32, 0);
+
+	/* INT_MIN */
+	ret = iio_str_to_fixpoint("-2147483648", PRECISION(6), &integer32,
+				  &fract32);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer32, INT_MIN);
+	KUNIT_EXPECT_EQ(test, fract32, 0);
+
+	/* INT_MIN with fractional part */
+	ret = iio_str_to_fixpoint("-2147483648.2147483647", PRECISION(10),
+				  &integer32, &fract32);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer32, INT_MIN);
+	KUNIT_EXPECT_EQ(test, fract32, INT_MAX);
+
+	/* LLONG_MAX */
+	ret = iio_str_to_fixpoint64("9223372036854775807", PRECISION(6),
+				    &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer64, LLONG_MAX);
+	KUNIT_EXPECT_EQ(test, fract64, 0);
+
+	/* LLONG_MIN */
+	ret = iio_str_to_fixpoint64("-9223372036854775808", PRECISION(6),
+				    &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer64, LLONG_MIN);
+	KUNIT_EXPECT_EQ(test, fract64, 0);
+
+	/* LLONG_MIN with fractional part */
+	ret = iio_str_to_fixpoint64("-9223372036854775808.9223372036854775807",
+				    PRECISION(19), &integer64, &fract64);
+	KUNIT_EXPECT_EQ(test, ret, 0);
+	KUNIT_EXPECT_EQ(test, integer64, LLONG_MIN);
+	KUNIT_EXPECT_EQ(test, fract64, LLONG_MAX);
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

