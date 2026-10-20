From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 20 Oct 2026 09:27:02 -0300
Subject: [PATCH RFC v3 4/5] iio: core: use kstrtodec64() to parse
 fixed-point values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-e-notation-v3-4-fd385c0fbf65@analog.com>
References: <20261020-e-notation-v3-0-fd385c0fbf65@analog.com>
In-Reply-To: <20261020-e-notation-v3-0-fd385c0fbf65@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792499229; l=6302;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=KFi1I15570KdykwHTdm8zhF2RfVXZbeGepz+AQtmJOI=;
 b=rAdKIZn/40zevfhC8WS9fdi12s/mxFqpsMxCRbXgaHBTFhKCKJNH6bexg8MgwKmR/7/eXKZcL
 XuAlhuGGO2bActlPRMFTCtkuo0lNpjdRNiF0969PnNXPnYfTH6Y5qF3
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the open-coded __iio_str_to_fixpoint() parser with kstrtodec64(),
so sysfs writes of fixed-point values also accept E notation.

The fractional part only keeps the sign when the integer part is zero,
as before. The dB suffix for scale attributes is now handled by a separate
__iio_str_to_fixpoint_units() helper. It strips an optional trailing
newline and the "dB" or " dB" suffix before parsing.

When there is no fractional part (fract_mult == 0, or dec_scale == 0 for
64-bit values), try base-autodetecting kstrtoll() first so hexadecimal
and octal input keeps its meaning ("010" is still 8). Fall back to
kstrtodec64() on -EINVAL to accept E notation.

As a side effect, inputs that used to be rejected for integer-only
attributes are now accepted. An invalid octal number such as "08" is
parsed as decimal 8, and a fractional value such as "1.5" is rounded
to 2.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-core.c | 155 ++++++++++++++++++++--------------------
 1 file changed, 79 insertions(+), 76 deletions(-)

diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index d73f2541375f..ce5391b1ca34 100644
--- a/drivers/iio/industrialio-core.c
+++ b/drivers/iio/industrialio-core.c
@@ -994,77 +994,6 @@ static ssize_t iio_read_channel_info_avail(struct device *dev,
 	}
 }
 
-/**
- * __iio_str_to_fixpoint() - Parse a fixed-point number from a string
- * @str: The string to parse
- * @fract_mult: Multiplier for the first decimal place, should be a power of 10
- * @integer: The integer part of the number
- * @fract: The fractional part of the number
- * @scale_db: True if this should parse as dB
- *
- * Returns:
- * 0 on success, or a negative error code if the string could not be parsed.
- */
-static int __iio_str_to_fixpoint(const char *str, int fract_mult,
-				 int *integer, int *fract, bool scale_db)
-{
-	int i = 0, f = 0;
-	bool integer_part = true, negative = false;
-
-	if (fract_mult == 0) {
-		*fract = 0;
-
-		return kstrtoint(str, 0, integer);
-	}
-
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
-
-	return 0;
-}
-
 /**
  * iio_str_to_fixpoint() - Parse a fixed-point number from a string
  * @str: The string to parse
@@ -1078,10 +1007,76 @@ static int __iio_str_to_fixpoint(const char *str, int fract_mult,
 int iio_str_to_fixpoint(const char *str, int fract_mult,
 			int *integer, int *fract)
 {
-	return __iio_str_to_fixpoint(str, fract_mult, integer, fract, false);
+	s64 dec64;
+	int ret;
+
+	if (fract_mult) {
+		/* scale = ffs(fract_mult) = ffs(10^n) = ffs(2^n * 5^n) = n + 1 */
+		ret = kstrtodec64(str, ffs(fract_mult), &dec64);
+		if (ret)
+			return ret;
+
+		dec64 = div_s64_rem(dec64, fract_mult * 10, fract);
+		/* only carry the sign in fract if the integer is zero */
+		if (dec64)
+			*fract = abs(*fract);
+	} else {
+		/* keep hex/octal support for integers */
+		ret = kstrtoll(str, 0, &dec64);
+		if (ret == -EINVAL)
+			ret = kstrtodec64(str, 0, &dec64);
+		if (ret)
+			return ret;
+
+		*fract = 0;
+	}
+
+	if (dec64 > INT_MAX || dec64 < INT_MIN)
+		return -ERANGE;
+
+	*integer = (int)dec64;
+
+	return 0;
 }
 EXPORT_SYMBOL_GPL(iio_str_to_fixpoint);
 
+/**
+ * __iio_str_to_fixpoint_units() - Parse a fixed-point number with units from a string
+ * @str: The string to parse
+ * @units: The units to expect at the end of the string
+ * @fract_mult: Multiplier for the first decimal place, should be a power of 10
+ * @integer: The integer part of the number
+ * @fract: The fractional part of the number
+ *
+ * Returns:
+ * 0 on success, or a negative error code if the string could not be parsed.
+ */
+static int __iio_str_to_fixpoint_units(const char *str, const char *units,
+				       int fract_mult, int *integer, int *fract)
+{
+	size_t units_len = strlen(units);
+	size_t s_len = strlen(str);
+	const char *dec_str = str;
+	char buf[64];
+
+	if (s_len && str[s_len - 1] == '\n')
+		s_len--;
+
+	if (s_len > units_len &&
+	    !strncmp(str + s_len - units_len, units, units_len)) {
+		s_len -= units_len;
+		if (str[s_len - 1] == ' ')
+			s_len--;
+		if (s_len >= sizeof(buf))
+			return -EINVAL;
+		memcpy(buf, str, s_len);
+		buf[s_len] = '\0';
+		dec_str = buf;
+	}
+
+	return iio_str_to_fixpoint(dec_str, fract_mult, integer, fract);
+}
+
 static ssize_t iio_write_channel_info(struct device *dev,
 				      struct device_attribute *attr,
 				      const char *buf,
@@ -1143,17 +1138,25 @@ static ssize_t iio_write_channel_info(struct device *dev,
 			return -EINVAL;
 		integer = ch;
 	} else if (is_64bit) {
-		if (dec_scale)
+		if (dec_scale) {
 			ret = kstrtodec64(buf, dec_scale, &integer64);
-		else
+		} else {
+			/* keep hex/octal support for integers */
 			ret = kstrtoll(buf, 0, &integer64);
+			if (ret == -EINVAL)
+				ret = kstrtodec64(buf, dec_scale, &integer64);
+		}
 		if (ret)
 			return ret;
 
 		iio_val_s64_decompose(integer64, &integer, &fract);
 	} else {
-		ret = __iio_str_to_fixpoint(buf, fract_mult, &integer, &fract,
-					    scale_db);
+		if (scale_db)
+			ret = __iio_str_to_fixpoint_units(buf, "dB", fract_mult,
+							  &integer, &fract);
+		else
+			ret = iio_str_to_fixpoint(buf, fract_mult, &integer,
+						  &fract);
 		if (ret)
 			return ret;
 	}

-- 
2.43.0

