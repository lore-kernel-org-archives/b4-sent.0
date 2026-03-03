From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 03 Mar 2026 20:05:00 +0100
Subject: [PATCH RESEND] powerpc: DTS: mpc8313erdb: Add
 timer@*/clock-frequency properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260303-timer-clock-v1-1-68336d3161f3@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, kernel test robot <lkp@intel.com>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772564704; l=1719;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=wToNi3p+7oH/fZkL7rybDw1OVJ8Mht3DHd2zANSoxwc=;
 b=1Y5vaGMTDSwDyTMDt6bOuEi0MTG9ayKBdBMjYkAgwux3aVe+bMocyRNbMftjIT1i5M06PHR/u
 RYochVODplxD1OWG3jKHme3675+QXAlXsjdItXL+fq+xU5SFOARPLdr
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The recent formalization of the fsl,gtm schema has shown that
mpc8313erdb.dts doesn't provide the clock-frequency property on timer
nodes. A few different expectations collide here:

 - Both the binding and the driver for the Freescale global timer module
   (GTM) have always required clock-frequency, since their addition in
   2008 (v2.6.26-rc5-236-g83ff9dcf375c41).
 - mpc8313erdb.dts never had the timer@*/clock-frequency property, since
   the timer nodes were added in 2008 (v2.6.26-3343-g574366128db29e)

I suspect the way this worked was that the bootloader filled these
values when booting on an MPC8313 board.

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202505300136.HOpO5P6y-lkp@intel.com/
Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/mpc8313erdb.dts | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/powerpc/boot/dts/mpc8313erdb.dts b/arch/powerpc/boot/dts/mpc8313erdb.dts
index 09508b4c8c7309..0bddc3be9e62f8 100644
--- a/arch/powerpc/boot/dts/mpc8313erdb.dts
+++ b/arch/powerpc/boot/dts/mpc8313erdb.dts
@@ -308,6 +308,7 @@ gtm1: timer@500 {
 			reg = <0x500 0x100>;
 			interrupts = <90 8 78 8 84 8 72 8>;
 			interrupt-parent = <&ipic>;
+			clock-frequency = <0>; /* filled by bootloader */
 		};
 
 		timer@600 {
@@ -315,6 +316,7 @@ timer@600 {
 			reg = <0x600 0x100>;
 			interrupts = <91 8 79 8 85 8 73 8>;
 			interrupt-parent = <&ipic>;
+			clock-frequency = <0>; /* filled by bootloader */
 		};
 	};
 

---
base-commit: 9448598b22c50c8a5bb77a9103e2d49f134c9578
change-id: 20250625-timer-clock-e03fa9e835c8

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

