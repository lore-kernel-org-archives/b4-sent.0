From: Han Gao <gaohan@iscas.ac.cn>
Date: Wed, 18 Nov 2026 03:55:31 +0800
Subject: [PATCH 1/2] dt-bindings: riscv: eswin: Add Milk-V Megrez
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-eic7700-megrez-v1-1-af8334b88336@iscas.ac.cn>
References: <20261118-eic7700-megrez-v1-0-af8334b88336@iscas.ac.cn>
In-Reply-To: <20261118-eic7700-megrez-v1-0-af8334b88336@iscas.ac.cn>
To: Min Lin <linmin@eswincomputing.com>, 
 Pinkesh Vaghela <pinkesh.vaghela@einfochips.com>, 
 Pritesh Patel <pritesh.patel@einfochips.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: Han Gao <rabenda.cn@gmail.com>, devicetree@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794945342; l=781;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=yEGqwvhItikCOim9M5s0hyGEeXn8c2umboDlEvC4XcE=;
 b=vJkJCHW1LYOknvi8cBGwJUp6g+DVOC4baz2OHV6esjchbFUr+XdmFwmXPZ5hydiIC++gZ6zdH
 ah+Dnw4H0SgA9R8ycE9DfuWS32P90YnPFhFfxzcpJi13THi2FcGZa1b
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatible for the Milk-V Megrez, a Mini-ITX board based on the
ESWIN EIC7700X SoC.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 Documentation/devicetree/bindings/riscv/eswin.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/riscv/eswin.yaml b/Documentation/devicetree/bindings/riscv/eswin.yaml
index c603c45eef2252e760818e830e9dccdf0fdae6cf..f730f5ff91797d4c2f0610f9024a74611ffeae63 100644
--- a/Documentation/devicetree/bindings/riscv/eswin.yaml
+++ b/Documentation/devicetree/bindings/riscv/eswin.yaml
@@ -21,6 +21,7 @@ properties:
     oneOf:
       - items:
           - enum:
+              - milkv,megrez
               - sifive,hifive-premier-p550
           - const: eswin,eic7700
 

-- 
2.47.3

