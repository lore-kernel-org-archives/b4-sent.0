From: Esteban Urrutia <esteuwu@proton.me>
Date: Sun, 02 Aug 2026 03:30:56 -0400
Subject: [PATCH v2 3/4] dt-bindings: pinctrl: qcom,sm8450-tlmm: Add
 compatible for SM8475
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-sm8475-tlmm-v2-3-a93e1d1cb53b@proton.me>
References: <20260802-sm8475-tlmm-v2-0-a93e1d1cb53b@proton.me>
In-Reply-To: <20260802-sm8475-tlmm-v2-0-a93e1d1cb53b@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vinod Koul <vkoul@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785656048; l=858;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=uNYE/Aw+T2Ydk8qBeptK7lz6gSl5CHQQQ2W4ELAzgXE=;
 b=9yeFSDwUCfMzNItrzFZOml7DUdDrqrYJed+jwA6tV5JQWsXILynfc8sIQ7mdrMUI7UaOf2G2N
 ULiBXphXKLyBd8xV8ht4FoLJB9zqie8+z3MHxkIbUEh/0j1uK+zuHK6
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8450 and SM8475 have different pinctrl drivers, which are incompatible
with each other.
Add compatible string for the SM8475 pinctrl driver.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 Documentation/devicetree/bindings/pinctrl/qcom,sm8450-tlmm.yaml | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/pinctrl/qcom,sm8450-tlmm.yaml b/Documentation/devicetree/bindings/pinctrl/qcom,sm8450-tlmm.yaml
index 16fd2c5e2339..c790ab851bc7 100644
--- a/Documentation/devicetree/bindings/pinctrl/qcom,sm8450-tlmm.yaml
+++ b/Documentation/devicetree/bindings/pinctrl/qcom,sm8450-tlmm.yaml
@@ -17,7 +17,9 @@ allOf:
 
 properties:
   compatible:
-    const: qcom,sm8450-tlmm
+    enum:
+      - qcom,sm8450-tlmm
+      - qcom,sm8475-tlmm
 
   reg:
     maxItems: 1

-- 
2.55.0

