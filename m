From: Dirk Chen <dirkchen@amd.com>
Date: Mon, 09 Feb 2026 15:58:53 +0800
Subject: [PATCH v2] ARM: dts: aspeed: anacapa: Add retimer EEPROMs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-b4-anacapa-dts-fix-v2-1-fe446a7038bf@amd.com>
X-B4-Tracking: v=1; b=H4sIALyTiWkC/32NOw7CMBBErxJtzSLbmF8q7oFSrH/ERZzIjixQ5
 Luz5AA0I72R5s0GxefoC/TdBtnXWOKcGNShAztSenmMjhmUUBfBgUYjJbK0ELq1YIhvVOIagr/
 TyQgLPFyy53qXPgfmMZZ1zp/9o8pf+1dXJUp2Om2ElPp21g+a3NHOEwyttS/r+y4osgAAAA==
X-Change-ID: 20260202-b4-anacapa-dts-fix-207ffe9a3b0c
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Dirk Chen <dirkchen@amd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770623940; l=1517;
 i=dirkchen@amd.com; s=20260202; h=from:subject:message-id;
 bh=q1pvDHup26t2gWq6fHUSx5KhOyJaw4CQELJ2qKSf88g=;
 b=+d5clqSgm87rC1q9Ol08GoDm3+lw2SvRxI9fXdTjZLhpFf6cW2vjFrUdJO1WfZNI5XmE+g+Y/
 MM6fJ1mG6qvBV6X7Na2+2Ueg2+YOlKAL0bUl9n0YQWIk4i4HvpKoSGY
X-Developer-Key: i=dirkchen@amd.com; a=ed25519;
 pk=NBIyLsVg/YYtGLruq9XLdLWx2PP/1MH4jDDQ1V+7wes=
X-Endpoint-Received: by B4 Relay for dirkchen@amd.com/20260202 with auth_id=622
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Anacapa board features Atmel 24C2048 EEPROMs on i2c0 and i2c1, which
are used to store retimer configurations. Add the corresponding device
tree nodes to support these components.

Signed-off-by: Dirk Chen <dirkchen@amd.com>
---
Changes in v2:
- Improved commit description to clarify that the change reflects
  actual hardware as requested by the reviewer.
- Removed mentions of other platforms to avoid confusion.
- Link to v1: https://lore.kernel.org/r/20260202-b4-anacapa-dts-fix-v1-1-20d4b0114854@amd.com
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
index 221af858cb6b..b8d248d99d7c 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa.dts
@@ -328,6 +328,12 @@ i2c0mux0ch3: i2c@3 {
 			#size-cells = <0>;
 		};
 	};
+
+	eeprom@50 {
+		compatible = "atmel,24c2048";
+		reg = <0x50>;
+		pagesize = <128>;
+	};
 };
 
 // R Bridge Board
@@ -362,6 +368,12 @@ i2c1mux0ch3: i2c@3 {
 			#size-cells = <0>;
 		};
 	};
+
+	eeprom@50 {
+		compatible = "atmel,24c2048";
+		reg = <0x50>;
+		pagesize = <128>;
+	};
 };
 
 // MB - E1.S

---
base-commit: 4c87cdd0328495759f6e9f9f4e1e53ef8032a76f
change-id: 20260202-b4-anacapa-dts-fix-207ffe9a3b0c

Best regards,
-- 
Dirk Chen <dirkchen@amd.com>

