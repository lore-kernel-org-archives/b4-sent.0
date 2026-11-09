From: Kohei Otsuka <kohei@spacemachines.com>
Subject: [PATCH v2 0/2] serial: 8250_of: RS-485 on Microchip Core16550
Date: Mon, 09 Nov 2026 13:55:04 +1100
Message-Id: <20261109-core16550-rs485-v2-0-a15933c7b907@spacemachines.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0JmbU0HHaKuvIdh0ZapjAmUdJBoC
 HcXdO3yJe+/P4NyFla4FDNknkQl9SuUuwJC6/o7G2lWhtKWFaI9mJAyY0VkTdbjiQxZctHG6Jg
 9rKshc5TXt3irf6xP/+AwbpnNaEXHlN/fywk37399QmNN1SCxZ2Ty56sOLnDnQis96z6kDuplW
 T5v6nYqyAAAAA==
X-Change-ID: 20261103-core16550-rs485-505af0ffaeeb
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lubomir Rintel <lkundrak@v3.sk>, 
 devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 conor.dooley@microchip.com, Kohei Otsuka <kohei@spacemachines.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794192905; l=2791;
 i=kohei@spacemachines.com; s=20261103; h=from:subject:message-id;
 bh=f2A/H5VB6PfODmMTbPgALIZYZl5rfDVy8lpdMZKZsFw=;
 b=xXTMsbmJO+GrhRmRI8JeoCEMfKJHsfBZMK7rQZY6zEHp4BDcYYihqsapc1FnA+8IZRG2S4+h5
 55TDccEl5qZCaUjja4g5zvlcuSL4QTFUcVKpsWrrkRi4gfaRUjlpMfq
X-Developer-Key: i=kohei@spacemachines.com; a=ed25519;
 pk=1kit/vmX5JiLGH9NPcqlvT55ISWaLmNipdL5VrriRt0=
X-Endpoint-Received: by B4 Relay for kohei@spacemachines.com/20261103 with auth_id=1385
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Core16550 is a 16550-compatible UART soft IP for Microchip FPGAs. We use
four of them in the fabric of a PolarFire SoC Icicle Kit as RS-485
ports, described as "ns16550a" with linux,rs485-enabled-at-boot-time.
With RS-485 enabled, RTS (the transceiver's driver enable) goes high at
the start of the first transmission and never drops, and the port stops
receiving. Core16550, like the original 16550A, raises no interrupt on
TEMT, so __stop_tx() waits for one forever unless the port has
UART_CAP_NOTEMT, which 8250_of never sets.

Testing, on a PolarFire SoC Icicle Kit with four Core16550 instances
on FIC3 (PCLK 50 MHz), linux-mchp 6.18.17 with this series applied
and the ports described as "microchip,core16550-rtl-v3", "ns16550a",
115200 8N1, against USB-RS485 (2-wire, half duplex) and USB-RS422
(4-wire) converters:
- All four ports transmit and receive correctly with both converters.
- On RS-485, each port keeps receiving after transmitting, across
  repeated request/response exchanges in both directions.
- Without the series, RTS stays high after the first transmission and
  nothing more is received.

This series was prepared with the help of an AI coding assistant
(Claude, Anthropic): the analysis of __stop_tx(), both patches and
these messages. I reviewed and tested the result and take
responsibility for it.

Link: https://github.com/linux4microchip/meta-mchp/issues/5

Signed-off-by: Kohei Otsuka <kohei@spacemachines.com>
---
Changes in v2:
- dt-bindings: rename the compatible to microchip,core16550-rtl-v3,
  following the -rtl-vN convention of Microchip's other fabric cores
  (Conor)
- dt-bindings: explain in the commit message why ns16550a remains a
  valid fallback (Conor)
- 8250_of: match microchip,core16550-rtl-v3
- Dropped Krzysztof's Acked-by on 1/2, as the compatible changed
- Link to v1: https://patch.msgid.link/20261103-core16550-rs485-v1-0-6d15ebe1e5b9@spacemachines.com

To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
To: Jiri Slaby <jirislaby@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Lubomir Rintel <lkundrak@v3.sk>
To: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-serial@vger.kernel.org

---
Kohei Otsuka (2):
      dt-bindings: serial: 8250: add Microchip Core16550
      serial: 8250_of: drop RS-485 RTS on Microchip Core16550

 Documentation/devicetree/bindings/serial/8250.yaml |  1 +
 drivers/tty/serial/8250/8250_of.c                  | 10 ++++++++++
 2 files changed, 11 insertions(+)
---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261103-core16550-rs485-505af0ffaeeb

Best regards,
--  
Kohei Otsuka <kohei@spacemachines.com>

