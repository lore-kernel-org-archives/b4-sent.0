From: Kohei Otsuka <kohei@spacemachines.com>
Subject: [PATCH v3 0/2] serial: 8250_of: RS-485 on Microchip Core16550
Date: Tue, 10 Nov 2026 09:06:47 +1100
Message-Id: <20261110-core16550-rs485-v3-0-4294334243fa@spacemachines.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNQQ7CIBQE0Ks0rMXwQVpx5T2MC6C/FhNLA5Vom
 t5dqBsTdTnJzJuZRAwOIzlUMwmYXHR+yEFsKmJ7PVyQujZnwhmvAZig1geEWkpGQ9ztJZVM6o5
 1nUY0JK/GgJ17rOLp/M7xbq5op8KURu/i5MNzvUxQev/1BJTRugWJBgGlUcc4aos3bXs3YNxaf
 yPlJfFPR307PDsapBLCNkax5pezLMsL/9CM5xABAAA=
X-Change-ID: 20261103-core16550-rs485-505af0ffaeeb
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lubomir Rintel <lkundrak@v3.sk>, 
 devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 conor.dooley@microchip.com, Kohei Otsuka <kohei@spacemachines.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794262008; l=3104;
 i=kohei@spacemachines.com; s=20261103; h=from:subject:message-id;
 bh=2t/y+JgPR+YcsPrIb1nJlI+zK2fJ6JA0sGv09e5rrOA=;
 b=hZzUdKg2K6uNjMYDff3C8oXouSGZf4MSIFlp63W0xXWUMs1PX4rxILMm+li+MtEhHAM9h7+Qj
 FMbE2lKaNOvAUv5GLdl8sZb5PUv4IXmEqjUGdbQqOn/fU7zDUkKPlwe
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
and the ports described as "microchip,core16550-rtl-v3",
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
Changes in v3:
- dt-bindings: drop the ns16550a fallback, as the generic driver leaves
  RTS asserted in RS-485 mode (Conor)
- 8250_of: match microchip,core16550-rtl-v3 directly, as a PORT_16550A,
  and retitle the patch to match
- Link to v2: https://patch.msgid.link/20261109-core16550-rs485-v2-0-a15933c7b907@spacemachines.com

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
      serial: 8250_of: add Microchip Core16550

 Documentation/devicetree/bindings/serial/8250.yaml |  1 +
 drivers/tty/serial/8250/8250_of.c                  | 12 ++++++++++++
 2 files changed, 13 insertions(+)
---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261103-core16550-rs485-505af0ffaeeb

Best regards,
--  
Kohei Otsuka <kohei@spacemachines.com>

