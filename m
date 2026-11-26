From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH net-next v2 0/3] net: ipa: add Qualcomm SC8180X (IPA v4.1)
 support
Date: Thu, 26 Nov 2026 09:14:04 +0100
Message-Id: <20261126-qcom-ipa-sc8180x-v2-0-89eba621da95@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEzqB2sC/2WNQQ6CMBREr0L+2m9oU7G48h6GRVs+UCMF20owh
 Ltb0J3Lycybt0AgbynAJVvA02SDHVwK/JCB6ZRrCW2dMvCcF4xxgU8z9GhHhcFIJvMZTdkIflb
 ERa0hYaOnxs775Q0cRXQ0R6i+TXjpO5m4PW7bzoY4+Pdun9hO/ESnf9HEMEchlZSlMpoKfW17Z
 R/HtINqXdcPpzxlH8wAAAA=
X-Change-ID: 20261124-qcom-ipa-sc8180x-c9f427ae24db
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alex Elder <elder@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795680844; l=2392;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=LPIY74EAuDUdSq0niHRQBOSjkztNa0/vNTUuA9b4jAY=;
 b=YMDZoZv3e8AeOJYNd4X9E3+cFgaEXfscnjeODtRGQ/nuWEheGaJFkGvn9u2PRcEYNzsDgb8TC
 8LZyBg0MSBuAMoeRnlF1GoVk3QIlxqRRQgawIVMouFd52M8hbTt4t62
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Devicetree binding documentation, IPA v4.1 register definitions, and
SC8180X configuration data for the Qualcomm IP Accelerator v4.1 present
on the SC8180X SoC.

Register layouts, resource group limits, and shared/IMEM regions were
cross-referenced against the downstream Qualcomm msm-4.14 poipu/sm8150
IPA v4.1 driver and SC8180X devicetree definitions. The corresponding
sc8180x.dtsi node will be submitted separately via the Qualcomm SoC
tree.

Tested end-to-end on Microsoft Surface Pro X SQ2 (SC8180X) with the
integrated Snapdragon X24 LTE modem over rmnet_ipa0 (QMAP / MAPv4).

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Changes in v2:
- Drop deprecated imem_addr/imem_size from SC8180X ipa_mem_data so the
  IPA IMEM slice is obtained from devicetree (Konrad Dybcio).
- Omit v4.2+ SSPND_PA_NO_START_STATE and v4.2-only SSPND_PA_NO_BQ_STATE
  from ipa_regs_v4_1 IPA_TX_CFG field masks.
- Set IPA_ENDPOINT_AP_COMMAND_TX .tre_count = 256 to match .event_count,
  omit unreferenced modem endpoints (MODEM_COMMAND_TX and MODEM_LAN_RX),
  index ipa_resource_src/dst using IPA_RESOURCE_TYPE_* and
  IPA_RSRC_GROUP_* enums, and express .backward_compat with BIT(BCR_*)
  flags.
- Pick up Krzysztof Kozlowski's Reviewed-by on patch 1/3.
- Link to v1: https://patch.msgid.link/20261125-qcom-ipa-sc8180x-v1-0-48a889acbe6b@gmail.com

---
Robert Ijtsma (3):
      dt-bindings: net: qcom,ipa: add qcom,sc8180x-ipa compatible
      net: ipa: add IPA v4.1 register definitions
      net: ipa: add SC8180X (IPA v4.1) configuration data

 .../devicetree/bindings/net/qcom,ipa.yaml          |   1 +
 drivers/net/ipa/Makefile                           |   4 +-
 drivers/net/ipa/data/ipa_data-v4.1.c               | 354 ++++++++++++++++
 drivers/net/ipa/gsi_reg.c                          |   1 +
 drivers/net/ipa/ipa_data.h                         |   1 +
 drivers/net/ipa/ipa_main.c                         |   4 +
 drivers/net/ipa/ipa_reg.c                          |   2 +
 drivers/net/ipa/ipa_reg.h                          |   1 +
 drivers/net/ipa/reg/ipa_reg-v4.1.c                 | 472 +++++++++++++++++++++
 9 files changed, 838 insertions(+), 2 deletions(-)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261124-qcom-ipa-sc8180x-c9f427ae24db

Best regards,
-- 
Robert Ijtsma <robertijtsma@gmail.com>

