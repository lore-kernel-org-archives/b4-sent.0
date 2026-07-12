From: Esteban Urrutia <esteuwu@proton.me>
Date: Sat, 11 Jul 2026 23:12:27 -0400
Subject: [PATCH v2 1/2] arm64: dts: qcom: sm8450: Remove unneeded reserved
 memory nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-sm8450-qol-dts-v2-1-5eb2e86468c5@proton.me>
References: <20260711-sm8450-qol-dts-v2-0-5eb2e86468c5@proton.me>
In-Reply-To: <20260711-sm8450-qol-dts-v2-0-5eb2e86468c5@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783825961; l=1232;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=f6mm6bP5cP/VdfADQcuVdSA9XTjnVcdOZJRex2sxwV0=;
 b=TcIlcP7ncJW4UTVFJGgshY/59oDIvuuhLqZRG+qXZfwBKb2XPfoB6I8mkK7K5ngv4SZaLpm9D
 b7akfWYyzlaCxCAXlFd4dEkcJSVpvlmnzy2ApXKKooXSHkiPc+h1dlq
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These nodes are not present on downstream device trees and only take memory
away from the AP.
No crashes occur without these nodes, so remove them.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 arch/arm64/boot/dts/qcom/sm8450.dtsi | 15 ---------------
 1 file changed, 15 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8450.dtsi b/arch/arm64/boot/dts/qcom/sm8450.dtsi
index 7ddd0f5f539c..cf7c8f831fb0 100644
--- a/arch/arm64/boot/dts/qcom/sm8450.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8450.dtsi
@@ -752,11 +752,6 @@ oem_vm_mem: memory@bb000000 {
 			no-map;
 		};
 
-		mte_mem: memory@c0000000 {
-			reg = <0x0 0xc0000000 0x0 0x20000000>;
-			no-map;
-		};
-
 		qheebsp_reserved_mem: memory@e0000000 {
 			reg = <0x0 0xe0000000 0x0 0x600000>;
 			no-map;
@@ -806,16 +801,6 @@ qtee_mem: memory@e9b00000 {
 			reg = <0x0 0xe9b00000 0x0 0x500000>;
 			no-map;
 		};
-
-		trusted_apps_mem: memory@ea000000 {
-			reg = <0x0 0xea000000 0x0 0x3900000>;
-			no-map;
-		};
-
-		trusted_apps_ext_mem: memory@ed900000 {
-			reg = <0x0 0xed900000 0x0 0x3b00000>;
-			no-map;
-		};
 	};
 
 	smp2p-adsp {

-- 
2.55.0

