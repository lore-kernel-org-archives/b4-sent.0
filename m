From: Kohei Otsuka <kohei@spacemachines.com>
Date: Mon, 09 Nov 2026 13:55:05 +1100
Subject: [PATCH v2 1/2] dt-bindings: serial: 8250: add Microchip Core16550
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-core16550-rs485-v2-1-a15933c7b907@spacemachines.com>
References: <20261109-core16550-rs485-v2-0-a15933c7b907@spacemachines.com>
In-Reply-To: <20261109-core16550-rs485-v2-0-a15933c7b907@spacemachines.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lubomir Rintel <lkundrak@v3.sk>, 
 devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 conor.dooley@microchip.com, Kohei Otsuka <kohei@spacemachines.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794192905; l=1517;
 i=kohei@spacemachines.com; s=20261103; h=from:subject:message-id;
 bh=tVquJwmRACDuh480fTmlsHeIfkSp7Ofs4+cTK3nRbqo=;
 b=VIyOrtl+nYTF1R05LAEuQP9NoK+Lhy2kJMg60Iib8Tz2NG5p9x1VmbIxgETfVKy9VrJL4lkNK
 qKdH4GvU05TCp9YAFJA24IQhfht6sfutY8om5D/nbBZcVtoApSO8ExK
X-Developer-Key: i=kohei@spacemachines.com; a=ed25519;
 pk=1kit/vmX5JiLGH9NPcqlvT55ISWaLmNipdL5VrriRt0=
X-Endpoint-Received: by B4 Relay for kohei@spacemachines.com/20261103 with auth_id=1385
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Core16550 is a 16550-compatible UART soft IP core for Microchip FPGAs,
including the fabric of PolarFire SoC. Its registers, interrupts and
baud rate divisor follow the 16550A, so a driver that knows only
ns16550a operates it fully: transmit, receive, FIFOs and modem control
all work. What the generic driver cannot know is that the core raises
no interrupt on TEMT, which it needs to drop RTS after a frame in
software RS-485 mode (em485). ns16550a therefore stays a valid
fallback, with RS-485 RTS control the one feature that needs the
specific compatible.

Add microchip,core16550-rtl-v3 with ns16550a as the fallback. As for
Microchip's other FPGA fabric cores, the -rtl-v3 suffix is the major
RTL version of the IP, Core16550 3.x.

Link: https://github.com/linux4microchip/meta-mchp/issues/5
Signed-off-by: Kohei Otsuka <kohei@spacemachines.com>
---
 Documentation/devicetree/bindings/serial/8250.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/serial/8250.yaml b/Documentation/devicetree/bindings/serial/8250.yaml
index 50d5c977afa3..6f806b972f5c 100644
--- a/Documentation/devicetree/bindings/serial/8250.yaml
+++ b/Documentation/devicetree/bindings/serial/8250.yaml
@@ -137,6 +137,7 @@ properties:
               - ti,da830-uart
               - loongson,ls2k0500-uart
               - loongson,ls2k1500-uart
+              - microchip,core16550-rtl-v3
           - const: ns16550a
       - items:
           - enum:

-- 
2.53.0

