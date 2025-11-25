From: Kimi Chen <kimi.zy.chen@fii-foxconn.com>
Date: Tue, 25 Nov 2025 13:42:50 +0800
Subject: [PATCH v4] ARM: dts: aspeed: clemente: add gpio line name to io
 expander
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251125-dts-add-gpio-to-io-expander-v4-1-e6d31f80470c@fii-foxconn.com>
X-B4-Tracking: v=1; b=H4sIANlBJWkC/43NwY7CIBDG8VcxnHcMUIZ2PfkexgMdBuWw0EDT1
 Ji++6InkzVmL5P85/D77qJyiVzFYXcXhZdYY04tzNdO0NWlC0P0rYWWGpWSFvxcwXkPlylmmDO
 0y+vkkucCzlCniQJa50QTpsIhrk/9dG59jXXO5fYcW9Tj+z93UaBgNL1Fkt+aRz6GGCHklXJKe
 8o/4qEv+lXsP4u6iTigN8NgEI19L3Yvopafxa6JNFqUjnobBvwrbtv2CxBfBOlwAQAA
X-Change-ID: 20251106-dts-add-gpio-to-io-expander-a4c32ccf56aa
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 george.kw.lee@fii-foxconn.com, Kimi Chen <kimi.zy.chen@fii-foxconn.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764049476; l=2917;
 i=kimi.zy.chen@fii-foxconn.com; s=20251105; h=from:subject:message-id;
 bh=XlfLH7aJAuTw4x56m8cEY+a7zkKS1LZ5QGzrmf+4eBo=;
 b=NVYxgBZKetYbHl9F3aQlJ7gp9sSKijq+JKD+rU92nilq7JM5ipsoFXrjWvIGef2z64tNRTNIQ
 qSN5/IqtucmCxhNuRN8OiiBkm4RQXn/SyVOOPkY8buZeVkVwKT1wjQE
X-Developer-Key: i=kimi.zy.chen@fii-foxconn.com; a=ed25519;
 pk=3zHetsW/3CYYIgQlYV9dqSS7aW7aZXLUaIvc+OKr3NM=
X-Endpoint-Received: by B4 Relay for kimi.zy.chen@fii-foxconn.com/20251105 with auth_id=559
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The chassis power cycle process requires a forced shutdown before
cutting off the standby power. The SCM CPLD implements a hard shutdown
host function that is controlled through the IO expander in the
Clemente platform.

This change adds a new GPIO line named "shdn_force_l_cpld" to the
PCA9555 IO expander's gpio-line-names at index 10. When asserted,
this GPIO signals the CPLD to pull the HPM's SHDN_FORCE_L pin low,
which triggers a forced host shutdown.

Signed-off-by: Kimi Chen <kimi.zy.chen@fii-foxconn.com>
---
Changes in v4:
- Rebased onto latest kernel; corrected "shdn_force_l_cpld" positioning
  in gpio-line-names from line 6 (v3) to index 10 (dts array index, not device pin).
- Updated commit message to clarify "index 10" refers to gpio-line-names
  array position, not PCA9555 device pin.
- Link to v3: https://lore.kernel.org/r/20251120-dts-add-gpio-to-io-expander-v3-1-cb650ac76f85@fii-foxconn.com

Changes in v3:
- Improve commit message clarity: restructure the description to clarify the 
  complete signal flow (BMC → IO expander → "shdn_force_l_cpld" GPIO → CPLD → 
  SHDN_FORCE_L pin → HPM → forced host shutdown).
- Rename GPIO line to match the schematics net naming convention.
- Add rationale: The current standby-AC power cycling process is suboptimal.
  When HSC power is turned off while host power remains active, the FPGA may
  detect a power fault. During this fault window, the FPGA—sustained by holdup
  capacitance—asserts power brake and initiates power-down sequence. A forced
  shutdown before cutting standby power ensures the FPGA properly handles the
  AC cycle event without spurious fault assertions. This patch enables the BMC
  to perform forced shutdown via the IO expander GPIO, thereby optimizing the
  standby-AC power cycling process.
- Link to v2: https://lore.kernel.org/r/20251107-dts-add-gpio-to-io-expander-v2-1-585d48845546@fii-foxconn.com

Changes in v2:
- Add "hard_shutdown_host" GPIO line name to PCA9555 IO expander for Clemente platform.
- Link to v1: https://lore.kernel.org/r/20251106-dts-add-gpio-to-io-expander-v1-1-b4765c092ebe@fii-foxconn.com
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
index 885c50a7d665..dfe8f6d0eeef 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-clemente.dts
@@ -1013,7 +1013,7 @@ io_expander4: gpio@4f {
 			"",
 			"",
 			"",
-			"",
+			"shdn_force_l_cpld",
 			"",
 			"",
 			"",

---
base-commit: f5f4511ccb747e01ed5364e9eec7be8b62020c4b
change-id: 20251106-dts-add-gpio-to-io-expander-a4c32ccf56aa

Best regards,
-- 
Kimi Chen <kimi.zy.chen@fii-foxconn.com>

