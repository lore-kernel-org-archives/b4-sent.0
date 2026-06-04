From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 04 Jun 2026 10:58:59 +0100
Subject: [PATCH v16 05/14] lib: kstrtox: add kstrtoudec64() and
 kstrtodec64()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-adf41513-iio-driver-v16-5-1a7d09143bc2@analog.com>
References: <20260604-adf41513-iio-driver-v16-0-1a7d09143bc2@analog.com>
In-Reply-To: <20260604-adf41513-iio-driver-v16-0-1a7d09143bc2@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, linux@analog.com
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780567181; l=5049;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=jkjWKrpazdHOL5wYa0w8oz3c/kjzCgC9AxyBAR3TDZo=;
 b=IeJBj40aZ2O02+nz8TdyIg5lcv58Xbos8qwJU8vinyodSKv8zrcjDOV1QD1j7vDQ5bLXD+80X
 /TqoQqa5IpwAkqXeBPPcZS6k1jPk2LiFfgpYIOalmL9ND+PCm3k7KmB
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
 lib/kstrtox.c           | 104 ++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 107 insertions(+)

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
index cc6869a97bf2..4ea0da1e0753 100644
--- a/lib/kstrtox.c
+++ b/lib/kstrtox.c
@@ -17,6 +17,7 @@
 #include <linux/export.h>
 #include <linux/kstrtox.h>
 #include <linux/math64.h>
+#include <linux/overflow.h>
 #include <linux/types.h>
 #include <linux/uaccess.h>
 
@@ -386,6 +387,109 @@ int kstrtobool(const char *s, bool *res)
 }
 EXPORT_SYMBOL(kstrtobool);
 
+static int _kstrtoudec64(const char *s, unsigned int scale, u64 *res)
+{
+	unsigned int rv_int, rv_frac;
+	u64 _res = 0;
+
+	rv_int = _parse_integer(s, 10, &_res);
+	if (rv_int & KSTRTOX_OVERFLOW)
+		return -ERANGE;
+	s += rv_int;
+
+	if (*s == '.')
+		s++; /* skip decimal point */
+
+	rv_frac = _parse_integer(s, 10, &_res, scale, _res);
+	if (rv_frac & KSTRTOX_OVERFLOW)
+		return -ERANGE;
+	s += rv_frac;
+
+	/*
+	 * Check input beyond rv_int and rv_frac to cover cases like ".5" with
+	 * scale 0, which is considered a valid input, being parsed as 0.
+	 */
+	if (!rv_int && !rv_frac && !isdigit(*s))
+		return -EINVAL;
+
+	while (isdigit(*s)) /* truncate digits */
+		s++;
+
+	if (*s == '\n')
+		s++;
+	if (*s)
+		return -EINVAL;
+
+	if (_res && ((scale - rv_frac) > 19 /* log10(2^64) = 19.26 */ ||
+		     check_mul_overflow(_res, int_pow(10, scale - rv_frac), &_res)))
+		return -ERANGE;
+
+	*res = _res;
+	return 0;
+}
+
+/**
+ * kstrtoudec64() - Convert a string to an unsigned 64-bit scaled decimal value.
+ * @s: The start of the string. The string must be null-terminated, and may also
+ *  include a single newline before its terminating null. The first character
+ *  may also be a plus sign, but not a minus sign.
+ * @scale: The number of digits to the right of the decimal point.
+ * @res: Where to write the result of the conversion on success.
+ *
+ * For example, a scale of 3 with input "123.45" results in 123450. Note that
+ * trailing zeros in the fractional part input to match the scale are not
+ * required. Also, digits beyond the specified scale are ignored.
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
+ * kstrtodec64() - Convert a string to a signed 64-bit scaled decimal value.
+ * @s: The start of the string. The string must be null-terminated, and may also
+ *  include a single newline before its terminating null. The first character
+ *  may also be a plus sign or a minus sign.
+ * @scale: The number of digits to the right of the decimal point.
+ * @res: Where to write the result of the conversion on success.
+ *
+ * For example, a scale of 4 with input "-3.141592" results in -31415. Note
+ * that digits beyond the specified scale are ignored. Also, trailing zeros in
+ * the fractional part input to match the scale are not required.
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

