From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v3 0/3] pinctrl: tegra: Add Tegra186 pinmux driver
Date: Tue, 12 Aug 2025 16:24:39 -0500
Message-Id: <20250812-tegra186-pinctrl-v3-0-115714eeecb1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABexm2gC/23OSw6DIBCA4asY1qWBAVG76j2aLhQGJfEVMKSN8
 e5Fu2iTdvlPMt/MSgJ6h4FcspV4jC64aUwhThnRXT22SJ1JTYBBzgQr6YKtr3mp6OxGvfieqpx
 b2zQNllyRtDZ7tO5xkLd76s6FZfLP40Lk+/SNSah+scgpowWALrQEUUm8tkPt+rOeBrJjET6A+
 vdNhATkDIzkViAa8w1s2/YCxaQ4DvEAAAA=
X-Change-ID: 20250308-tegra186-pinctrl-651ffbbbe816
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755033884; l=1385;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Dpv1oPQG74ZYLF+MG89cus6fJnJbgGSnLUHZdOkHhkA=;
 b=+vr+CNjojq1xVphpGn0Tq+9eXtmNHftCVnsWUizbQ1tZ7hiFuCn5eBh7/C3TuIBy7UF+eAKG5
 iQ8k4EUtK1rBoyxoD+0U3yNUsA/uH74/dCNzeRMRCVDRZM6kUWDxJ3a
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for Tegra186 pin control, based on a downstream
driver, updated to match the existing Tegra194 driver.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v3:
- Fixed some spacing and formating issues in patch 2
- Link to v2: https://lore.kernel.org/r/20250608-tegra186-pinctrl-v2-0-502d41f3eedd@gmail.com

Changes in v2:
- Don't allow underscores in node names in patch 1
- Rebase on v6.16-rc1
- Patch 2 was picked up and thus not in the rebase
- Link to v1: https://lore.kernel.org/r/20250429-tegra186-pinctrl-v1-0-722c7c42394e@gmail.com

---
Aaron Kling (3):
      dt-bindings: pinctrl: Document Tegra186 pin controllers
      pinctrl: tegra: Add Tegra186 pinmux driver
      arm64: tegra: Add Tegra186 pin controllers

 .../bindings/pinctrl/nvidia,tegra186-pinmux.yaml   |  285 +++
 arch/arm64/boot/dts/nvidia/tegra186.dtsi           |   12 +
 drivers/pinctrl/tegra/Kconfig                      |    4 +
 drivers/pinctrl/tegra/Makefile                     |    1 +
 drivers/pinctrl/tegra/pinctrl-tegra186.c           | 1979 ++++++++++++++++++++
 drivers/soc/tegra/Kconfig                          |    1 +
 6 files changed, 2282 insertions(+)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250308-tegra186-pinctrl-651ffbbbe816

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

