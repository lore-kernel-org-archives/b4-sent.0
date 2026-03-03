From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 03 Mar 2026 13:27:08 +0000
Subject: [PATCH v8 03/10] lib: test-kstrtox: add tests for kstrntoull()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-adf41513-iio-driver-v8-3-8dd2417cc465@analog.com>
References: <20260303-adf41513-iio-driver-v8-0-8dd2417cc465@analog.com>
In-Reply-To: <20260303-adf41513-iio-driver-v8-0-8dd2417cc465@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772544443; l=4874;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=on3FpvpRalj0PIdH7WCk6vmRu4hDbH1Z0/+fJowkZVQ=;
 b=IAqWCFIDmLHXOgRb5CvzPQvGqnHhRHpKfOaZW2lL/RGQ/C7gRe4aBF8eQDyfQF0fjl3sJe3+9
 0PBIjUMveHnBKypsaz0Ham7YEca4p9sowenwjvj85kd75Vtl1zFOSU8
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add test cases for the new kstrntoull() function which converts a string
to unsigned long long with a maximum character limit.

The OK tests cover basic decimal conversion, max_chars truncation, octal
and hex with both autodetection and explicit base, stop-at-non-digit
behavior, and chained conversions where the return value is used to
advance through a compound string (e.g. "192.168.1.0", "123::456").

The fail tests cover overflow for decimal, hex, and octal, prefix
consumed entirely by max_chars, zero max_chars, empty string, and bare
hex prefix.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/test-kstrtox.c | 121 +++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 121 insertions(+)

diff --git a/lib/test-kstrtox.c b/lib/test-kstrtox.c
index ee87fef66cb5..c3fe2a3bc142 100644
--- a/lib/test-kstrtox.c
+++ b/lib/test-kstrtox.c
@@ -703,6 +703,124 @@ static void __init test_kstrtos8_fail(void)
 	TEST_FAIL(kstrtos8, s8, "%hhd", test_s8_fail);
 }
 
+static void __init test_kstrntoull_ok(void)
+{
+	struct test_ntoull {
+		const char *str;
+		size_t step;
+		unsigned int base;
+		size_t max_chars;
+		ssize_t expected_rv;
+		unsigned long long expected_res;
+	};
+	static const struct test_ntoull test[] __initconst = {
+		/* basic decimal */
+		{"0",		0,	10,	1,	1,	0ULL},
+		{"1",		0,	10,	1,	1,	1ULL},
+		{"123",		0,	10,	3,	3,	123ULL},
+		{"123",		0,	10,	10,	3,	123ULL},
+		/* max_chars truncation */
+		{"1234567",	0,	10,	1,	1,	1ULL},
+		{"1234567",	0,	10,	3,	3,	123ULL},
+		{"1234567",	0,	10,	5,	5,	12345ULL},
+		/* octal with base autodetection */
+		{"0177",	0,	0,	4,	4,	0177ULL},
+		{"0177",	0,	0,	3,	3,	017ULL},
+		{"0177",	0,	0,	2,	2,	01ULL},
+		/* octal with explicit base */
+		{"01777",	0,	8,	4,	4,	0177ULL},
+		{"01777",	0,	8,	3,	3,	017ULL},
+		/* hex with base autodetection */
+		{"0xff",	0,	0,	4,	4,	0xffULL},
+		{"0xffff",	0,	0,	4,	4,	0xffULL},
+		{"0xffff",	0,	0,	6,	6,	0xffffULL},
+		{"0xFF",	0,	0,	4,	4,	0xffULL},
+		/* hex with explicit base */
+		{"0xff",	0,	16,	4,	4,	0xffULL},
+		{"ff",		0,	16,	2,	2,	0xffULL},
+		/* stop at non-digit */
+		{"12abc",	0,	10,	5,	2,	12ULL},
+		/* large values */
+		{"18446744073709551615", 0, 10, 20, 20, 18446744073709551615ULL},
+		{"ffffffffffffffff", 0, 16, 16, 16, 0xffffffffffffffffULL},
+		/* chained tests */
+		{"123::456",	0,	10,	10,	3,	123ULL},
+		{NULL,		2,	10,	10,	3,	456ULL},
+		{"192.168.1.0",	0,	10,	10,	3,	192ULL},
+		{NULL,		1,	10,	10,	3,	168ULL},
+		{NULL,		1,	10,	10,	1,	1ULL},
+		{NULL,		1,	10,	10,	1,	0ULL},
+		{"123-beef",	0,	10,	10,	3,	123ULL},
+		{NULL,		1,	16,	10,	4,	0xBEEFULL},
+		{"12345678",	0,	10,	5,	5,	12345ULL},
+		{NULL,		0,	10,	5,	3,	678ULL},
+	};
+	unsigned int i;
+	const char *s = NULL;
+
+	for_each_test(i, test) {
+		const struct test_ntoull *t = &test[i];
+		unsigned long long res = ~0ULL;
+		ssize_t rv;
+
+		if (t->str)
+			s = t->str;
+		s += t->step;
+
+		rv = kstrntoull(s, t->base, &res, t->max_chars);
+		if (rv != t->expected_rv) {
+			WARN(1, "str '%s', base %u, max_chars %zu, expected rv %zd, got %zd\n",
+			     s, t->base, t->max_chars, t->expected_rv, rv);
+			continue;
+		}
+		if (rv >= 0 && res != t->expected_res) {
+			WARN(1, "str '%s', base %u, max_chars %zu, expected %llu, got %llu\n",
+			     s, t->base, t->max_chars, t->expected_res, res);
+			continue;
+		}
+		s += rv;
+	}
+}
+
+static void __init test_kstrntoull_fail(void)
+{
+	struct test_ntoull_fail {
+		const char *str;
+		unsigned int base;
+		size_t max_chars;
+		ssize_t expected_rv;
+	};
+	static const struct test_ntoull_fail test[] __initconst = {
+		/* overflow */
+		{"18446744073709551616",	10,	20,	-ERANGE},
+		{"10000000000000000",		16,	17,	-ERANGE},
+		{"2000000000000000000000",	8,	22,	-ERANGE},
+		/* max_chars is too small */
+		{"123",		10,	0,	-EINVAL},
+		{"0xff",	0,	1,	-EINVAL},
+		{"0xff",	0,	2,	-EINVAL},
+		{"0xff",	16,	1,	-EINVAL},
+		{"0xff",	16,	2,	-EINVAL},
+		/* empty string */
+		{"",		10,	10,	-EINVAL},
+		{"0x",		16,	10,	-EINVAL},
+	};
+	unsigned int i;
+
+	for_each_test(i, test) {
+		const struct test_ntoull_fail *t = &test[i];
+		unsigned long long res = 0;
+		ssize_t rv;
+
+		rv = kstrntoull(t->str, t->base, &res, t->max_chars);
+		if (rv != t->expected_rv) {
+			WARN(1, "str '%s', base %u, max_chars %zu, expected %zd, got %zd\n",
+			     t->str, t->base, t->max_chars, t->expected_rv, rv);
+			continue;
+		}
+	}
+}
+
 static int __init test_kstrtox_init(void)
 {
 	test_kstrtoull_ok();
@@ -729,6 +847,9 @@ static int __init test_kstrtox_init(void)
 	test_kstrtou8_fail();
 	test_kstrtos8_ok();
 	test_kstrtos8_fail();
+
+	test_kstrntoull_ok();
+	test_kstrntoull_fail();
 	return -EINVAL;
 }
 module_init(test_kstrtox_init);

-- 
2.43.0

