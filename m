From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Thu, 15 Oct 2026 19:54:09 +0200
Subject: [PATCH v6 1/4] arm64: dts: amlogic: t7: Add cooling cells to all
 CPUs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-add-thermal-t7-vim4-v6-1-37d1c954390c@aliel.fr>
References: <20261015-add-thermal-t7-vim4-v6-0-37d1c954390c@aliel.fr>
In-Reply-To: <20261015-add-thermal-t7-vim4-v6-0-37d1c954390c@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2150;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=pWfl7HrfY/sohfU3J31MDc3TckJ5tV1lL5L4g5UHqnU=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ9ZF4RL7iPpni/7yLXnJ8ZCf41X2xIIdUtnPH+3S3Sy1N
 YDFQrG7o5SFQYyLQVZMkaV/ruWJd5ePnvm6Rz0FZg4rE8gQBi5OAZjIJSuGf+atK6OEFB7/T3YQ
 1997bfG5h5n3ondOPG0UccDw7+5g/8UMv9lnNSvvuvJVbP48k3M3K+tONNwMvpDHwRNy8fDm0Bk
 H+jgA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add #cooling-cells = <2> to all CPU nodes (both little and big cluster)
to allow them to be used as cooling devices in thermal zone mappings.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
index 6894c06a836bc..8aa85aab30469 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
@@ -63,6 +63,7 @@ cpu100: cpu@100 {
 			i-cache-size = <0x8000>;
 			i-cache-sets = <32>;
 			next-level-cache = <&l2_cache_l>;
+			#cooling-cells = <2>;
 		};
 
 		cpu101: cpu@101 {
@@ -77,6 +78,7 @@ cpu101: cpu@101 {
 			i-cache-size = <0x8000>;
 			i-cache-sets = <32>;
 			next-level-cache = <&l2_cache_l>;
+			#cooling-cells = <2>;
 		};
 
 		cpu102: cpu@102 {
@@ -91,6 +93,7 @@ cpu102: cpu@102 {
 			i-cache-size = <0x8000>;
 			i-cache-sets = <32>;
 			next-level-cache = <&l2_cache_l>;
+			#cooling-cells = <2>;
 		};
 
 		cpu103: cpu@103 {
@@ -105,6 +108,7 @@ cpu103: cpu@103 {
 			i-cache-size = <0x8000>;
 			i-cache-sets = <32>;
 			next-level-cache = <&l2_cache_l>;
+			#cooling-cells = <2>;
 		};
 
 		cpu0: cpu@0 {
@@ -119,6 +123,7 @@ cpu0: cpu@0 {
 			i-cache-size = <0x10000>;
 			i-cache-sets = <64>;
 			next-level-cache = <&l2_cache_b>;
+			#cooling-cells = <2>;
 		};
 
 		cpu1: cpu@1 {
@@ -133,6 +138,7 @@ cpu1: cpu@1 {
 			i-cache-size = <0x10000>;
 			i-cache-sets = <64>;
 			next-level-cache = <&l2_cache_b>;
+			#cooling-cells = <2>;
 		};
 
 		cpu2: cpu@2 {
@@ -147,6 +153,7 @@ cpu2: cpu@2 {
 			i-cache-size = <0x10000>;
 			i-cache-sets = <64>;
 			next-level-cache = <&l2_cache_b>;
+			#cooling-cells = <2>;
 		};
 
 		cpu3: cpu@3 {
@@ -161,6 +168,7 @@ cpu3: cpu@3 {
 			i-cache-size = <0x10000>;
 			i-cache-sets = <64>;
 			next-level-cache = <&l2_cache_b>;
+			#cooling-cells = <2>;
 		};
 
 		l2_cache_l: l2-cache-cluster0 {

-- 
2.49.0

