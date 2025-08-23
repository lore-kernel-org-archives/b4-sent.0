From: Maud Spierings <maud_spierings@hotmail.com>
Subject: [PATCH 0/3] arm64: dts: rockchip: Improvements for
 rk3588-orangepi-5 and friends
Date: Sat, 23 Aug 2025 14:43:49 +0200
Message-Id: <20250823-orangepi5-v1-0-ae77dd0e06d7@hotmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIW3qWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCyNj3fwikGhBpqluokWyhYGpuWFyWoqBElB9QVFqWmYF2Kzo2NpaAMS
 YGExbAAAA
X-Change-ID: 20250823-orangepi5-a8c80571cfd0
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Ondrej Jirman <megi@xff.cz>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755953033; l=829;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=qmoItphEwgbnOc3Kx/jB+wrA6iB1hYbkpqBVKQ9GP5s=;
 b=XW9abXAO3w57Ix2LwWlF3Yf5as+Mfqdo0VxxzjVLdssOTDU6o907NIN3Z3Qkd8L2uBlWiRCoe
 hxfh6KYtzBVCQMRvy6MCvp55sK409dtkfYwwmBjZtik20y2cSgMZ2UM
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the headphone detection logic on the orangepi 5 plus.
Enable the HDMI receiver on the orangepi 5 plus.
Enable the NPU on all orangepi 5 boards.

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
Maud Spierings (3):
      arm64: dts: rockchip: Fix the headphone detection on the orangepi 5 plus
      arm64: dts: rockchip: Enable HDMI receiver on orangepi 5 plus
      arm64: dts: rockchip: Enable the NPU on the orangepi 5 boards

 .../boot/dts/rockchip/rk3588-orangepi-5-plus.dts   | 19 +++++++-
 .../arm64/boot/dts/rockchip/rk3588-orangepi-5.dtsi | 56 ++++++++++++++++++++++
 2 files changed, 74 insertions(+), 1 deletion(-)
---
base-commit: 0f4c93f7eb861acab537dbe94441817a270537bf
change-id: 20250823-orangepi5-a8c80571cfd0

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

