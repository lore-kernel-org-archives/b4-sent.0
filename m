From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 11 Mar 2026 18:35:56 +0100
Subject: [PATCH 1/3] powerpc: wii: Add unit address to /memory
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260311-wii-schema-v1-1-1563ac4aefa8@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773250574; l=818;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=mJE8J3UROLwpIHwAWtFDUS3Blti09quatD3rOT0SWfg=;
 b=ylDvuZVLPNLElaZid8QO26o8IzgFIG7Yx18Wx4wLYXyw7WJPvg4rFnGOx2Pcm54GcqvJM8ODQ
 NeSWti1K4DiDImCVseuhM2kXLW+7sUJmumCcQ6mYUeWExL689YVUr/O
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes the following dtschema warning:

  arch/powerpc/boot/dts/wii.dtb: /: memory: False schema does not allow
  {'device_type': ['memory'], 'reg': [[0, 25165824], [268435456, 67108864]]}

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/wii.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/powerpc/boot/dts/wii.dts b/arch/powerpc/boot/dts/wii.dts
index e46143c3230882..e001c4c6fd79ad 100644
--- a/arch/powerpc/boot/dts/wii.dts
+++ b/arch/powerpc/boot/dts/wii.dts
@@ -29,7 +29,7 @@ chosen {
 		bootargs = "root=/dev/mmcblk0p2 rootwait udbg-immortal";
 	};
 
-	memory {
+	memory@0 {
 		device_type = "memory";
 		reg = <0x00000000 0x01800000	/* MEM1 24MB 1T-SRAM */
 		       0x10000000 0x04000000>;	/* MEM2 64MB GDDR3 */

-- 
2.51.0

