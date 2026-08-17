From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH 0/2] watchdog: Add Exynos5515 watchdog timer support
Date: Mon, 17 Aug 2026 11:22:51 +0100
Message-Id: <20260817-for-next-lucky7-watchdog-v1-0-a14370e20b92@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPvggmoC/yXMQQ6CMBBA0auQWTsJU4OgVzEuaJnCqGlNWxRCu
 DsVlm/x/wKRg3CEW7FA4K9E8S6DTgWYoXU9o3TZoEp1KRuq0PqAjqeE79G85hp/bTJD53s8K21
 1RXQlS5DzT2Ar076+Pw7HUT/ZpP8P1nUDRgYGxHwAAAA=
X-Change-ID: 20260815-for-next-lucky7-watchdog-32bfb51191f1
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Aiden Isik <aidenisik+git@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1332;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=0VUxeKXCA+Jwc4fUkZKqZlpIjFFuiY5z4ib6VJ1O9P0=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqguEVSBtciqsRvU0ly2IDdyKzgPzAKZC0FqZcW
 N/b0U0n7hWJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoLhFQAKCRBJJwGyxHrX
 62aQD/90D+3JrG0uou0nGOngl9mATJAgpQMpDYCke6u9agd8cy2w3Cd1UA1J22TVpe5yBIzVWNX
 PM3vPDtbkzmY3hIJOCaRYK0Sm3305YuILFeeBtcWOWQyv3TwoOdp7MEgR5uO6HOC8qAbdm8L0ZT
 FbcgNSlWN6IDfeWY23l+O1YrYpFJOhpZmwdCZWP6nVKveg+v1v9H1AmSQhk2L91HAc54/eR6TGZ
 sczDF3Z5iNeLfYfY1wtdi9DScfb7/iUFIPrljwcKyYHkbDd3+tXSoKhov1F8V9vEmMSxk2RUlFX
 +zl/LWp8xgueCqUbLpDYVWOjnayBbnxHEBshZO8qMqSFLsAGLivnSm/Aoxz/noyimv6u8GMa7XX
 va2XWZqWISkPunb42+rW73NjTZFCqKS7pNDCahkQjiywEjGyXQJKn07e+5prosNrqfVOf3fDXfX
 YZGHV1P7vvJvvZkeGb24AQ/qrQD+Cbfa1HDUMmMV8u2uX3qofwgnfarjN/cML/qNJM3eHn9SKd6
 AI5JnJnRVkrSG/i5Q4/Xq3QYqlsMpzyVqiqDqUgfvk6itQNzPXaTeZwo5G3fvDp9mKkAcJVD/oE
 yrtQAYI/KJ/+8u2PkBOOH+UGB7YSKAtpHmyk1Wfto7NXW5HXGiHcMKcwC0iASUW4ZpkxkzjXOCk
 4U9gLqwQNE1sV9g==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi there,

This patchset adds support for the Exynos5515 SoC's watchdog timer
to the S3C2410 watchdog timer driver.

There is one checkpatch warning for this patchset:

> -------------------------------------------------------------------------
> Commit 8f4ec3a9b89b ("watchdog: s3c2410_wdt: Add exynos5515-wdt compatibl
> -------------------------------------------------------------------------
> WARNING: Avoid unnecessary line continuations
> #26: FILE: drivers/watchdog/s3c2410_wdt.c:240:
> +       .quirks = QUIRK_HAS_WTCLRINT_REG | QUIRK_HAS_PMU_MASK_RESET | \

Which seems to be erroneous: this line continuation is necessary
(and is done by every other existing entry).

Kind regards,
- Aiden Isik

Signed-off-by: Aiden Isik <aidenisik+git@member.fsf.org>
---
Aiden Isik (2):
      dt-bindings: watchdog: samsung-wdt: Add exynos5515-wdt compatible
      watchdog: s3c2410_wdt: Add exynos5515-wdt compatible data

 .../devicetree/bindings/watchdog/samsung-wdt.yaml  | 22 +++++++++++++++++++++-
 drivers/watchdog/s3c2410_wdt.c                     | 12 ++++++++++++
 2 files changed, 33 insertions(+), 1 deletion(-)
---
base-commit: acde40ba506aae78633e080b5704d33cf4bc13c6
change-id: 20260815-for-next-lucky7-watchdog-32bfb51191f1

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

