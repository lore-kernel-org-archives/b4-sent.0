From: David Heidelberg <david@ixit.cz>
Date: Thu, 02 Apr 2026 00:39:37 +0200
Subject: [PATCH v4 3/4] arm64: dts: qcom: sdm845-shift-axolotl: Convert fb
 to use memory-region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260402-beryllium-fb-v4-3-46170004da28@ixit.cz>
References: <20260402-beryllium-fb-v4-0-46170004da28@ixit.cz>
In-Reply-To: <20260402-beryllium-fb-v4-0-46170004da28@ixit.cz>
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
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzZ6pHRyFSYYyLRZSL/TNiTj6Do2Md0cQOP7X0
 s3L4IbAg8KJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac2eqQAKCRBgAj/E00kg
 cm2sD/4uehhD9AFQDG+GalI2LIZlNF9XBsx/Y/jVYmjY0CI02LmtBd2pz6IVvBv/0k+mgkc3hvC
 sIoFmjkRhmw9gjtCeeEfnWd/2FlbXnKdVdGouglPaJONvne/t6mGpPvEFMhT1GDDi83MOdR0j5g
 G9Vxfdktg1jeTYhloSYoJiAsEOIsDwEo8fa3SsaY0TcjL4hRpy4UVvwBdREKwcTvPy+gZFoINii
 4vJhAHrEaKfaJPZx5O1yz+DY7qohXje9eKFY8Nc9Zd9NQhqTM0sArWg6zz0MfXeTv1ZEGvOoaDX
 SaBlNk02CymnHhHYS/Dr8me4xts2Id5ZOKPMe5+XVrBsPUEe4r14Rxb8uOELWNPP/HyqOpFj2GU
 W7lXtujsPOAz8RBfWshPBz8UqSqhwBD/owoRjDaMWshS1kQKkzketK+6ZL4V988tB2LoAyH6o9i
 AX0ttZfXc7BTlIQPR2t21lAWelKunDO6cV1LlS9CprWwF2+bwS2AejB3dWt6wB774YAaorwtZvu
 tk3oRJ5jxyLSX/gpbKZ4TU84xgY42hQ5DfiHDyWhMSu5IFEYDwRAAcDmedIfJ9k0qSo/ZYtnN4u
 iIapS+9KX6EtykGIG8qGy5fXGul9a5ZkHqVLXY68DMgC5+lqwZU+GpSDAOYi7X/ar4BqUr8SIJL
 baSzgn8uARsG07Q==
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

