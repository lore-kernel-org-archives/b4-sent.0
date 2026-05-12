From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Tue, 12 May 2026 19:47:28 +0200
Subject: [PATCH 1/2] arm64: dts: amlogic: t7: Fix pwm_ao_c pinmux
 definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-add-kvim4-sysled-v1-1-7178719a43e7@aliel.fr>
References: <20260512-add-kvim4-sysled-v1-0-7178719a43e7@aliel.fr>
In-Reply-To: <20260512-add-kvim4-sysled-v1-0-7178719a43e7@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1390;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=Vceb+Rx57Kg52Yl+xM01/jcuRqzhC1zMhtRZU3GpSrg=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQxZz+oM9/rIHYgxu7G+yVuoqFlDmfPno/EeN/ov7/ot59
 X/6zzS1o5SFQYyLQVZMkaV/ruWJd5ePnvm6Rz0FZg4rE8gQBi5OAZiI+GlGhqkicoyPj61ZFWio
 +TQ+5qTCFd8COxf/nVLZbzKumZ1kmM7I8O9/UkNpaTBvvkTtJdavt1YmiUhsdvzZWKyxViLuqoU
 GJwA=
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pwm_ao_c pin node was incomplete: it was missing the group name
suffix, conflating two distinct pin groups (pwm_ao_c_d and pwm_ao_c_e)
into a single, ambiguous entry.

Split the node into two separate pinmux entries:
  - pwm_ao_c_d_pins: uses group "pwm_ao_c_d"
  - pwm_ao_c_e_pins: uses group "pwm_ao_c_e"

Both alternate pins are not yet referenced by any peripheral node,
so this has no functional impact on existing boards. No backport needed.

Fixes: ee6e05a49b93 ("arm64: dts: amlogic: t7: Add PWM pinctrl nodes")
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
index 7fe72c94ed623..62f6b9baad28b 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi
@@ -400,9 +400,17 @@ mux {
 					};
 				};
 
-				pwm_ao_c_pins: pwm-ao-c {
+				pwm_ao_c_d_pins: pwm-ao-c-d {
 					mux {
-						groups = "pwm_ao_c";
+						groups = "pwm_ao_c_d";
+						function = "pwm_ao_c";
+						bias-disable;
+					};
+				};
+
+				pwm_ao_c_e_pins: pwm-ao-c-e {
+					mux {
+						groups = "pwm_ao_c_e";
 						function = "pwm_ao_c";
 						bias-disable;
 					};

-- 
2.49.0

