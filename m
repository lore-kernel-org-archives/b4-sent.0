From: fangez <quic_fangez@quicinc.com>
Subject: [PATCH 0/6] add_display_support_for_QCS615
Date: Mon, 14 Oct 2024 17:47:26 +0800
Message-Id: <20241014-add_display_support_for_qcs615-v1-0-4efa191dbdd4@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK/oDGcC/x3N0QrCMAxA0V8ZebbQjE7FXxEpXZNpQNaaTFHG/
 n3Fx/Ny7wrGKmxw6VZQ/ohJmRvw0EF+pPnOTqgZet8H9BhcIookVp/pF+1da9ElTkXjK9sRBzf
 iacyeAuKZoUWq8iTf/+B627Ydkk2RfXAAAAA=
X-Change-ID: 20241014-add_display_support_for_qcs615-b17bc0d4118e
To: kernel@quicinc.com, quic_lliu6@quicinc.com, quic_fangez@quicinc.com, 
 quic_xiangxuy@quicinc.com
Cc: linux-arm-msm@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728899259; l=1722;
 i=quic_fangez@quicinc.com; s=20241014; h=from:subject:message-id;
 bh=l+6tyAR8Y+45VN9YkwbD6ypi05FC9WhaBUBRAu7wGkc=;
 b=4J4gR/9hofkze78VJ7NJiiM+QLqxTNOFiPZMum42KqswlmRSehlEjlSCBGxflJgtFLmNnwmzE
 QaWgIf7mxvHC6LJyqdJDR6frAeDG7FTPFjjQ+eKJG0Q5gmS2jEXpg/R
X-Developer-Key: i=quic_fangez@quicinc.com; a=ed25519;
 pk=tJv8Cz0npA34ynt53o5GaQfBC0ySFhyb2FGj+V2Use4=
X-Endpoint-Received: by B4 Relay for quic_fangez@quicinc.com/20241014 with auth_id=245
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: fangez <quic_fangez@quicinc.com>
---
lliu6 (6):
      arm64: defconfig: Enable SX150X
      arm64: dts: qcom: qcs615: Add display mdss and dsi configuration
      drm/msm/dpu: Add QCS615 support
      dt-bindings: display/msm: Add QCS615 DSI phy
      dt-bindings: display/msm: Add QCS615 MDSS & DPU
      dt-bindings: display/msm: dsi-controller-main: Document QCS615

 .../bindings/display/msm/dsi-controller-main.yaml  |   1 +
 .../bindings/display/msm/dsi-phy-14nm.yaml         |   1 +
 .../bindings/display/msm/qcom,qcs615-dpu.yaml      | 117 +++++++++
 .../bindings/display/msm/qcom,qcs615-mdss.yaml     | 278 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/qcs615-ride.dts           | 101 ++++++++
 arch/arm64/boot/dts/qcom/qcs615.dtsi               | 195 +++++++++++++++
 arch/arm64/configs/defconfig                       |   1 +
 .../gpu/drm/msm/disp/dpu1/catalog/dpu_5_3_qcs615.h | 268 ++++++++++++++++++++
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.c     |   1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_hw_catalog.h     |   1 +
 drivers/gpu/drm/msm/disp/dpu1/dpu_kms.c            |   1 +
 drivers/gpu/drm/msm/dsi/dsi_cfg.c                  |  17 ++
 drivers/gpu/drm/msm/dsi/dsi_cfg.h                  |   1 +
 drivers/gpu/drm/msm/dsi/phy/dsi_phy.c              |   2 +
 drivers/gpu/drm/msm/dsi/phy/dsi_phy.h              |   1 +
 drivers/gpu/drm/msm/dsi/phy/dsi_phy_14nm.c         |  21 ++
 drivers/gpu/drm/msm/msm_mdss.c                     |   7 +
 17 files changed, 1014 insertions(+)
---
base-commit: 77dca4e0530173cb10896cc113f14e6403f0a31a
change-id: 20241014-add_display_support_for_qcs615-b17bc0d4118e

Best regards,
-- 
fangez <quic_fangez@quicinc.com>

