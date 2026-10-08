From: Juerg Haefliger <juerg.haefliger@canonical.com>
Date: Thu, 08 Oct 2026 20:34:46 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: hp-elitebook-ultra-g1q: Drop
 omnibook-x14.dts include
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-dts-qcom-hp-omnibook-x14-cleanup-v1-2-9702f7c6f9a0@canonical.com>
References: <20261008-dts-qcom-hp-omnibook-x14-cleanup-v1-0-9702f7c6f9a0@canonical.com>
In-Reply-To: <20261008-dts-qcom-hp-omnibook-x14-cleanup-v1-0-9702f7c6f9a0@canonical.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1423;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=36Xroda5BgwIhkZde/g7EP2PrCQr/TI7HkISUfuROf4=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBqx+K+XCdXfVAjulej4V6gmwDfwDUz7sI6Woj0u
 3iC0/3asQ+JAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCasfivgAKCRAP04sJC6ZC
 t5GWD/9LFkLKo+6BEYan3hqibByPRyQD/xaLIjARQXfDcQGm/Rvj+bOSiO1k8mWJaEo1EahCGDq
 KVhS9q7em4FxXGBUTSQFoVVprEywK5noURAU5hu3zFntZxlsADveQFbJi2c/Uh3+H7WfWHUCUGr
 bp1vubWGpULCeeHjyWUPSL3AItljrZO367le+6+oV6mJrNQXw+cyOYx3qdxkVGsozTVQWgR2a7Y
 hNfOa5C/80pVYvsWrMb1uFHUN0GRQ0PoHDHpPWz9UUIJPhwMCZnUNUlxaa4GaL4wYL36lzbI8/1
 O6dWQYiqf6NKTKmQ72Dfw3JDBnK/LgG3PFWCSsc6MoWVhEb9LGAhgWSLaqcicgNI2+sH5bvswm7
 rWioLzAh1WdbQpTVOm93ce6FaI046TvMAaWs0KvOYcO6mW7QbvtFMxdF0ZHzMDRTurZwMsdV5NZ
 BGqjDGBCEAOekkYUnGCGmg0T2O3Uqrcsh/e0KBt1XI286lZvu6gLW/xAld9ki72SqGlfbde8WOx
 6PoUwe6V3RK/TRecx+9FkegJXL5kb7IbP/pH3hZ0NwyZAtHBpZFN60+K+mWplIpYQNCDLqquxgo
 GwRLwK53ZRXYdiPkUoVNPj8NW09q8GYG+ZYzsrm8pMDs63pgToT/Yqcohyji4ojODstTSFFwnKo
 d8eTK11o/vj+5pA==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The EliteBook Ultra G1q is a different product from the OmniBook X14 that
happens to reuse the same mainboard, not a variant of it. As such, it
should not be a child of x1e80100-hp-omnibook-x14 but rather a sibling.
Include the shared base platform dtsi to match the other OmniBook X14s.

Signed-off-by: Juerg Haefliger <juerg.haefliger@canonical.com>
---
 arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts b/arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts
index 0b3b6cb23e1a..9327eaa16b92 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-hp-elitebook-ultra-g1q.dts
@@ -2,7 +2,8 @@
 
 /dts-v1/;
 
-#include "x1e80100-hp-omnibook-x14.dts"
+#include "hamoa.dtsi"
+#include "x1-hp-omnibook-x14.dtsi"
 
 / {
 	model = "HP EliteBook Ultra G1q";
@@ -16,11 +17,15 @@ &gpu_zap_shader {
 &remoteproc_adsp {
 	firmware-name = "qcom/x1e80100/hp/elitebook-ultra-g1q/qcadsp8380.mbn",
 			"qcom/x1e80100/hp/elitebook-ultra-g1q/adsp_dtbs.elf";
+
+	status = "okay";
 };
 
 &remoteproc_cdsp {
 	firmware-name = "qcom/x1e80100/hp/elitebook-ultra-g1q/qccdsp8380.mbn",
 			"qcom/x1e80100/hp/elitebook-ultra-g1q/cdsp_dtbs.elf";
+
+	status = "okay";
 };
 
 &sound {

-- 
2.53.0

