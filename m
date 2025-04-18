From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 18 Apr 2025 21:28:54 +0200
Subject: [PATCH 4/4] powerpc: p2020: Rename wdt@ nodes to watchdog@
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250418-watchdog-v1-4-987ff2046272@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745004545; l=1065;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=Jfd85PbJEHShQtp0Z7D0ENH84wB5WrTefZVsj2LtPg4=;
 b=9Ddx++hJwjUu5ZT5RcAMKL458F4jL4oZdbNqUIm8fWLxvPqyPovL1NfQreYYdr5rYTNz/J468
 Kbeijo/OUapDOomDiJYvXXiMNPWkdWwcCjdtQrbm/WLjITPmZiWBFgf
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The watchdog.yaml schema prescribes a node name of "timer" or "watchdog"
rather than the abbreviation "wdt".

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/fsl/ge_imp3a.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/boot/dts/fsl/ge_imp3a.dts b/arch/powerpc/boot/dts/fsl/ge_imp3a.dts
index da3de8e2b7d2c55cf735f3cfdef8729655979a06..9e5c01cfac2f8ad93dfa3b33d05b3ad3331b2c76 100644
--- a/arch/powerpc/boot/dts/fsl/ge_imp3a.dts
+++ b/arch/powerpc/boot/dts/fsl/ge_imp3a.dts
@@ -94,7 +94,7 @@ gef_gpio: gpio@4,400 {
 			gpio-controller;
 		};
 
-		wdt@4,800 {
+		watchdog@4,800 {
 			compatible = "ge,imp3a-fpga-wdt", "gef,fpga-wdt-1.00",
 				"gef,fpga-wdt";
 			reg = <0x4 0x800 0x8>;
@@ -103,7 +103,7 @@ wdt@4,800 {
 		};
 
 		/* Second watchdog available, driver currently supports one.
-		wdt@4,808 {
+		watchdog@4,808 {
 			compatible = "gef,imp3a-fpga-wdt", "gef,fpga-wdt-1.00",
 				"gef,fpga-wdt";
 			reg = <0x4 0x808 0x8>;

-- 
2.48.0.rc1.219.gb6b6757d772

