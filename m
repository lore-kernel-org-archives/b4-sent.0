From: Asdlerto Korry <korryasdlerto@gmail.com>
Subject: [PATCH v2 0/4] arm64: dts: qcom: Add Samsung Galaxy M52 5G
Date: Wed, 11 Nov 2026 17:07:44 +0200
Message-Id: <20261111-m52xq-dts-v2-0-063289405882@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMGE9GoC/23MQQ6CMBCF4auQWVvTGdFQV97DsIDSwiSWYksaD
 Ondraxd/i8v3w7RBDYR7tUOwSSO7OcSdKpAT908GsFDaSBJN0RZC3el7S2GNQpqLtpIq3tdKyj
 /JRjL22E929ITx9WHz0En/K3/lIRCih5VYyUpJGsfo+v4ddbeQZtz/gKBjxXKogAAAA==
X-Change-ID: 20261104-m52xq-dts-283ce0fcbc49
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 netdev@vger.kernel.org, Asdlerto Korry <korryasdlerto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794409665; l=3039;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=XfNua7PAV4kckWXtmCx56IqauZbV+Xj3aih6wYA69X0=;
 b=hlEHBlU91uiogwNELsRP1uTsAlQH/qJAfSeJKUVyPS7aTgJKc/kwJW15queGzapffIldwXd1C
 qNHldpxRX87Cd05qWSEa7vqMolfGCelWeAQ+1HzFvdauVKW6LhZ2Fry
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds initial support for the Samsung Galaxy M52 5G
(SM-M526B, codename m52xq), a smartphone based on the Qualcomm SM7325
SoC.

Tested on next-20261030 with only this series applied: the device boots
to a postmarketOS userspace from UFS. ADSP, MPSS and WPSS come up, WiFi
connects, Venus probes, the microSD card is detected and readable, and
USB peripheral mode works in both plug orientations. The kernel log
shows no errors from the nodes described here. Bluetooth, NFC, IPA
mobile data and the GPU were tested with the same nodes on a 7.1
kernel.

Not included yet: the display panel, touchscreen, cameras, audio, the
fuel gauge/charger and the USB Type-C controller (SM5714). They need
drivers that are not upstream yet. The display works through
simple-framebuffer for now.

Notes:
* The stock ABL picks the DTB by qcom,msm-id/qcom,board-id. These
  properties are left out as required for new SM7325 boards, so users
  add them when packaging the boot image.
* The reserved memory map follows the stock device tree. The removed
  region is larger than on other SM7325 devices (0x5f00000). With the
  common size, the kernel livelocks when it touches the memory the
  hypervisor keeps.
* Several regulators need a fixed voltage or must stay always-on (UFS
  VCC on L7b, the ADSP-managed sensors on L12c). With the stock ranges
  Linux sets the minimum and UFS or the ADSP fail.

Signed-off-by: Asdlerto Korry <korryasdlerto@gmail.com>
---
Changes in v2:
- framebuffer: drop reg and unit address, memory-region is enough (Konrad)
- dt-bindings: nfc: samsung,s3fwrn5: add pvdd-supply; the s3fwrn5 driver
  enables it, so the NFC regulator is no longer always-on (Konrad)
- enable qupv3_id_0, it holds uart7 for Bluetooth (Sashiko)
- reserved memory: drop cdsp_mem/remoteproc_cdsp, the ADSP region covers
  them; replace the overlapping video region with camera_mem (Sashiko)
- Bluetooth: fix the vddrfa1p2/vddrfa2p2 supplies (Sashiko)
- NFC: edge-triggered interrupt (Sashiko)
- raise the minimum voltage of S1b/S7b/S8b to the stock levels, lower
  values starve the LDOs and the touchscreen loses touches
- Link to v1: https://lore.kernel.org/r/20261104-m52xq-dts-v1-0-b198f02912ff@gmail.com

---
Asdlerto Korry (4):
      dt-bindings: arm: qcom: Add Samsung Galaxy M52 5G
      dt-bindings: net: nfc: samsung,s3fwrn5: Add pvdd-supply
      nfc: s3fwrn5: i2c: Enable the pvdd supply
      arm64: dts: qcom: sm7325: Add Samsung Galaxy M52 5G

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 .../bindings/net/nfc/samsung,s3fwrn5.yaml          |   5 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 arch/arm64/boot/dts/qcom/sm7325-samsung-m52xq.dts  | 839 +++++++++++++++++++++
 drivers/nfc/s3fwrn5/i2c.c                          |   7 +
 5 files changed, 853 insertions(+)
---
base-commit: 7649ba73f9e7e1e04d0b46213e39c79ae09dd55c
change-id: 20261104-m52xq-dts-283ce0fcbc49

Best regards,
-- 
Asdlerto Korry <korryasdlerto@gmail.com>

