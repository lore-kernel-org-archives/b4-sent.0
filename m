From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/2] Add some devices nodes for S4.
Date: Fri, 08 Dec 2023 15:16:25 +0800
Message-Id: <20231208-s4-dts-v2-0-5a93fa356c5d@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMnCcmUC/0XMQQ6CMBCF4auQWTuknVZCXXkP46LSASYRSlqiR
 MLdbdy4/JL/vR0yJ+EMl2qHxC/JEucCOlXQjX4eGCUUAykymlSL2WJYM5IN/AjNuSHloMRL4l6
 239HtXtynOOE6Jvb/uSanHDnratLKGNOixk38/GapP6OPVz894yBd3cUJjuMLP2hC5pwAAAA=
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702019788; l=1074;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=x1LVuWnPlnaL4+2ytK6scMJJiGc0PC686IXbzerTiJw=;
 b=ec+Ua7KFxOXT8HGqxc1F4xX4Bxgl9cTzrFEJxXZPSLqxRST5tvzJdnm2ui19/ZBp6SAD0ck5l
 lZlTeCFIAC2BJ+NJl5bWz97x6ZiBFhzLebcuXOWgOFX6ZZnSMlCmcE4
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add some device nodes for SoC S4, including periphs clock controller
node, PLL clock controller node, I2C nodes, SPICC node, NAND
controller node, Ethernet MAC and PHY node.

Add reserved memory for board AQ222 which is used by ATF.
Enable NAND, SPICC nodes for board AQ222.

---
Changes in v2:
- Separate and independent commit for dts file.
- Revision format error.
- Add comment for resered memory.
- Link to v1: https://lore.kernel.org/all/20231129092949.2103338-1-xianwei.zhao@amlogic.com/

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>

---
Xianwei Zhao (2):
      arm64: dts: amlogic: add some device nodes for S4
      arm64: dts: amlogic: enable some nodes for board AQ222

 .../boot/dts/amlogic/meson-s4-s805x2-aq222.dts     |  56 ++++
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          | 350 ++++++++++++++++++++-
 2 files changed, 405 insertions(+), 1 deletion(-)
---
base-commit: 093098370b4693b0da8b7fdf5fd212cb46705928
change-id: 20231208-s4-dts-24debd656209

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

