From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH v2 0/2] arm64: dts: qcom: sc8180x: add IMEM and IPA nodes
Date: Thu, 26 Nov 2026 14:39:42 +0100
Message-Id: <20261126-sc8180x-dts-ipa-v2-0-ad57b1be7c70@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ6CMBBEf4Xs2Zq2WgVO/ofhAO0Ka4SSLhIM6
 b9b8Gzm9JKZNyswBkKGMlsh4ExMfkigDxnYrh5aFOQSg5b6opQ2gm2ucrkIN7GgsRZS5ligMbZ
 oHKTVGPBBy268Vz/md/NEO22ardERTz589stZbb3/9lmJFI3mbK+oTo25tX1Nr6P1PVQxxi9vn
 v2IwAAAAA==
X-Change-ID: 20261125-sc8180x-dts-ipa-008e9e55c9bd
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Robert Ijtsma <robertijtsma@gmail.com>, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795700384; l=1808;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=QyOTC2IVuu3v71bzMrVHNN/OT7Tq0DSK2eLPad57qH4=;
 b=GFfbt++1Ni77TnAhvAXmQ8Q3AuDx+CSh8if6Z0fYCNDyBOhnVtTskZ+Ekk/Wryahoof3saZAC
 8jGHoXYFaXyDpsMFyQqWlmJWjBC/P/V5to0e62AcFZL4m9V8I3FmNDn
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the SC8180X on-chip SRAM (IMEM) compatible string under the
generic mmio-sram binding and add the IMEM (sram@14680000) and disabled
IPA v4.1 (ipa@1e40000) nodes to sc8180x.dtsi so board devicetrees can
enable IPA with their board-specific firmware and reserved memory region.

Note: Patch 2/2 references the "qcom,sc8180x-ipa" compatible string
documented in the companion net-next IPA v4.1 series [1].

[1] https://lore.kernel.org/r/20261126-qcom-ipa-sc8180x-v2-0-89eba621da95@gmail.com

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Changes in v2:
- Document qcom,sc8180x-imem in Documentation/devicetree/bindings/sram/sram.yaml
  as generic mmio-sram.
- Add sram@14680000 with modem-tables-sram@3d000 to sc8180x.dtsi and
  reference it via sram = <&ipa_modem_tables> from ipa@1e40000 so the
  IPA driver obtains the IMEM slice from Devicetree (Konrad Dybcio).
- Link to v1: https://patch.msgid.link/20261125-sc8180x-dts-ipa-v1-1-12e54c7e13b5@gmail.com

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
To: Abel Vesa <abelvesa@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-msm@vger.kernel.org

---
Robert Ijtsma (2):
      dt-bindings: sram: document qcom,sc8180x-imem compatible
      arm64: dts: qcom: sc8180x: add IMEM and IPA nodes

 Documentation/devicetree/bindings/sram/sram.yaml |  1 +
 arch/arm64/boot/dts/qcom/sc8180x.dtsi            | 60 ++++++++++++++++++++++++
 2 files changed, 61 insertions(+)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261125-sc8180x-dts-ipa-008e9e55c9bd

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

