From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH v2 0/3] clk: samsung: Introduce Exynos5515 clock driver
 support
Date: Tue, 18 Aug 2026 22:58:34 +0100
Message-Id: <20260818-for-next-lucky7-clock-v2-0-cda0cc80f158@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIrVhGoC/3WNyw6CMBBFf4V07ZC2IFVW/odhYccpVB41LRAI4
 d8FjEuXJ7n3nIUF8pYCy6OFeRptsK7bQJ4ihtWjKwnsc2Mmucz4RZzBOA8dTT00A9azAmwc1pD
 oVCvKtEBK2fZ9ezJ2Orz34sth0C/Cfpfti8qG3vn5CI9i3/0a6k9jFMCBJ5JSLeUVVXZrqdXkY
 xNM7HzJinVdP6YX1Y7RAAAA
X-Change-ID: 20260815-for-next-lucky7-clock-3b4b7e6b1ce4
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Aiden Isik <aidenisik+git@member.fsf.org>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org, 
 Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2585;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=UDNWr97k0IQ0S9m6OO8km8BsOp+W7P/+APdAzwtHDLE=;
 b=owEBbQKS/ZANAwAIAUknAbLEetfrAcsmYgBqhNWSjMY1I95L0VqIOxvnyDYXRcaVDhL/tc/xa
 sCiBeSgrnyJAjMEAAEIAB0WIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCaoTVkgAKCRBJJwGyxHrX
 6/afEACenWvCS6HggKqzTvionUili9AXn0eqVLMpoVEvXucgWGrfDygJS+7bs19W75SU5qtwYpV
 7W4VfHSYyg1J+eSOlZCDzJThDAz9GW2T0r/gArrcHQ10Wc8xifFqFViWDRL2NkOgck8A5uIruCw
 Z8m0Rw7PZ2T2L35B/7E/thKYFyoPMTbazdNHfHsQDi/T4dFOs1RZPlUbq8Xlshcr5Ik8npTe9fZ
 BFbS1h7wp2ZsfbtMtL4aATrD6sHyGe22TXF78aVe3AZpvD1uqSB9BmzvwU0LlBBBfX1YfL0VIUI
 z5Nk2OEmCmLzyNxdAVIRbTLfHJ8meRk31AOcfsc1jyEIMoTJBtkaqDwyC57m7bVs0RAhVdwr7xz
 vLB2Sn+b82Z5nbCuR5AbOD+uO9od3FAApCtMSAJZjfQoKmbCJx8n7WUb423LaFsf/0eFvAMwjIk
 1RPDObNmfJk0uduDiP0XAUzABN1TnmhT1BgI1PMKZDLDRPnUDZA6HLY4xzfUCkyyg6DO86DDOVc
 S9GwDwq7PXLx/0cqfbEa1YyiGr3HvbcYVDDEFwj8lzIKoTesBtI5+xYyiYwi5Mkb8oBSAx8TSpx
 wl9wbzfyeB6s+dlSg+W36ZEX2cYC4Oo6wrWmDt3lal6nt4jz6w4YRUYt8wkuKTahWU66zoem7VS
 /V9G+An7Xh30gHw==
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

Support for more blocks to come as support for the hardware requiring
them is added.

I am getting some checkpatch warnings telling me to check the MAINTAINERS
file, as new files have been added. I am assuming these can be ignored as
I am not a maintainer, and the whole clock driver and samsung subsystems
already have maintainers listed.

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
Changes in v2:
- Fixed accidental revert in clk-pll.c
- Corrected mux parent ordering
- Corrected Signed-off-by tags
- Link to v1: https://patch.msgid.link/20260817-for-next-lucky7-clock-v1-0-032e4b229c76@member.fsf.org

To: Krzysztof Kozlowski <krzk@kernel.org>
To: Sylwester Nawrocki <s.nawrocki@samsung.com>
To: Chanwoo Choi <cw00.choi@samsung.com>
To: Peter Griffin <peter.griffin@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>
To: Michael Turquette <mturquette@baylibre.com>
To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney@redhat.com>
To: Rob Herring <robh@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Aiden Isik <aidenisik+git@member.fsf.org>
Cc: linux-samsung-soc@vger.kernel.org
Cc: linux-clk@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-kernel@vger.kernel.org

---
Aiden Isik (3):
      dt-bindings: clock: Add Exynos5515 SoC
      clk: samsung: clk-pll: Add support for pll_309
      clk: samsung: Introduce Exynos5515 clock driver

 .../bindings/clock/samsung,exynos5515-cmu.yaml     |  145 ++
 drivers/clk/samsung/Makefile                       |    1 +
 drivers/clk/samsung/clk-exynos5515.c               | 1485 ++++++++++++++++++++
 drivers/clk/samsung/clk-pll.c                      |    1 +
 drivers/clk/samsung/clk-pll.h                      |    1 +
 include/dt-bindings/clock/samsung,exynos5515-cmu.h |  191 +++
 6 files changed, 1824 insertions(+)
---
base-commit: acde40ba506aae78633e080b5704d33cf4bc13c6
change-id: 20260815-for-next-lucky7-clock-3b4b7e6b1ce4

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

