From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 11 Jun 2025 23:07:49 +0200
Subject: [PATCH RESEND v2] powerpc/microwatt: Fix model property in device
 tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250611-microwatt-v2-1-80847bbc5f9c@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749676071; l=989;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=0awhdLFMY97nl4C5F/YShrc0qAsdI3niSehOCyjeP30=;
 b=ZMOkaTWiJOp36wFAV/SY2jnAnp+AZyYy2CRFTJPmh6K0/aofSEgV3b9vN20mTvwv9m1LN1z9J
 q8O2aN8AgxTAYFK/ucjfyFYNO1QFYmpzpBIryCvniX3UPgmg6ej1YFh
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The standard property for the model name is called "model".

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Rebase on v6.15-rc1 (no changes except line numbers)
- Link to v1: https://lore.kernel.org/r/20241225-microwatt-v1-1-8e071fcfc2bd@posteo.net
---
 arch/powerpc/boot/dts/microwatt.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/powerpc/boot/dts/microwatt.dts b/arch/powerpc/boot/dts/microwatt.dts
index c4e4d2a9b4606a689e3f9eefd1ca5bcf1aa3395f..b7eac4e56019eaa84d8afe70c639f2112defdd7d 100644
--- a/arch/powerpc/boot/dts/microwatt.dts
+++ b/arch/powerpc/boot/dts/microwatt.dts
@@ -4,7 +4,7 @@
 / {
 	#size-cells = <0x02>;
 	#address-cells = <0x02>;
-	model-name = "microwatt";
+	model = "microwatt";
 	compatible = "microwatt-soc";
 
 	aliases {

---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20241225-microwatt-d9258189aff5

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

