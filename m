From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 29 Jan 2026 01:46:31 -0600
Subject: [PATCH 2/3] arm64: dts: qcom: sm8550: Add tz-log node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260129-sm8550-abl-dtbo-v1-2-abca3be14024@gmail.com>
References: <20260129-sm8550-abl-dtbo-v1-0-abca3be14024@gmail.com>
In-Reply-To: <20260129-sm8550-abl-dtbo-v1-0-abca3be14024@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kumar Sharma <quic_vksharma@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Lei Chen <quic_chenlei@quicinc.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769672821; l=937;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=kuDPS1lxGGLEWDgl2NZmSf54NnC2W6l23QlaSfrIpcU=;
 b=FtNF3w+JDBp3IKpM79Nvrxs75KYnRL50BAUcWKnpKdrUJd8AZdy23R4XQMZDNUhuRMz7u8AXR
 b3HT8/hh2x5AFL3w/UItq6BF5EJrkhSwpbjLdBKhh7+16YTguyfCrQe
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Lei Chen <quic_chenlei@quicinc.com>

Add DT node to enable tz-log driver.

Signed-off-by: Lei Chen <quic_chenlei@quicinc.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index e3f93f4f412ded9583a6bc9215185a0daf5f1b57..740e3c238e8ed0f162dd168291f6e307ace66e80 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -5136,6 +5136,14 @@ data-pins {
 			};
 		};
 
+		qcom_tzlog: tz-log@146aa720 {
+			compatible = "qcom,tz-log";
+			reg = <0 0x146aa720 0 0x3000>;
+			qcom,hyplog-enabled;
+			hyplog-address-offset = <0x410>;
+			hyplog-size-offset = <0x414>;
+		};
+
 		apps_smmu: iommu@15000000 {
 			compatible = "qcom,sm8550-smmu-500", "qcom,smmu-500", "arm,mmu-500";
 			reg = <0 0x15000000 0 0x100000>;

-- 
2.52.0

