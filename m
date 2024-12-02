From: Thomas Antoine <t.antoine@uclouvain.be>
Subject: [PATCH 0/4] Google Pixel 6 (oriole): max77759 fuel gauge
 enablement and driver support
Date: Mon, 02 Dec 2024 14:07:14 +0100
Message-Id: <20241202-b4-gs101_max77759_fg-v1-0-98d2fa7bfe30@uclouvain.be>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAKxTWcC/x2MywqAIBAAfyX2nOCqIfUrEWG12h56oBCC9O9Jl
 4E5zBRIFJkSDE2BSA8nvs4q2Daw7u4MJHirDkoqgxViMSIklDgfLltru372QRipSGl0ZtEaanp
 H8pz/7Ti97wc7Q2hxZgAAAA==
X-Change-ID: 20241202-b4-gs101_max77759_fg-402e231a4b33
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733144859; l=1133;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=gutyObQKsachHq0/nA2oAKqQxOFoQ3uvLG/DLWbnDiw=;
 b=Bhzd4ybqtj55n/U2YOZSfbuvXzTGyNb206Tg8GJtVh03aqvqpmF8Nj8CDa4qgOCKVsNZyXzzf
 NKlykWlpZGdAQoXH5iuxKaEXiFeZPBrvAsOb3+wQlD3Lviex1H6Bmen
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Google Pixel 6 has a Maxim max77759 which provides a fuel gauge with
the same interface as the Maxim max1720x, except for the non-volatile
memory.

Modify the Maxim max1720x driver to be compatible with the Maxim max77759 and
enable it for the gs101-oriole board.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
Thomas Antoine (4):
      power: supply: add support for max77759 fuel gauge
      dt-bindings: power: supply: add max77759-fg flavor and don't require nvme address
      arm64: defconfig: enable Maxim max1720x driver
      arm64: dts: exynos: gs101-oriole: enable Maxim max77759 fuel gauge

 .../bindings/power/supply/maxim,max17201.yaml      | 14 +++++
 arch/arm64/boot/dts/exynos/google/gs101-oriole.dts |  7 +++
 arch/arm64/configs/defconfig                       |  1 +
 drivers/power/supply/max1720x_battery.c            | 71 ++++++++++++++++++----
 4 files changed, 81 insertions(+), 12 deletions(-)
---
base-commit: 12e0a4072e8edc49c99418a4303bd7b96916de95
change-id: 20241202-b4-gs101_max77759_fg-402e231a4b33

Best regards,
-- 
Thomas Antoine <t.antoine@uclouvain.be>

