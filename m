From: Nayab Sayed <nayabbasha.sayed@microchip.com>
Date: Tue, 04 Mar 2025 11:45:40 +0530
Subject: [PATCH] ARM: dts: microchip: sama7g5: add ADC hw trigger edge type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250304-sama7g5-hw-trigger-enable-v1-1-61b5618285f0@microchip.com>
X-B4-Tracking: v=1; b=H4sIAIuaxmcC/x3MwQqDMAyA4VeRnA1kreLwVYaHVGMNzG6ksgniu
 1s8fof/PyCLqWToqwNMfpr1kwoedQXjwikK6lQMjlxLnjxmXrmLLS5/3ExjFENJHN6CTxco+Km
 hxjGU/msy636/X8N5XiSpX5trAAAA
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Nayab Sayed <nayabbasha.sayed@microchip.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=922;
 i=nayabbasha.sayed@microchip.com; h=from:subject:message-id;
 bh=eJnQC/9attKgZIiaANkEiYWZpDq4uolpOBt4ZgepDmk=;
 b=owGbwMvMwCEmfMj/xNz7ei8ZT6slMaQfm7Uk+2f+9iV2N1Y/lzcXr1/UvOdZyYt864Dq3CtHD
 7Zsfq6/sqOUhUGMg0FWTJGle/P82YZFfzozf3KugJnDygQyhIGLUwAm0n6f4X9R9DI532kSk8oV
 Nsuqv5cwq2CamaXu0ay/qfTGKVGnWlZGhvnHVbi/xlzIq//9k28qi9XuJ+YfEvaLFTSdlV+z/rK
 gBBsA
X-Developer-Key: i=nayabbasha.sayed@microchip.com; a=openpgp;
 fpr=E108A58C09FB2280B0AB41DAE24318EF3B3861A3
X-Endpoint-Received: by B4 Relay for nayabbasha.sayed@microchip.com/default with auth_id=304
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set ADC trigger edge type property as interrupt edge rising value.

Signed-off-by: Nayab Sayed <nayabbasha.sayed@microchip.com>
---
 arch/arm/boot/dts/microchip/at91-sama7g5ek.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/boot/dts/microchip/at91-sama7g5ek.dts b/arch/arm/boot/dts/microchip/at91-sama7g5ek.dts
index 0f5e6ad438dd..2543599013b1 100644
--- a/arch/arm/boot/dts/microchip/at91-sama7g5ek.dts
+++ b/arch/arm/boot/dts/microchip/at91-sama7g5ek.dts
@@ -137,6 +137,7 @@ &adc {
 	vref-supply = <&vddout25>;
 	pinctrl-names = "default";
 	pinctrl-0 = <&pinctrl_mikrobus1_an_default &pinctrl_mikrobus2_an_default>;
+	atmel,trigger-edge-type = <IRQ_TYPE_EDGE_RISING>;
 	status = "okay";
 };
 

---
base-commit: 99fa936e8e4f117d62f229003c9799686f74cebc
change-id: 20250303-sama7g5-hw-trigger-enable-82b0b3d4042a

Best regards,
-- 
Nayab Sayed <nayabbasha.sayed@microchip.com>

