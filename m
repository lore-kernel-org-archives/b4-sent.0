From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sat, 14 Nov 2026 14:09:56 +0000
Subject: [PATCH v6 4/7] lib: test-kstrtox: add E notation tests for
 kstrto[u]dec64()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-e-notation-v6-4-205ca9a1438a@analog.com>
References: <20261114-e-notation-v6-0-205ca9a1438a@analog.com>
In-Reply-To: <20261114-e-notation-v6-0-205ca9a1438a@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794665398; l=5466;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=nIiIP9SD5omcIoOm+2iP0/q9S4xqAXZkU/Z/buM2wZ0=;
 b=VkOTOuXz0nxKn5VpktoYwOINW1pIXzhI+kWLas5QlSpmVZ4OgMdFnHr4UYv1/4cOKT8ByueVh
 haywaM/2GhwC/+YbNjM0eha9CZqRSVqKPyBJJ1WJv0byjvI38jO6FLj
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cover E notation parsing in kstrtoudec64() and kstrtodec64(): positive,
zero and negative exponents, upper case 'E', an explicit '+' sign,
rounding (ties to even) of integer digits dropped by negative exponents,
large values, and failures for overflowing and invalid inputs.

Also cover big exponents, up to the limits of int, either alone or
offset by an opposite scale, and exponents that overflow when added to
the scale.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/test-kstrtox.c | 97 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 97 insertions(+)

diff --git a/lib/test-kstrtox.c b/lib/test-kstrtox.c
index 8ba0f23bb8ef..a5b3fdc6e9b9 100644
--- a/lib/test-kstrtox.c
+++ b/lib/test-kstrtox.c
@@ -838,6 +838,45 @@ static void __init test_kstrtoudec64_ok(void)
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
+		/* E notation: big exponents */
+		{"1e19",		0,	10000000000000000000ULL},
+		{"1.8446744073709551615e19",	0,	ULLONG_MAX},
+		{"18446744073709551615e-20",	20,	ULLONG_MAX},
+		{"123456789012345678901234567890e-29",	0,	1ULL},
+		{"0e2147483647",	0,	0ULL},
+		{"1e-2147483648",	0,	0ULL},
+		{"1e2147483647",	-2147483647,	1ULL},
+		{"1e-2147483647",	2147483647,	1ULL},
 		/* negative scale: drops integer digits */
 		{"12345",		-2,	123ULL},
 		{"12355",		-2,	124ULL},
@@ -883,6 +922,24 @@ static void __init test_kstrtoudec64_fail(void)
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
+		/* E notation: big exponents */
+		{"1e20",			0},
+		{"1.8446744073709551616e19",	0},
+		{"1e2147483647",		0},
+		{"1e2147483647",		1}, /* exponent + scale overflow */
+		{"1e2147483648",		0}, /* exponent beyond int */
+		{"1e-2147483649",		0},
 		/* negative scale: rounds up past the limit */
 		{"18446744073709551615500",	-3},
 		/* negative scale: exponent overflows when added to it */
@@ -946,6 +1003,32 @@ static void __init test_kstrtodec64_ok(void)
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
+		/* E notation: big exponents */
+		{"9.223372036854775807e18",	0,	LLONG_MAX},
+		{"-9.223372036854775808e18",	0,	LLONG_MIN},
+		{"-1e-2147483648",	0,	0LL},
+		{"-1e2147483647",	-2147483647,	-1LL},
 		/* negative scale: drops integer digits */
 		{"-12345",		-2,	-123LL},
 		{"-12355",		-2,	-124LL},
@@ -983,6 +1066,20 @@ static void __init test_kstrtodec64_fail(void)
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
+		/* E notation: big exponents */
+		{"9.223372036854775808e18",	0},
+		{"-1e2147483647",		0},
+		{"1e2147483648",		0}, /* exponent beyond int */
 		/* negative scale: rounds up past the limit */
 		{"9223372036854775807500",	-3},
 		{"-9223372036854775808501",	-3},

-- 
2.43.0

