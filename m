From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 18 Apr 2025 21:28:53 +0200
Subject: [PATCH 3/4] powerpc: 86xx: Rename wdt@ nodes to watchdog@
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250418-watchdog-v1-3-987ff2046272@posteo.net>
References: <20250418-watchdog-v1-0-987ff2046272@posteo.net>
In-Reply-To: <20250418-watchdog-v1-0-987ff2046272@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745004545; l=2682;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=rZMd++6lrdOvQcrT6pf6xOYPM6SAtU5WeGJhAq64EIk=;
 b=tf93aCaOdy1EsZyU9FYVRQHK9ZP9v8Ml4xUXSUXJ5nNXpjBRmV+1T7Wmr5lcS0c2kGNGLJL9f
 sEDGXlRy+WHAh+988Co+paUGx0tza3RDe8ZISXSuTmWBhgH7dOd7pUa
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The watchdog.yaml schema prescribes a node name of "timer" or "watchdog"
rather than the abbreviation "wdt".

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/fsl/gef_ppc9a.dts  | 4 ++--
 arch/powerpc/boot/dts/fsl/gef_sbc310.dts | 4 ++--
 arch/powerpc/boot/dts/fsl/gef_sbc610.dts | 4 ++--
 3 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/arch/powerpc/boot/dts/fsl/gef_ppc9a.dts b/arch/powerpc/boot/dts/fsl/gef_ppc9a.dts
index fc92bb032c517a543d6e1e498ab903f1937414f8..48a81430a8a31fc29b53fba03986b2fb984b66c1 100644
--- a/arch/powerpc/boot/dts/fsl/gef_ppc9a.dts
+++ b/arch/powerpc/boot/dts/fsl/gef_ppc9a.dts
@@ -82,7 +82,7 @@ fpga@4,0 {
 			reg = <0x4 0x0 0x40>;
 		};
 
-		wdt@4,2000 {
+		watchdog@4,2000 {
 			compatible = "gef,ppc9a-fpga-wdt", "gef,fpga-wdt-1.00",
 				"gef,fpga-wdt";
 			reg = <0x4 0x2000 0x8>;
@@ -90,7 +90,7 @@ wdt@4,2000 {
 			interrupt-parent = <&gef_pic>;
 		};
 		/* Second watchdog available, driver currently supports one.
-		wdt@4,2010 {
+		watchdog@4,2010 {
 			compatible = "gef,ppc9a-fpga-wdt", "gef,fpga-wdt-1.00",
 				"gef,fpga-wdt";
 			reg = <0x4 0x2010 0x8>;
diff --git a/arch/powerpc/boot/dts/fsl/gef_sbc310.dts b/arch/powerpc/boot/dts/fsl/gef_sbc310.dts
index 47ae85c34635bb0165004e52d15df92542406b15..8eb254b1738dde7327d5e3fc07b4bbba137b4d9c 100644
--- a/arch/powerpc/boot/dts/fsl/gef_sbc310.dts
+++ b/arch/powerpc/boot/dts/fsl/gef_sbc310.dts
@@ -79,7 +79,7 @@ fpga@4,0 {
 			reg = <0x4 0x0 0x40>;
 		};
 
-		wdt@4,2000 {
+		watchdog@4,2000 {
 			compatible = "gef,sbc310-fpga-wdt", "gef,fpga-wdt-1.00",
 				"gef,fpga-wdt";
 			reg = <0x4 0x2000 0x8>;
@@ -87,7 +87,7 @@ wdt@4,2000 {
 			interrupt-parent = <&gef_pic>;
 		};
 /*
-		wdt@4,2010 {
+		watchdog@4,2010 {
 			compatible = "gef,sbc310-fpga-wdt", "gef,fpga-wdt-1.00",
 				"gef,fpga-wdt";
 			reg = <0x4 0x2010 0x8>;
diff --git a/arch/powerpc/boot/dts/fsl/gef_sbc610.dts b/arch/powerpc/boot/dts/fsl/gef_sbc610.dts
index 5322be44b62e78bebac0fa92c0de05094b186dde..02edbb262b8f00279dea024700eebf874501f6d5 100644
--- a/arch/powerpc/boot/dts/fsl/gef_sbc610.dts
+++ b/arch/powerpc/boot/dts/fsl/gef_sbc610.dts
@@ -82,14 +82,14 @@ fpga@4,0 {
 			reg = <0x4 0x0 0x40>;
 		};
 
-		wdt@4,2000 {
+		watchdog@4,2000 {
 			compatible = "gef,fpga-wdt";
 			reg = <0x4 0x2000 0x8>;
 			interrupts = <0x1a 0x4>;
 			interrupt-parent = <&gef_pic>;
 		};
 		/* Second watchdog available, driver currently supports one.
-		wdt@4,2010 {
+		watchdog@4,2010 {
 			compatible = "gef,fpga-wdt";
 			reg = <0x4 0x2010 0x8>;
 			interrupts = <0x1b 0x4>;

-- 
2.48.0.rc1.219.gb6b6757d772

