From: Ishu Brar <patches@brar.si>
Subject: [PATCH 0/2] iommu/arm-smmu-qcom: Add SM7250 support
Date: Fri, 16 Oct 2026 15:16:39 +0530
Message-Id: <20261016-smmu-sm7250-v1-0-e11fc0384cfa@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0Mz3eLc3FIgYW5kaqBraWqekmZglGJpZGGsBNRRUJSallkBNi06FsI
 vLk3KSk0uARmhVFsLAG6DOrFvAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792144002; l=976;
 i=patches@brar.si; h=from:subject:message-id;
 bh=POI86Emv7LXTXvwaaJBvK12dMOj7PnyouyYL3O/OxHs=;
 b=z/jR/8mzWoN9+ulva91kznpd3Hm8A2A5JQJ6+dwPb9j9/g7oKoOMZAFiIq84ALgiwuk32Pa0t
 cdd324JFkduBwMLbMg5TURPTgYHTEUioKE8q+KrMkRliT8lGl5/9hRp
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
Ishu Brar (2):
      dt-bindings: arm-smmu: Document SM7250 SMMU
      iommu/arm-smmu-qcom: Skip PRR setup on SM7250 GPU SMMU

 Documentation/devicetree/bindings/iommu/arm,smmu.yaml | 3 +++
 drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c            | 1 +
 2 files changed, 4 insertions(+)
---
base-commit: 7b7429c28ac01c8a2952225a4b8a742eec7359c3
change-id: 20261016-smmu-sm7250-957df02d9283

Best regards,
--  
Ishu Brar <patches@brar.si>

