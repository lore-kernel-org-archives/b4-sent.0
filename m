From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH RESEND v3 0/2] Initial QMP USB PHY support for SM8475
Date: Tue, 04 Aug 2026 14:06:18 -0400
Message-Id: <20260804-sm8475-bup-usbss-v3-0-9a5b9ebf62de@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785866807; l=1598;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=UYYeoFYGn74wN3HBRtWiUwkieFmQvRE83tQm10aXEO8=;
 b=L72rDqhmOb52xnhpROj5aEtCiw6jb355ELkkORugIfTAJB/wS+qrYr4lrPMQFOPUreOcjir0n
 SfnUusl8AnKBK41/OEh97Yolcmm5lQxu+NANskHoyOBfHXxirN90Ylo
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Based on the following patch:
[1] https://lore.kernel.org/all/20260711-sm8450-qol-qmp-v2-2-d14353bd6ff4@proton.me/

This series adds support for the QMP USB PHY found in the SM8475 SoC.
The initialization sequence varies noticeably when compared to the one
used in the SM8450 SoC, hence the need to add support for this PHY.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Changes in v3:
- Apply suggestions from Dmitry
- Drop PLL version patch
  - Explain the situation instead of renaming the structs
- Link to v2: https://patch.msgid.link/20260715-sm8475-bup-usbss-v2-0-2d8def39b190@proton.me

Changes in v2:
- Split series in subseries (pcie, usbss)
  - Sorry, it should have been like this from the start!
- Add notice about base commit
  - Reason why calibrate_dp_phy is not present
- Modify referenced swing and pre-emphasis tables
- Move v1 PLL tables to SM8475 support patch
  - Warnings are generated at build time otherwise
- Link to v1: https://patch.msgid.link/20260714-sm8475-bup-v1-0-b2871be2b4ec@proton.me

---
Esteban Urrutia (2):
      dt-bindings: phy: qcom,sc8280xp-qmp-usb43dp-phy: Add SM8475 QMP PHY
      phy: qcom: qmp-combo: Add SM8475 support

 .../phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml         |   1 +
 drivers/phy/qualcomm/phy-qcom-qmp-combo.c          | 169 +++++++++++++++++++++
 2 files changed, 170 insertions(+)
---
base-commit: 30b4a96d99ce8447f4589af6f7da35d4b43e0af6
change-id: 20260714-sm8475-bup-usbss-e68349473f6e

Best regards,
--
Esteban Urrutia <esteuwu@proton.me>
-- 
Esteban Urrutia <esteuwu@proton.me>

