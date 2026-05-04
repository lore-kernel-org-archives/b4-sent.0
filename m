From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 04 May 2026 21:25:02 +0300
Subject: [PATCH 10/13] ARM: dts: mediatek: mt6323: add support for AUXADC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-mt6323-v1-10-799b58b355ff@protonmail.com>
References: <20260504-mt6323-v1-0-799b58b355ff@protonmail.com>
In-Reply-To: <20260504-mt6323-v1-0-799b58b355ff@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Lee Jones <lee@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-pm@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777919095; l=814;
 i=rva333@protonmail.com; s=20260325; h=from:subject:message-id;
 bh=La2MB3KRVqMYMwKFh7B+QquLap8lejJsUVONHZ0oCfM=;
 b=If4UY3kmkGiEJJtVFcFrKYvQsaQvfITJvuCaHU1csy8WFVf6gx+wsgv7vYyM5HTJ73TbQgOTx
 WkNqaEcst4fCb1ix8Y3iJ4sOMMXOH9KGgZQl8YBm0mb/AlQVmgIlyRm
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=euuVBZGtA2Cqb8Dju84qpQPhvwxyUirJlXpqEPQWKBM=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260325 with auth_id=695
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the devicetree node for the mt6323 AUXADC.

Tested-by: Ben Grisdale <bengris32@protonmail.ch> # Amazon Echo Dot (2nd Generation)
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 arch/arm/boot/dts/mediatek/mt6323.dtsi | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm/boot/dts/mediatek/mt6323.dtsi b/arch/arm/boot/dts/mediatek/mt6323.dtsi
index c230c865116d..c070f4b0936c 100644
--- a/arch/arm/boot/dts/mediatek/mt6323.dtsi
+++ b/arch/arm/boot/dts/mediatek/mt6323.dtsi
@@ -14,6 +14,11 @@ pmic: mt6323 {
 		interrupt-controller;
 		#interrupt-cells = <2>;
 
+		mt6323_adc: adc {
+			compatible = "mediatek,mt6323-auxadc";
+			#io-channel-cells = <1>;
+		};
+
 		mt6323_leds: leds {
 			compatible = "mediatek,mt6323-led";
 			#address-cells = <1>;

-- 
2.53.0

