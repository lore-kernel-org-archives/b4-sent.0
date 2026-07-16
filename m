From: Alexandru Chimac <alex@chimac.ro>
Date: Thu, 16 Jul 2026 20:14:59 +0300
Subject: [PATCH v2 5/5] MAINTAINERS: Add entry for Exynos9610
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-exynos9610-clocks-v2-5-c13ce8ef1861@chimac.ro>
References: <20260716-exynos9610-clocks-v2-0-c13ce8ef1861@chimac.ro>
In-Reply-To: <20260716-exynos9610-clocks-v2-0-c13ce8ef1861@chimac.ro>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Alexandru Chimac <alex@chimac.ro>, Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-samsung-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784222102; l=938;
 i=alex@chimac.ro; s=20250914; h=from:subject:message-id;
 bh=E1bSKMgEPtMif3Sdy3gDrAXfrBKn4CyIguCFFF+2z0k=;
 b=n/yIIHt/0i3lrYnCiW57+C73q+GrdrF3E7W62qTJpaUVRoTX6GF8REncb6qpBXC4Vi3Pmmib5
 ftMoztZEG5iCYzMucGoacXv/Vte2XaNiRBji4c8FcG2Ye0qwqxLIeis
X-Developer-Key: i=alex@chimac.ro; a=ed25519;
 pk=OKD+X09b7uEsyw05zyuqq14SLGg8B/X4xey5tJeYCig=
X-Endpoint-Received: by B4 Relay for alex@chimac.ro/20250914 with auth_id=877
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add maintainers entry for Samsung Exynos9610-based platforms.

Signed-off-by: Alexandru Chimac <alex@chimac.ro>
---
 MAINTAINERS | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index cd2c02840336..7c26c3ce1696 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -24073,6 +24073,15 @@ L:	linux-samsung-soc@vger.kernel.org
 S:	Maintained
 F:	arch/arm64/boot/dts/exynos/exynos8855*
 
+SAMSUNG EXYNOS9610 SoC SUPPORT
+M:	Alexandru Chimac <alex@chimac.ro>
+L:	linux-arm-kernel@lists.infradead.org (moderated for non-subscribers)
+L:	linux-samsung-soc@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/clock/samsung,exynos9610-cmu.yaml
+F:	drivers/clk/samsung/clk-exynos9610.c
+F:	include/dt-bindings/clock/samsung,exynos9610-cmu.h
+
 SAMSUNG EXYNOS ACPM MAILBOX PROTOCOL
 M:	Tudor Ambarus <tudor.ambarus@linaro.org>
 L:	linux-kernel@vger.kernel.org

-- 
2.54.0

