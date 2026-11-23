From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 24 Nov 2026 00:51:00 +0300
Subject: [PATCH 3/3] MAINTAINERS: Track CS7542 global reset specifiers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-cs7542-global-controls-v1-3-12548785df2c@gmail.com>
References: <20261124-b4-cs7542-global-controls-v1-0-12548785df2c@gmail.com>
In-Reply-To: <20261124-b4-cs7542-global-controls-v1-0-12548785df2c@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795470657; l=805;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=jZiseWlg2CtTRviMIS/xUtTqGqfyqbUonSFVhgEfXD8=;
 b=XgrqNi9Rk0GtZ2qbN18FPMvfN9NFeP8t7VKAcEwv74gpusXsM0eOBZ5QrS9+QsjrqWuGqnCKw
 a+hgjrA4zQZAFgDY7PKhB2YkyrxqW+9h96fDxJPDkk1vhb95Sv39jv1
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Cover the shared reset identifiers under the existing global control
entry. PCIe host/PHY and network datapath ownership remain separate.

AI assistance: Codex prepared this draft from the posted CS7542 series.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 MAINTAINERS | 1 +
 1 file changed, 1 insertion(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index d8835aeca..3c51d13e7 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2958,6 +2958,7 @@ F:	Documentation/devicetree/bindings/soc/cortina/
 F:	drivers/clk/clk-cs7542.c
 F:	drivers/pinctrl/pinctrl-cs7542.c
 F:	include/dt-bindings/clock/cortina,cs7542-clock.h
+F:	include/dt-bindings/reset/cortina,cs7542-reset.h
 
 ARM/CORTINA SYSTEMS GEMINI ARM ARCHITECTURE
 M:	Hans Ulli Kroll <ulli.kroll@googlemail.com>

-- 
2.53.0

