From: Long Zhao <longzhao@ambarella.com>
Date: Tue, 10 Nov 2026 12:32:38 +0800
Subject: [PATCH v14 13/14] lib/string_choices: add str_rising_falling()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-cv75-gpio-v14-13-e586aad0467a@ambarella.com>
References: <20261110-cv75-gpio-v14-0-e586aad0467a@ambarella.com>
In-Reply-To: <20261110-cv75-gpio-v14-0-e586aad0467a@ambarella.com>
To: Bartosz Golaszewski <brgl@kernel.org>, linux-gpio@vger.kernel.org
Cc: Linus Walleij <linusw@kernel.org>, Michael Walle <mwalle@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, Mika Westerberg <westeri@kernel.org>, 
 devicetree@vger.kernel.org, Long Zhao <longzhao@ambarella.com>, 
 Long Zhao <zl020895@163.com>, linux-kernel@vger.kernel.org, 
 Kees Cook <kees@kernel.org>, linux-hardening@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794285162; l=959;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=wyB82tzUGO+6Su8wsiZ1PCnlZE8C1WY1st0J3Yh3blM=;
 b=ujWayqqQBdxFq5SKSKgXak3dYThVTLR5XGPpoFdHd0TQW3ngeSzAXibkTrG+AXd0Oyf2AbZT7
 yuiDKQz51EzB/SZO0I77rOUkeopsiattzaFAsIuzsW1XVFy6UYFfjmL
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add str_rising_falling() and str_falling_rising() for code that
prints an IRQ trigger edge.

Suggested-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Long Zhao <longzhao@ambarella.com>

---
Cc: Kees Cook <kees@kernel.org>
Cc: linux-hardening@vger.kernel.org
---
 include/linux/string_choices.h | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/include/linux/string_choices.h b/include/linux/string_choices.h
index ee84087d4b26..c3a0360334d6 100644
--- a/include/linux/string_choices.h
+++ b/include/linux/string_choices.h
@@ -65,6 +65,12 @@ static inline const char *str_read_write(bool v)
 }
 #define str_write_read(v)		str_read_write(!(v))
 
+static inline const char *str_rising_falling(bool v)
+{
+	return v ? "rising" : "falling";
+}
+#define str_falling_rising(v)		str_rising_falling(!(v))
+
 static inline const char *str_true_false(bool v)
 {
 	return v ? "true" : "false";

-- 
2.34.1

