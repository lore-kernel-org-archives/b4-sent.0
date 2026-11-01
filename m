From: Han Gao <gaohan@iscas.ac.cn>
Date: Sun, 01 Nov 2026 21:35:31 +0800
Subject: [PATCH 1/2] dt-bindings: timer: add the FU740 CLINT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-b4-sifive-fu740-clint-v1-1-b4821199a733@iscas.ac.cn>
References: <20261101-b4-sifive-fu740-clint-v1-0-b4821199a733@iscas.ac.cn>
In-Reply-To: <20261101-b4-sifive-fu740-clint-v1-0-b4821199a733@iscas.ac.cn>
To: Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Anup Patel <anup@brainfault.org>, 
 Conor Dooley <conor@kernel.org>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: Yao Zi <me@ziyao.cc>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 Han Gao <rabenda.cn@gmail.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793540132; l=1006;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=VwCnzE/4MZz2gbGvZGs9P9obrlQjk7zxT+DpHDQL0Gg=;
 b=nICmxnHvq/ap74lRCP7Vd3qaf3i6Oa2kxxw4daKe6HXHkRD+6qk7p3gq2AizwI5a3zXQybX5L
 NEEGeCPbiMwBpYAeRsQnKtZYJGJa1lRSlirw+HfHIg6nwZ8jKxtIKTF
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the FU740 CLINT compatible.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 Documentation/devicetree/bindings/timer/sifive,clint.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/timer/sifive,clint.yaml b/Documentation/devicetree/bindings/timer/sifive,clint.yaml
index d53f52e80d887b40c0d20049d86867c8a5b6fae2..13a8638f6b08e87bff3e37f947b0fe5458ebb38d 100644
--- a/Documentation/devicetree/bindings/timer/sifive,clint.yaml
+++ b/Documentation/devicetree/bindings/timer/sifive,clint.yaml
@@ -33,6 +33,7 @@ properties:
               - eswin,eic7700-clint     # ESWIN EIC7700
               - microchip,pic64gx-clint # Microchip PIC64GX
               - sifive,fu540-c000-clint # SiFive FU540
+              - sifive,fu740-c000-clint # SiFive FU740
               - spacemit,k1-clint       # SpacemiT K1
               - starfive,jh7100-clint   # StarFive JH7100
               - starfive,jh7110-clint   # StarFive JH7110

-- 
2.47.3

