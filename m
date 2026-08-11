From: Robin Snyders <robin@snyders.xyz>
Date: Tue, 11 Aug 2026 22:31:47 +0200
Subject: [PATCH] arm64: dts: qcom: sm8150: describe download mode register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-submit-sm8150-dload-v1-1-1a87eefe6c89@snyders.xyz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQ5AMBBA4avIrE3SVlCuIhalg0n8pYNIxN01l
 t/ivQeEApNAnTwQ6GLhbY3QaQL95NaRkH00GGUKZbVGObuFD5TF6lyhnzfnMbNWmY6oLPsKYrk
 HGvj+r037vh+54kYDZQAAAA==
X-Change-ID: 20260811-submit-sm8150-dload-38802bee77c9
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robin Snyders <robin@snyders.xyz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786480311; l=1610;
 i=robin@snyders.xyz; s=default; h=from:subject:message-id;
 bh=IKJvXONfBx6mWcM7wTLz3EXzTj/e7+3NPE9L6/UFmew=;
 b=76HBD9DEiWH5l+Q82sYN4i/79gdPZhgaOCo8lqsVZt6vrmic8kalnfzbIfk3Okj3PFtjU6R53
 ashWuk7mojOAqQtqLYKmcvLSjbRtpaqAtyZmFjGaCgowvmjlFp4kf6c
X-Developer-Key: i=robin@snyders.xyz; a=ed25519;
 pk=Mdk5dNn+Tkcy7BWexDxBLR/s1BNz8WdqDPnr3qtYBIU=
X-Endpoint-Received: by B4 Relay for robin@snyders.xyz/default with auth_id=938
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SM8150 SCM node does not describe the TCSR download-mode register.
Without it, the SCM driver falls back to a firmware call and the
mode cookie may remain set across a warm reset, causing the next boot to
enter the Qualcomm crashdump transport.

Describe the TCSR window and point qcom,dload-mode at offset 0x13000,
matching the layout used by SM8250 and other related Qualcomm platforms.

On a OnePlus 7T Pro this changes software reboot from a reproducible
05c6:900e transition to six consecutive successful boots.

Signed-off-by: Robin Snyders <robin@snyders.xyz>
---
 arch/arm64/boot/dts/qcom/sm8150.dtsi | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8150.dtsi b/arch/arm64/boot/dts/qcom/sm8150.dtsi
index 94a3b02cb289..29cdef6b3ee2 100644
--- a/arch/arm64/boot/dts/qcom/sm8150.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8150.dtsi
@@ -610,6 +610,7 @@ cpu7_opp20: opp-2841600000 {
 	firmware {
 		scm: scm {
 			compatible = "qcom,scm-sm8150", "qcom,scm";
+			qcom,dload-mode = <&tcsr 0x13000>;
 			#reset-cells = <1>;
 		};
 	};
@@ -2176,6 +2177,11 @@ tcsr_mutex: hwlock@1f40000 {
 			#hwlock-cells = <1>;
 		};
 
+		tcsr: syscon@1fc0000 {
+			compatible = "qcom,sm8150-tcsr", "syscon";
+			reg = <0x0 0x01fc0000 0x0 0x30000>;
+		};
+
 		tcsr_regs_1: syscon@1f60000 {
 			compatible = "qcom,sm8150-tcsr", "syscon";
 			reg = <0x0 0x01f60000 0x0 0x20000>;

---
base-commit: 3d08ff75a47a3e7e2ab45a3bcab6723b4d906422
change-id: 20260811-submit-sm8150-dload-38802bee77c9

Best regards,
-- 
Robin Snyders <robin@snyders.xyz>

