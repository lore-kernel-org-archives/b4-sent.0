From: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
Date: Thu, 05 Jun 2025 19:06:06 -0500
Subject: [PATCH] arm64: defconfig: Enable Qualcomm CPUCP mailbox driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250605-enable-cpucp-v1-1-111ecef7e4c9@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAO0wQmgC/x3MQQqAIBBA0avIrBNGw6CuEi3UxhoIE6UIpLsnL
 d/i/wqFMlOBSVTIdHPhMzaoToDfbdxI8toMGrXBAY2kaN1B0qfLJzkqa9D0AV1Q0JKUKfDz7+b
 lfT8Vhg+VXgAAAA==
X-Change-ID: 20250605-enable-cpucp-91a5053f0bf1
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749168367; l=931;
 i=bjorn.andersson@oss.qualcomm.com; s=20250318; h=from:subject:message-id;
 bh=mwZCvU5SjPvj2kO7B5ZfonxzycfZ+NOz+VGaDsi0ueE=;
 b=L05l4pr3UPZUZ5Tco/EHocmMvBvnHuoV/CG26hOOlmpoGvi0y/J50xiVyWHqBhKDtLGRRVJKx
 4BWrg4OWuZ6ByYUBCzvI5YNd+uPCN6J6cirhNYCrvDjo7wT9Z4C8hnI
X-Developer-Key: i=bjorn.andersson@oss.qualcomm.com; a=ed25519;
 pk=rD3O9C9Erg+mUPBRBNw91AGaIaDVqquHZbnn6N6xh6s=
X-Endpoint-Received: by B4 Relay for bjorn.andersson@oss.qualcomm.com/20250318 with auth_id=362
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Qualcomm CPUCP mailbox driver needs to be enabled for CPU frequency
scaling to work on the X Elite platform, so enable this driver.

Signed-off-by: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index 62d3c87858e1817bac291780dff3823dacd72510..d3ef95df7b2770ac1c7a6022a9ec22d1fb4c25da 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -1447,6 +1447,7 @@ CONFIG_PLATFORM_MHU=y
 CONFIG_BCM2835_MBOX=y
 CONFIG_QCOM_APCS_IPC=y
 CONFIG_MTK_ADSP_MBOX=m
+CONFIG_QCOM_CPUCP_MBOX=m
 CONFIG_QCOM_IPCC=y
 CONFIG_ROCKCHIP_IOMMU=y
 CONFIG_TEGRA_IOMMU_SMMU=y

---
base-commit: 4f27f06ec12190c7c62c722e99ab6243dea81a94
change-id: 20250605-enable-cpucp-91a5053f0bf1

Best regards,
-- 
Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>

