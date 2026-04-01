From: David Heidelberg <david@ixit.cz>
Date: Wed, 01 Apr 2026 22:40:16 +0200
Subject: [PATCH v3 3/4] arm64: dts: qcom: sdm845-shift-axolotl: Convert fb
 to use memory-region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260401-beryllium-fb-v3-3-ec7d443402ab@ixit.cz>
References: <20260401-beryllium-fb-v3-0-ec7d443402ab@ixit.cz>
In-Reply-To: <20260401-beryllium-fb-v3-0-ec7d443402ab@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Sam Day <me@samcday.com>, Dzmitry Sankouski <dsankouski@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1355; i=david@ixit.cz;
 h=from:subject:message-id; bh=D5MWNeEDbREP1CY/G2xbH5lREdxUtDqmzDAssXMN22Y=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzYKu9kIyOgQCRgFC5IBYjrv+2demvqAVpbNM/
 qbBWcmvplWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2CrgAKCRBgAj/E00kg
 ct7SD/wLa3/+aQwIM8t95Eg9VjpUaQNFTnvFegPVj5XxKIz0NxuF7fHYc4nuiPu0D8L2rQ4cppN
 GQKFDxXFB4YxnllkQv0wueKE9LZpNvQRoe4UC6yFG89a8yryp1v2f0G8I4DB9bHi0jkFcKtxoW8
 LJi+9ZYA9id9VZ6o3huwDiqS2S2CLOOnEPRTAlfyXAHljaaCCgEPYH3N87rb8AyTZiEY3budMcN
 wpJNt6arUw2vKFfvKe3pJmQb68qgCuohhh0vEks5AYtwyE77FsXjOpM74K30pgGpy+cRmkWb0Y0
 cXlBYgFFEN/S8tcvEpeluGLMX7Jv8nQZ4G2nefW9c+p1aTOuv315qRZcm3Ch0oMrQW5pCaUTwXf
 vCbMAXTNd1wfnwXMJifaNfck7Cg7MB/l1QcJQ0PZ3qM0cnOnpO2x9sX3AjtrcBDF97QHieiF+PI
 FzLrancw3Nma7eCCTE/dbKY8Wryf4UcZBWFzpwosnP9TQodMQmzBYsXh+q3YCMa2K3pz8owMwfA
 AEHuxAk/xBoI7kRRacSfjf8EIa2tHnPGG5ZYwJ+MQQs9QrH9f3O3DOVUze8PUecBkz+J3r6n+3S
 uppedzA7SSi6EVC+R4rWRiM3c8Kq6+Gk11u3kr0Lm3ukXw4MpL50q+mhTUDjVh6ZVjEt9ILaF4q
 +l/XLgLz8gjVscg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of manually specifying reg, reuse the memory region.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 740eb22550724..88d970268e282 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -23,7 +23,7 @@ / {
 	qcom,board-id = <11 0>;
 
 	aliases {
-		display0 = &framebuffer0;
+		display0 = &framebuffer;
 		serial0 = &uart9;
 		serial1 = &uart6;
 	};
@@ -36,9 +36,9 @@ chosen {
 		stdout-path = "serial0";
 
 		/* Use framebuffer setup by the bootloader. */
-		framebuffer0: framebuffer@9d400000 {
+		framebuffer: framebuffer {
 			compatible = "simple-framebuffer";
-			reg = <0x0 0x9d400000 0x0 (1080 * 2160 * 4)>;
+			memory-region = <&framebuffer_mem>;
 			width = <1080>;
 			height = <2160>;
 			stride = <(1080 * 4)>;
@@ -62,7 +62,7 @@ key-vol-up {
 	};
 
 	reserved-memory {
-		framebuffer@9d400000 {
+		framebuffer_mem: framebuffer@9d400000 {
 			reg = <0x0 0x9d400000 0x0 (1080 * 2160 * 4)>;
 			no-map;
 		};

-- 
2.53.0

