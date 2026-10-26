From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 26 Oct 2026 08:54:07 -0300
Subject: [PATCH v4 3/6] lib: test-kstrtox: add E notation tests for
 kstrto[u]dec64()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-e-notation-v4-3-a366a6d14d57@analog.com>
References: <20261026-e-notation-v4-0-a366a6d14d57@analog.com>
In-Reply-To: <20261026-e-notation-v4-0-a366a6d14d57@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793015661; l=4105;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=AplilCw0/lgZtXwyKRUjI6JAbU6gbrQk+IIYLQb21T4=;
 b=34D9hB0iVYW1857tWE1NPi1VxrCzJ5TPLBL0PjZyg/FuJdSMTQdj3043SWfISMraC6L6gNbVY
 kbAdN7XZqpCBA2CE/mHUbwE4/9l9P63BDB0X1IqqvCXpM3t8iQpO9Ju
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cover E notation parsing in kstrtoudec64() and kstrtodec64(): positive,
zero and negative exponents, upper case 'E', an explicit '+' sign,
rounding (ties to even) of integer digits dropped by negative exponents,
large values, and failures for overflowing and invalid inputs.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/test-kstrtox.c | 72 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 72 insertions(+)

diff --git a/lib/test-kstrtox.c b/lib/test-kstrtox.c
index 1f176b232085..a0c1e4286fd4 100644
--- a/lib/test-kstrtox.c
+++ b/lib/test-kstrtox.c
@@ -781,6 +781,36 @@ static void __init test_kstrtoudec64_ok(void)
 		/* rounding with many excess digits */
 		{"0.00000000000000000000000000000000423",	34,	42},
 		{"1.99999999999999999999999999999999999",	3,	2000},
+		/* E notation: positive exponent, no fraction */
+		{"1e3",			3,	1000000ULL},
+		{"42e2",		3,	4200000ULL},
+		/* E notation: positive exponent with fraction */
+		{"2.718e3",		3,	2718000ULL},
+		{"1.5e2",		1,	1500ULL},
+		/* E notation: uppercase E */
+		{"1E3",			3,	1000000ULL},
+		/* E notation: explicit positive exponent sign */
+		{"1e+3",		3,	1000000ULL},
+		/* E notation: zero exponent */
+		{"1.5e0",		1,	15ULL},
+		/* E notation: negative exponent shifts decimal left */
+		{"271828e-5",		3,	2718ULL},
+		{"2.71828e-1",		3,	272ULL},
+		{"270e-2",		3,	2700ULL},
+		/* E notation: negative exponent that rounds integer digits */
+		{"27e-4",		3,	3ULL},
+		{"19e-1",		0,	2ULL},
+		/* E notation: ties to even on integer digits */
+		{"125e-1",		0,	12ULL},
+		{"135e-1",		0,	14ULL},
+		{"25.0001e-1",		0,	3ULL},
+		/* E notation: negative exponent below 1 ULP rounds to 0 */
+		{"1e-5",		3,	0ULL},
+		{"5e-1",		0,	0ULL},
+		{"5e-2",		0,	0ULL},
+		{"6e-1",		0,	1ULL},
+		/* E notation: large value (27 GHz in micro Hz) */
+		{"2.7e10",		6,	27000000000000000ULL},
 	};
 	TEST_OK(kstrtoudec64, u64, "%llu", test_udec64_ok);
 }
@@ -814,6 +844,17 @@ static void __init test_kstrtoudec64_fail(void)
 		{"0.2",				20},
 		{"0.18446744073709551616",	20},
 		{"1",				20},
+		/* E notation: exponent causes overflow */
+		{"1e21",			1},
+		{"2e20",			1},
+		/* E notation: no digits after exponent marker */
+		{"1e",			3},
+		/* E notation: sign only after exponent marker */
+		{"1e+",			3},
+		{"1e-",			3},
+		/* E notation: misc */
+		{"1ee",			3}, /* double 'e' */
+		{"1e+0b",		3}, /* hex character after exponent */
 	};
 	TEST_FAIL(kstrtoudec64, u64, "%llu", test_udec64_fail);
 }
@@ -873,6 +914,27 @@ static void __init test_kstrtodec64_ok(void)
 		{"-0.00000000000000000001",	20,	-1},
 		{"0.009223372036854775807",	21,	LLONG_MAX},
 		{"-0.009223372036854775808",	21,	LLONG_MIN},
+		/* E notation: positive number */
+		{"1e3",			3,	1000000LL},
+		{"2.7e3",		3,	2700000LL},
+		{"1.5e0",		1,	15LL},
+		/* E notation: negative number with positive exponent */
+		{"-1e3",		3,	-1000000LL},
+		{"-2.7e3",		3,	-2700000LL},
+		/* E notation: negative exponent */
+		{"27e-1",		3,	2700LL},
+		{"-27e-1",		3,	-2700LL},
+		{"2.7e-1",		3,	270LL},
+		{"-2.7e-1",		3,	-270LL},
+		/* E notation: negative exponent rounds integer digits */
+		{"-27e-4",		3,	-3LL},
+		{"-125e-1",		0,	-12LL},
+		{"-135e-1",		0,	-14LL},
+		/* E notation: negative exponent below 1 ULP rounds to 0 */
+		{"1e-5",		3,	0LL},
+		{"-1e-5",		3,	0LL},
+		{"-5e-1",		0,	0LL},
+		{"-6e-1",		0,	-1LL},
 	};
 	TEST_OK(kstrtodec64, s64, "%lld", test_dec64_ok);
 }
@@ -903,6 +965,16 @@ static void __init test_kstrtodec64_fail(void)
 		{"-0.1",			20},
 		{"0.09223372036854775808",	20},
 		{"-0.09223372036854775809",	20},
+		/* E notation: exponent causes overflow */
+		{"1e21",		1},
+		{"-1e21",		1},
+		/* E notation: no digits after exponent marker */
+		{"1e",			3},
+		{"1e+",			3},
+		{"1e-",			3},
+		/* E notation: misc */
+		{"1Ee+3",		3}, /* double 'e' with mixed case */
+		{"1e+0xa",		3}, /* hex number exponent */
 	};
 	TEST_FAIL(kstrtodec64, s64, "%lld", test_dec64_fail);
 }

-- 
2.43.0

