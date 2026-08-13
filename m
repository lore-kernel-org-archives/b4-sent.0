From: Colin Huang <u8813345@gmail.com>
Date: Thu, 13 Aug 2026 19:59:45 +0800
Subject: [PATCH v5 15/15] ARM: dts: aspeed: anacapa: Remove redundant vhub
 pinctrl-names
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-anacapa-devlop-phase-devicetree-v5-15-c7058f63dc67@gmail.com>
References: <20260813-anacapa-devlop-phase-devicetree-v5-0-c7058f63dc67@gmail.com>
In-Reply-To: <20260813-anacapa-devlop-phase-devicetree-v5-0-c7058f63dc67@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Joel Stanley <joel@jms.id.au>, 
 Andrew Jeffery <andrew@codeconstruct.com.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 colin.huang2@amd.com, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786622378; l=708;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=wZdptsf5KZoTZdsrUVb6bffHaz43HHnvSy2YjypcUzQ=;
 b=MNt1Xza2YC6AF1CLGYg5+fmVk3XcUzlYvu95056SM6MqhkXzcaRkrr1IQA22bjZap3PORfade
 w/MHSUsshQbCLMjz2y0SW7ThkUYvZHr+3ilQAmi6wMoioflnFU1XQyj
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the pinctrl-names property from the vhub node since it is
already defined in aspeed-g6.dtsi.

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
 arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts | 2 --
 1 file changed, 2 deletions(-)

diff --git a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts
index d613b5b9d6b0..039b016ae06c 100644
--- a/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts
+++ b/arch/arm/boot/dts/aspeed/aspeed-bmc-facebook-anacapa-evt1.dts
@@ -1106,8 +1106,6 @@ &uhci {
 };
 
 &vhub {
-	pinctrl-names = "default";
-
 	status = "okay";
 };
 

-- 
2.34.1

