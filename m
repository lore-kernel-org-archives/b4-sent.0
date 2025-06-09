From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/3] pinctrl: tegra: Add Tegra186 pinmux driver
Date: Sun, 08 Jun 2025 21:13:12 -0500
Message-Id: <20250608-tegra186-pinctrl-v2-0-502d41f3eedd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADhDRmgC/2WNyw6CMBBFf4XM2pp2KC9X/odhQesUJuGVtiEaw
 r9bcenynOSeu0MgzxTglu3gaePAy5wALxnYoZt7EvxMDCixkLmsRaTed6ouxcqzjX4UZaGcM8Z
 QrUpIs9WT49eZfLSJBw5x8e/zYVNf+4tpbP5jmxJSVIi2shrzRtO9nzoer3aZoD2O4wOodoShs
 AAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749435198; l=1219;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=lOx07OEPHI4zIhQLY6PyPM+jjTNfD5XG4BYf083Bork=;
 b=O1rlq6CV9i34HIKnA2LRs9rH6O9Bnt683ScNvXZXVAqIWBk3Yq6RQDFNOzO4LQi+KVVwaV+Ju
 VgsQi1AFbneBuSoJ55FJ2JDsEg23RmM8iC+mCFXUHdJqgneva1MFsTm
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for Tegra186 pin control, based on a downstream
driver, updated to match the existing Tegra194 driver.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
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

 .../bindings/pinctrl/nvidia,tegra186-pinmux.yaml   |  285 ++++
 arch/arm64/boot/dts/nvidia/tegra186.dtsi           |   12 +
 drivers/pinctrl/tegra/Kconfig                      |    4 +
 drivers/pinctrl/tegra/Makefile                     |    1 +
 drivers/pinctrl/tegra/pinctrl-tegra186.c           | 1784 ++++++++++++++++++++
 drivers/soc/tegra/Kconfig                          |    1 +
 6 files changed, 2087 insertions(+)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250308-tegra186-pinctrl-651ffbbbe816

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

