From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH v2 0/3] arm64: dts: qcom: sc8180x: add IMEM and IPA nodes
Date: Thu, 26 Nov 2026 15:10:15 +0100
Message-Id: <20261126-sc8180x-dts-ipa-v2-0-e919ed1643c1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMc9CGsC/3WNzQrCMBCEX6Xs2ZUkGk178j2khzRZ2wX7Q1JCp
 eTdjb3LnL6B+WaHSIEpQlPtEChx5HkqoE4VuMFOPSH7wqCEukmpNEZnpBEb+jUiLxaFMFST1q7
 uPJTVEujF22F8toUHjuscPsdBkr/2vytJLFGkr+5O8tLpRz9afp/dPEKbc/4Cor6m264AAAA=
X-Change-ID: 20261125-sc8180x-dts-ipa-008e9e55c9bd
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795702215; l=1209;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=Q6eOgzYuDQdWByH1Fa1iUBFwIliyQWN4q9ZxgGtM9pw=;
 b=ZjDAAWAcf6DtlMt3HbRW7rtIMrNrbhn9AYmWSPDBXaCBPWScGpesoj1ijewXc6C/YHT/EdB+c
 paFEFqvB8VMC2etZPeGZZ50y/F9EQrUZMp2Y4/3I7n96rO9+Vjg18BX
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Depends-on: https://lore.kernel.org/r/20261126-qcom-ipa-sc8180x-v2-0-89eba621da95@gmail.com
The "qcom,sc8180x-ipa" binding patch in that series carries a
Reviewed-by from Krzysztof Kozlowski.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Changes in v2:
- Document qcom,sc8180x-imem in Documentation/devicetree/bindings/sram/sram.yaml.
- Add the SC8180X IMEM SRAM node (sram@14680000) with the IPA modem tables
  slice (0x3d000, 8 KiB) and reference it via sram = <&ipa_modem_tables> on
  the IPA node instead of relying on hardcoded driver IMEM addresses.
- Link to v1: https://lore.kernel.org/r/20261125-sc8180x-dts-ipa-v1-1-12e54c7e13b5@gmail.com

---
Robert Ijtsma (3):
      dt-bindings: sram: Document qcom,sc8180x-imem compatible
      arm64: dts: qcom: sc8180x: add IMEM node
      arm64: dts: qcom: sc8180x: add IPA node

 Documentation/devicetree/bindings/sram/sram.yaml |  1 +
 arch/arm64/boot/dts/qcom/sc8180x.dtsi            | 60 ++++++++++++++++++++++++
 2 files changed, 61 insertions(+)
---
base-commit: ef922b721a5e99348fc1f5801fdeb427ee14ee9f
change-id: 20261125-sc8180x-dts-ipa-008e9e55c9bd

Best regards,
-- 
Robert Ijtsma <robertijtsma@gmail.com>

