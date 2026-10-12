From: Juerg Haefliger <juerg.haefliger@canonical.com>
Date: Mon, 12 Oct 2026 17:50:58 +0200
Subject: [PATCH v2 1/2] arm64: dts: qcom: x1-hp-omnibook-x14: Consolidate
 pmics and chassis
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-dts-qcom-hp-omnibook-x14-cleanup-v2-1-c859ac395b81@canonical.com>
References: <20261012-dts-qcom-hp-omnibook-x14-cleanup-v2-0-c859ac395b81@canonical.com>
In-Reply-To: <20261012-dts-qcom-hp-omnibook-x14-cleanup-v2-0-c859ac395b81@canonical.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abel Vesa <abel.vesa@oss.qualcomm.com>, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2295;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=qnNk8lBIZZu+ycGCBRLG3YFrQOAuUw/bFF0S3K4QKy8=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBqzQH8MBTQ+LILxL/CoDc8DblfYmhq3E24TLSGE
 yK3ZEvJPiOJAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCas0B/AAKCRAP04sJC6ZC
 t/YTD/9YmBloQMDobaXd45qo/+AbH+33b25IDZfqrNapTsTUkhWe7Ou9xJ1NNPOF9jC6M/u3gew
 nV2NSXCzmpe09Y0Pge2rLGVgsLvmpmFW9/pXyMFYNd2xu3d47QgF+6+fUtxLobIdJbi2G2DJH1m
 xpNAW7JxZ7FOn0cet3vgb0K2K2DG7HMLj4AC4+nfM7GcOpyZXLBrV/6svV1gaAF2+2siilnlDvT
 UZfGaVCpjgn3d9hhNVHpYKQayOb6XmROypAGUMYRGrbOqQi6SrFAsgK+qRuMmBIs5CXZQ61wd/d
 8gDB4YSiU0IvJrGAkf96Gqj2djzf1WRj1Encm1BX0KmuX7IZWM2GGgzjhXscc3bRZKdJK99IvuC
 PNN/8XlIiK+MYJ0Jb4ilTs/wXOMkRc1vgMepzaNoTj2ddgAgQBtjMUyLvSM6AIa8HqO7kBeZcvN
 iHYODU8IUqOrNwKCdE/dgmjnsUer4NV2sQLs/9ZY63POcpyAh+N9LaXr6XdilR9LuZXSu9KATar
 WJNZtxmmuXnY/j/lr+bd/ehaOF9EP+f3NcSEgn9njLHQeVDnvblxygNxOs/JHoVQ8avXrsiee3L
 72x5g4ZLYk7IQPohJ1fMdor/pBIuj6MEe9YuAglkJEyB5gvu3WbhN789+7AK5S8KVui1ss+yK7u
 q1/+NmNns8y6C5w==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hamoa-pmics.dtsi and chassis-type are identical across the HP Omnibook X14
boards that include this shared dtsi, so move them there.

Reviewed-by: Abel Vesa <abel.vesa@oss.qualcomm.com>
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

