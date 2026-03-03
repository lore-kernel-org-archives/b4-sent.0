From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 03 Mar 2026 13:27:07 +0000
Subject: [PATCH v8 02/10] lib: kstrtox: add kstrntoull() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260303-adf41513-iio-driver-v8-2-8dd2417cc465@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772544443; l=3621;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=QOA2ebXlCGOu4rEF7LtCPczO4bNdBpAyoo2OhH/870A=;
 b=wV3bcB78rfX1cS1C53uRVYeEZWLj9IlYYYqbKdCGwFXsZ9gp+BQgGEIz+SeKEFkki+7v3FBtC
 yQX8C5gQY2JD/Sxq364rygWsMEnB7CNS5Gh/P9MyRdSWPl4nE2Gmg3A
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add kstrntoull() function, which converts a string to an ULL with a max
character limit. The function is an alternative integer parsing function
that does not require a null-terminated string. It becomes a better option
over simple_strtoull() or kstrtoull() when parsing integers from a buffer
with custom delimiters without having to create temporary copies.
The function is consumed inside the implementation _kstrtoull(),
promoting reuse.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 include/linux/kstrtox.h |  3 +++
 lib/kstrtox.c           | 47 +++++++++++++++++++++++++++++++++++++++++++----
 2 files changed, 46 insertions(+), 4 deletions(-)

diff --git a/include/linux/kstrtox.h b/include/linux/kstrtox.h
index 6ea897222af1..49a6102b8e15 100644
--- a/include/linux/kstrtox.h
+++ b/include/linux/kstrtox.h
@@ -9,6 +9,9 @@
 int __must_check _kstrtoul(const char *s, unsigned int base, unsigned long *res);
 int __must_check _kstrtol(const char *s, unsigned int base, long *res);
 
+ssize_t __must_check kstrntoull(const char *s, unsigned int base,
+				unsigned long long *res, size_t max_chars);
+
 int __must_check kstrtoull(const char *s, unsigned int base, unsigned long long *res);
 int __must_check kstrtoll(const char *s, unsigned int base, long long *res);
 
diff --git a/lib/kstrtox.c b/lib/kstrtox.c
index bdde40cd69d7..202ecc058284 100644
--- a/lib/kstrtox.c
+++ b/lib/kstrtox.c
@@ -93,17 +93,56 @@ unsigned int _parse_integer(const char *s, unsigned int base, unsigned long long
 	return _parse_integer_limit(s, base, p, INT_MAX);
 }
 
-static int _kstrtoull(const char *s, unsigned int base, unsigned long long *res)
+/**
+ * kstrntoull - convert a string to an unsigned long long with a maximum
+ * character limit
+ * @s: The start of the string. The string does not need to be null-terminated.
+ * The first character cannot be a sign.
+ * @base: The number base to use. The maximum supported base is 16. If base is
+ *  given as 0, then the base of the string is automatically detected with the
+ *  conventional semantics - If it begins with 0x the number will be parsed as a
+ *  hexadecimal (case insensitive), if it otherwise begins with 0, it will be
+ *  parsed as an octal number. Otherwise it will be parsed as a decimal.
+ * @res: Where to write the result of the conversion.
+ * @max_chars: The maximum number of characters to convert.
+ *
+ * Conversion stops when the maximum number of characters is reached or a
+ * non-digit character is encountered.
+ *
+ * Returns the number of characters consumed on success, -ERANGE on overflow and
+ * -EINVAL on invalid input. Return code must be checked.
+ */
+noinline
+ssize_t kstrntoull(const char *s, unsigned int base, unsigned long long *res,
+		   size_t max_chars)
 {
-	unsigned long long _res;
+	const char *cp;
+	size_t prefix_cnt;
 	unsigned int rv;
 
-	s = _parse_integer_fixup_radix(s, &base);
-	rv = _parse_integer(s, base, &_res);
+	cp = _parse_integer_fixup_radix(s, &base);
+	prefix_cnt = cp - s;
+	if (prefix_cnt >= max_chars)
+		return -EINVAL;
+
+	rv = _parse_integer_limit(cp, base, res, max_chars - prefix_cnt);
 	if (rv & KSTRTOX_OVERFLOW)
 		return -ERANGE;
 	if (rv == 0)
 		return -EINVAL;
+
+	return prefix_cnt + rv;
+}
+EXPORT_SYMBOL(kstrntoull);
+
+static int _kstrtoull(const char *s, unsigned int base, unsigned long long *res)
+{
+	unsigned long long _res;
+	ssize_t rv;
+
+	rv = kstrntoull(s, base, &_res, INT_MAX);
+	if (rv < 0)
+		return rv;
 	s += rv;
 	if (*s == '\n')
 		s++;

-- 
2.43.0

