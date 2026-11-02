From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 02 Nov 2026 07:40:59 -0300
Subject: [PATCH v5 1/7] lib: kstrtox: support E notation in kstrtoudec64()
 and kstrtodec64()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-e-notation-v5-1-d399e544a982@analog.com>
References: <20261102-e-notation-v5-0-d399e544a982@analog.com>
In-Reply-To: <20261102-e-notation-v5-0-d399e544a982@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793616082; l=3022;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=ZFrp/Yq7l//slmYaYIz9SzmuWKV15eT4mVooRD3b6KQ=;
 b=E8cO0I8vlgu29Ecu1Os6xOke+5hJcOsixwWE6Xgor7KRk0puiWUigRqpf5sbzPaE0KJhX0QEE
 UVCKjUE5FsHCFghFumdJBDcrY8G1fkhXk3GFwms/mTyBnNiM3gMrJu3
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow decimal strings to carry an exponent suffix, such as "2.7e10" or
"271828e-5", in kstrtoudec64() and kstrtodec64(). The exponent is added
to the requested scale to work out how many integer and fractional digits
are consumed. A negative effective exponent drops integer digits.

The digits are now scanned first and the string termination is checked
before any conversion. A missing or malformed exponent ("1e", "1e+")
returns -EINVAL. An exponent that overflows when added to the scale, or
that makes the result exceed 64 bits, returns -ERANGE.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 lib/kstrtox.c | 69 +++++++++++++++++++++++++++++++++++++++++------------------
 1 file changed, 48 insertions(+), 21 deletions(-)

diff --git a/lib/kstrtox.c b/lib/kstrtox.c
index 1b3f0d3fff37..94f3399b3a9b 100644
--- a/lib/kstrtox.c
+++ b/lib/kstrtox.c
@@ -395,41 +395,68 @@ int kstrtobool(const char *s, bool *res)
 }
 EXPORT_SYMBOL(kstrtobool);
 
+static int skip_digits(const char **s)
+{
+	const char *start = *s;
+
+	while (isdigit(**s))
+		(*s)++;
+
+	return *s - start;
+}
+
 static int _kstrtoudec64(const char *s, unsigned int scale, u64 *res)
 {
-	unsigned int rv_int, rv_frac;
+	const char *s_int, *s_frac;
+	int len_int, len_frac;
+	unsigned int rv;
 	u64 _res = 0;
+	int exp = 0;
+	int ret;
 
-	rv_int = _parse_integer(s, 10, &_res);
-	if (rv_int & KSTRTOX_OVERFLOW)
-		return -ERANGE;
-	s += rv_int;
+	s_int = s;
+	len_int = skip_digits(&s);
 
 	if (*s == '.')
 		s++; /* skip decimal point */
 
-	rv_frac = _parse_integer(s, 10, &_res, scale, _res);
-	if (rv_frac & KSTRTOX_OVERFLOW)
-		return -ERANGE;
-	s += rv_frac;
+	s_frac = s;
+	len_frac = skip_digits(&s);
 
-	/*
-	 * Check input beyond rv_int and rv_frac to cover cases like ".5" with
-	 * scale 0, which is considered a valid input, being parsed as 0.
-	 */
-	if (!rv_int && !rv_frac && !isdigit(*s))
+	if (!len_int && !len_frac)
 		return -EINVAL;
 
-	while (isdigit(*s)) /* truncate digits */
+	if (_tolower(*s) == 'e') { /* E Notation */
 		s++;
+		ret = kstrtoint(s, 10, &exp);
+		if (ret)
+			return ret;
+	} else { /* verify termination */
+		if (*s == '\n')
+			s++;
+		if (*s)
+			return -EINVAL;
+	}
 
-	if (*s == '\n')
-		s++;
-	if (*s)
-		return -EINVAL;
+	if (check_add_overflow(exp, scale, &exp))
+		return -ERANGE;
+
+	if (exp < 0) {
+		len_int = max(len_int + exp, 0);
+		exp = 0;
+	}
+
+	rv = _parse_integer(s_int, 10, &_res, len_int);
+	if (rv & KSTRTOX_OVERFLOW)
+		return -ERANGE;
+
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

