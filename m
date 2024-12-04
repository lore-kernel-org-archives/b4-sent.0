From: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
Date: Wed, 04 Dec 2024 16:05:29 +0000
Subject: [PATCH v5 6/6] MAINTAINER: Add entry for Blaize SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241204-blaize-blzp1600_init_board_support-v5-6-b642bcc49307@blaize.com>
References: <20241204-blaize-blzp1600_init_board_support-v5-0-b642bcc49307@blaize.com>
In-Reply-To: <20241204-blaize-blzp1600_init_board_support-v5-0-b642bcc49307@blaize.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 James Cowgill <james.cowgill@blaize.com>, 
 Matt Redfearn <matt.redfearn@blaize.com>, 
 Neil Jones <neil.jones@blaize.com>, 
 Niko Pasaloukos <nikolaos.pasaloukos@blaize.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, Olof Johansson <olof@lixom.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, soc@lists.linux.dev
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733328392; l=1011;
 i=nikolaos.pasaloukos@blaize.com; s=20241111; h=from:subject:message-id;
 bh=B8JPdEWFjlJ8iEOYfys3/T/ybAOs8kuytmN42/vy2FE=;
 b=69fm4FjATA2NwB5OGt8iyDk9vJ/CiyV9KeDh/wGTGXFqK24nbZoonpWBIw7h7n36QG+NsR/eT
 ZUX5cmE+gCtCDWs7fkmPLb33xMqw5aS1cLuJ9T70M1GH4NASTaqSw+Y
X-Developer-Key: i=nikolaos.pasaloukos@blaize.com; a=ed25519;
 pk=gGEjGCXdSuvCJPIiu0p0UeiPcW5LC710Z6KGN/dzo3g=
X-Endpoint-Received: by B4 Relay for nikolaos.pasaloukos@blaize.com/20241111 with auth_id=274
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MAINTAINERS entry for Blaize SoC platform with a list of
maintainers.

Signed-off-by: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
---
 MAINTAINERS | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 273a84483b74543b510de7b08804bbd1f6514358..43846a23f9d990ae9fe066e65ed2bdd36376e327 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2238,6 +2238,15 @@ F:	arch/arm64/boot/dts/bitmain/
 F:	drivers/clk/clk-bm1880.c
 F:	drivers/pinctrl/pinctrl-bm1880.c
 
+ARM/BLAIZE ARCHITECTURE
+M:	James Cowgill <james.cowgill@blaize.com>
+M:	Matt Redfearn <matt.redfearn@blaize.com>
+M:	Neil Jones <neil.jones@blaize.com>
+M:	Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
+S:	Maintained
+F:	Documentation/devicetree/bindings/arm/blaize.yaml
+F:	arch/arm64/boot/dts/blaize/
+
 ARM/CALXEDA HIGHBANK ARCHITECTURE
 M:	Andre Przywara <andre.przywara@arm.com>
 L:	linux-arm-kernel@lists.infradead.org (moderated for non-subscribers)

-- 
2.43.0

