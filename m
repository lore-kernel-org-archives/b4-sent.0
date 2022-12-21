From: Konstantin Ryabitsev <icon@mricon.com>
Date: Wed, 21 Dec 2022 14:27:59 -0500
Subject: [PATCH] arm: lanyang: fix lable->label typo for lanyang dts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20221221-lanyang-lable-fix-v1-1-eb6e11eb4a6c@mricon.com>
X-B4-Tracking: v=1; b=H4sIAD9eo2MC/x1NWwrCQAy8Ssm3ge7iA7yK+JHtTm2grpKIKKV3N
 xUGhnkxCzlM4XTuFjK81fXRQqRdR8Mk7QbWGppyn3MK8CztG35wmcGjfvjYH1DHtK/5BIpdEQcX
 kzZM2/Iu/oJtwdMQ/f/Z5bquP95wODB8AAAA
To: Rob Herring <robh+dt@kernel.org>,
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>,
 Joel Stanley <joel@jms.id.au>, Andrew Jeffery <andrew@aj.id.au>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org,
 linux-aspeed@lists.ozlabs.org, linux-kernel@vger.kernel.org,
 Jens Schleusener <Jens.Schleusener@fossies.org>,
 Konstantin Ryabitsev <mricon@kernel.org>,
 Konstantin Ryabitsev <icon@mricon.com>
X-Mailer: b4 0.11.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1671650898; l=1212;
 i=icon@mricon.com; s=20221221; h=from:subject:message-id;
 bh=2IbMt37be02samN0SyLfQQMRKqpQAoGkiG6WjPTqeHE=;
 b=vky9FSwxUi524bgC0XAV2tIoUj+s5J6LHm9YNa6hbEgx1ns8LctbBs+ql6Q21U0spd5JmTc6j9Bm
 NcUS5faPCAN15saXFVSPQNRNPm0aTh0AM3NW6ctQGnj29YEq3LJQ
X-Developer-Key: i=icon@mricon.com; a=ed25519;
 pk=24L8+ejW6PwbTbrJ/uT8HmSM8XkvGGtjTZ6NftSSI6I=
X-Endpoint-Received: by B4 Submission Endpoint for icon@mricon.com/20221221 with auth_id=16
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Fix an obvious spelling error in the dts file for Lanyang BMC.
This was reported via bugzilla a few years ago but never fixed.

Reported-by: Jens Schleusener <Jens.Schleusener@fossies.org>
Link: https://bugzilla.kernel.org/show_bug.cgi?id=205891
Signed-off-by: Konstantin Ryabitsev <icon@mricon.com>
---
 arch/arm/boot/dts/aspeed-bmc-opp-lanyang.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm/boot/dts/aspeed-bmc-opp-lanyang.dts b/arch/arm/boot/dts/aspeed-bmc-opp-lanyang.dts
index c0847636f20b..e72e8ef5bff2 100644
--- a/arch/arm/boot/dts/aspeed-bmc-opp-lanyang.dts
+++ b/arch/arm/boot/dts/aspeed-bmc-opp-lanyang.dts
@@ -52,12 +52,12 @@ hdd_fault {
 			gpios = <&gpio ASPEED_GPIO(B, 3) GPIO_ACTIVE_HIGH>;
 		};
 		bmc_err {
-			lable = "BMC_fault";
+			label = "BMC_fault";
 			gpios = <&gpio ASPEED_GPIO(H, 6) GPIO_ACTIVE_HIGH>;
 		};
 
 		sys_err {
-			lable = "Sys_fault";
+			label = "Sys_fault";
 			gpios = <&gpio ASPEED_GPIO(H, 7) GPIO_ACTIVE_HIGH>;
 		};
 	};

---
base-commit: 830b3c68c1fb1e9176028d02ef86f3cf76aa2476
change-id: 20221221-lanyang-lable-fix-605edf14d27e

Best regards,
-- 
Konstantin Ryabitsev <icon@mricon.com>
