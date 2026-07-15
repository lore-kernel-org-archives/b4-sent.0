From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH v2 0/3] Initial PCIe0 PHY support for SM8475
Date: Wed, 15 Jul 2026 02:37:45 -0400
Message-Id: <20260715-sm8475-bup-pcie-v2-0-48bd91a19abf@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NQQ6CMBBFr0Jm7RhaaousvIdhYesoYwJtWiAaw
 t2luHX5kvffXyBRZErQFAtEmjmxHzaQhwJcdxuehHzfGGQpdWmEwtTXypzQTgGDY8KKKnPWpIV
 TBNsqRHrwey9e2x+nyb7IjTmTjY7T6ONnv5xF9v7WZ4ElWlkbYUlaRe4Soh/9cOwJ2nVdv1tUO
 PK7AAAA
X-Change-ID: 20260714-sm8475-bup-pcie-3e3796e61c4e
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784097545; l=1058;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=DXCPklQlaMdsbJnYQs6c8poFEg6YyAXU0DXLOMPqOgY=;
 b=0goYS6cTjDxMQMw2HZnPcWJ/7uXDiMnvjqOFKfhc6a3+SijbKl60TY0IUojz1BqgY26QZBANY
 IHaycNsKF9PCKsLJrOhXPvH4oT38mzOv2/4uNxg10W06GxTsfuQ1N7N
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the PCIe0 PHY found in the SM8475 SoC.
The initialization sequence varies noticeably when compared to the one used
in the SM8450 SoC, hence the need to add support for this PHY.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Changes in v2:
- Split series in subseries (pcie, usbss)
  - Sorry, it should have been like this from the start!
- Link to v1: https://patch.msgid.link/20260714-sm8475-bup-v1-0-b2871be2b4ec@proton.me

---
Esteban Urrutia (3):
      dt-bindings: phy: qcom,sc8280xp-qmp-pcie-phy: Add SM8475 QMP PHY
      phy: qcom: qmp-pcie: Add pcs_lane1 offset to V5 offsets
      phy: qcom: qmp-pcie: Add support for SM8475 Gen3x1 PCIe0 port

 .../bindings/phy/qcom,sc8280xp-qmp-pcie-phy.yaml   |   2 +
 drivers/phy/qualcomm/phy-qcom-qmp-pcie.c           | 109 +++++++++++++++++++++
 2 files changed, 111 insertions(+)
---
base-commit: cc2b5f627e8ccbae1188ef2d8be3e451d7f933a5
change-id: 20260714-sm8475-bup-pcie-3e3796e61c4e

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

