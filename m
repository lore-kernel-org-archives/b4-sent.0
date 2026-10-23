From: Ishu Brar <patches@brar.si>
Subject: [PATCH v2 0/2] iommu/arm-smmu-qcom: Add SM7250 support
Date: Fri, 23 Oct 2026 13:24:30 +0530
Message-Id: <20261023-smmu-sm7250-v2-0-8bb881ce19f5@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NzQ6CMBCEX4Xs2Zq2yJ8n38NwgHYrawKYLhAN6
 bvb4tXLJF8y880OjJ6Q4Zrt4HEjpnmKoE8ZmKGbHijIRgYtdamkKgWP4xqj0oUUTVFZJ7VtdJ1
 DXLw8Onoftnv7Y177J5olKVJjIF5m/znuNpV6/82bElKgUs7IvL4Y19163/kzE7QhhC/ZArMAt
 gAAAA==
X-Change-ID: 20261016-smmu-sm7250-957df02d9283
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>
Cc: linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792742166; l=1770;
 i=patches@brar.si; h=from:subject:message-id;
 bh=sQLOhZMi8aZbIqVsMhAfiz8/FuPFV6+J4pw61zOCgdE=;
 b=9Q+sBnjBwBjboIPiR/Ad0kQ1lgiFss5sSPJvkLB0DOL5jYe8jhRpQHcODvee7s5/620vV8P02
 HensHpKQT9jAyR/kTvQ7J909qy2quEecxQBdUAYoSfbETXuXqmHdH3S
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This documents SMMUs of Qualcomm SM7250 (Snapdragon
765/765G/768G) and skips Adreno SMMU PRR setup on it.

As on SM8250, firmware resets device when PRR registers are
written, which happens as soon as GPU creates its first per-process
pagetable. Patch 1 adds the compatible to binding (apps SMMU and GPU
SMMU). Patch 2 excludes it from PRR callbacks.

Tested on OnePlus Nord (SM7250) with Vulkan on Adreno 620. The SoC
devicetree nodes are not part of this series.

Signed-off-by: Ishu Brar <patches@brar.si>
---
Changes in v2:
- Patch 1: also add qcom,sm7250-smmu-500 to the allOf block that
  requires the ahb/bus/iface clocks, so the GPU SMMU clocks are
  validated like on sm8250 (sashiko review, confirmed by Krzysztof).
- Patch 2: unchanged.
- Link to v1: https://patch.msgid.link/20261016-smmu-sm7250-v1-0-e11fc0384cfa@brar.si

To: Will Deacon <will@kernel.org>
To: Robin Murphy <robin.murphy@arm.com>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Rob Clark <robin.clark@oss.qualcomm.com>
Cc: linux-arm-kernel@lists.infradead.org
Cc: iommu@lists.linux.dev
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-arm-msm@vger.kernel.org

---
Ishu Brar (2):
      dt-bindings: arm-smmu: Document SM7250 SMMU
      iommu/arm-smmu-qcom: Skip PRR setup on SM7250 GPU SMMU

 Documentation/devicetree/bindings/iommu/arm,smmu.yaml | 4 ++++
 drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c            | 1 +
 2 files changed, 5 insertions(+)
---
base-commit: 7b7429c28ac01c8a2952225a4b8a742eec7359c3
change-id: 20261016-smmu-sm7250-957df02d9283

Best regards,
--  
Ishu Brar <patches@brar.si>

