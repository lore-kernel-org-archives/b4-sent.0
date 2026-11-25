From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 25 Nov 2026 13:34:14 +0300
Subject: [PATCH v4 6/6] MAINTAINERS: Add CS7542 global control support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-cs7542-syscon-v4-6-3337bb0d3b48@gmail.com>
References: <20261125-cs7542-syscon-v4-0-3337bb0d3b48@gmail.com>
In-Reply-To: <20261125-cs7542-syscon-v4-0-3337bb0d3b48@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795602848; l=1145;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=451qyYBYGcKQBnv4zkYbgyAEFoN+lZtfxN3rOpF09y8=;
 b=7SwLJdRedUZdNTGMoRkhPdZqvW/+eAFF2+lVWXeaAGO7mvMncnIIxXO/jiDMvff4bEPKnKzYv
 mKlRMyg8oTzBhHK2X3iFcZ0QPJQOgrroMCuxvaDvhAefcQBlvJi9ovP
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add contacts and paths for the CS7542 clock, reset and pinctrl
drivers and their device tree bindings.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 MAINTAINERS | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 44540a1eb..703e95e83 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2949,6 +2949,18 @@ F:	tools/perf/tests/shell/coresight/*
 F:	tools/perf/util/cs-etm-decoder/*
 F:	tools/perf/util/cs-etm.*
 
+ARM/CORTINA SYSTEMS CS7542 GLOBAL CONTROL
+M:	Fil Dunsky <filipp.dunsky@gmail.com>
+L:	linux-arm-kernel@lists.infradead.org (moderated for non-subscribers)
+S:	Maintained
+F:	Documentation/devicetree/bindings/pinctrl/cortina,cs7542-pinctrl.yaml
+F:	Documentation/devicetree/bindings/soc/cortina/
+F:	drivers/clk/clk-cs7542.c
+F:	drivers/pinctrl/pinctrl-cs7542.c
+F:	drivers/reset/reset-cs7542.c
+F:	include/dt-bindings/clock/cortina,cs7542-clock.h
+F:	include/dt-bindings/reset/cortina,cs7542-reset.h
+
 ARM/CORTINA SYSTEMS GEMINI ARM ARCHITECTURE
 M:	Hans Ulli Kroll <ulli.kroll@googlemail.com>
 M:	Linus Walleij <linusw@kernel.org>

-- 
2.53.0

