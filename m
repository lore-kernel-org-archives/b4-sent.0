From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 04 Jun 2026 10:59:01 +0100
Subject: [PATCH v16 07/14] lib: math: div64: add div64_s64_rem()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-adf41513-iio-driver-v16-7-1a7d09143bc2@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780567181; l=2327;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=ROKa5iAD0w5bgrXddKrko8IjoFXS2V0nXvPl5DFoZoI=;
 b=2iEc8P2m9zI2rqyUKhM1ARNBTEtG0NbMD7xgrFgqOEyAemqJqxLvDZBFO78qLgf2fMsmvYOBP
 ONLU5IzgHIxBB7tyZVc85ZpKMgUP1OyUu07vEez5TY+MRBAMCFRzZ8O
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add div64_s64_rem() function, with 32-bit implementation that uses
div64_u64_rem() and a branchless approach to resolve the sign of the
remainder and quotient (negation in two's complement).

Reviewed-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 include/linux/math64.h | 18 ++++++++++++++++++
 lib/math/div64.c       | 15 +++++++++++++++
 2 files changed, 33 insertions(+)

diff --git a/include/linux/math64.h b/include/linux/math64.h
index cc305206d89f..99189410d4bb 100644
--- a/include/linux/math64.h
+++ b/include/linux/math64.h
@@ -57,6 +57,20 @@ static inline u64 div64_u64_rem(u64 dividend, u64 divisor, u64 *remainder)
 	return dividend / divisor;
 }
 
+/**
+ * div64_s64_rem - signed 64bit divide with 64bit divisor and remainder
+ * @dividend: signed 64bit dividend
+ * @divisor: signed 64bit divisor
+ * @remainder: pointer to signed 64bit remainder
+ *
+ * Return: sets ``*remainder``, then returns dividend / divisor
+ */
+static inline s64 div64_s64_rem(s64 dividend, s64 divisor, s64 *remainder)
+{
+	*remainder = dividend % divisor;
+	return dividend / divisor;
+}
+
 /**
  * div64_u64 - unsigned 64bit divide with 64bit divisor
  * @dividend: unsigned 64bit dividend
@@ -102,6 +116,10 @@ extern s64 div_s64_rem(s64 dividend, s32 divisor, s32 *remainder);
 extern u64 div64_u64_rem(u64 dividend, u64 divisor, u64 *remainder);
 #endif
 
+#ifndef div64_s64_rem
+extern s64 div64_s64_rem(s64 dividend, s64 divisor, s64 *remainder);
+#endif
+
 #ifndef div64_u64
 extern u64 div64_u64(u64 dividend, u64 divisor);
 #endif
diff --git a/lib/math/div64.c b/lib/math/div64.c
index d1e92ea24fce..0b10ded09a9b 100644
--- a/lib/math/div64.c
+++ b/lib/math/div64.c
@@ -158,6 +158,21 @@ u64 div64_u64(u64 dividend, u64 divisor)
 EXPORT_SYMBOL(div64_u64);
 #endif
 
+#ifndef div64_s64_rem
+s64 div64_s64_rem(s64 dividend, s64 divisor, s64 *remainder)
+{
+	s64 quot, t, rem;
+
+	quot = div64_u64_rem(abs(dividend), abs(divisor), (u64 *)&rem);
+	t = dividend >> 63;
+	*remainder = (rem ^ t) - t;
+	t = (dividend ^ divisor) >> 63;
+
+	return (quot ^ t) - t;
+}
+EXPORT_SYMBOL(div64_s64_rem);
+#endif
+
 #ifndef div64_s64
 s64 div64_s64(s64 dividend, s64 divisor)
 {

-- 
2.43.0

