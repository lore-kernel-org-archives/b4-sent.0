From: Han Gao <gaohan@iscas.ac.cn>
Date: Sun, 22 Nov 2026 02:18:04 +0800
Subject: [PATCH v2 1/2] dt-bindings: clock: sophgo: Allow protected gate
 clocks on SG2042
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-sg2042-efi-rtc-v2-1-6d087e03e4e8@iscas.ac.cn>
References: <20261122-b4-sg2042-efi-rtc-v2-0-6d087e03e4e8@iscas.ac.cn>
In-Reply-To: <20261122-b4-sg2042-efi-rtc-v2-0-6d087e03e4e8@iscas.ac.cn>
To: Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen Wang <chen.wang@linux.dev>, 
 Inochi Amaoto <inochiama@gmail.com>, Yao Zi <me@ziyao.cc>
Cc: Chen Wang <unicorn_wang@outlook.com>, Han Gao <rabenda.cn@gmail.com>, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 sophgo@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795285099; l=966;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=UH/ltGBkhI4HWv393ZO1ftLc3kIT2ZoPiDb2EP7JazI=;
 b=zmlvbZFVIaQrl6XZFIezeydHolQUEOTmc+FSKHQENwcz/B4QFcXIDuxmrFsJuOyhenTIo7DYZ
 Wk2vsHYsIZjD3KfsFhi/e424pM/pBgEO2UuygCb2fh9m/uc99M3suZY
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Firmware may need some gates kept on for its runtime services, such as
the APB I2C gate for the EFI RTC and the AHB serial flash gate for EFI
variables. Which ones depends on the firmware, not the SoC, so let
firmware list them in protected-clocks.

Suggested-by: Yao Zi <me@ziyao.cc>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 Documentation/devicetree/bindings/clock/sophgo,sg2042-clkgen.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/sophgo,sg2042-clkgen.yaml b/Documentation/devicetree/bindings/clock/sophgo,sg2042-clkgen.yaml
index e7a9255bcb58..76f123b84309 100644
--- a/Documentation/devicetree/bindings/clock/sophgo,sg2042-clkgen.yaml
+++ b/Documentation/devicetree/bindings/clock/sophgo,sg2042-clkgen.yaml
@@ -30,6 +30,8 @@ properties:
       - const: dpll0
       - const: dpll1
 
+  protected-clocks: true
+
   '#clock-cells':
     const: 1
     description:

-- 
2.55.0

