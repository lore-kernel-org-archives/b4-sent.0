From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH net-next 0/3] net: ipa: add Qualcomm SC8180X (IPA v4.1)
 support
Date: Wed, 25 Nov 2026 00:01:32 +0100
Message-Id: <20261125-qcom-ipa-sc8180x-v1-0-48a889acbe6b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QrCMAwAf2Xk2cAaik5/RXzoskwj2M2mSmHs3
 +3c43HcLWCSVAwuzQJJvmo6xQru0AA/QrwL6lAZqKWjc+TxzdMLdQ5o3LmuLcjn0dMpCPmhh5r
 NSUYt/+UVomSMUjLcdmOf/imctyOs6w+7508EfgAAAA==
X-Change-ID: 20261124-qcom-ipa-sc8180x-c9f427ae24db
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alex Elder <elder@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795561294; l=1671;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=B0CIwbvN+2fYF0mDco/OQwdk/RBQil8KeHGz3LsDY8I=;
 b=d/sW/21nAhnGYf05i9driPQgnzDMyy2gs1OBsU6vDu3+5t812nTY/rv9PzsBMmM8kd1E17kDT
 0Ob3TPx0sGMCyoYZlJfzu8znlC4uDwzoSZp9ZC9dAdhZ+wI5jGbQuLh
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
Robert Ijtsma (3):
      dt-bindings: net: qcom,ipa: add qcom,sc8180x-ipa compatible
      net: ipa: add IPA v4.1 register definitions
      net: ipa: add SC8180X (IPA v4.1) configuration data

 .../devicetree/bindings/net/qcom,ipa.yaml          |   1 +
 drivers/net/ipa/Makefile                           |   4 +-
 drivers/net/ipa/data/ipa_data-v4.1.c               | 319 ++++++++++++++
 drivers/net/ipa/gsi_reg.c                          |   1 +
 drivers/net/ipa/ipa_data.h                         |   1 +
 drivers/net/ipa/ipa_main.c                         |   4 +
 drivers/net/ipa/ipa_reg.c                          |   2 +
 drivers/net/ipa/ipa_reg.h                          |   1 +
 drivers/net/ipa/reg/ipa_reg-v4.1.c                 | 475 +++++++++++++++++++++
 9 files changed, 806 insertions(+), 2 deletions(-)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261124-qcom-ipa-sc8180x-c9f427ae24db

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

