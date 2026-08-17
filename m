From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH 0/3] clk: samsung: Introduce Exynos5515 clock driver
 support
Date: Mon, 17 Aug 2026 11:17:04 +0100
Message-Id: <20260817-for-next-lucky7-clock-v1-0-032e4b229c76@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKDfgmoC/yXMyw6CMBBG4Vchs3YSytX4KoYFHX90hLSmBYMhv
 LsVl9/inI0igiLSJdso4K1RvUswp4zk0bs7WG/JVORFk59NzYMP7LDOPC0yflqWycvIpa1si8Y
 aQUWpfQUMuh7fa/d3XOwTMv9mtO9fH3WFunkAAAA=
X-Change-ID: 20260815-for-next-lucky7-clock-3b4b7e6b1ce4
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 Aiden Isik <aidenisik+git@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1760;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=wK06Xs2Ehefp3TZxBkcPfV9xrG3dW+KVswLp5LqL3mc=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqgt+n7x+JSaql6wYRLNjCbegcsTaeYmm3X/Z3j
 3dToC00kLKJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoLfpwAKCRBJJwGyxHrX
 61bhD/0c1sO3XsVb6kLHOBkdMv24elZQGjDxSfXbEHMrA3gzRJIhgtAHvhDvTngOU8Yz+lMmLmm
 GrbWgLmltl2heHeVNkjw8r3iSonAsZ8eCXwHjq7vGjLTEH1/sr3aDufT65sBjiuxAuHGf7xwm2H
 JYL8K68pwvsdvyc8YRbVERTx58mpKlhRFVsuHd6A2KZRrq+gat+76lVYSE5Kh5CJY6w1GD5Af9W
 R/n3YUEWpMUf2gSmqsVRmrsPeBckjSnLVLis4r1QVNhaq3uPz6L8xBDZo6EVYKFrS6ExCt3n5Ko
 H3ktnZQ0d/upy5+KcWhh812qRw4FMmzh1AoRXbg6q9QqFF87FRQRJfB/BtbnDopimy2gVih5AtY
 gRQ17r/SsH+jDc3dBEQXLdRHVlo4Os9L7MRvHkuhfrGE+xO902Li1cdXSKrf2mOtfvoEUOj7qcL
 gLOxqru+Jta42VssLOPArOn/TlJ20EQ8QGWm9XRmo7zHFqqRkOaqR8dSt0jrhqfoaCKwJQ3Mfow
 PrJGkskySCzJBiIKBmLz6yeD9k11srtO1xaR9fqCIs60xpp0FstRku0P4Gkz8wXHfe0Sh+im7wt
 KtrjvjS+Zq2I3yS+E/FFahbfm2yxU0cnrmt8Xr7v9UklILmjSShyB074O1BXSnVGY1SQ+JA32kO
 7xGramGjXU5nZkg==
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi there,

This patchset introduces clock driver support for the Exynos5515 SoC.

Currently, the following CMU blocks are defined:
- CMU_TOP (handles clocks for all child CMU blocks)
- CMU_PERI (handles clocks for USI, watchdog timer, etc)
- CMU_FSYS (handles clocks for MMC, USB, etc)

This driver support makes use of HWACG (hardware automatic clock gating),
so gates do not need to be manually forced on with CLK_IGNORE_UNUSED or
CLK_IS_CRITICAL. Rather, the hardware handles the clock gating.

Support for more blocks to come as support for the the hardware requiring
them is added.

I am getting some checkpatch warnings telling me to check the MAINTAINERS
file, as new files have been added. I am assuming these can be ignored as
I am not a maintainer, and the whole clock driver and samsung subsystems
already have maintainers listed.

Kind regards,
- Aiden Isik

Signed-off-by: Aiden Isik <aidenisik+git@member.fsf.org>
---
Aiden Isik (3):
      dt-bindings: clock: Add Exynos5515 SoC
      clk: samsung: clk-pll: Add support for pll_309
      clk: samsung: Introduce Exynos5515 clock driver

 .../bindings/clock/samsung,exynos5515-cmu.yaml     |  145 ++
 drivers/clk/samsung/Makefile                       |    1 +
 drivers/clk/samsung/clk-exynos5515.c               | 1485 ++++++++++++++++++++
 drivers/clk/samsung/clk-pll.c                      |   57 +-
 drivers/clk/samsung/clk-pll.h                      |    1 +
 include/dt-bindings/clock/samsung,exynos5515-cmu.h |  191 +++
 6 files changed, 1854 insertions(+), 26 deletions(-)
---
base-commit: acde40ba506aae78633e080b5704d33cf4bc13c6
change-id: 20260815-for-next-lucky7-clock-3b4b7e6b1ce4

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

