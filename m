From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Sun, 31 May 2026 09:30:46 +0100
Subject: [PATCH v15 03/12] lib: kstrtox: add kstrtoudec64() and
 kstrtodec64()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260531-adf41513-iio-driver-v15-3-da09adf1c0dd@analog.com>
References: <20260531-adf41513-iio-driver-v15-0-da09adf1c0dd@analog.com>
In-Reply-To: <20260531-adf41513-iio-driver-v15-0-da09adf1c0dd@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780216295; l=4931;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=Pr5+NBfQy2PXMwkQMZ2Ccvc7BauaEGWsUrxgWkFdXyQ=;
 b=4LIlBmzp9L2AQp7uay3mllOo+Muruh4jV6wZIQL0sJPPV8Vpkt9V9vh70cW7XPAR9kNlZTT7y
 t7SmtpqR8qsBegwQ4WHbQd+y20g/Gc5LFNzt7ArLAUOSEcx9H+/859a
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add helpers that parses decimal numbers into 64-bit number, i.e., decimal
point numbers with pre-defined scale are parsed into a 64-bit value (fixed
precision). After the decimal point, digits beyond the specified scale
are ignored.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 include/linux/kstrtox.h |   3 ++
 lib/kstrtox.c           | 100 ++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 103 insertions(+)

diff --git a/include/linux/kstrtox.h b/include/linux/kstrtox.h
index 6ea897222af1..bec2fc17bde0 100644
--- a/include/linux/kstrtox.h
+++ b/include/linux/kstrtox.h
@@ -97,6 +97,9 @@ int __must_check kstrtou8(const char *s, unsigned int base, u8 *res);
 int __must_check kstrtos8(const char *s, unsigned int base, s8 *res);
 int __must_check kstrtobool(const char *s, bool *res);
 
+int __must_check kstrtoudec64(const char *s, unsigned int scale, u64 *res);
+int __must_check kstrtodec64(const char *s, unsigned int scale, s64 *res);
+
 int __must_check kstrtoull_from_user(const char __user *s, size_t count, unsigned int base, unsigned long long *res);
 int __must_check kstrtoll_from_user(const char __user *s, size_t count, unsigned int base, long long *res);
 int __must_check kstrtoul_from_user(const char __user *s, size_t count, unsigned int base, unsigned long *res);
diff --git a/lib/kstrtox.c b/lib/kstrtox.c
index bd63c55b8490..ab43d16659ce 100644
--- a/lib/kstrtox.c
+++ b/lib/kstrtox.c
@@ -17,6 +17,7 @@
 #include <linux/export.h>
 #include <linux/kstrtox.h>
 #include <linux/math64.h>
+#include <linux/overflow.h>
 #include <linux/types.h>
 #include <linux/uaccess.h>
 
@@ -407,6 +408,105 @@ int kstrtobool(const char *s, bool *res)
 }
 EXPORT_SYMBOL(kstrtobool);
 
+static int _kstrtoudec64(const char *s, unsigned int scale, u64 *res)
+{
+	u64 _res = 0;
+	unsigned int rv_int, rv_frac;
+
+	rv_int = _parse_integer(s, 10, &_res);
+	if (rv_int & KSTRTOX_OVERFLOW)
+		return -ERANGE;
+	s += rv_int;
+
+	if (*s == '.')
+		s++; /* skip decimal point */
+
+	rv_frac = _parse_integer_limit_init(s, 10, _res, &_res, scale);
+	if (rv_frac & KSTRTOX_OVERFLOW)
+		return -ERANGE;
+	s += rv_frac;
+
+	if (!rv_int && !rv_frac && !isdigit(*s))
+		return -EINVAL; /* no digits at all */
+
+	while (isdigit(*s)) /* truncate digits */
+		s++;
+
+	if (*s == '\n')
+		s++;
+	if (*s)
+		return -EINVAL;
+
+	if (_res && (scale > (19 + rv_frac) || /* log10(2^64) = 19.26 */
+	    check_mul_overflow(_res, int_pow(10, scale - rv_frac), &_res)))
+		return -ERANGE;
+
+	*res = _res;
+	return 0;
+}
+
+/**
+ * kstrtoudec64() - Convert a string to an unsigned 64-bit value that represents
+ *		    a scaled decimal number.
+ * @s: The start of the string. The string must be null-terminated, and may also
+ *  include a single newline before its terminating null. The first character
+ *  may also be a plus sign, but not a minus sign. Digits beyond the specified
+ *  scale are ignored.
+ * @scale: The number of digits to the right of the decimal point. For example,
+ *  a scale of 2 would mean the number is represented with two decimal places,
+ *  so "123.45" would be represented as 12345.
+ * @res: Where to write the result of the conversion on success.
+ *
+ * Return: 0 on success, -ERANGE on overflow and -EINVAL on parsing error.
+ */
+noinline
+int kstrtoudec64(const char *s, unsigned int scale, u64 *res)
+{
+	if (s[0] == '+')
+		s++;
+	return _kstrtoudec64(s, scale, res);
+}
+EXPORT_SYMBOL(kstrtoudec64);
+
+/**
+ * kstrtodec64() - Convert a string to a signed 64-bit value that represents a
+ *		   scaled decimal number.
+ * @s: The start of the string. The string must be null-terminated, and may also
+ *  include a single newline before its terminating null. The first character
+ *  may also be a plus sign or a minus sign. Digits beyond the specified scale
+ *  are ignored.
+ * @scale: The number of digits to the right of the decimal point. For example,
+ *  a scale of 5 would mean the number is represented with five decimal places,
+ *  so "-3.141592" would be represented as -314159.
+ * @res: Where to write the result of the conversion on success.
+ *
+ * Return: 0 on success, -ERANGE on overflow and -EINVAL on parsing error.
+ */
+noinline
+int kstrtodec64(const char *s, unsigned int scale, s64 *res)
+{
+	u64 tmp;
+	int rv;
+
+	if (s[0] == '-') {
+		rv = _kstrtoudec64(s + 1, scale, &tmp);
+		if (rv < 0)
+			return rv;
+		if ((s64)-tmp > 0)
+			return -ERANGE;
+		*res = -tmp;
+	} else {
+		rv = kstrtoudec64(s, scale, &tmp);
+		if (rv < 0)
+			return rv;
+		if ((s64)tmp < 0)
+			return -ERANGE;
+		*res = tmp;
+	}
+	return 0;
+}
+EXPORT_SYMBOL(kstrtodec64);
+
 /*
  * Since "base" would be a nonsense argument, this open-codes the
  * _from_user helper instead of using the helper macro below.

-- 
2.43.0

