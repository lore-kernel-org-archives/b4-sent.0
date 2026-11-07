From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Sat, 07 Nov 2026 21:00:50 +0100
Subject: [PATCH] iommu/arm-smmu-qcom: Add SM8550 MDSS compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-b4-smmu-sm8550-v1-1-777d0a41170b@dxdmail.cc>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNz3SQT3eLc3FIgYWFqaqBraWFqZJhiYpmanGKiBNRUUJSallkBNjA
 6trYWACyoUvRgAAAA
X-Change-ID: 20261107-b4-smmu-sm8550-98521d49ecd4
To: Rob Clark <robin.clark@oss.qualcomm.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>
Cc: iommu@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794081653; l=1170;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=I+cZ1+xcU8CJV0qjts4gYWFK7UhBiDpGLpae4t5CYy0=;
 b=NkMED2aV/LYn6RCVXeu3yCrogjKaMuCYqOcoLgxBi5pmCjZKeQcmzjGxY5BtpSm6lapuAMURR
 NGRdTTK028QAJ5nW1ofTlnfor8Sr2Tw8Z9Ne1DmhB0Kp0Bl0ZxYUqr0
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the SM8550 MDSS compatible to the clients list, as it also needs an
identity domain at boot. Otherwise the scanout of the bootloader's
splash screen causes unhandled context faults and the screen goes
black.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
Found while bringing up the display on the Samsung Galaxy Tab S9 Wi-Fi.
---
 drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c b/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
index 795e8ec7e8fa..483e9e4147b3 100644
--- a/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
+++ b/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
@@ -426,6 +426,7 @@ static const struct of_device_id qcom_smmu_client_of_match[] __maybe_unused = {
 	{ .compatible = "qcom,sm8150-mdss" },
 	{ .compatible = "qcom,sm8250-mdss" },
 	{ .compatible = "qcom,sm8450-mdss" },
+	{ .compatible = "qcom,sm8550-mdss" },
 	{ .compatible = "qcom,x1e80100-mdss" },
 	{ }
 };

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261107-b4-smmu-sm8550-98521d49ecd4

Best regards,
-- 
Nizat Mikayilli <nacht@dxdmail.cc>

