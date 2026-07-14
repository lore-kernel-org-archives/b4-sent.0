From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 14 Jul 2026 12:02:47 +0100
Subject: [PATCH v8 07/17] iio: test: add kunit tests for channel prefix
 naming generation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260714-ad9910-iio-driver-v8-7-36939c3c07d2@analog.com>
References: <20260714-ad9910-iio-driver-v8-0-36939c3c07d2@analog.com>
In-Reply-To: <20260714-ad9910-iio-driver-v8-0-36939c3c07d2@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-hardening@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784026971; l=11782;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=cLsar4g6ywEsFfBe5Wt3Znzrh2jrG/2Jj2nW3Bwx/Rs=;
 b=pPGs4QuH28V1qiWC1C9rvBJyWe9S1IEDDX1ybZjrov+7GGsfEReEOZhoY6vNgo6MRYp7NHeN3
 SiqHXjl2YIsA+JoAbcLL11z6xYXCVed11d3I7YLj9yZcWr/DBfngE0Q
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a KUnit test suite covering __iio_chan_prefix_emit(), the helper
that builds IIO sysfs attribute name prefixes from an iio_chan_spec.
The suite groups cases by the enum iio_shared_by mode it exercises:

  - IIO_SHARED_BY_ALL: produces an empty prefix.
  - IIO_SHARED_BY_DIR: emits direction only ("in" / "out").
  - IIO_SHARED_BY_TYPE: emits "<dir>_<type>" and the differential
    "<dir>_<type>-<type>" variant.
  - IIO_SEPARATE: covers the full matrix of indexed, differential,
    modified, output and extend_name combinations, plus the two
    documented error paths (differential without indexed, differential
    with modifier).

A final case exercises the seq_buf overflow path by passing an
undersized buffer and expects -EOVERFLOW.

Because __iio_chan_prefix_emit() is static, the test translation unit
is pulled into industrialio-core.c.

Also, an entry is created under MAINTAINERS dedicated to tests for IIO
core helpers.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 MAINTAINERS                                |   7 +
 drivers/iio/industrialio-core.c            |   4 +
 drivers/iio/test/Kconfig                   |  14 ++
 drivers/iio/test/iio-test-channel-prefix.c | 299 +++++++++++++++++++++++++++++
 4 files changed, 324 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 2b1ec46c5919..ffeee7c1ffa8 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -12634,6 +12634,13 @@ F:	include/dt-bindings/iio/
 F:	include/linux/iio/
 F:	tools/iio/
 
+IIO CORE KUNIT TESTS
+M:	Rodrigo Alencar <rodrigo.alencar@analog.com>
+L:	linux-iio@vger.kernel.org
+S:	Maintained
+F:	drivers/iio/test/iio-test-channel-prefix.c
+F:	drivers/iio/test/iio-test-format.c
+
 IIO UNIT CONVERTER
 M:	Peter Rosin <peda@lysator.liu.se>
 L:	linux-iio@vger.kernel.org
diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index b365922d8481..3909255212f5 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -2230,6 +2230,10 @@ EXPORT_SYMBOL_GPL(iio_device_get_current_mode);
 subsys_initcall(iio_init);
 module_exit(iio_exit);
 
+#if IS_ENABLED(CONFIG_IIO_CHANNEL_PREFIX_KUNIT_TEST)
+#include "test/iio-test-channel-prefix.c"
+#endif
+
 MODULE_AUTHOR("Jonathan Cameron <jic23@kernel.org>");
 MODULE_DESCRIPTION("Industrial I/O core");
 MODULE_LICENSE("GPL");
diff --git a/drivers/iio/test/Kconfig b/drivers/iio/test/Kconfig
index 4fc17dd0dcd7..7d2c29cc583b 100644
--- a/drivers/iio/test/Kconfig
+++ b/drivers/iio/test/Kconfig
@@ -4,6 +4,20 @@
 #
 
 # Keep in alphabetical order
+config IIO_CHANNEL_PREFIX_KUNIT_TEST
+	tristate "Test IIO channel prefix" if !KUNIT_ALL_TESTS
+	depends on KUNIT && IIO
+	default KUNIT_ALL_TESTS
+	help
+	  Build unit tests for __iio_chan_prefix_emit(), the helper that
+	  builds IIO sysfs attribute name prefixes from an iio_chan_spec.
+	  The tests are compiled into the IIO core module.
+
+	  For more information on KUnit and unit tests in general, please refer
+	  to the KUnit documentation in Documentation/dev-tools/kunit/.
+
+	  If unsure, say N.
+
 config IIO_GTS_KUNIT_TEST
 	tristate "Test IIO gain-time-scale helpers" if !KUNIT_ALL_TESTS
 	depends on KUNIT
diff --git a/drivers/iio/test/iio-test-channel-prefix.c b/drivers/iio/test/iio-test-channel-prefix.c
new file mode 100644
index 000000000000..4326d9bc466d
--- /dev/null
+++ b/drivers/iio/test/iio-test-channel-prefix.c
@@ -0,0 +1,299 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Unit tests for IIO channel prefix generation.
+ */
+
+#include <kunit/test.h>
+
+#include <linux/iio/iio.h>
+#include <linux/limits.h>
+#include <linux/string.h>
+
+#define PREFIX_BUF_SIZE		(NAME_MAX + 1)
+
+#define EXPECT_PREFIX(_test, _buf, _ret, _expected) do {			\
+		struct kunit *__test = (_test);					\
+		const char *__expected = (_expected);				\
+										\
+		KUNIT_EXPECT_EQ(__test, (_ret), (ssize_t)strlen(__expected));	\
+		KUNIT_EXPECT_STREQ(__test, (_buf), __expected);			\
+	} while (0)
+
+static char *iio_test_prefix_alloc(struct kunit *test)
+{
+	char *buf = kunit_kzalloc(test, PREFIX_BUF_SIZE, GFP_KERNEL);
+
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, buf);
+	return buf;
+}
+
+static void iio_test_prefix_shared_by_all(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_VOLTAGE,
+	};
+	const struct iio_chan_spec chan_noisy = {
+		.type = IIO_ACCEL,
+		.output = 1,
+		.indexed = 1,
+		.modified = 1,
+		.channel = 7,
+		.channel2 = IIO_MOD_Z,
+		.extend_name = "supply",
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SHARED_BY_ALL,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "");
+
+	ret = __iio_chan_prefix_emit(NULL, &chan_noisy, IIO_SHARED_BY_ALL,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "");
+}
+
+static void iio_test_prefix_shared_by_dir(struct kunit *test)
+{
+	const struct iio_chan_spec chan_in = {
+		.type = IIO_VOLTAGE,
+		.output = 0,
+	};
+	const struct iio_chan_spec chan_out = {
+		.type = IIO_VOLTAGE,
+		.output = 1,
+	};
+	const struct iio_chan_spec chan_in_noisy = {
+		.type = IIO_ACCEL,
+		.indexed = 1,
+		.modified = 1,
+		.channel = 5,
+		.channel2 = IIO_MOD_Y,
+		.extend_name = "supply",
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan_in, IIO_SHARED_BY_DIR,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in");
+
+	ret = __iio_chan_prefix_emit(NULL, &chan_out, IIO_SHARED_BY_DIR,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "out");
+
+	ret = __iio_chan_prefix_emit(NULL, &chan_in_noisy, IIO_SHARED_BY_DIR,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in");
+}
+
+static void iio_test_prefix_shared_by_type(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_VOLTAGE,
+	};
+	const struct iio_chan_spec chan_diff = {
+		.type = IIO_VOLTAGE,
+		.differential = 1,
+	};
+	const struct iio_chan_spec chan_noisy = {
+		.type = IIO_VOLTAGE,
+		.indexed = 1,
+		.modified = 1,
+		.channel = 4,
+		.channel2 = IIO_MOD_X,
+		.extend_name = "supply",
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SHARED_BY_TYPE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in_voltage");
+
+	ret = __iio_chan_prefix_emit(NULL, &chan_diff, IIO_SHARED_BY_TYPE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in_voltage-voltage");
+
+	ret = __iio_chan_prefix_emit(NULL, &chan_noisy, IIO_SHARED_BY_TYPE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in_voltage");
+}
+
+static void iio_test_prefix_separate_simple(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_TEMP,
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SEPARATE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in_temp");
+}
+
+static void iio_test_prefix_separate_indexed(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_VOLTAGE,
+		.indexed = 1,
+		.channel = 3,
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SEPARATE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in_voltage3");
+}
+
+static void iio_test_prefix_separate_indexed_diff(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_VOLTAGE,
+		.indexed = 1,
+		.differential = 1,
+		.channel = 0,
+		.channel2 = 1,
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SEPARATE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in_voltage0-voltage1");
+}
+
+static void iio_test_prefix_separate_modified(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_ACCEL,
+		.modified = 1,
+		.channel2 = IIO_MOD_X,
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SEPARATE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in_accel_x");
+}
+
+static void iio_test_prefix_separate_indexed_modified(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_ACCEL,
+		.indexed = 1,
+		.modified = 1,
+		.channel = 2,
+		.channel2 = IIO_MOD_Y,
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SEPARATE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in_accel2_y");
+}
+
+static void iio_test_prefix_separate_extend_name(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_VOLTAGE,
+		.indexed = 1,
+		.channel = 2,
+		.extend_name = "supply",
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SEPARATE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "in_voltage2_supply");
+}
+
+static void iio_test_prefix_output_separate(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_VOLTAGE,
+		.output = 1,
+		.indexed = 1,
+		.channel = 0,
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SEPARATE,
+				     buf, PREFIX_BUF_SIZE);
+	EXPECT_PREFIX(test, buf, ret, "out_voltage0");
+}
+
+static void iio_test_prefix_diff_unindexed_fails(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_VOLTAGE,
+		.differential = 1,
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SEPARATE,
+				     buf, PREFIX_BUF_SIZE);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+}
+
+static void iio_test_prefix_diff_modified_fails(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_VOLTAGE,
+		.indexed = 1,
+		.differential = 1,
+		.modified = 1,
+		.channel = 0,
+		.channel2 = 1,
+	};
+	char *buf = iio_test_prefix_alloc(test);
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SEPARATE,
+				     buf, PREFIX_BUF_SIZE);
+	KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+}
+
+static void iio_test_prefix_overflow(struct kunit *test)
+{
+	const struct iio_chan_spec chan = {
+		.type = IIO_VOLTAGE,
+	};
+	char small[4];
+	ssize_t ret;
+
+	ret = __iio_chan_prefix_emit(NULL, &chan, IIO_SHARED_BY_TYPE,
+				     small, sizeof(small));
+	KUNIT_EXPECT_EQ(test, ret, -EOVERFLOW);
+}
+
+static struct kunit_case iio_chan_prefix_test_cases[] = {
+	KUNIT_CASE(iio_test_prefix_shared_by_all),
+	KUNIT_CASE(iio_test_prefix_shared_by_dir),
+	KUNIT_CASE(iio_test_prefix_shared_by_type),
+	KUNIT_CASE(iio_test_prefix_separate_simple),
+	KUNIT_CASE(iio_test_prefix_separate_indexed),
+	KUNIT_CASE(iio_test_prefix_separate_indexed_diff),
+	KUNIT_CASE(iio_test_prefix_separate_modified),
+	KUNIT_CASE(iio_test_prefix_separate_indexed_modified),
+	KUNIT_CASE(iio_test_prefix_separate_extend_name),
+	KUNIT_CASE(iio_test_prefix_output_separate),
+	KUNIT_CASE(iio_test_prefix_diff_unindexed_fails),
+	KUNIT_CASE(iio_test_prefix_diff_modified_fails),
+	KUNIT_CASE(iio_test_prefix_overflow),
+	{ }
+};
+
+static struct kunit_suite iio_channel_prefix_test_suite = {
+	.name = "iio-channel-prefix",
+	.test_cases = iio_chan_prefix_test_cases,
+};
+
+kunit_test_suite(iio_channel_prefix_test_suite);

-- 
2.43.0

