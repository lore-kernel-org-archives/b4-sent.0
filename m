From: Igor Velkov <iav@iav.lv>
Subject: [PATCH 0/2] arm64: dts: amlogic: meson-sm1-odroid-hc4: fix the SPI
 NOR
Date: Wed, 30 Sep 2026 16:52:13 +0000
Message-Id: <20260930-hc4-spi-nor-v1-0-9a3351e2984e@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD0+vWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDS2MD3YxkE93igkzdvPwi3UQLA0NTo1Rjg9REQyWgjoKi1LTMCrBp0bG
 1tQBEQpybXQAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Christian Hewitt <christianshewitt@gmail.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=793; i=iav@iav.lv;
 h=from:subject:message-id; bh=FkTS1J850r7Vj79AJGPS5AoW9XnMem2eGQVjUeS1sP0=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl77Ry+ae2L8vxTvSl2tdjba93Cf4SeTfPdmyhyauPpT
 a01a7vmdpSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJpP9n+CtQL/L8hb3782ns
 JguX1ZY/FWj5UX7k4/PN2fzcutNfB1oy/BX5NsVdR+DUgfvdxj/qn75j3sLie8H6e0ZN4sHcqpW
 bNbkB
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for the SPI NOR flash on ODROID-HC4. Patch 1 lets the flash
probe after a boot from SD past the SPI. Patch 2 lowers the clock to
40 MHz, where reads stop returning corrupted data.

U-Boot takes this device tree from dts/upstream and gets the fixes with
the next sync.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Igor Velkov (2):
      arm64: dts: amlogic: meson-sm1-odroid-hc4: mux the SPI NOR HOLD# and WP# pins
      arm64: dts: amlogic: meson-sm1-odroid-hc4: run the SPI NOR at 40 MHz

 arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)
---
base-commit: 065957517880dc7053e0723cc9532b6e78c8855c
change-id: 20260930-hc4-spi-nor-a80152e30ea1

Best regards,
-- 
Igor Velkov <iav@iav.lv>

