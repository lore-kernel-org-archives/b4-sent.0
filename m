From: Biswapriyo Nath <nathbappai@gmail.com>
Date: Mon, 19 Jan 2026 15:13:03 +0000
Subject: [PATCH 1/5] arm64: dts: qcom: sm6125-xiaomi-ginkgo: Fix volume up
 button
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260119-xiaomi-ginkgo-features-v1-1-3c8fae984bda@gmail.com>
References: <20260119-xiaomi-ginkgo-features-v1-0-3c8fae984bda@gmail.com>
In-Reply-To: <20260119-xiaomi-ginkgo-features-v1-0-3c8fae984bda@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Biswapriyo Nath <nathbappai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768835583; l=1209;
 i=nathbappai@gmail.com; s=20260118; h=from:subject:message-id;
 bh=jiiaTZ15Im6IHRFc766Pp3tb05C/ONJ1MBj9QOjD0yQ=;
 b=a8AaxCiAMz5dGHdlem4D4eh1crcCVCVY9UZCvErpOPZLuNC5xt6fzQHQbmyy7RaLvV9OPw+Bc
 /bkvG/vpY+uBLyLF6WkZYkPn3YXM0uxo9BP7otEcGZB8kgQYMGj+wP9
X-Developer-Key: i=nathbappai@gmail.com; a=ed25519;
 pk=slmb/9yXbet+KTiT3EYLCp0p0MEOYa3EdjUXP+HXfjg=
X-Endpoint-Received: by B4 Relay for nathbappai@gmail.com/20260118 with auth_id=607
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gpio6 in pm6125 is used for EMMC and UFS thermal monitoring. It is
changed to the correct gpio for volume up button.

Fixes: 9b1a6c925c88 ("arm64: dts: qcom: sm6125: Initial support for xiaomi-ginkgo")

Signed-off-by: Biswapriyo Nath <nathbappai@gmail.com>
---
 arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi b/arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi
index 2605d0c94..6e0333378 100644
--- a/arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm6125-xiaomi-ginkgo-common.dtsi
@@ -85,7 +85,7 @@ gpio-keys {
 
 		key-volume-up {
 			label = "Volume Up";
-			gpios = <&pm6125_gpios 6 GPIO_ACTIVE_LOW>;
+			gpios = <&pm6125_gpios 5 GPIO_ACTIVE_LOW>;
 			linux,code = <KEY_VOLUMEUP>;
 			debounce-interval = <15>;
 			linux,can-disable;
@@ -96,9 +96,9 @@ key-volume-up {
 
 &pm6125_gpios {
 	vol_up_n: vol-up-n-state {
-		pins = "gpio6";
+		pins = "gpio5";
 		function = "normal";
-		power-source = <1>;
+		power-source = <0>;
 		bias-pull-up;
 		input-enable;
 	};

-- 
2.52.0

