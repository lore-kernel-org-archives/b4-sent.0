From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 06 May 2026 15:08:47 +0100
Subject: [PATCH v11 03/11] lib: test-kstrtox: tests for kstrtodec64() and
 kstrtoudec64()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260506-adf41513-iio-driver-v11-3-2b7e99cfe8f2@analog.com>
References: <20260506-adf41513-iio-driver-v11-0-2b7e99cfe8f2@analog.com>
In-Reply-To: <20260506-adf41513-iio-driver-v11-0-2b7e99cfe8f2@analog.com>
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
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778076527; l=4968;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=tp8hvAbYc3biI7q7ogMTaReytHsO+RY7GLMjwvwZ1gQ=;
 b=31/YEzIhZNRzHU1ZdGf2MBpzcjgEyqVmwEJEm1RwN68CaeCxdFJhdyozirusF0+eXXvBPJAAg
 eCSJx8fa8P0BcfctN9+gyZz4QT4wAy/8dTr7kBW8BNMVIR3Ih1IT1l0
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add tests for decimal parsing helpers kstrtodec64() and kstrtoudec64().
The test infrastructure is reused from other kstrto*() functions, i.e.,
the decimal parsers have fixed base of 10, so base field is used as
scale input for the helpers.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/test-kstrtox.c | 156 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 156 insertions(+)

diff --git a/lib/test-kstrtox.c b/lib/test-kstrtox.c
index ee87fef66cb5..ee9b535bcf1c 100644
--- a/lib/test-kstrtox.c
+++ b/lib/test-kstrtox.c
@@ -703,6 +703,156 @@ static void __init test_kstrtos8_fail(void)
 	TEST_FAIL(kstrtos8, s8, "%hhd", test_s8_fail);
 }
 
+static void __init test_kstrtoudec64_ok(void)
+{
+	DECLARE_TEST_OK(u64, struct test_udec64);
+	static DEFINE_TEST_OK(struct test_udec64, test_udec64_ok) = {
+		/* basic: integer.fraction, exact digits */
+		{"0.0",			1,	0},
+		{"1.5",			1,	15},
+		{"1.234",		3,	1234},
+		{"42.0",		1,	420},
+		/* zero */
+		{"0.0",			1,	0},
+		{"0.000",		3,	0},
+		/* integer only (no decimal point) */
+		{"0",			1,	0},
+		{"42",			3,	42000},
+		{"1",			1,	10},
+		/* fractional only (leading dot) */
+		{".5",			1,	5},
+		{".123",		3,	123},
+		{".001",		3,	1},
+		/* zero padding: fewer fractional digits than scale */
+		{"1.2",			3,	1200},
+		{"1.2",			6,	1200000},
+		{"0.01",		3,	10},
+		{"0.1",			9,	100000000ULL},
+		{"0.01",		9,	10000000},
+		/* truncation: more fractional digits than scale */
+		{"1.23456",		3,	1234},
+		{"3.1415926535",	6,	3141592},
+		{"0.999999999",		3,	999},
+		{"1.99",		1,	19},
+		/* trailing newline */
+		{"1.5\n",		1,	15},
+		{"42\n",		3,	42000},
+		/* plus sign */
+		{"+1.5",		1,	15},
+		{"+.5",			1,	5},
+		/* scale progression */
+		{"1.0",			1,	10},
+		{"1.00",		2,	100},
+		{"1.000",		3,	1000},
+		{"1.000000",		6,	1000000},
+		{"1.000000000",		9,	1000000000ULL},
+		/* large values spanning u64 range */
+		{"9223372036.854775807",	9,	9223372036854775807ULL},
+		{"18446744073709.551615",	6,	18446744073709551615ULL},
+	};
+	TEST_OK(kstrtoudec64, u64, "%llu", test_udec64_ok);
+}
+
+static void __init test_kstrtoudec64_fail(void)
+{
+	static DEFINE_TEST_FAIL(test_udec64_fail) = {
+		/* empty / whitespace */
+		{"",		3},
+		{"\n",		3},
+		/* invalid scale */
+		{"1.0",		21},
+		/* minus sign (unsigned) */
+		{"-1.5",	1},
+		{"-0.5",	1},
+		/* no digits after dot */
+		{"1.",		3},
+		{".",		3},
+		/* no digits at all */
+		{"+",		3},
+		/* non-digit characters */
+		{"abc",		3},
+		{"1.2x",	3},
+		/* leading/trailing space */
+		{" 1.5",	1},
+		{"1.5 ",	1},
+		/* overflow */
+		{"18446744073710.551615",	6},
+		{"99999999999999999999",	1},
+	};
+	TEST_FAIL(kstrtoudec64, u64, "%llu", test_udec64_fail);
+}
+
+static void __init test_kstrtodec64_ok(void)
+{
+	DECLARE_TEST_OK(s64, struct test_dec64);
+	static DEFINE_TEST_OK(struct test_dec64, test_dec64_ok) = {
+		/* basic positive */
+		{"0.0",			1,	0},
+		{"1.5",			1,	15},
+		{"1.234",		3,	1234},
+		/* basic negative */
+		{"-1.5",		1,	-15},
+		{"-1.234",		3,	-1234},
+		{"-0.5",		1,	-5},
+		{"-0.001",		3,	-1},
+		/* zero (signed) */
+		{"-0",			1,	0},
+		{"-0.0",		1,	0},
+		{"0.000",		3,	0},
+		/* integer only */
+		{"42",			3,	42000},
+		{"-42",			3,	-42000},
+		/* fractional only */
+		{".5",			1,	5},
+		{"-.5",			1,	-5},
+		/* zero padding */
+		{"1.2",			3,	1200},
+		{"-1.2",		3,	-1200},
+		{"0.01",		3,	10},
+		{"-0.01",		3,	-10},
+		/* truncation */
+		{"1.23456",		3,	1234},
+		{"-1.23456",		3,	-1234},
+		{"0.999999999",		3,	999},
+		{"-0.999999999",	3,	-999},
+		/* trailing newline */
+		{"1.5\n",		1,	15},
+		{"-1.5\n",		1,	-15},
+		/* plus sign */
+		{"+1.5",		1,	15},
+		/* limits */
+		{"9223372036.854775807",	9,	LLONG_MAX},
+		{"-9223372036.854775808",	9,	LLONG_MIN},
+	};
+	TEST_OK(kstrtodec64, s64, "%lld", test_dec64_ok);
+}
+
+static void __init test_kstrtodec64_fail(void)
+{
+	static DEFINE_TEST_FAIL(test_dec64_fail) = {
+		/* empty / whitespace */
+		{"",		3},
+		{"\n",		3},
+		/* invalid scale */
+		{"1.0",		21},
+		/* no digits after dot */
+		{"1.",		3},
+		{".",		3},
+		{"-.",		3},
+		/* no digits at all */
+		{"+",		3},
+		{"-",		3},
+		/* non-digit characters */
+		{"abc",		3},
+		{"-1.2x",	3},
+		/* signed overflow */
+		{"9223372036.854775808",	9},
+		{"-9223372036.854775809",	9},
+		{"99999999999999999999",	1},
+	};
+	TEST_FAIL(kstrtodec64, s64, "%lld", test_dec64_fail);
+}
+
 static int __init test_kstrtox_init(void)
 {
 	test_kstrtoull_ok();
@@ -729,6 +879,12 @@ static int __init test_kstrtox_init(void)
 	test_kstrtou8_fail();
 	test_kstrtos8_ok();
 	test_kstrtos8_fail();
+
+	test_kstrtoudec64_ok();
+	test_kstrtoudec64_fail();
+	test_kstrtodec64_ok();
+	test_kstrtodec64_fail();
+
 	return -EINVAL;
 }
 module_init(test_kstrtox_init);

-- 
2.43.0

