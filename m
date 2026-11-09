From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Subject: [PATCH v2 0/2] Add support for Samsung Galaxy Tab A 10.1 (2019,
 4G)
Date: Mon, 09 Nov 2026 21:02:01 +0000
Message-Id: <20261109-gta3xllte-support-v2-0-85c31b6efebd@mentallysanemainliners.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32Nyw6DIBQFf8WwLg0ooY9V/6NxgXBRGgTDRaMx/
 nvV7rucZM6clSAkB0iexUoSTA5dDDuUl4LoToUWqDM7k5KVknP2oG1W1ex9BorjMMSUqZXCWHG
 TptKS7LshgXXz2XzXP8ax+YDOR+gwOoc5puU8nfjh/etPnDJqNNOisereCPHqIWTl/YIqQK9c8
 C5AwmtMLam3bfsCD+HNL9UAAAA=
X-Change-ID: 20261109-gta3xllte-support-f64df476d3c6
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Umer Uddin <umer.uddin@mentallysanemainliners.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794258123; l=1578;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=agqWjBLMvEse0eu1plUAKimZM+XtZzwOh/y90EL/9AY=;
 b=9onZelZpLaXYd6RnSVn5XhXY5jMFeZzxh9Kme4kcVPNeUPmqcwl1ca/2BCLee1Pj0m0HMWxtF
 VQFrfwzVOl0BhYFfR1zeC6zjgyBK5mimt26TUQifjzlvtY/cshDbcpd
X-Developer-Key: i=umer.uddin@mentallysanemainliners.org; a=ed25519;
 pk=Hsgrt4A72CFTe27AI1AAWlnLsiQrlb4+T+cbrfWDhUA=
X-Endpoint-Received: by B4 Relay for umer.uddin@mentallysanemainliners.org/20261109 with auth_id=1466
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi guys,

This series adds support for Samsung Galaxy Tab A 10.1 (2019, 4G).

The device trees have been tested with dtbs_check W=1 and scripts/dtc/dt-check-style
with --mode strict flag and both results in no warnings.

This initial bringup consists of:
 * pinctrl
 * internal eMMC
 * gpio-keys
 * simple-framebuffer

This is enough to reach a shell in an initramfs. More platform support
will be added in the future.

The preferred way to boot kernel is by using a shim bootloader called
uniLoader [1], which works around some issues with the stock bootloader,
primarily the decon trigger control quirk, causing the framebuffer to not
refresh.

[1] https://github.com/ivoszbg/uniLoader

Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
Changes in v2:
- Fixed dts oversights pointed out via Sashiko.
- Link to v1: https://patch.msgid.link/20261109-gta3xllte-support-v1-0-dc0c4bfa8b44@mentallysanemainliners.org

---
Umer Uddin (2):
      dt-bindings: arm: samsung: samsung-boards: Add bindings for SM-T515 board
      arm64: exynos: Add initial support for Samsung Galaxy Tab A 10.1 (2019, 4G)

 .../bindings/arm/samsung/samsung-boards.yaml       |   1 +
 arch/arm64/boot/dts/exynos/Makefile                |   1 +
 .../arm64/boot/dts/exynos/exynos7885-gta3xllte.dts | 129 +++++++++++++++++++++
 3 files changed, 131 insertions(+)
---
base-commit: c916d326360966fa41b1d9c3fb659215053387f5
change-id: 20261109-gta3xllte-support-f64df476d3c6

Best regards,
--  
Umer Uddin <umer.uddin@mentallysanemainliners.org>

