From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Date: Thu, 10 Apr 2025 12:07:29 +0200
Subject: [PATCH v2 2/3] arm64: dts: qcom: x1e80100-hp-x14: remove unused
 i2c buses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250410-hp-x14-v2-2-d36414704a0a@oldschoolsolutions.biz>
References: <20250410-hp-x14-v2-0-d36414704a0a@oldschoolsolutions.biz>
In-Reply-To: <20250410-hp-x14-v2-0-d36414704a0a@oldschoolsolutions.biz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744279681; l=1346;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=ZyHx8tpkezT4PWqlyK3kuVMpZWcGl8TKWIo9oNbQYXE=;
 b=D758D0QxXhHhG79neF4c/1QKsPkT1M2ln7uW3IK/IEHVTWDOJdE4obhp2pTeW9z5575I+WhsB
 F1YVh6NG5zADoAsSjT9QAhybXlCqe5wK58knK80SxbwQwor1FSYIGp/
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

At least from Linux, these buses are not in use. Remove them from the dt.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
 .../boot/dts/qcom/x1e80100-hp-omnibook-x14.dts     | 25 ----------------------
 1 file changed, 25 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts b/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
index 582d4326d5d527d20f99e716349ea0e9c0d35099..6c0e56168eaf133b9500c32b98821fa1fc3e7a2d 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
@@ -904,15 +904,6 @@ touchpad@15 {
 	};
 };
 
-&i2c1 {
-	clock-frequency = <400000>;
-
-	status = "okay";
-
-	/* type-c PS8830 Retimer #2 0x8 */
-	/* is active on Windows */
-};
-
 &i2c3 {
 	clock-frequency = <400000>;
 
@@ -970,14 +961,6 @@ retimer_ss0_con_sbu_out: endpoint {
 	};
 };
 
-&i2c4 {
-	clock-frequency = <400000>;
-
-	status = "okay";
-
-	/* is active on Windows */
-};
-
 &i2c5 {
 	clock-frequency = <400000>;
 	status = "okay";
@@ -1018,14 +1001,6 @@ touchscreen@10 {
 	};
 };
 
-&i2c9 {
-	clock-frequency = <400000>;
-
-	status = "okay";
-
-	/* is active on Windows */
-};
-
 &lpass_tlmm {
 	spkr_01_sd_n_active: spkr-01-sd-n-active-state {
 		pins = "gpio12";

-- 
2.48.1

