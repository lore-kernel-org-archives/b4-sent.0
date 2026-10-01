From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 01 Oct 2026 12:34:58 -0300
Subject: [PATCH RFC 3/3] iio: core: use kstrtodec64() to parse fixed-point
 values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-e-notation-v1-3-75187bf06c10@analog.com>
References: <20261001-e-notation-v1-0-75187bf06c10@analog.com>
In-Reply-To: <20261001-e-notation-v1-0-75187bf06c10@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Andrew Morton <akpm@linux-foundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790868966; l=6669;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=vZlhPBlHph5MJsiQtE5ZSwDyo8lXzlfhWg5+fE85ugo=;
 b=IQeCPjeRiRS1K2bo9DZOGkuJr3y0JQ+79PdAV6wxq+8+lbPTTw8IM5B4p0x8WKhPoXpbaDbiJ
 fdD6pFClZS/BLY8fuq3vRYxeFIiaGS+YaxSG8JoUdv3qqgHIi+/MN7p
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the open-coded __iio_str_to_fixpoint() parser with
kstrtodec64(), so sysfs writes of fixed-point values also accept E
notation. The scale passed to kstrtodec64() comes from fract_mult, which
is a power of ten, 10^n, so ffs(10^n) = n + 1. The fractional part only
keeps the sign when the integer part is zero, as before.

The dB suffix for scale attributes is now handled by a separate
iio_str_to_fixpoint_units() helper. It strips an optional trailing
newline and the "dB" or " dB" suffix before parsing.

When there is no fractional part (fract_mult == 0, or dec_scale == 0 for
64-bit values), try base-autodetecting kstrtoll() first so hexadecimal
and octal input keeps its meaning ("010" is still 8). Fall back to
kstrtodec64() on -EINVAL to accept E notation.

As a side effect, inputs that used to be rejected for integer-only
attributes are now accepted. An invalid octal number such as "08" is
parsed as decimal 8, and a fractional value such as "1.5" is truncated
to 1, matching how kstrtodec64() drops digits beyond the requested
scale.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/industrialio-core.c | 155 ++++++++++++++++++++--------------------
 1 file changed, 76 insertions(+), 79 deletions(-)

diff --git a/drivers/iio/industrialio-core.c b/drivers/iio/industrialio-core.c
index d73f2541375f..b22d2f427bbd 100644
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
@@ -1075,13 +1004,76 @@ static int __iio_str_to_fixpoint(const char *str, int fract_mult,
  * Returns:
  * 0 on success, or a negative error code if the string could not be parsed.
  */
-int iio_str_to_fixpoint(const char *str, int fract_mult,
-			int *integer, int *fract)
+int iio_str_to_fixpoint(const char *str, int fract_mult, int *integer,
+			int *fract)
 {
-	return __iio_str_to_fixpoint(str, fract_mult, integer, fract, false);
+	/* fract_mult = 10^n, so ffs(10^n) = ffs(2^n * 5^n) = n + 1 */
+	unsigned int scale = ffs(fract_mult);
+	s64 dec64;
+	int ret;
+
+	ret = -EINVAL;
+	if (!fract_mult) /* keep hex/octal support for integers */
+		ret = kstrtoll(str, 0, &dec64);
+	if (ret == -EINVAL)
+		ret = kstrtodec64(str, scale, &dec64);
+	if (ret)
+		return ret;
+
+	if (fract_mult > 0)
+		dec64 = div_s64_rem(dec64, fract_mult * 10, fract);
+	else
+		*fract = 0;
+
+	if (dec64 > INT_MAX || dec64 < INT_MIN)
+		return -ERANGE;
+
+	*integer = (int)dec64;
+	/* only carry the sign in the fractional part if the integer is zero */
+	if (*integer)
+		*fract = abs(*fract);
+
+	return 0;
 }
 EXPORT_SYMBOL_GPL(iio_str_to_fixpoint);
 
+/**
+ * iio_str_to_fixpoint_units() - Parse a fixed-point number with units from a string
+ * @str: The string to parse
+ * @units: The units to expect at the end of the string
+ * @fract_mult: Multiplier for the first decimal place, should be a power of 10
+ * @integer: The integer part of the number
+ * @fract: The fractional part of the number
+ *
+ * Returns:
+ * 0 on success, or a negative error code if the string could not be parsed.
+ */
+static int iio_str_to_fixpoint_units(const char *str, const char *units,
+				     int fract_mult, int *integer, int *fract)
+{
+	size_t units_len = strlen(units);
+	size_t num_len = strlen(str);
+	const char *dec_str = str;
+	char buf[64];
+
+	if (num_len && str[num_len - 1] == '\n')
+		num_len--;
+
+	if (num_len > units_len &&
+	    !strncmp(str + num_len - units_len, units, units_len)) {
+		num_len -= units_len;
+		if (str[num_len - 1] == ' ')
+			num_len--;
+		if (num_len >= sizeof(buf))
+			return -EINVAL;
+		memcpy(buf, str, num_len);
+		buf[num_len] = '\0';
+		dec_str = buf;
+	}
+
+	return iio_str_to_fixpoint(dec_str, fract_mult, integer, fract);
+}
+
 static ssize_t iio_write_channel_info(struct device *dev,
 				      struct device_attribute *attr,
 				      const char *buf,
@@ -1143,17 +1135,22 @@ static ssize_t iio_write_channel_info(struct device *dev,
 			return -EINVAL;
 		integer = ch;
 	} else if (is_64bit) {
-		if (dec_scale)
-			ret = kstrtodec64(buf, dec_scale, &integer64);
-		else
+		ret = -EINVAL;
+		if (!dec_scale) /* keep hex/octal support for integers */
 			ret = kstrtoll(buf, 0, &integer64);
+		if (ret == -EINVAL)
+			ret = kstrtodec64(buf, dec_scale, &integer64);
 		if (ret)
 			return ret;
 
 		iio_val_s64_decompose(integer64, &integer, &fract);
 	} else {
-		ret = __iio_str_to_fixpoint(buf, fract_mult, &integer, &fract,
-					    scale_db);
+		if (scale_db)
+			ret = iio_str_to_fixpoint_units(buf, "dB", fract_mult,
+							&integer, &fract);
+		else
+			ret = iio_str_to_fixpoint(buf, fract_mult, &integer,
+						  &fract);
 		if (ret)
 			return ret;
 	}

-- 
2.43.0

