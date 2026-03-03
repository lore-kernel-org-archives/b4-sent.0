From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Tue, 03 Mar 2026 16:09:49 +0100
Subject: [PATCH RESEND] powerpc: Move GameCube/Wii options under
 EMBEDDED6xx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260303-gcwii-kconfig-v1-1-636b288e7270@posteo.net>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Link Mauve <linkmauve@linkmauve.fr>, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772550590; l=2106;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=Xmi3nHsOpx0ZMFbJp+lFFK0uM65XCmoMsN2vzb2RwRI=;
 b=yiVBUQtZ+yjf3Bem6jDqzzZEFCyn8pmHnGrNQO0JTMrDNAXZgUUARRgjKbUoOBuq37W6WFgTu
 ewBssZJw5itAmj1Yd8mt/ux4HTcB8xa6N9MEisBWh1vemIWhMLc+/Wf
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move CONFIG_GAMECUBE and CONFIG_WII directly below other embedded6xx
boards, and above options such as TSI108_BRIDGE. This has two
advantages for the GC/Wii options:

 - They won't be moved around by USBGECKO_UDBG appearing or disappearing
 - They will be intendented in menuconfig/nconfig, to make it clear they
   are part of the embedded6xx platforms

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/platforms/embedded6xx/Kconfig | 31 +++++++++++++++---------------
 1 file changed, 16 insertions(+), 15 deletions(-)

diff --git a/arch/powerpc/platforms/embedded6xx/Kconfig b/arch/powerpc/platforms/embedded6xx/Kconfig
index c6adff216fe633..f406b3c7936b23 100644
--- a/arch/powerpc/platforms/embedded6xx/Kconfig
+++ b/arch/powerpc/platforms/embedded6xx/Kconfig
@@ -51,6 +51,22 @@ config MVME5100
 	  This option enables support for the Motorola (now Emerson) MVME5100
 	  board.
 
+config GAMECUBE
+	bool "Nintendo-GameCube"
+	depends on EMBEDDED6xx
+	select GAMECUBE_COMMON
+	help
+	  Select GAMECUBE if configuring for the Nintendo GameCube.
+	  More information at: <http://gc-linux.sourceforge.net/>
+
+config WII
+	bool "Nintendo-Wii"
+	depends on EMBEDDED6xx
+	select GAMECUBE_COMMON
+	help
+	  Select WII if configuring for the Nintendo Wii.
+	  More information at: <http://gc-linux.sourceforge.net/>
+
 config TSI108_BRIDGE
 	bool
 	select FORCE_PCI
@@ -77,18 +93,3 @@ config USBGECKO_UDBG
 
 	  If in doubt, say N here.
 
-config GAMECUBE
-	bool "Nintendo-GameCube"
-	depends on EMBEDDED6xx
-	select GAMECUBE_COMMON
-	help
-	  Select GAMECUBE if configuring for the Nintendo GameCube.
-	  More information at: <http://gc-linux.sourceforge.net/>
-
-config WII
-	bool "Nintendo-Wii"
-	depends on EMBEDDED6xx
-	select GAMECUBE_COMMON
-	help
-	  Select WII if configuring for the Nintendo Wii.
-	  More information at: <http://gc-linux.sourceforge.net/>

---
base-commit: 9448598b22c50c8a5bb77a9103e2d49f134c9578
change-id: 20260103-gcwii-kconfig-0ba5b415b99b

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

