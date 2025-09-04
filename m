From: David Heidelberg <david@ixit.cz>
Date: Thu, 04 Sep 2025 22:41:44 +0200
Subject: [PATCH v2] dt-bindings: extcon: linux,extcon-usb-gpio: GPIO must
 be provided
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-yaml-extcon-usb-gpio-v2-1-a5c4afa496c3@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAIf5uWgC/4WNQQ6CMBBFr0Jm7ZgypFVceQ/DgtYRJlFK2kpAw
 t2tXMD81fvJf3+FyEE4wqVYIfAkUfyQgQ4FuL4dOka5ZwZSpFVFNS7t64k8J+cHfEeL3SgeSZf
 WGE1E5xPk6Rj4IfOuvTWZe4nJh2V/mcpf+0c4lZhTK1Mb1lWr7FVmSUf3gWbbti8mkUwKtgAAA
 A==
X-Change-ID: 20250329-yaml-extcon-usb-gpio-251b66522287
To: MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Conor Dooley <conor.dooley@microchip.com>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1393; i=david@ixit.cz;
 h=from:subject:message-id; bh=38o5l+Gd5d4+Zkxmiu4BB0zsyw4fWa9j1Br5WQIrDCY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoufmPMszQV/vhPettuncRzuRf3JM93viHJZSlO
 o6rS08QHdyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaLn5jwAKCRBgAj/E00kg
 ct8MD/sEYLadRUK+M64Y8KLwkwKTy+Cw9A8/l5d/rXwyGH+cMl5XxV66eS6NPBPHHjXlhIxFfVX
 uw4gYIfxETbo8A+SvddLtij4awSMqKnj9S/7R0VmwtMSyPlKjp7gxZL5a160E02PVXHykLeHFiA
 My0jE/FHguyArG+RVy9lZAw3K6o8mYpe89v1aRJb5vNUYnw5DTgPPHMgk2jv7H1e9vj4WDqSK3B
 y+98ZNzuheG4RCx4k1bbkCVXYHs5gepo5J5UYXZJpYTK5mOKBnkXioIscdm8lXPNALAKThpMtan
 MfcKNylmdcEu9kh6sNcNpGmfGL0o+uE1S+aiS7SXuEr2Cm9A/zBWg9ahEE0QVdPR7tRzTxf8f0e
 zCWmmG5CEfzqUPdF7dT8qHzAPi4b5NuXvxtXcMGqv8YJLBiN5BOkqw2vEkQxdNz5OGUt2ZdKP0U
 s2+ptBOz4ulFhU21vznXRE14GPiEmGPYBpDtmjhjw6r2PV7n5Vs9MFKLxP3xKApkiWeXxRWZ1Jk
 FWbloHF2NR1e7oSyPTteBwpRwJJ0v+AyP+cjKSfmU7u0A4sKMIO5BqrF9IMkJlDej3bfwnGadJ+
 oawdsy12rsiKa2vH6Yb/VKxTRw7ZDCgx4tlrDpQPL/jXM4CQTI8++EDFFBQ4N0c75IB+X7mwcDr
 /3Zt8iIocpxv7yQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Without providing either ID or VBUS GPIO the driver is not able to operate.
Original text binding says:
  "Either one of id-gpio or vbus-gpio must be present."

Fixes: 79a31ce03f41 ("dt-bindings: extcon: convert extcon-usb-gpio.txt to yaml format")
Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Rebased and added Conor A-b.
- Link to v1: https://lore.kernel.org/r/20250329-yaml-extcon-usb-gpio-v1-1-190696e53a0b@ixit.cz
---
 Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml b/Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml
index 8856107bdd33b8654812ab9c97e85e23dc2ef75a..8f29d333602b95fe5ccd8464aa64e2d1f0c1c781 100644
--- a/Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml
+++ b/Documentation/devicetree/bindings/extcon/linux,extcon-usb-gpio.yaml
@@ -25,6 +25,12 @@ properties:
 required:
   - compatible
 
+anyOf:
+  - required:
+      - id-gpios
+  - required:
+      - vbus-gpios
+
 additionalProperties: false
 
 examples:

---
base-commit: 4ac65880ebca1b68495bd8704263b26c050ac010
change-id: 20250329-yaml-extcon-usb-gpio-251b66522287

Best regards,
-- 
David Heidelberg <david@ixit.cz>

