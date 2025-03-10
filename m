From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 10 Mar 2025 01:11:58 -0500
Subject: [PATCH] iommu/arm: Allow disabling Qualcomm support in arm_smmu_v3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250310-b4-qcom-smmu-v1-1-733a1398ff85@gmail.com>
X-B4-Tracking: v=1; b=H4sIAK2CzmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDY0MD3SQT3cLk/Fzd4tzcUt0Uk+TkxDQzs0TD5FQloJaCotS0zAqwcdG
 xtbUAKo+Rtl4AAAA=
X-Change-ID: 20250310-b4-qcom-smmu-d4ccaf66a1ce
To: Joerg Roedel <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Arnd Bergmann <arnd@arndb.de>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741587175; l=992;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=8mZdDIMzM15RJAJ2ViAymKW4I/RyQ463WLVTHNvdOss=;
 b=VxZlCVYBtjNtBkmmPUW9Cq2dx3v6oxhk7wRY+57QD7wraDxUu2bicinn3sWO5zq0hNa5Bto0T
 /dYzcsQuL2KB5bhHQ8pQL52WvdFKE00bBofObUCQcIpLBHOGJxLGeDO
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If ARCH_QCOM is enabled when building arm_smmu_v3, a dependency on
qcom-scm is added, which currently cannot be disabled. Add a prompt to
ARM_SMMU_QCOM to allow disabling this dependency.

Fixes: 0f0f80d9d5db ("iommu/arm: fix ARM_SMMU_QCOM compilation")
Cc: stable@vger.kernel.org
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/iommu/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iommu/Kconfig b/drivers/iommu/Kconfig
index ec1b5e32b9725bc1104d10e5d7a32af7b211b50a..cca0825551959e3f37cc2ea41aeae526fdb73312 100644
--- a/drivers/iommu/Kconfig
+++ b/drivers/iommu/Kconfig
@@ -381,6 +381,7 @@ config ARM_SMMU_MMU_500_CPRE_ERRATA
 
 config ARM_SMMU_QCOM
 	def_tristate y
+	prompt "Qualcomm SMMUv3 Support"
 	depends on ARM_SMMU && ARCH_QCOM
 	select QCOM_SCM
 	help

---
base-commit: 1110ce6a1e34fe1fdc1bfe4ad52405f327d5083b
change-id: 20250310-b4-qcom-smmu-d4ccaf66a1ce

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

