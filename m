From: Thomas Maarseveen <maarseveent@gmail.com>
Date: Wed, 12 Aug 2026 20:55:33 +0200
Subject: [PATCH] lib/tests: add KUnit tests for errseq
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260812-errseq-kunit-v1-1-312be4c3aa0d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKTBfGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0Mj3dSiouLUQt3s0rzMEl3DNENjI4u0pOTUVEMloJaCotS0zAqwcdG
 xtbUAKW6Nol4AAAA=
X-Change-ID: 20260812-errseq-kunit-1f1328fbcee1
To: Jeff Layton <jlayton@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: David Gow <david@davidgow.net>, kunit-dev@googlegroups.com, 
 linux-kselftest@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Thomas Maarseveen <maarseveent@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786560934; l=12227;
 i=maarseveent@gmail.com; h=from:subject:message-id;
 bh=75Gy+F6zO2ftuiONJL1i57FaWWxelXMazNNz9c9HTcE=;
 b=D3wWDYAP/ia9jR8ztxB7ULzlFLamK8HQIynbT0zo/bFlNGyDLHf5ADqnA9WMCZwmMDMvJ7bie
 hbDuwGSmRqeA5Bt20o1e8cG/b1EfH2oSsFNKgClqd6hOTYC+EEvKake
X-Developer-Key: i=maarseveent@gmail.com; a=ed25519;
 pk=W1QNGKhOCOEXIAdTN0UwzNPpvcxVx7vDfChmpEN0REw=
X-Endpoint-Received: by B4 Relay for maarseveent@gmail.com/default with auth_id=943
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The errseq_t infrastructure (lib/errseq.c) underpins writeback error
reporting but has no regression tests. Its semantics are subtle enough
to have needed fixing before: commit b4678df184b3 ("errseq: Always
report a writeback error once") changed how unseen errors reach new
samplers.

Add a KUnit suite covering the documented single-threaded semantics:

 - a zeroed errseq_t is the "no error yet" epoch
 - errors are recorded, overwrite one another, and both ends of the
   valid errno range round-trip exactly
 - an error nobody has seen samples as zero, so a check against a
   fresh sample still reports it
 - errseq_check_and_advance() reports a given error exactly once per
   cursor and leaves the cursor in place when nothing has changed
 - once an error has been seen, a fresh sample is current and a check
   against it reports nothing
 - the same error recorded again after being seen is reported again,
   even to a cursor that consumed the first occurrence while another
   cursor marked the repeat as seen
 - independent cursors each observe each error

The lockless behaviour of errseq_t under concurrent updates and the
WARN path for invalid error values are deliberately out of scope.

Tested with ./tools/testing/kunit/kunit.py run, with a kunitconfig
enabling CONFIG_KUNIT=y and CONFIG_ERRSEQ_KUNIT_TEST=y; all 13 tests
pass under ARCH=um.

Signed-off-by: Thomas Maarseveen <maarseveent@gmail.com>
---
Single patch adding the first KUnit suite for lib/errseq.c.
(Cover not sent for a single-patch series; trailers below drive
the recipients.)
---
 MAINTAINERS              |   1 +
 lib/Kconfig.debug        |  15 +++
 lib/tests/Makefile       |   1 +
 lib/tests/errseq_kunit.c | 237 +++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 254 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 8014b9f8253edf15231df215d1b14063a54a55ec..70de54372c4f8f12b2431e693cb3b0b5ec5fdfc9 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -9624,6 +9624,7 @@ M:	Jeff Layton <jlayton@kernel.org>
 S:	Maintained
 F:	include/linux/errseq.h
 F:	lib/errseq.c
+F:	lib/tests/errseq_kunit.c
 
 ESD CAN NETWORK DRIVERS
 M:	Stefan Mätje <stefan.maetje@esd.eu>
diff --git a/lib/Kconfig.debug b/lib/Kconfig.debug
index 1244dcac2294ad99fda37fa6767c9e76f16a4d14..3f1a7103328678926dd82620349957fdede32ee4 100644
--- a/lib/Kconfig.debug
+++ b/lib/Kconfig.debug
@@ -2826,6 +2826,21 @@ config SYSCTL_KUNIT_TEST
 
 	  If unsure, say N.
 
+config ERRSEQ_KUNIT_TEST
+	tristate "KUnit test for errseq" if !KUNIT_ALL_TESTS
+	depends on KUNIT
+	default KUNIT_ALL_TESTS
+	help
+	  This builds the errseq KUnit test suite.
+	  It tests the documented semantics of the errseq_t error-tracking
+	  infrastructure (lib/errseq.c), which underpins writeback error
+	  reporting.
+
+	  For more information on KUnit and unit tests in general please refer
+	  to the KUnit documentation in Documentation/dev-tools/kunit/.
+
+	  If unsure, say N.
+
 config KFIFO_KUNIT_TEST
 	tristate "KUnit Test for the generic kernel FIFO implementation" if !KUNIT_ALL_TESTS
 	depends on KUNIT
diff --git a/lib/tests/Makefile b/lib/tests/Makefile
index 4ead57602eac468e1b9b8148593dc8c41ddc5779..a1e69b2c4318ae03f7834ba41414caf986997f02 100644
--- a/lib/tests/Makefile
+++ b/lib/tests/Makefile
@@ -13,6 +13,7 @@ obj-$(CONFIG_BLACKHOLE_DEV_KUNIT_TEST) += blackhole_dev_kunit.o
 obj-$(CONFIG_CHECKSUM_KUNIT) += checksum_kunit.o
 obj-$(CONFIG_CMDLINE_KUNIT_TEST) += cmdline_kunit.o
 obj-$(CONFIG_CPUMASK_KUNIT_TEST) += cpumask_kunit.o
+obj-$(CONFIG_ERRSEQ_KUNIT_TEST) += errseq_kunit.o
 obj-$(CONFIG_FFS_KUNIT_TEST) += ffs_kunit.o
 CFLAGS_fortify_kunit.o += $(call cc-disable-warning, unsequenced)
 CFLAGS_fortify_kunit.o += $(call cc-disable-warning, stringop-overread)
diff --git a/lib/tests/errseq_kunit.c b/lib/tests/errseq_kunit.c
new file mode 100644
index 0000000000000000000000000000000000000000..8f39ebc4a2488e564efe216883008b0d96a75fe6
--- /dev/null
+++ b/lib/tests/errseq_kunit.c
@@ -0,0 +1,237 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * KUnit tests for the errseq_t error-tracking infrastructure.
+ *
+ * These exercise the documented single-threaded semantics of the errseq
+ * API (see Documentation/core-api/errseq.rst and lib/errseq.c): error
+ * recording and overwriting, the "seen" handoff between errseq_sample()
+ * and errseq_check_and_advance(), and the re-reporting of an error that
+ * is recorded again after it has been seen.
+ *
+ * The lockless properties of errseq_t under concurrent updates are
+ * outside the scope of these deterministic tests, as is the WARN path
+ * for invalid error values.
+ */
+#include <kunit/test.h>
+
+#include <linux/err.h>
+#include <linux/errno.h>
+#include <linux/errseq.h>
+
+/*
+ * A zeroed errseq_t is the "no error has ever occurred" epoch: it
+ * samples as zero and no check against it reports anything.
+ */
+static void errseq_test_zero_epoch_reports_no_error(struct kunit *test)
+{
+	errseq_t eseq = 0;
+	errseq_t since = 0;
+
+	KUNIT_EXPECT_EQ(test, errseq_sample(&eseq), 0);
+	KUNIT_EXPECT_EQ(test, errseq_check(&eseq, 0), 0);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), 0);
+	KUNIT_EXPECT_EQ(test, since, 0);
+}
+
+static void errseq_test_set_records_error(struct kunit *test)
+{
+	errseq_t eseq = 0;
+
+	/* errseq_set() returns the previous value; the epoch is zero. */
+	KUNIT_EXPECT_EQ(test, errseq_set(&eseq, -EIO), 0);
+	KUNIT_EXPECT_EQ(test, errseq_check(&eseq, 0), -EIO);
+}
+
+/* Any error set always overwrites an existing error. */
+static void errseq_test_set_overwrites_error(struct kunit *test)
+{
+	errseq_t eseq = 0;
+
+	errseq_set(&eseq, -EIO);
+	errseq_set(&eseq, -ENOSPC);
+	KUNIT_EXPECT_EQ(test, errseq_check(&eseq, 0), -ENOSPC);
+}
+
+/* Both ends of the valid error range are recorded exactly. */
+static void errseq_test_errno_range_extremes(struct kunit *test)
+{
+	errseq_t lo = 0;
+	errseq_t hi = 0;
+
+	errseq_set(&lo, -1);
+	KUNIT_EXPECT_EQ(test, errseq_check(&lo, 0), -1);
+
+	errseq_set(&hi, -MAX_ERRNO);
+	KUNIT_EXPECT_EQ(test, errseq_check(&hi, 0), -MAX_ERRNO);
+}
+
+/*
+ * An error nobody has seen yet samples as zero, so that a check against
+ * the sample still reports it (see commit b4678df184b3 ("errseq: Always
+ * report a writeback error once")).
+ */
+static void errseq_test_sample_of_unseen_error_is_zero(struct kunit *test)
+{
+	errseq_t eseq = 0;
+
+	errseq_set(&eseq, -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_sample(&eseq), 0);
+}
+
+static void errseq_test_new_sampler_sees_unseen_error(struct kunit *test)
+{
+	errseq_t eseq = 0;
+	errseq_t since;
+
+	errseq_set(&eseq, -EIO);
+	since = errseq_sample(&eseq);
+	KUNIT_EXPECT_EQ(test, errseq_check(&eseq, since), -EIO);
+}
+
+/* A given error is reported exactly once per advancing cursor. */
+static void errseq_test_check_and_advance_reports_once(struct kunit *test)
+{
+	errseq_t eseq = 0;
+	errseq_t since = errseq_sample(&eseq);
+
+	errseq_set(&eseq, -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), 0);
+}
+
+/*
+ * Once an error has been seen, a fresh sample is non-zero and checking
+ * against it reports nothing: handled errors do not reach new samplers.
+ */
+static void errseq_test_sample_after_seen_is_current(struct kunit *test)
+{
+	errseq_t eseq = 0;
+	errseq_t since = 0;
+	errseq_t sample;
+
+	errseq_set(&eseq, -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), -EIO);
+
+	sample = errseq_sample(&eseq);
+	KUNIT_EXPECT_NE(test, sample, 0);
+	KUNIT_EXPECT_EQ(test, errseq_check(&eseq, sample), 0);
+}
+
+static void errseq_test_new_error_after_advance(struct kunit *test)
+{
+	errseq_t eseq = 0;
+	errseq_t since = 0;
+
+	errseq_set(&eseq, -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), -EIO);
+
+	errseq_set(&eseq, -ENOSPC);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), -ENOSPC);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), 0);
+}
+
+/*
+ * Recording the same error again after it has been seen must bump the
+ * sequence, so cursors that consumed the first occurrence see the
+ * second one too.
+ */
+static void errseq_test_same_error_reported_again_after_seen(struct kunit *test)
+{
+	errseq_t eseq = 0;
+	errseq_t since = 0;
+	errseq_t seen_cursor;
+
+	errseq_set(&eseq, -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), -EIO);
+
+	seen_cursor = since;
+	errseq_set(&eseq, -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check(&eseq, since), -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), -EIO);
+	/* The repeat must advance the sequence, not just re-toggle "seen". */
+	KUNIT_EXPECT_NE(test, since, seen_cursor);
+}
+
+/*
+ * A cursor that consumed an error must still observe a repeat of that
+ * error even when another cursor has already marked the repeat seen:
+ * recording over a seen value must advance the sequence.
+ */
+static void errseq_test_repeat_error_visible_to_all_cursors(struct kunit *test)
+{
+	errseq_t eseq = 0;
+	errseq_t cursor_a = 0;
+	errseq_t cursor_b = 0;
+
+	errseq_set(&eseq, -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &cursor_a), -EIO);
+
+	errseq_set(&eseq, -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &cursor_b), -EIO);
+
+	KUNIT_EXPECT_EQ(test, errseq_check(&eseq, cursor_a), -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &cursor_a), -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &cursor_a), 0);
+}
+
+/* An advance with no new error reports nothing and leaves the cursor put. */
+static void errseq_test_advance_stable_when_unchanged(struct kunit *test)
+{
+	errseq_t eseq = 0;
+	errseq_t since = 0;
+	errseq_t cursor;
+
+	errseq_set(&eseq, -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), -EIO);
+
+	cursor = since;
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &since), 0);
+	KUNIT_EXPECT_EQ(test, since, cursor);
+}
+
+/*
+ * Cursors are independent: one subscriber consuming an error does not
+ * consume it for another, and each subscriber sees each error once.
+ */
+static void errseq_test_two_subscribers_independent(struct kunit *test)
+{
+	errseq_t eseq = 0;
+	errseq_t cursor_a = errseq_sample(&eseq);
+	errseq_t cursor_b = errseq_sample(&eseq);
+
+	errseq_set(&eseq, -EIO);
+
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &cursor_a), -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check(&eseq, cursor_b), -EIO);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &cursor_b), -EIO);
+
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &cursor_a), 0);
+	KUNIT_EXPECT_EQ(test, errseq_check_and_advance(&eseq, &cursor_b), 0);
+}
+
+static struct kunit_case errseq_test_cases[] = {
+	KUNIT_CASE(errseq_test_zero_epoch_reports_no_error),
+	KUNIT_CASE(errseq_test_set_records_error),
+	KUNIT_CASE(errseq_test_set_overwrites_error),
+	KUNIT_CASE(errseq_test_errno_range_extremes),
+	KUNIT_CASE(errseq_test_sample_of_unseen_error_is_zero),
+	KUNIT_CASE(errseq_test_new_sampler_sees_unseen_error),
+	KUNIT_CASE(errseq_test_check_and_advance_reports_once),
+	KUNIT_CASE(errseq_test_sample_after_seen_is_current),
+	KUNIT_CASE(errseq_test_new_error_after_advance),
+	KUNIT_CASE(errseq_test_same_error_reported_again_after_seen),
+	KUNIT_CASE(errseq_test_repeat_error_visible_to_all_cursors),
+	KUNIT_CASE(errseq_test_advance_stable_when_unchanged),
+	KUNIT_CASE(errseq_test_two_subscribers_independent),
+	{}
+};
+
+static struct kunit_suite errseq_test_suite = {
+	.name = "errseq",
+	.test_cases = errseq_test_cases,
+};
+
+kunit_test_suite(errseq_test_suite);
+
+MODULE_DESCRIPTION("KUnit tests for the errseq infrastructure");
+MODULE_LICENSE("GPL");

---
base-commit: 3d6d817622b0a9721e3cc404df3469171582be13
change-id: 20260812-errseq-kunit-1f1328fbcee1

Best regards,
-- 
Thomas Maarseveen <maarseveent@gmail.com>

