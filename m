From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 13 Oct 2026 10:36:44 -0300
Subject: [PATCH RFC v2 1/4] lib: kstrtox: support E notation in
 kstrtoudec64() and kstrtodec64()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-e-notation-v2-1-d4adb5e193fc@analog.com>
References: <20261013-e-notation-v2-0-d4adb5e193fc@analog.com>
In-Reply-To: <20261013-e-notation-v2-0-d4adb5e193fc@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791898614; l=2928;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=3fLsUR5b5WZAVfLhBMXZfjqcJYDq5+HP2L3agWEZDXg=;
 b=DkDLz1lE0D4DRbTCt0V3gZNWAIxIjkB/IT+WdXFH0h41c5pqlVKEUXLlgCt4obrAF7Bq3beaD
 plTFiZjMAj9AWrSMJfxyOXyCBuYiHYd5E7kp5oFK4El4R1JhjkAtInF
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow decimal strings to carry an exponent suffix, such as "2.7e10" or
"271828e-5", in kstrtoudec64() and kstrtodec64(). The exponent is added
to the requested scale to work out how many integer and fractional digits
are consumed. A negative effective exponent drops integer digits. Digits
beyond the resulting precision are truncated, as before.

The digits are now scanned first and the string termination is checked
before any conversion. A missing or malformed exponent ("1e", "1e+")
returns -EINVAL. An exponent that overflows when added to the scale, or
that makes the result exceed 64 bits, returns -ERANGE.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/kstrtox.c | 64 +++++++++++++++++++++++++++++++++++++++--------------------
 1 file changed, 42 insertions(+), 22 deletions(-)

diff --git a/lib/kstrtox.c b/lib/kstrtox.c
index bac1c057e1b0..4755fc78a62c 100644
--- a/lib/kstrtox.c
+++ b/lib/kstrtox.c
@@ -397,39 +397,59 @@ EXPORT_SYMBOL(kstrtobool);
 
 static int _kstrtoudec64(const char *s, unsigned int scale, u64 *res)
 {
-	unsigned int rv_int, rv_frac;
+	const char *s_int, *s_frac;
+	int exp = 0, len_int = 0;
+	unsigned int rv;
 	u64 _res = 0;
+	int ret;
 
-	rv_int = _parse_integer(s, 10, &_res);
-	if (rv_int & KSTRTOX_OVERFLOW)
-		return -ERANGE;
-	s += rv_int;
+	s_int = s;
+	while (isdigit(*s)) {
+		s++;
+		len_int++;
+	}
 
 	if (*s == '.')
 		s++; /* skip decimal point */
 
-	rv_frac = _parse_integer(s, 10, &_res, scale, _res);
-	if (rv_frac & KSTRTOX_OVERFLOW)
+	s_frac = s;
+	while (isdigit(*s))
+		s++;
+
+	if (!len_int && s_frac == s)
+		return -EINVAL;
+
+	if (*s == 'e' || *s == 'E') { /* E Notation */
+		s++;
+		ret = kstrtoint(s, 10, &exp);
+		if (ret)
+			return ret;
+	} else { /* verify termination */
+		if (*s == '\n')
+			s++;
+		if (*s)
+			return -EINVAL;
+	}
+
+	if (check_add_overflow(exp, (int)scale, &exp))
 		return -ERANGE;
-	s += rv_frac;
 
-	/*
-	 * Check input beyond rv_int and rv_frac to cover cases like ".5" with
-	 * scale 0, which is considered a valid input, being parsed as 0.
-	 */
-	if (!rv_int && !rv_frac && !isdigit(*s))
-		return -EINVAL;
+	if (exp < 0) {
+		len_int = max(len_int + exp, 0);
+		exp = 0;
+	}
 
-	while (isdigit(*s)) /* truncate digits */
-		s++;
+	rv = _parse_integer(s_int, 10, &_res, len_int);
+	if (rv & KSTRTOX_OVERFLOW)
+		return -ERANGE;
 
-	if (*s == '\n')
-		s++;
-	if (*s)
-		return -EINVAL;
+	rv = _parse_integer(s_frac, 10, &_res, exp, _res);
+	if (rv & KSTRTOX_OVERFLOW)
+		return -ERANGE;
 
-	if (_res && ((scale - rv_frac) > 19 /* log10(2^64) = 19.26 */ ||
-		     check_mul_overflow(_res, int_pow(10, scale - rv_frac), &_res)))
+	exp -= rv;
+	if (_res && (exp > 19 /* log10(2^64) = 19.26 */ ||
+		     check_mul_overflow(_res, int_pow(10, exp), &_res)))
 		return -ERANGE;
 
 	*res = _res;

-- 
2.43.0

