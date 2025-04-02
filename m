From: Maud Spierings <maudspierings@gocontroll.com>
Date: Wed, 02 Apr 2025 09:07:07 +0200
Subject: [PATCH v4 4/9] MAINTAINERS: add maintainer for the GOcontroll
 Moduline controllers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-initial_display-v4-4-9f898838a864@gocontroll.com>
References: <20250402-initial_display-v4-0-9f898838a864@gocontroll.com>
In-Reply-To: <20250402-initial_display-v4-0-9f898838a864@gocontroll.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743577640; l=784;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=Kodl+8kPIGsleRbs7jxCH5LW1v9NBKtCtLsNy8vvbV0=;
 b=COnYDITO8KLBM330+KlG1z4sWgqvpLjhbp6rySeWf1NXyACYSbRmrN+MS0nti86mEaSBaCFZQ
 rWus+T1FYIuCZ9h9Q4sLbSkC7jDIhAGDE/Wla6MLpa3+xXnBQUv/R3h
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a maintainer for the GOcontroll Moduline series of controllers.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 MAINTAINERS | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 4b3864a9852f9fca2be48987d383c0671e668336..7d4fbfdaaac1776fc7c4a569f7ab667f0a485eab 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -10043,6 +10043,12 @@ L:	linux-media@vger.kernel.org
 S:	Maintained
 F:	drivers/media/usb/go7007/
 
+GOCONTROLL MODULINE CONTROLLERS
+M:	Maud Spierings <maudspierings@gocontroll.com>
+L:	devicetree@vger.kernel.org
+S:	Maintained
+F:	arch/arm64/boot/dts/freescale/*moduline*.dts*
+
 GOCONTROLL MODULINE MODULE SLOT
 M:	Maud Spierings <maudspierings@gocontroll.com>
 S:	Maintained

-- 
2.49.0

