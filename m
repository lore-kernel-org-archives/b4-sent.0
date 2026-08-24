From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 24 Aug 2026 23:54:40 +0200
Subject: [PATCH v2] dt-bindings: gpio: fsl,qoriq-gpio: allow gpio-hog child
 nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260824-for-upstream-dt-qoriq-gpio-hog-v2-1-58bbc82b881e@free.fr>
X-B4-Tracking: v=1; b=H4sIAJ+9jGoC/42NQQ6CMBAAv0L27JpSQcGT/zAcKt3CHqSwxUZD+
 ncrL/A4c5jZIJAwBbgWGwhFDuynDPpQQD+aaSBkmxm00mfV6AqdF3zNYRUyT7QrLl54wWFmj6M
 fsFatNspVVjUt5Mgs5Pi9D+5d5pHD6uWz/2L5s3+nY4kl2kvd6tOjp97YmxOioxPoUkpfHC6/y
 coAAAA=
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Frank Li <Frank.Li@nxp.com>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787608486; l=2553;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=vLftnW/6ZHYpxUdAguO8gqJD/zFrC/vFGlvGHyTT+do=;
 b=vnETn4Fqarl7H1tavyKw/MO27Msn4zA6zF1Bg6CprtBiH1Fp+nKXMthIjCMp6ZsX/uBB43goO
 nG6wBIpHOwuBuoce7R1RgwnOLGXKTdGdGRNTU64igJgmUY9tksh6P2Q
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The binding sets additionalProperties: false and describes no child nodes,
so a gpio-hog on a QorIQ/Layerscape GPIO controller is rejected by
dtbs_check as an unmatched node name, even though the hardware and the
kernel both support it.

Hogs are not a controller feature and need nothing from the driver:
gpio-mpc8xxx.c does not mention them at all. A hog on this controller
works today, only the schema rejects it.

QorIQ and Layerscape boards do need them. These SoCs bring board-level
reset, enable and mux-select lines out on the SoC GPIOs, and those lines
have to be driven to a safe level at boot before any consumer claims them,
which is exactly what a hog is for.

Some boards in the tree already express this need where they can:
fsl-ls1088a-ten64.dts and the tqmls1012a/ls1028a boards all carry hogs, but
on I2C GPIO expanders, because that is the only place the schema currently
supports them. No board uses one on this controller yet, so this fixes no
current failure.

Other GPIO bindings already carry the same block. gpio-mvebu.yaml and
gpio-davinci.yaml use the identical "^(.+-hog(-[0-9]+)?)$" object requiring
gpio-hog.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Changes in v2:
- Change the commit message. Drop the dmesg excerpt: those hog names come
  from my out-of-tree dev git repo and are not in the tree (Frank Li)
- Note: the hog call path is: gpiochip_hog_lines(), called from gpiochip_add_data_with_key()
- Explain why these QorIQ SoCs need it
- No change to the diff
- Link to v1: https://lore.kernel.org/r/20260824-for-upstream-dt-qoriq-gpio-hog-v1-1-d75923bcecad@free.fr
---
 Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml b/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
index 4cb2a6b9fabfb..a6252440e099b 100644
--- a/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
+++ b/Documentation/devicetree/bindings/gpio/fsl,qoriq-gpio.yaml
@@ -63,6 +63,13 @@ properties:
       GPIO registers are used as little endian. If not
       present registers are used as big endian by default.
 
+patternProperties:
+  "^(.+-hog(-[0-9]+)?)$":
+    type: object
+
+    required:
+      - gpio-hog
+
 required:
   - compatible
   - reg

---
base-commit: 0a0d1d55dad570724bf8c7ea83409639cfb4be9b
change-id: 20260824-for-upstream-dt-qoriq-gpio-hog-5092a0f4d089

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

