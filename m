From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH v3 0/2] watchdog: Add Exynos5515 watchdog timer support
Date: Tue, 18 Aug 2026 19:03:16 +0100
Message-Id: <20260818-for-next-lucky7-watchdog-v3-0-2912bd122c57@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGSehGoC/32N0Q6CIBhGX6VxHQ4QRbvqPVoXgj9KpTRA0znfP
 bW1tbW6PNv3nTMhD86AR4fdhBz0xhvbLhDvd0jVRVsBNuXCiBGWkowmWFuHWxgCvnXqOgr8KIK
 qS1vhmEktE0pzqila7ncH2gyb+nR+se/kBVRYfeuiNj5YN27tnq67d0b8zvQUE1xQHgsCjMicH
 RtoJLhIex1ZV6G11bNPW/bHxhZbKnisucgLLvSXbZ7nJw9BaFMlAQAA
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
 Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2292;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=8HrdoPzCe8M0K/kkdyBGtCSmfZLfdSCynj06k0MN/yw=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhJ5qDXxwECM3vqTnOkqyEwFfgqeEcIY8Lz5Sj
 56zeQpl9qCJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoSeagAKCRBJJwGyxHrX
 68wvD/9K1UE+6Xx6yiiz86LOMAbT+nK3nUF/FmuEjTVEGPmFsGz6WBfnSESJynM+wMcaSNXWb+l
 ChR1ItFfgjaQDUvWbfCUOOkW9oa4HWP0fUyavot8vudQKuDLus8VmmBobrEZO+03EWupLL9XYmv
 n+AqpBStCIhoPd5sVk+jux1ygvVr9wc9Va4fHZo/eY/m3Wb0nphLrw2k+zY8AD8vZCC4h8XV3r2
 YLJ5ki91OM+QGc66+XJ7p+oOkIdrxcZbQIwtINxqRB7GNmo6Ln4PDwfPRlOBN4Ds9juSnICJ3oB
 DVdRoY7OGMfQOInzH9SxxRD6SwgF5dwSEXbU6Kp7vi0ojku8wU6JYAtjVd58612lAmuqCv96UKW
 2nfTbPJFSoip6kjdQLKOaG+2xZlrYJKHNfrzLJ8053QFslU3/GHosv5Oe55m9nrmnafnMvWPHYN
 sLywFDRZS7MaTzTcJIzbFthUI5rqmfr9uuLJLKICA2OujHI1/n22aZ0RezKnfyeaLRfmdrbzEkf
 llMbpgbp/cnwxEOOUwx7kLoI1iGpkVdrO7x4DBi3BsCsC3uNnhPWMU3kwLiHn9/LcT+5VPhKqrf
 ltyG9zTWBdzoknvWDZFud1plPQhCDn8QcsMbZKP6y287LbkNiZQ2embLt7+Z4l/vxTuGbDDmc2E
 5nY1gdjXB9wKNZA==
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

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
Changes in v3:
- Set reset_mask_inv to true
- Remove erroneous QUIRK_HAS_PMU_AUTO_DISABLE flag
- Link to v2: https://patch.msgid.link/20260818-for-next-lucky7-watchdog-v2-0-6743f479a47f@member.fsf.org

Changes in v2:
- Add samsung,cluster-index: false to documentation
- Remove SoC comment from documentation
- Correct signed-off-by tag in commits
- Link to v1: https://patch.msgid.link/20260817-for-next-lucky7-watchdog-v1-0-a14370e20b92@member.fsf.org

To: Wim Van Sebroeck <wim@linux-watchdog.org>
To: Guenter Roeck <linux@roeck-us.net>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Peter Griffin <peter.griffin@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>
Cc: linux-watchdog@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-samsung-soc@vger.kernel.org

---
Aiden Isik (2):
      dt-bindings: watchdog: samsung-wdt: Add exynos5515-wdt compatible
      watchdog: s3c2410_wdt: Add exynos5515-wdt compatible data

 .../devicetree/bindings/watchdog/samsung-wdt.yaml  | 23 +++++++++++++++++++++-
 drivers/watchdog/s3c2410_wdt.c                     | 12 +++++++++++
 2 files changed, 34 insertions(+), 1 deletion(-)
---
base-commit: acde40ba506aae78633e080b5704d33cf4bc13c6
change-id: 20260815-for-next-lucky7-watchdog-32bfb51191f1

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

