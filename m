From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Mon, 16 Feb 2026 15:02:17 +0000
Subject: [PATCH v7 2/8] iio: core: add fixed point parsing with 64-bit
 parts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-adf41513-iio-driver-v7-2-b0ed387ab559@analog.com>
References: <20260216-adf41513-iio-driver-v7-0-b0ed387ab559@analog.com>
In-Reply-To: <20260216-adf41513-iio-driver-v7-0-b0ed387ab559@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771254149; l=7786;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=cUyqu8aKsZMI5PrdQO6dpsnsWP9WegoLugfDe7Kurh0=;
 b=AzhsEHLavGUWTEW31BmLAlbhg+BIB3N3l4QcMlSTypZUAFEoUEt5vBNRTxJr+mg/orqSuwszW
 D7fdwWxYl6yD8vrOPI41sC5iUdsVGGmu5oSTyiblwWW6qAe3jE41y9e
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add iio_str_to_fixpoint64() function that leverages simple_strtoull()
to parse numbers from a string.
A helper function __iio_str_to_fixpoint64() replaces
__iio_str_to_fixpoint() implementation, extending its usage for
64-bit fixed-point parsing.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-core.c | 211 ++++++++++++++++++++++++++++++----------
 include/linux/iio/iio.h         |   2 +
 2 files changed, 163 insertions(+), 50 deletions(-)

diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index 3115d59c1372..37e9ed6b659b 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -21,6 +21,7 @@
 #include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/mutex.h>
+#include <linux/overflow.h>
 #include <linux/poll.h>
 #include <linux/property.h>
 #include <linux/sched.h>
@@ -881,6 +882,136 @@ static ssize_t iio_read_channel_info_avail(struct device *dev,
 	}
 }
 
+/**
+ * iio_safe_strntou64() - Parse u64 from string checking for overflow safety
+ * @str: The string to parse
+ * @endp: output pointer to the end parsing position
+ * @result: parsed value
+ * @max_chars: maximum number of digit characters to read
+ *
+ * This function is used in fixed-point parsing and it iterates over a const
+ * char array. It might duplicate behavior of simple_strtoull() or kstrtoull(),
+ * but those have their own limitations:
+ * - simple_strtoull() is not overflow-safe and its usage is discouraged;
+ * - kstrtoull() is safe, but requires termination and it would required a copy
+ *   of the string to a temporary buffer.
+ *
+ * The implementation of this function is similar to _parse_integer_limit()
+ * available in lib/kstrtox.h, but that header/function is not available to be
+ * used in kernel modules. Hence, this implementation may need to change or
+ * removed to reuse a new suitable helper that is properly exposed.
+ *
+ * Returns:
+ * number of parsed characters on success, -ERANGE on overflow
+ */
+static ssize_t iio_safe_strntou64(const char *str, const char **endp,
+				  u64 *result, size_t max_chars)
+{
+	u64 digit, acc = 0;
+	ssize_t idx = 0;
+
+	while (isdigit(str[idx]) && idx < max_chars) {
+		digit = str[idx] - '0';
+		if (unlikely(acc & (~0ull << 60))) {
+			if (check_mul_overflow(acc, 10, &acc) ||
+			    check_add_overflow(acc, digit, &acc))
+				return -ERANGE;
+		} else {
+			acc = acc * 10 + digit;
+		}
+		idx++;
+	}
+
+	*endp = str + idx;
+	*result = acc;
+	return idx;
+}
+
+/**
+ * __iio_str_to_fixpoint64() - Parse a fixed-point number from a string
+ * @str: The string to parse
+ * @fract_mult: Multiplier for the first decimal place, should be a power of 10
+ * @integer: The integer part of the number
+ * @fract: The fractional part of the number
+ * @scale_db: True if this should parse as dB
+ *
+ * This variant uses 64-bit integers for both integer and fractional parts.
+ * Parsed positive values greater than S64_MAX are returned as-is. Parsed
+ * negative values less than S64_MIN are treated as range error, so -ERANGE is
+ * returned.
+ *
+ * Returns:
+ * 0 on success, or a negative error code if the string could not be parsed.
+ */
+static int __iio_str_to_fixpoint64(const char *str, u64 fract_mult,
+				   s64 *integer, s64 *fract, bool scale_db)
+{
+	u64 i = 0, f = 0;
+	int ret, precision = ffs(fract_mult);
+	bool negative = false;
+
+	if (precision > 20) /* ceil(log10(U64_MAX)) = 20 */
+		return -EINVAL;
+
+	if (str[0] == '-') {
+		negative = true;
+		str++;
+	} else if (str[0] == '+') {
+		str++;
+	}
+
+	ret = iio_safe_strntou64(str, &str, &i, SIZE_MAX);
+	if (ret < 0)
+		return ret;
+
+	if (precision && *str == '.') {
+		str++; /* skip decimal point */
+		ret = iio_safe_strntou64(str, &str, &f, precision);
+		if (ret < 0)
+			return ret;
+
+		if (ret < precision) /* scale up */
+			f *= int_pow(10, precision - ret);
+
+		while (isdigit(*str)) /* truncate: ignore further digits */
+			str++;
+	}
+
+	if (!ret)
+		return -EINVAL;
+
+	if (scale_db) {
+		/* Ignore the dB suffix */
+		if (!strncmp(str, " dB", sizeof(" dB") - 1))
+			str += sizeof(" dB") - 1;
+		else if (!strncmp(str, "dB", sizeof("dB") - 1))
+			str += sizeof("dB") - 1;
+	}
+
+	if (*str == '\n')
+		str++;
+
+	if (*str != '\0')
+		return -EINVAL;
+
+	if (negative) {
+		if (i) {
+			if (i > (u64)S64_MIN)
+				return -ERANGE;
+			i = -i;
+		} else {
+			if (f > (u64)S64_MIN)
+				return -ERANGE;
+			f = -f;
+		}
+	}
+
+	*integer = i;
+	*fract = f;
+
+	return 0;
+}
+
 /**
  * __iio_str_to_fixpoint() - Parse a fixed-point number from a string
  * @str: The string to parse
@@ -895,63 +1026,43 @@ static ssize_t iio_read_channel_info_avail(struct device *dev,
 static int __iio_str_to_fixpoint(const char *str, int fract_mult,
 				 int *integer, int *fract, bool scale_db)
 {
-	int i = 0, f = 0;
-	bool integer_part = true, negative = false;
+	s64 integer64, fract64;
+	int ret;
 
-	if (fract_mult == 0) {
-		*fract = 0;
+	ret = __iio_str_to_fixpoint64(str, fract_mult, &integer64, &fract64,
+				      scale_db);
+	if (ret)
+		return ret;
 
-		return kstrtoint(str, 0, integer);
-	}
+	if (integer64 < INT_MIN || integer64 > UINT_MAX ||
+	    fract64 < INT_MIN || fract64 > UINT_MAX)
+		return -ERANGE;
 
-	if (str[0] == '-') {
-		negative = true;
-		str++;
-	} else if (str[0] == '+') {
-		str++;
-	}
-
-	while (*str) {
-		if ('0' <= *str && *str <= '9') {
-			if (integer_part) {
-				i = i * 10 + *str - '0';
-			} else {
-				f += fract_mult * (*str - '0');
-				fract_mult /= 10;
-			}
-		} else if (*str == '\n') {
-			if (*(str + 1) == '\0')
-				break;
-			return -EINVAL;
-		} else if (!strncmp(str, " dB", sizeof(" dB") - 1) && scale_db) {
-			/* Ignore the dB suffix */
-			str += sizeof(" dB") - 1;
-			continue;
-		} else if (!strncmp(str, "dB", sizeof("dB") - 1) && scale_db) {
-			/* Ignore the dB suffix */
-			str += sizeof("dB") - 1;
-			continue;
-		} else if (*str == '.' && integer_part) {
-			integer_part = false;
-		} else {
-			return -EINVAL;
-		}
-		str++;
-	}
-
-	if (negative) {
-		if (i)
-			i = -i;
-		else
-			f = -f;
-	}
-
-	*integer = i;
-	*fract = f;
+	*integer = integer64;
+	*fract = fract64;
 
 	return 0;
 }
 
+/**
+ * iio_str_to_fixpoint64() - Parse a fixed-point number from a string
+ * @str: The string to parse
+ * @fract_mult: Multiplier for the first decimal place, should be a power of 10
+ * @integer: The integer part of the number
+ * @fract: The fractional part of the number
+ *
+ * This variant uses 64-bit integers for both integer and fractional parts.
+ *
+ * Returns:
+ * 0 on success, or a negative error code if the string could not be parsed.
+ */
+int iio_str_to_fixpoint64(const char *str, u64 fract_mult, s64 *integer,
+			  s64 *fract)
+{
+	return __iio_str_to_fixpoint64(str, fract_mult, integer, fract, false);
+}
+EXPORT_SYMBOL_GPL(iio_str_to_fixpoint64);
+
 /**
  * iio_str_to_fixpoint() - Parse a fixed-point number from a string
  * @str: The string to parse
diff --git a/include/linux/iio/iio.h b/include/linux/iio/iio.h
index a9ecff191bd9..cb30d153465a 100644
--- a/include/linux/iio/iio.h
+++ b/include/linux/iio/iio.h
@@ -1055,6 +1055,8 @@ int iio_active_scan_mask_index(struct iio_dev *indio_dev);
 
 ssize_t iio_format_value(char *buf, unsigned int type, int size, int *vals);
 
+int iio_str_to_fixpoint64(const char *str, u64 fract_mult, s64 *integer,
+			  s64 *fract);
 int iio_str_to_fixpoint(const char *str, int fract_mult, int *integer,
 	int *fract);
 

-- 
2.43.0

