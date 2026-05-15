From: Jia Wang <wangjia@ultrarisc.com>
Date: Fri, 15 May 2026 09:17:57 +0800
Subject: [PATCH 1/9] dt-bindings: vendor-prefixes: add Rongda
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260515-ultrarisc-pinctrl-v1-1-bf559589ea8a@ultrarisc.com>
References: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
In-Reply-To: <20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Samuel Holland <samuel.holland@sifive.com>
Cc: Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@sifive.com>, Conor Dooley <conor@kernel.org>, 
 devicetree@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778807890; l=871;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=9QG7ZiRK3RyROMWf2rb572b5ZDl0GYAcQWD6s3msFM8=;
 b=BmYVDPTGabV641x/qomuXrXxvhNW6sr86M4t/0nTP8YFuQsD95smGsJaFll9aSWKoJtQnh7cU
 5tJXdszmLHLBQn3ku83uxnGymFuIGnfBD/Gu4ylCzy79lP6l68xIEup
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Shenzhen Rongda Computer Co., Ltd. to the vendor prefixes.

Link: http://www.shenrongda.com/

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 28784d66ae7b..04e593c66c7c 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1407,6 +1407,8 @@ patternProperties:
     description: Rockchip Electronics Co., Ltd.
   "^rocktech,.*":
     description: ROCKTECH DISPLAYS LIMITED
+  "^rongda,.*":
+    description: Shenzhen Rongda Computer Co., Ltd.
   "^rohm,.*":
     description: ROHM Semiconductor Co., Ltd
   "^ronbo,.*":

-- 
2.34.1

