From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/4] pinctrl: tegra: Add Tegra186 pinmux driver
Date: Tue, 29 Apr 2025 16:33:29 -0500
Message-Id: <20250429-tegra186-pinctrl-v1-0-722c7c42394e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKlFEWgC/x3MQQqAIBBA0avIrBO0UKSrRIu0sQbCYowIxLsnL
 d/i/wIZmTDDKAowPpTpTA26ExD2JW0oaW2GXvVGDcrJGzdetLPyohRuPqQ1OkbvPTptoWUXY6T
 3X05zrR/vH5J7YgAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745962426; l=1088;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=sqgl5y8PVkwCo9nS/VR1ZpFSL6mY1lIOi7iBfe47K3E=;
 b=82IwiueRLIua0SuZBRzUSmXl81Zbv2b6djBSxHxKnI8T6smApO86ykTTBxfRIbDo3CWdWaQnn
 Rgx+JNwb27wBcGEP1lIIXapKtz6Fm9bK5pOrMWtsDNSV0qZaNfcKb6f
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for Tegra186 pin control, based on a downstream
driver, updated to match the existing Tegra194 driver.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (4):
      dt-bindings: pinctrl: Document Tegra186 pin controllers
      dt-bindings: gpio: tegra186: Add gpio-ranges
      pinctrl: tegra: Add Tegra186 pinmux driver
      arm64: tegra: Add Tegra186 pin controllers

 .../bindings/gpio/nvidia,tegra186-gpio.yaml        |    3 +
 .../bindings/pinctrl/nvidia,tegra186-pinmux.yaml   |  285 ++++
 arch/arm64/boot/dts/nvidia/tegra186.dtsi           |   12 +
 drivers/pinctrl/tegra/Kconfig                      |    4 +
 drivers/pinctrl/tegra/Makefile                     |    1 +
 drivers/pinctrl/tegra/pinctrl-tegra186.c           | 1784 ++++++++++++++++++++
 drivers/soc/tegra/Kconfig                          |    1 +
 7 files changed, 2090 insertions(+)
---
base-commit: 1110ce6a1e34fe1fdc1bfe4ad52405f327d5083b
change-id: 20250308-tegra186-pinctrl-651ffbbbe816

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

