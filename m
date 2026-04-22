From: Haritha S K <haritha.k@oss.qualcomm.com>
Date: Wed, 22 Apr 2026 19:15:55 +0530
Subject: [PATCH] arm64: dts: qcom: talos: Add passive polling-delay to
 gpu-thermal zone
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-qcs615_gpu_cooling-v1-1-d5a984ac29e3@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIABLR6GkC/yXMQQqDMBBA0avIrBtIUk3RqxSRGifpiCSa0VIQ7
 95Ul2/x/w6MiZChKXZI+CGmGDLUrQD7fgWPgoZs0FIbWWotFstGVZ2ft87GOFHw4l6bSvYP50o
 1QA7nhI6+5/TZXuatH9Gu/xMcxw8CLHVjdgAAAA==
X-Change-ID: 20260422-qcs615_gpu_cooling-39650b7ff41d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, manaf.pallikunhi@oss.qualcomm.com, 
 gaurav.kohli@oss.qualcomm.com, Haritha S K <haritha.k@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776865565; l=853;
 i=haritha.k@oss.qualcomm.com; s=20260422; h=from:subject:message-id;
 bh=bEeXthao5AxPlUbPaBK/C+/v/mQ8p69utkWRhhz7Ow8=;
 b=oT2QuqyLDyfY+zGIZ7EJKJa21B2m+lISVcXqxQkjhwPo0EMKWjPwHZ8QUL2EKVqvCCS6kt3b5
 yT5jT3ePYvtArhgxaD5bqyc07ke9NAv4PERBA+UeHYUJ9zuDYeFWnIc
X-Developer-Key: i=haritha.k@oss.qualcomm.com; a=ed25519;
 pk=ivp2P9RgsC6IkOe8JaqweeahT9pd0BVtL2d1YD8ICSg=
X-Endpoint-Received: by B4 Relay for haritha.k@oss.qualcomm.com/20260422 with auth_id=745
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a passive polling-delay to the gpu-thermal thermal zone on Talos
to ensure periodic temperature monitoring while in passive mode.

Signed-off-by: Haritha S K <haritha.k@oss.qualcomm.com>
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

