From: Alexandru Chimac <alex@chimac.ro>
Subject: [PATCH v2 0/5] clk: samsung: Introduce support for Exynos9610
 clocks
Date: Thu, 16 Jul 2026 20:14:54 +0300
Message-Id: <20260716-exynos9610-clocks-v2-0-c13ce8ef1861@chimac.ro>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22OSw6CMBBAr0Jm7Zi2fGXlPQyLUgdplFbbSiCEu
 1vBpcs3k/dmFvDkNHmokwUcjdprayKIQwKql+ZGqK+RQTBRsJLnSNNsrD8VnKF6WHX3KCshM5W
 JTsgUovd01Olpa16anR293jEd9iG00hMqOww61ImhKeAvX8BX6LUP1s3bTyPfjLjP2env+ZEjw
 7QreM6EaHlZnVWvB6mOzkKzrusHHo8JseMAAAA=
X-Change-ID: 20260715-exynos9610-clocks-a82a4c42f2a3
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Alexandru Chimac <alex@chimac.ro>, Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784222102; l=1530;
 i=alex@chimac.ro; s=20250914; h=from:subject:message-id;
 bh=X1Fos9kKkDy2zbBIakV8ZOCZ9DAxzYNhdLDz5n9bfc8=;
 b=oe/N4QjcY7RjD90vVYaAfx7OOis561uo4+mAZaidGEwmABp72QNciImjaCS4G+mDFyOSXERlo
 MCwY7fXqfuAAEyE43juQm34lCyjnH1AGWI27t2iG4NioxCFnI2S7Bkn
X-Developer-Key: i=alex@chimac.ro; a=ed25519;
 pk=OKD+X09b7uEsyw05zyuqq14SLGg8B/X4xey5tJeYCig=
X-Endpoint-Received: by B4 Relay for alex@chimac.ro/20250914 with auth_id=877
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds partial support for clocks (no SHUB, MIF, ISP, VIPX
or MFC) on Exynos9610.

---
Changes in v2:
- Remove device tree node commits
- Fix binding formatting / example build issues
- Enable auto clock gating
- Add USB CMU
- Remove CPUCL1 CMU (PLL initialization fails with ACG enabled)
- Update maintainer e-mail, copyright year

- Link to v1: https://lore.kernel.org/r/20250915-exynos9610-clocks-v1-0-3f615022b178@chimac.ro

---
Alexandru Chimac (5):
      dt-bindings: clock: samsung: Add Exynos9610 CMU bindings
      dt-bindings: soc: exynos-sysreg: Add Exynos9610 SYSREG bindings
      clk: samsung: clk-pll: Add support for pll_1061x
      clk: samsung: Introduce Exynos9610 clock controller driver
      MAINTAINERS: Add entry for Exynos9610

 .../bindings/clock/samsung,exynos9610-cmu.yaml     |  335 ++
 .../soc/samsung/samsung,exynos-sysreg.yaml         |   20 +
 MAINTAINERS                                        |    9 +
 drivers/clk/samsung/Makefile                       |    1 +
 drivers/clk/samsung/clk-exynos9610.c               | 3716 ++++++++++++++++++++
 drivers/clk/samsung/clk-pll.c                      |   29 +-
 drivers/clk/samsung/clk-pll.h                      |    1 +
 include/dt-bindings/clock/samsung,exynos9610-cmu.h |  722 ++++
 8 files changed, 4826 insertions(+), 7 deletions(-)
---
base-commit: ce28329fef089fc63dbaadcc4c1fbf9c287e57e0
change-id: 20260715-exynos9610-clocks-a82a4c42f2a3

Best regards,
-- 
Alexandru Chimac <alex@chimac.ro>

