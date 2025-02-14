From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH 0/2] arm64: dts: imx8m: Add pinctrl config definitions
Date: Fri, 14 Feb 2025 16:57:41 +0100
Message-Id: <20250214-pinctrl_defines-v1-0-fbc86a42ef3c@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPVnr2cC/x2MQQqAIBAAvyJ7TlArhb4SEaZbLYSJRgTS35OOw
 zBTIGMizDCwAglvynSGCrJh4HYbNuTkK4MSqhdKdjxScFc6Zo8rBcxctQaNX7R02kKtYqri+Y/
 j9L4fbhIcqWEAAAA=
X-Change-ID: 20250214-pinctrl_defines-237e7db61c6a
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739548663; l=1365;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=v1WR08AE5CQqOnR8ISmiWg8KMk9RyvrCOO0/gEgkyDE=;
 b=PZmKXcESL9UNqXoct8RAJHd6TdzLVVn9O/CXE6fXNCm6ETGyIGhid8rlHWVZWigHGukjbfOXY
 +PilzN3VEcgBrxiR62CJ0Eyuhw8Tfr9yqxoFvcT8Oz7GPn6WhgMpQD9
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Up untill now the extra function mux (pull resistor, etc) has been
defined as a raw hex value, this is difficult to interpret. Add
definitions for these parts of the pinctrl registers to allow for more
readable pinctrl definitions in devictree files.

At this point the patch is not complete, some pinctrl definitions set
bit 30 (0x40000000) but according to the reference manual this is a
reserved field, I currently have no way to identify what the meaning of
this bit is, I hope someone in this CC may be able to provide an answer
to this. It will then be fixed in the v2 of this patch.

It should also be done for the mn/mq but I currently do not have the
reference manuals for these to verify these fields, though I can only
assume that they would be the same.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Maud Spierings (2):
      arm64: dts: imx8mm: Add pinctrl config definitions
      arm64: dts: imx8mp: Add pinctrl config definitions

 arch/arm64/boot/dts/freescale/imx8mm-pinfunc.h | 27 ++++++++++++++++++++++++++
 arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h | 27 ++++++++++++++++++++++++++
 2 files changed, 54 insertions(+)
---
base-commit: 0ae0fa3bf0b44c8611d114a9f69985bf451010c3
change-id: 20250214-pinctrl_defines-237e7db61c6a

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

