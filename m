From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v3 0/3] arm64: dts: qcom: x1-hp-x14: Add support for
 X1P42100 HP Omnibook X14
Date: Thu, 03 Jul 2025 08:59:10 +0200
Message-Id: <20250703-hp-x14-x1p-v3-0-affe103b4356@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD4qZmgC/3XOwQ6DIAyA4VcxnMcCRVB22nssO6jgIDFiwBE34
 7uvep6HHv4m/dKVJBu9TeRWrCTa7JMPI4a4FKRzzfiy1BtsAgwkqxhQN9GFlzgTta2AvlRaGa0
 IHkzR9n45sMcT2/k0h/g57Mz37V8mc8oocC2ksrUAVt3DYFLnQhhSGN4zfpSurf+S3cxw7gA6T
 S9bWdeG60qfOtu2/QDJ7uTo+QAAAA==
X-Change-ID: 20250702-hp-x14-x1p-eb32f4696d96
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751525956; l=2124;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=tQJdnJYlTNIs5lgbSl8DiVHPrsh3z/fqveMuaTC90Og=;
 b=IYn8bd9kGEwYlsibDlmnND/7ucFXPmAwIBpJYyW+D9VKz+iOMZp/t1SKVxeyH+VMnaWrftfCr
 Xp7lo6zh01pB3ck+4C2aOJDK6zT3EkXhNnoc3r15KUSwJTY0YSrttqH
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds support for the HP Omnibook X Laptop 14-fe1xxx. [1]

Since this is actually the same model as the 14-fe0xxx, but with an
X1P-42-100 SoC (Purwa), it needs a slightly different device tree.
To have as minimal duplicate definition as possible, the hp X14 gets 
commonalized into a dtsi (and it stays compatible to the derived 
device trees, like the Ultrabook G1q). 

The supported features are the same as for the original Omnibook X14:

- Keyboard (no function keys though)
- Display
- PWM brightness control
- Touchpad
- Touchscreen
- PCIe ports (pcie4, pcie6a)
- USB type-c, type-a
- WCN6855 Wifi-6E
- WCN6855 Bluetooth
- ADSP and CDSP
- X1 GPU
- GPIO Keys (Lid switch)
- Audio definition (works via USB and with internal speakers)

[1]: https://www.hp.com/us-en/shop/pdp/hp-omnibook-x-laptop-next-gen-ai-pc-14-fe100-14-a4nd1av-1#techSpecs

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Changes in v3:
- removed copyright strings
- amended changed commit message  
- Link to v2: https://lore.kernel.org/r/20250702-hp-x14-x1p-v2-0-af5b588d1979@oldschoolsolutions.biz

Changes in v2:
- remove pm8010 handling
- Link to v1: https://lore.kernel.org/r/20250702-hp-x14-x1p-v1-0-219356e83207@oldschoolsolutions.biz

---
Jens Glathe (3):
      dt-bindings: arm: qcom: Split HP Omnibook X14 AI in SoC variants
      arm64: dts: qcom: x1-hp-x14: Commonalize HP Omnibook X14 device tree
      arm64: dts: qcom: x1-hp-x14: Add support for X1P42100 HP Omnibook X14

 Documentation/devicetree/bindings/arm/qcom.yaml    |    3 +-
 arch/arm64/boot/dts/qcom/Makefile                  |    2 +
 arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi   | 1549 ++++++++++++++++++++
 .../boot/dts/qcom/x1e80100-hp-omnibook-x14.dts     | 1544 +------------------
 .../boot/dts/qcom/x1p42100-hp-omnibook-x14.dts     |   40 +
 5 files changed, 1596 insertions(+), 1542 deletions(-)
---
base-commit: 3f804361f3b9af33e00b90ec9cb5afcc96831e60
change-id: 20250702-hp-x14-x1p-eb32f4696d96

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

