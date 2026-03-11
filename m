From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 11 Mar 2026 18:35:57 +0100
Subject: [PATCH 2/3] powerpc: wii: Fix GPIO key name pattern
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260311-wii-schema-v1-2-1563ac4aefa8@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773250574; l=841;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=tYdEm39DKLsN+x1RpeowsrJyD+YP6FEzuLwykYwk9Tg=;
 b=eu9NoxwayNEl+/lwzPRUx2hDf2f/CIq8ukS16+rS7u1veFXrlYg4Je6EO0OllPuFTl0P/IFJQ
 m4mqXChvjZiDuGcPr2pjiPZEde5GpJVtDCvkqzolstrWf79oQpkrfo5
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adjust the names of GPIO key nodes to comply with the schema in
Documentation/devicetree/bindings/input/gpio-keys.yaml.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/wii.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/boot/dts/wii.dts b/arch/powerpc/boot/dts/wii.dts
index e001c4c6fd79ad..57d428b1f78740 100644
--- a/arch/powerpc/boot/dts/wii.dts
+++ b/arch/powerpc/boot/dts/wii.dts
@@ -256,13 +256,13 @@ drive-slot {
 	gpio-keys {
 		compatible = "gpio-keys";
 
-		power {
+		button-power {
 			label = "Power Button";
 			gpios = <&GPIO 0 GPIO_ACTIVE_HIGH>;
 			linux,code = <KEY_POWER>;
 		};
 
-		eject {
+		button-eject {
 			label = "Eject Button";
 			gpios = <&GPIO 6 GPIO_ACTIVE_HIGH>;
 			linux,code = <KEY_EJECTCD>;

-- 
2.51.0

