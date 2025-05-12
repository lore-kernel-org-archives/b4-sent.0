From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 12 May 2025 18:36:47 +0400
Subject: [PATCH 2/2] arm64: dts: qcom: ipq5018: enable the download mode
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250512-ipq5018-syscon-v1-2-eb1ad2414c3c@outlook.com>
References: <20250512-ipq5018-syscon-v1-0-eb1ad2414c3c@outlook.com>
In-Reply-To: <20250512-ipq5018-syscon-v1-0-eb1ad2414c3c@outlook.com>
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747060624; l=1075;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=zfAYNmt44Rxqlg/ZxmVRJXn5Sdnp96Uz5P6gJVc6Rpc=;
 b=otGj6mDMvVAeW3DAnmE1Q52E32RMPaedTO6pqYspuD6W7nLLCdgSbUcoPZ8FCW9RkP3EoOjvK
 vpkAT0R9w69DE2lsQLoC8nc9mo+VGfpPJ3n1Os6uxVbMzXJRwGyZzy1
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable support for download mode to collect RAM dumps in case of a
system crash, allowing post mortem analysis.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 8914f2ef0bc47fda243b19174f77ce73fc10757d..0abb00cfe4ce2f9bdea73deebedad8297f56322c 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -79,6 +79,7 @@ opp-1008000000 {
 	firmware {
 		scm {
 			compatible = "qcom,scm-ipq5018", "qcom,scm";
+			qcom,dload-mode = <&tcsr 0x6100>;
 			qcom,sdi-enabled;
 		};
 	};
@@ -187,6 +188,11 @@ tcsr_mutex: hwlock@1905000 {
 			#hwlock-cells = <1>;
 		};
 
+		tcsr: syscon@1937000 {
+			compatible = "qcom,tcsr-ipq5018", "syscon";
+			reg = <0x01937000 0x21000>;
+		};
+
 		sdhc_1: mmc@7804000 {
 			compatible = "qcom,ipq5018-sdhci", "qcom,sdhci-msm-v5";
 			reg = <0x7804000 0x1000>;

-- 
2.49.0

