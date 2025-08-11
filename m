From: Cristian Cozzolino <cristian_ci@protonmail.com>
Subject: [PATCH RESEND v4 0/3] Add initial device tree for Billion Capture+
Date: Mon, 11 Aug 2025 23:08:08 +0200
Message-Id: <20250811-rimob-initial-devicetree-v4-0-b3194f14aa33@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754946504; l=1749;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=iGpOrPiTcjSqjaJKYglayvOHuHZxT9a26u3piPV43Cc=;
 b=oa3QBVoZJAN/3rVhLcTZ0V7gnSVN1N86UmgFi3RK8fR+G6jrEQxwN7ELV8pDcO38mOmjDAVCu
 ZjcZPYShCtsBeEaYCOSj/kxEG9WyAgA8XY1R4BIBBGIqfK6bQLNQy89
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Billion Capture+ is a handset using the MSM8953 SoC released in 2017
and sold by Flipkart.

Add a device tree with initial support for:

- GPIO keys
- SDHCI (internal and external storage)
- USB Device Mode
- Regulators
- Simple framebuffer

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
Changes in v4:
- pick up tags (Rob);
- Link to v3: https://lore.kernel.org/r/20250626-rimob-initial-devicetree-v3-0-4017ac9fd93d@protonmail.com

Changes in v3:
- (patch 3/3): pick up tag (Konrad);
- Link to v2: https://lore.kernel.org/r/20250624-rimob-initial-devicetree-v2-0-34f6045ebc30@protonmail.com

Changes in v2:
- (patch 3/3):
  - add unit address and label to qseecom (Luca);
  - reorder properties alphabetically in gpio-keys node (Konrad);
  - fix hex values in reg address and size cells: from 0x00 to 0x0 (Konrad);
  - add regulator-allow-set-load property to regulators supplying sdhc1/sdhc2.
- Link to v1: https://lore.kernel.org/r/20250620-rimob-initial-devicetree-v1-0-8e667ea21f82@protonmail.com

---
Cristian Cozzolino (3):
      dt-bindings: vendor-prefixes: Add Flipkart
      dt-bindings: arm: qcom: Add Billion Capture+
      arm64: dts: qcom: msm8953: Add device tree for Billion Capture+

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts | 255 +++++++++++++++++++++
 4 files changed, 259 insertions(+)
---
base-commit: 0ff41df1cb268fc69e703a08a57ee14ae967d0ca
change-id: 20250620-rimob-initial-devicetree-da86a5bffc8b

Best regards,
-- 
Cristian Cozzolino <cristian_ci@protonmail.com>

