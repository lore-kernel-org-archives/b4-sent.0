From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 26 Jun 2026 10:34:51 +0100
Subject: [PATCH] lib: kstrtox: missing parameter description doc fixup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260626-b4-parse-integer-doc-fixup-v1-1-25cc495af36f@analog.com>
X-B4-Tracking: v=1; b=H4sIALpHPmoC/x2MSQqAMAwAvyI5G9CiFfyKeOgSNZdaUhVB/LvB4
 8zAPFBImAqM1QNCFxfek0JbVxA2l1ZCjspgGmMbayz6DrOToj4dtJJg3AMufJ8ZrTeuD3EYXOt
 BB1lIwz+f5vf9AItxv4FsAAAA
X-Change-ID: 20260626-b4-parse-integer-doc-fixup-6b2a5cd77a1b
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, Andy Shevchenko <andy@kernel.org>, 
 kernel test robot <lkp@intel.com>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782466534; l=1254;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=0zsOBTI42P3g2kfdlM7nlhHBpm6s1YXvENs9QIOY8g8=;
 b=kK4WFPi/iswOySotpz3urFxegMNCrRexLGmrD0b1TnoVUK2JpJQSbSNrT+/enC8Ego6OAbOZM
 1JIyq+isd6AAIjJ+lhjv/rOrPS6SDPYl3RynfiOHPzNKjpiCKFaDufM
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add description string for 'init' parameter.

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202606250230.etPGuolf-lkp@intel.com/
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
Recent change causing a build warning. This is to be a fixup
patch amended to:

https://git.kernel.org/pub/scm/linux/kernel/git/jic23/iio.git/commit/?h=testing&id=521b4ae3b5a47cf4ef5826016eecde08e8740bef
---
 lib/kstrtox.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/lib/kstrtox.c b/lib/kstrtox.c
index 17357c4ae52c..bac1c057e1b0 100644
--- a/lib/kstrtox.c
+++ b/lib/kstrtox.c
@@ -46,6 +46,7 @@ const char *_parse_integer_fixup_radix(const char *s, unsigned int *base)
  * @base: Radix
  * @p: Where to store result
  * @max_chars: Maximum amount of characters to convert
+ * @init: Initial value of the multiply-accumulate result
  *
  * Convert non-negative integer string representation in explicitly given
  * radix to an integer. If overflow occurs, value at @p is set to ULLONG_MAX.

---
base-commit: 7667a80340e99fd45357d0c90ae05813b01bbfef
change-id: 20260626-b4-parse-integer-doc-fixup-6b2a5cd77a1b

Best regards,
-- 
Rodrigo Alencar <rodrigo.alencar@analog.com>

