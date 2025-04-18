From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 18 Apr 2025 21:28:51 +0200
Subject: [PATCH 1/4] powerpc: 512x: Rename wdt@ node to watchdog@
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250418-watchdog-v1-1-987ff2046272@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745004545; l=756;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=i9RRcgFgqG7vVmSK4gfLWPx1rqQqfqMd2ZucazKYG/I=;
 b=F1LooNULEUf7uRf+8ft+DzMgEvMttxjoQo/CjBcTZ897BrcwUTqMni/4/CpJl3ZpI1bNTsy+q
 eJkxXaXipmyBNkxJvVIDt8R1Mk0lODMfG2doascTzJ2emZYvqHgQyMz
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The watchdog.yaml schema prescribes a node name of "timer" or "watchdog"
rather than the abbreviation "wdt".

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/mpc5121.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/powerpc/boot/dts/mpc5121.dtsi b/arch/powerpc/boot/dts/mpc5121.dtsi
index d3fc8062fbcd7b959a7edf17c8e9a28086034d69..a278fb7b9e71182582f658b30c2ea4e962edd7b7 100644
--- a/arch/powerpc/boot/dts/mpc5121.dtsi
+++ b/arch/powerpc/boot/dts/mpc5121.dtsi
@@ -112,7 +112,7 @@ ipic: interrupt-controller@c00 {
 		};
 
 		/* Watchdog timer */
-		wdt@900 {
+		watchdog@900 {
 			compatible = "fsl,mpc5121-wdt";
 			reg = <0x900 0x100>;
 		};

-- 
2.48.0.rc1.219.gb6b6757d772

