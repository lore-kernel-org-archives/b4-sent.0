From: Akshat Singh <automobilehacks@gmail.com>
Date: Tue, 24 Nov 2026 08:45:31 +0000
Subject: [PATCH v2 3/3] mips: dts: Connect the EcoNet EN751221 intc to
 IP2-IP6
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-en751221-intc-all-lines-v2-3-a33a520aac81@gmail.com>
References: <20261124-en751221-intc-all-lines-v2-0-a33a520aac81@gmail.com>
In-Reply-To: <20261124-en751221-intc-all-lines-v2-0-a33a520aac81@gmail.com>
To: Caleb James DeLisle <cjd@cjdns.fr>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Akshat Singh <automobilehacks@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795509928; l=1447;
 i=automobilehacks@gmail.com; s=20261115; h=from:subject:message-id;
 bh=bcpG4VqWZ5RTgbVtG1xy5hfk40cJOdNACjWS9OrS13c=;
 b=HPQU2ymqtYjchxJ2Do5M7BCXGrK6w9xpR6RbW+j7tlgS6I4XWMF4vsWjDHDn9yVIAwtxweWMM
 TtfqLPedcHLBGIo5ZEYQQipfUGnCd3aDLvb+JMHQQGuW3vVP+sSoR9v
X-Developer-Key: i=automobilehacks@gmail.com; a=ed25519;
 pk=wYmYXn6wy/XN0edTCg6D7UtE9nYLei8mbfqydGGCdf4=
X-Endpoint-Received: by B4 Relay for automobilehacks@gmail.com/20261115 with auth_id=1535
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The interrupt controller presents the number of the pending interrupt
plus one, in binary, on the CPU interrupt lines IP2-IP7. Without VEIC,
chaining it to IP2 alone leaves the odd-numbered interrupts, such as the
QDMA, xHCI and the first PCIe port, waiting for an even-numbered one to
run the handler.

List IP2-IP6. IP7 is left out: the CPU can also signal its own timer on
it, and only hwirq 31, which is unused, needs it.

Fixes: 0ec488700972 ("mips: dts: Add EcoNet DTS with EN751221 and SmartFiber XP8421-B board")
Signed-off-by: Akshat Singh <automobilehacks@gmail.com>
---
 arch/mips/boot/dts/econet/en751221.dtsi | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/arch/mips/boot/dts/econet/en751221.dtsi b/arch/mips/boot/dts/econet/en751221.dtsi
index 57ae84a8a..5e3f626b5 100644
--- a/arch/mips/boot/dts/econet/en751221.dtsi
+++ b/arch/mips/boot/dts/econet/en751221.dtsi
@@ -66,7 +66,12 @@ intc: interrupt-controller@1fb40000 {
 		compatible = "econet,en751221-intc";
 		reg = <0x1fb40000 0x100>;
 		interrupt-parent = <&cpuintc>;
-		interrupts = <2>;
+		/*
+		 * The number of the pending interrupt plus one is presented in
+		 * binary on IP2-IP7. IP7 is left out: the CPU can also signal its
+		 * own timer on it, and only hwirq 31, which is unused, needs it.
+		 */
+		interrupts = <2>, <3>, <4>, <5>, <6>;
 
 		interrupt-controller;
 		#interrupt-cells = <1>;

-- 
2.43.0

