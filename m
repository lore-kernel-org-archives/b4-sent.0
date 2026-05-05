From: Haritha S K <haritha.k@oss.qualcomm.com>
Date: Tue, 05 May 2026 16:56:17 +0530
Subject: [PATCH v2] arm64: dts: qcom: talos: Add passive polling-delay for
 gpu-thermal zone
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260505-qcs615_gpu_cooling-v2-1-1ba42260b29d@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIANjT+WkC/32NywqDMBREf0WybsTER2tX/Y8iEuNVb9FEc1Vax
 H9vtPtuBg7MzNkYgUMgdg825mBFQms8yEvAdKdMCxxrz0xGMosSKfmkKRNp2Y5Lqa3t0bQ8zrM
 0qq5Nk4ia+eHooMH3efosfkxL9QI9H09Ho0Oarfuc1lUcvb+CVXDB61Tlt0RpmUP8sEThtKhe2
 2EIfbBi3/cvvKWFPM0AAAA=
X-Change-ID: 20260422-qcs615_gpu_cooling-39650b7ff41d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, manaf.pallikunhi@oss.qualcomm.com, 
 gaurav.kohli@oss.qualcomm.com, Haritha S K <haritha.k@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777980508; l=1005;
 i=haritha.k@oss.qualcomm.com; s=20260422; h=from:subject:message-id;
 bh=pZXEN7DVPFaFDrW/CKL2KXb/m1Lm+4AA3U1lQG1OwgM=;
 b=fjPsnfcijY1WZVTHRFxBstIPndZDmJmEQ2dXAvhXt1jShAdcpPwaRbNVaCaGvqLcbugpDZ/pJ
 XIaCuB9bTfQDECE1/VxYikBXvBBpm90hCnT/wOaXjHY4pz6nl+ciAas
X-Developer-Key: i=haritha.k@oss.qualcomm.com; a=ed25519;
 pk=ivp2P9RgsC6IkOe8JaqweeahT9pd0BVtL2d1YD8ICSg=
X-Endpoint-Received: by B4 Relay for haritha.k@oss.qualcomm.com/20260422 with auth_id=745
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a passive polling delay to ensure more than one
"passive" thermal point is considered when throttling the GPU
thermal zone.

Signed-off-by: Haritha S K <haritha.k@oss.qualcomm.com>
---
Changes in v2:
- Updated commit message.
- Link to v1: https://patch.msgid.link/20260422-qcs615_gpu_cooling-v1-1-d5a984ac29e3@oss.qualcomm.com
---
 arch/arm64/boot/dts/qcom/talos.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/talos.dtsi b/arch/arm64/boot/dts/qcom/talos.dtsi
index ff5afbfce2a4..8a3669b2d062 100644
--- a/arch/arm64/boot/dts/qcom/talos.dtsi
+++ b/arch/arm64/boot/dts/qcom/talos.dtsi
@@ -5267,6 +5267,7 @@ cpu-critical {
 
 		gpu-thermal {
 			thermal-sensors = <&tsens0 9>;
+			polling-delay-passive = <200>;
 
 			trips {
 				gpu_alert0: trip-point0 {

---
base-commit: bee6ea30c48788e18348309f891ed8afbf7702ac
change-id: 20260422-qcs615_gpu_cooling-39650b7ff41d

Best regards,
--  
Haritha S K <haritha.k@oss.qualcomm.com>

