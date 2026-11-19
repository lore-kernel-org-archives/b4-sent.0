From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Subject: [PATCH 0/6] Add USB support for Exynos7885 and enable USB and FG
 on gta3xllte
Date: Thu, 19 Nov 2026 19:49:16 +0000
Message-Id: <20261119-gta3xllte-usb-battery-v1-0-0cf5f763522e@mentallysanemainliners.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTuJRTDUqxgWLfziGIKmMxgI4
 e5WXX6L9zZSJIHSpdgo4S0qzynDHQrq7mEawNJnU3ksz845z4OF0zKOBp41cgxmSCtHX6PqGx/
 Q1JTbV8JNlt/32v6tc3ygs++M9v0DH3PPq3kAAAA=
X-Change-ID: 20261119-gta3xllte-usb-battery-b95e4d89ae85
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, 
 Umer Uddin <umer.uddin@mentallysanemainliners.org>, 
 David Virag <virag.david003@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795117759; l=1828;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=yfFFDGO1vosaycRHkyMq/ESVrYzVjaRTqRdxrfEOlRU=;
 b=DOUWCJC+nGAPnXyDeJyc7GzcvtXM33vcEfPLeUGUDgC34VJmZIADaL8pMrRRf0Q+kEdHuXTF9
 pScKDNhyaBXCo8FM/p5Xk8rvTEEKTBTi+pjQnkEozJPcCyD4Te1NT4c
X-Developer-Key: i=umer.uddin@mentallysanemainliners.org; a=ed25519;
 pk=Hsgrt4A72CFTe27AI1AAWlnLsiQrlb4+T+cbrfWDhUA=
X-Endpoint-Received: by B4 Relay for umer.uddin@mentallysanemainliners.org/20261109 with auth_id=1466
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi guys, this patch series adds support for USB on Exynos7885. This series
is based on David Virag's work[1] I had rebased it onto krzk's for-next
tree and tested it on gta3xllte. This series also enables S2MU005 FG
on gta3xllte, which is also tested.

Please note, I did drop enabling USB on jackpotlte, this is because I
don't have the device myself to test the changes personally and I didn't
want to risk a regression on jackpotlte.

DT changes were tested with make dtbs_check W=1, and the dt styling check
scripts with --mode strict flags, both of which returned no warnings.

Best regards,
Umer

[1] https://github.com/VDavid003/linux/commits/linux-6.11-rc2-7885/

Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
David Virag (4):
      dt-bindings: phy: samsung,usb3-drd-phy: Add Exynos7885 support
      dt-bindings: usb: samsung,exynos-dwc3: Add Exynos7885 support
      phy: exynos5-usbdrd: support Exynos7885 USB PHY
      arm64: dts: exynos: Enable USB in Exynos7885

Umer Uddin (2):
      arm64: dts: exynos: exynos7885-gta3xllte: Enable USB support
      arm64: dts: exynos: exynos7885-gta3xllte: Enable FuelGauge support

 .../bindings/phy/samsung,usb3-drd-phy.yaml         |  2 +
 .../bindings/usb/samsung,exynos-dwc3.yaml          |  3 ++
 .../arm64/boot/dts/exynos/exynos7885-gta3xllte.dts | 50 ++++++++++++++++++++++
 arch/arm64/boot/dts/exynos/exynos7885.dtsi         | 43 +++++++++++++++++++
 drivers/phy/samsung/phy-exynos5-usbdrd.c           | 27 ++++++++++++
 include/linux/soc/samsung/exynos-regs-pmu.h        |  3 ++
 6 files changed, 128 insertions(+)
---
base-commit: 397f550f3c8551b3ffbf3f45a571b58448514988
change-id: 20261119-gta3xllte-usb-battery-b95e4d89ae85

Best regards,
--  
Umer Uddin <umer.uddin@mentallysanemainliners.org>

