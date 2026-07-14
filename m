From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH 0/6] Initial PCIe0 and QMP USB PHYs support for SM8475
Date: Tue, 14 Jul 2026 02:36:38 -0400
Message-Id: <20260714-sm8475-bup-v1-0-b2871be2b4ec@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDWpRrVxFbHQGozETzqIRNxds
 fwW713AGAgZyuSCgAcxLXNElibgh2buUVAbDUqqQposFzzZ3Gjh9lVob2WrO+mUayAGa8COzm9
 W1b95dyP67T3AfT9v8AbObgAAAA==
X-Change-ID: 20260714-sm8475-bup-5c80d5f0b2ba
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784011013; l=1233;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=loOVyJQdNo2C/7b6M2ZU7HXekbM+vRvrsTr0PcS5i0A=;
 b=2itTSQOEtB51eyLG5Ly2sH889FWi31qrOSgVL8uSfy7U8P+fKSBTFKWN5YEkKPK7gJs2Df/H2
 dOWy4a03DFPAiwLJ2r6Y0JDnVtWIDgpSzBNshzM3bkrsB1POy+5cDDL
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for both the PCIe0 and the QMP USB PHYs which
can be found on the SM8475 SoC.
The initialization sequences vary noticeably when compared to the ones
used in the SM8450 SoC, hence the need to add support for these PHYs.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Esteban Urrutia (6):
      dt-bindings: phy: qcom,sc8280xp-qmp-pcie-phy: Add SM8475 QMP PHY
      phy: qcom: qmp-pcie: Add pcs_lane1 offset to V5 offsets
      phy: qcom: qmp-pcie: Add support for SM8475 Gen3x1 PCIe0 port
      dt-bindings: phy: qcom,sc8280xp-qmp-usb43dp-phy: Add SM8475 QMP PHY
      phy: qcom: qmp-combo: Add serdes and RBR/HBR/HBR2/HBR3 tables for v1 DP PLLs
      phy: qcom: qmp-combo: Add SM8475 support

 .../bindings/phy/qcom,sc8280xp-qmp-pcie-phy.yaml   |   2 +
 .../phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml         |   1 +
 drivers/phy/qualcomm/phy-qcom-qmp-combo.c          | 259 +++++++++++++++++----
 drivers/phy/qualcomm/phy-qcom-qmp-pcie.c           | 109 +++++++++
 4 files changed, 326 insertions(+), 45 deletions(-)
---
base-commit: 49362394dad7df66c274c867a271394c10ca2bb8
change-id: 20260714-sm8475-bup-5c80d5f0b2ba

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

