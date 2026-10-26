From: Ishu Brar <patches@brar.si>
Subject: [PATCH v3 0/2] interconnect: qcom: Add SM7250 interconnect
 provider
Date: Mon, 26 Oct 2026 23:18:16 +0530
Message-Id: <20261026-icc-sm7250-v3-0-aa303226298c@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NywrCMBBFf6VkbSSZ5qUr/0NctHG0I9hKUoNS+
 u8mdaGCywP3nDuxiIEwsm01sYCJIg19hnpVMd81/Rk5HTMzEGCkgJqT9zxeLWjBpXEKDSrZCGB
 ZuAU80WOJ7Q9vjvf2gn4shbLoKI5DeC5vSZbd33CSPNdRWS8BjNN214YmrCOxkk3wLaofEbIo0
 GrtNqqVzn3EeZ5fH0+yPe0AAAA=
X-Change-ID: 20261023-icc-sm7250-1684e6e41a02
To: Georgi Djakov <djakov@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Ishu Brar <patches@brar.si>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 Konrad Dybcio <konradybcio@kernel.org>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793036977; l=2815;
 i=patches@brar.si; h=from:subject:message-id;
 bh=XMn17Mlz1sQ1bjtBVxi9S/AkNIdkb5Ce8gNvbH3tfeM=;
 b=p6liVVIh25kiR7QvG2SeuvdfSRLRIVGeO/1/wz6ACoFFHbsJsxpSYqQSqZsuZ3JLEK0/StOyC
 LNqW8DHZp0eBSkq95HLKpvpdbRsr+jxiEbjBhLPdf1H2DCwE9dvOUWX
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the binding and the driver for the Network-On-Chip interconnect
providers of the Qualcomm SM7250 SoC (Snapdragon 765/765G/768G). They are
controlled through RPMh Bus Clock Managers, like the other RPMh based
providers. The driver follows the layout of sm7150 and sm8250, and the
nodes and BCMs come from the downstream interconnect description of the
platform.

Tested on a OnePlus Nord (a 7.3 based tree): all providers probe,
and UFS, USB, display, I2C, serial and camera ISP devices get their
paths without errors. The Adreno 620 GPU also takes its memory bandwidth
levels from these providers (the Adreno 620 series sent earlier relies on
them). The SoC devicetree nodes are not part of this series.

---
Changes in v3:
- Subject: drop the redundant trailing "bindings" (Krzysztof)
- Drop the "Child node's properties" comment (Krzysztof)
- Binding: no child nodes any more; compute-noc, mc-virt and qup-virt are
  separate compatibles on top-level nodes without reg (reg: false), as in
  the milos and kuno bindings, so patternProperties goes away (Krzysztof)
- No change to the driver
- Link to v2: https://patch.msgid.link/20261024-icc-sm7250-v2-0-0e755894b188@brar.si

Changes in v2:
- Set .enable_mask = BIT(3) on the ACV BCM, like sm8150, sm8250 and sc7180, so
  that the voter sends the one-hot APPS RSC bit instead of the scaled bandwidth
  (reported by sashiko-bot)
- Drop the IPA virtual provider (qcom,sm7250-ipa-virt, its BCM and its node IDs):
  clk-rpmh already owns the IP0 BCM through RPMH_IPA_CLK, and the sibling SoCs
  have no such provider either; otherwise icc_sync_state() would zero its vote
  (reported by sashiko-bot)
- Link to v1: https://patch.msgid.link/20261023-icc-sm7250-v1-0-1e47c1226857@brar.si

To: Georgi Djakov <djakov@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Ishu Brar <patches@brar.si>
Cc: linux-arm-msm@vger.kernel.org
Cc: linux-pm@vger.kernel.org
Cc: Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Ishu Brar (2):
      dt-bindings: interconnect: qcom: Add SM7250 RPMh NoC
      interconnect: qcom: Add SM7250 interconnect provider driver

 .../bindings/interconnect/qcom,sm7250-rpmh.yaml    |   81 +
 drivers/interconnect/qcom/Kconfig                  |   14 +
 drivers/interconnect/qcom/Makefile                 |    2 +
 drivers/interconnect/qcom/sm7250.c                 | 1642 ++++++++++++++++++++
 .../dt-bindings/interconnect/qcom,sm7250-rpmh.h    |  148 ++
 5 files changed, 1887 insertions(+)
---
base-commit: 3fd56a2833c22f62eb84297d0dbd47739632f1a0
change-id: 20261023-icc-sm7250-1684e6e41a02

Best regards,
--  
Ishu Brar <patches@brar.si>

