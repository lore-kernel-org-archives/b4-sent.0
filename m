From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 11 Mar 2026 18:35:58 +0100
Subject: [PATCH 3/3] powerpc: wii: Fix LED name pattern
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260311-wii-schema-v1-3-1563ac4aefa8@posteo.net>
References: <20260311-wii-schema-v1-0-1563ac4aefa8@posteo.net>
In-Reply-To: <20260311-wii-schema-v1-0-1563ac4aefa8@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Link Mauve <linkmauve@linkmauve.fr>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773250574; l=871;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=dxb0z+bZ6O263uGIQqre6Tj1enaP+WCL8KxxI5d4cWs=;
 b=/DY0cdSzCp+gX0zwhnW/DRGuhSs6t4aMpw8W11d0LWq3iAuY1blw7ZZz1vd1oIlFVAj6gYZsm
 TZErN6bNY7iCXITcJLnMMEvkwmrAYDDM1p83HUi9jzS5WW9mpok8FV4
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adjust the name of the drive slot LED node to comply with the schema in
Documentation/devicetree/bindings/leds/leds-gpio.yaml.

  arch/powerpc/boot/dts/wii.dtb: gpio-leds: 'drive-slot' does not match
  any of the regexes: '(^led-[0-9a-f]$|led)', 'pinctrl-[0-9]+'

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/wii.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/powerpc/boot/dts/wii.dts b/arch/powerpc/boot/dts/wii.dts
index 57d428b1f78740..473d9feb9cdb83 100644
--- a/arch/powerpc/boot/dts/wii.dts
+++ b/arch/powerpc/boot/dts/wii.dts
@@ -246,7 +246,7 @@ gpio-leds {
 		compatible = "gpio-leds";
 
 		/* This is the blue LED in the disk drive slot */
-		drive-slot {
+		led-0 {
 			label = "wii:blue:drive_slot";
 			gpios = <&GPIO 5 GPIO_ACTIVE_HIGH>;
 			panic-indicator;

-- 
2.51.0

