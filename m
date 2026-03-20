From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 20 Mar 2026 16:27:27 +0000
Subject: [PATCH v9 2/9] lib: vsprintf: export simple_strntoull() in a safe
 prototype
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-adf41513-iio-driver-v9-2-132f0d076374@analog.com>
References: <20260320-adf41513-iio-driver-v9-0-132f0d076374@analog.com>
In-Reply-To: <20260320-adf41513-iio-driver-v9-0-132f0d076374@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774024051; l=4961;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=y9XuvOW7WnSOw9U6xKx4a7qJToIhm1Kjwj+aTkUEMP0=;
 b=7BHPg3COnAmow6RIibVkXv2I8hJnFf5WiTTNEZgjF+DwrsPlq0Yx97QGmtJHuZW3yAJqbXwvH
 NGDcvO2lErjAS6pRDT6Xu90PlZhbSDwoHRsCVBbU0PtBOavW72Ya7sL
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expose simple_strntoull(), by addressing its FIXME, i.e. its prototype is
slightly changed so that -ERANGE or -EINVAL can be evaluated by the user.
Flow of the function is not changed and error value is returned in the
end. Unsafe internal wrapper is created to reduce amount of changes.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 include/linux/kstrtox.h |  4 ++++
 lib/vsprintf.c          | 59 +++++++++++++++++++++++++++++++++++++++++--------
 2 files changed, 54 insertions(+), 9 deletions(-)

diff --git a/include/linux/kstrtox.h b/include/linux/kstrtox.h
index 6ea897222af1..5e161073121f 100644
--- a/include/linux/kstrtox.h
+++ b/include/linux/kstrtox.h
@@ -148,4 +148,8 @@ extern long simple_strtol(const char *,char **,unsigned int);
 extern unsigned long long simple_strtoull(const char *,char **,unsigned int);
 extern long long simple_strtoll(const char *,char **,unsigned int);
 
+extern ssize_t __must_check simple_strntoull(const char *startp, const char **endp,
+					     unsigned int base, size_t max_chars,
+					     unsigned long long *res);
+
 #endif	/* _LINUX_KSTRTOX_H */
diff --git a/lib/vsprintf.c b/lib/vsprintf.c
index 800b8ac49f53..6fb880f4013b 100644
--- a/lib/vsprintf.c
+++ b/lib/vsprintf.c
@@ -75,25 +75,66 @@ enum hash_pointers_policy {
 };
 static enum hash_pointers_policy hash_pointers_mode __initdata;
 
+/**
+ * simple_strntoull - convert a string to an unsigned long long with a character limit
+ *
+ * @startp: The start of the string
+ * @endp: A pointer to the end of the parsed string will be placed here
+ * @base: The number base to use
+ * @max_chars: The maximum number of characters to parse
+ * @res: Where to write the result of the conversion on success
+ *
+ * Returns amount of processed characters on success, -ERANGE on overflow and
+ * -EINVAL on parsing error.
+ */
 noinline
-static unsigned long long simple_strntoull(const char *startp, char **endp, unsigned int base, size_t max_chars)
+ssize_t simple_strntoull(const char *startp, const char **endp,
+			 unsigned int base, size_t max_chars,
+			 unsigned long long *res)
 {
 	const char *cp;
-	unsigned long long result = 0ULL;
 	size_t prefix_chars;
 	unsigned int rv;
+	ssize_t ret;
 
 	cp = _parse_integer_fixup_radix(startp, &base);
 	prefix_chars = cp - startp;
 	if (prefix_chars < max_chars) {
-		rv = _parse_integer_limit(cp, base, &result, max_chars - prefix_chars);
-		/* FIXME */
+		rv = _parse_integer_limit(cp, base, res, max_chars - prefix_chars);
+		if (rv & KSTRTOX_OVERFLOW)
+			ret = -ERANGE;
+		else if (rv == 0)
+			ret = -EINVAL;
+		else
+			ret = rv + prefix_chars;
 		cp += (rv & ~KSTRTOX_OVERFLOW);
 	} else {
 		/* Field too short for prefix + digit, skip over without converting */
 		cp = startp + max_chars;
+		ret = -EINVAL;
+		*res = 0ULL;
 	}
 
+	if (endp)
+		*endp = cp;
+
+	return ret;
+}
+EXPORT_SYMBOL(simple_strntoull);
+
+/* unsafe_strntoull ignores simple_strntoull() return value and endp const qualifier */
+inline
+static unsigned long long unsafe_strntoull(const char *startp, char **endp,
+					   unsigned int base, size_t max_chars)
+{
+	unsigned long long result;
+	const char *cp;
+
+#pragma GCC diagnostic push
+#pragma GCC diagnostic ignored "-Wunused-result"
+	simple_strntoull(startp, &cp, base, max_chars, &result);
+#pragma GCC diagnostic pop
+
 	if (endp)
 		*endp = (char *)cp;
 
@@ -111,7 +152,7 @@ static unsigned long long simple_strntoull(const char *startp, char **endp, unsi
 noinline
 unsigned long long simple_strtoull(const char *cp, char **endp, unsigned int base)
 {
-	return simple_strntoull(cp, endp, base, INT_MAX);
+	return unsafe_strntoull(cp, endp, base, INT_MAX);
 }
 EXPORT_SYMBOL(simple_strtoull);
 
@@ -132,7 +173,7 @@ EXPORT_SYMBOL(simple_strtoul);
 unsigned long simple_strntoul(const char *cp, char **endp, unsigned int base,
 			      size_t max_chars)
 {
-	return simple_strntoull(cp, endp, base, max_chars);
+	return unsafe_strntoull(cp, endp, base, max_chars);
 }
 EXPORT_SYMBOL(simple_strntoul);
 
@@ -163,9 +204,9 @@ static long long simple_strntoll(const char *cp, char **endp, unsigned int base,
 	 * and the content of *cp is irrelevant.
 	 */
 	if (*cp == '-' && max_chars > 0)
-		return -simple_strntoull(cp + 1, endp, base, max_chars - 1);
+		return -unsafe_strntoull(cp + 1, endp, base, max_chars - 1);
 
-	return simple_strntoull(cp, endp, base, max_chars);
+	return unsafe_strntoull(cp, endp, base, max_chars);
 }
 
 /**
@@ -3670,7 +3711,7 @@ int vsscanf(const char *buf, const char *fmt, va_list args)
 			val.s = simple_strntoll(str, &next, base,
 						field_width >= 0 ? field_width : INT_MAX);
 		else
-			val.u = simple_strntoull(str, &next, base,
+			val.u = unsafe_strntoull(str, &next, base,
 						 field_width >= 0 ? field_width : INT_MAX);
 
 		switch (qualifier) {

-- 
2.43.0

