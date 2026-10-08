From: Juerg Haefliger <juerg.haefliger@canonical.com>
Date: Thu, 08 Oct 2026 20:34:45 +0200
Subject: [PATCH 1/2] arm64: dts: qcom: x1-hp-omnibook-x14: Consolidate
 pmics and chassis
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261008-dts-qcom-hp-omnibook-x14-cleanup-v1-1-9702f7c6f9a0@canonical.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2242;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=j7pMf26hX8bJSWnw8uEGTbwJEDfsrIEGVVZIkhhh8uo=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBqx+K+R2lBpLey6me2EmAd3V4hxEyjkr0eM9VQ+
 itHGCEL1HSJAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCasfivgAKCRAP04sJC6ZC
 t5U5EACcu6My0DQzXypIkBrRF7Eu9omv95F5oCCZPyDcjlKsu1x3XxyAwZEGvt3CVGHV+6VztTp
 nPgSsr7+AOgZO1Bq6LVDwnx8CACex01PJRhwK76Hd/omQkaXefrLjCwhhkbt8WP1/5lCScZYi9+
 4w6j8fHMBFg2yEvBBy4fSxWUIOITdbQV2FXzVniby08xpPAu/LjeJnUTHHNwju8tLA8x/ayb4vt
 w/voxcwjYMER8jFwG1jrFWKCejfxehD+pcDZhrOYgMZ6TC+fYdC+9zAm0Oi+HS5Nezth7KKXg6B
 jgGUqhZ5Z7/LToQlZHmY5oYXCpW5qIUP6Pm4JfD3VbxAjtZtxxTfI7dj6Hg0JgeOlq80YyQq1El
 znom09+M2Osqki+uRRegZaIHHd43DXzS4iTayIh7dNffEcM+DsxUuUlN2TMszegzkVZC3Qm8R/y
 /XDTk78ThM3yo33zvdqAuHJPua2DJEkIRHX4R2uAGAtIYu7PdYuzSE4EXThsatxvVVG+SNV7Ght
 868ALpKYXGXIVBaW5pVua5k98eom9Snm44yeUa3h+Nw+YmgsI3wFt4G+z6N3Bp2k7iYMr4JAAb2
 803Arp04y6LfDjXZ2rLsfC8cOmb3kkEArxr3fPGH37nlL9OaWnpv0F6DX4bYkdCswAoX5XElcdZ
 34TX8/a7AM/PqFw==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hamoa-pmics.dtsi and chassis-type are identical across the HP Omnibook X14
boards that include this shared dtsi, so move them there.

Signed-off-by: Juerg Haefliger <juerg.haefliger@canonical.com>
---
 arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi      | 4 ++++
 arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts | 2 --
 arch/arm64/boot/dts/qcom/x1p42100-hp-omnibook-x14.dts | 3 +--
 3 files changed, 5 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi b/arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi
index 443901a09d4c..1ae68a71bb3e 100644
--- a/arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi
+++ b/arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi
@@ -10,7 +10,11 @@
 #include <dt-bindings/pinctrl/qcom,pmic-gpio.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 
+#include "hamoa-pmics.dtsi"
+
 / {
+	chassis-type = "laptop";
+
 	aliases {
 		serial0 = &uart21;
 		serial1 = &uart14;
diff --git a/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts b/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
index b79e59e1c413..5630ed1181ca 100644
--- a/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
+++ b/arch/arm64/boot/dts/qcom/x1e80100-hp-omnibook-x14.dts
@@ -7,13 +7,11 @@
 /dts-v1/;
 
 #include "hamoa.dtsi"
-#include "hamoa-pmics.dtsi"
 #include "x1-hp-omnibook-x14.dtsi"
 
 / {
 	model = "HP Omnibook X 14-fe0";
 	compatible = "hp,omnibook-x14", "qcom,x1e80100";
-	chassis-type = "laptop";
 };
 
 &gpu_zap_shader {
diff --git a/arch/arm64/boot/dts/qcom/x1p42100-hp-omnibook-x14.dts b/arch/arm64/boot/dts/qcom/x1p42100-hp-omnibook-x14.dts
index 0e4dfb0f0a2a..53a3ede856f0 100644
--- a/arch/arm64/boot/dts/qcom/x1p42100-hp-omnibook-x14.dts
+++ b/arch/arm64/boot/dts/qcom/x1p42100-hp-omnibook-x14.dts
@@ -3,8 +3,8 @@
 /dts-v1/;
 
 #include "purwa.dtsi"
-#include "hamoa-pmics.dtsi"
 #include "x1-hp-omnibook-x14.dtsi"
+
 /delete-node/ &pmc8380_6;
 /delete-node/ &pmc8380_6_thermal;
 /delete-node/ &pmc8380_6_die_temp;
@@ -12,7 +12,6 @@
 / {
 	model = "HP Omnibook X 14-fe1";
 	compatible = "hp,omnibook-x14-fe1", "qcom,x1p42100";
-	chassis-type = "laptop";
 };
 
 &gpu_zap_shader {

-- 
2.53.0

