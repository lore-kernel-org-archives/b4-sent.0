From: Serv Pol <servpol@tuta.io>
Subject: [PATCH 0/2] power: supply: Add GL.iNet GL-E750 MCU battery driver
Date: Mon, 05 Oct 2026 22:25:23 +0000
Message-Id: <20261005-gl-e750-mcu-v1-0-499d2e31f786@tuta.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANMjxGoC/yXMwQrCMAyA4VcpOS+QFRbBVxEPLk1nRKu0ToTSd
 1+nx+/w/xWKZtMCR1ch68eKPVPHODiQ6yUtiha6wZPnkWjC5Y56mAgfsmJkYpHAHFSgF6+s0b6
 /2+n8d1nnm8p7X0BrG4WdAFhvAAAA
X-Change-ID: 20261005-gl-e750-mcu-f606ccd66dec
To: Serv Pol <servpol@tuta.io>, Sebastian Reichel <sre@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791239123; l=2347;
 i=servpol@tuta.io; s=20261005; h=from:subject:message-id;
 bh=WzrXr+286so0YfZSbG016gCWVzsB4SC45b59lp5A3b0=;
 b=g1cfgCZEVYxe8JiPEhW94zSLAkO7/Oz0lis/SpvzZSQKH1xfjdpzoUlyKcR0qFy0PJrJJmJ4W
 7XsfAhHUXF3A2PuZA42QMlWhZ/NkC18+UL5cymZmZwfLwODwTtD1XVa
X-Developer-Key: i=servpol@tuta.io; a=ed25519;
 pk=2HCjaqYjXxgwTYu30Nem9DOHT8mtKgjitt1vEXKpwrE=
X-Endpoint-Received: by B4 Relay for servpol@tuta.io/20261005 with auth_id=1120
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GL.iNet GL-E750 (Mudi) is a battery powered LTE travel router
(QCA9531). A microcontroller on the SoC UART drives the OLED status
screen, monitors the battery and watches the power switch. The host talks
to it in text lines of JSON; on request it reports the battery state, and
when the power switch is turned off it sends a notification a few seconds
before cutting the power.

This series adds a binding and a serdev driver that exposes the battery
through the power_supply class and shuts the system down cleanly when the
switch is turned off. The screen content (SSIDs, clients, cellular state,
free-form vendor JSON) is deliberately left out.

The board itself is supported by OpenWrt (ath79), not by an in-tree DTS,
so there is no in-tree user of the binding yet. The OpenWrt side is at
https://github.com/openwrt/openwrt/pull/25649

Testing: OpenWrt main with kernel 6.18 on a GL-E750 V1. Battery
properties read back as expected (capacity, status, temperature, cycle
count), the module was unloaded and reloaded repeatedly without
warnings, and turning the power switch off logs "power switch turned off,
shutting down" and leads to a clean shutdown before the MCU removes
power. On this tree: checkpatch --strict, W=1 and sparse builds, and
dt_binding_check are clean.

Tool use: the driver, the binding and the changelogs were written with
the help of an AI coding assistant (Claude, claude-opus-5-5), based on
the vendor protocol description at
https://github.com/gl-inet/GL-E750-MCU-instruction and on traces of the
MCU traffic on the device. I reviewed the code, tested it on the
hardware as described above and am responsible for it.

---
Serv Pol (2):
      dt-bindings: power: supply: Add GL.iNet GL-E750 MCU
      power: supply: Add GL.iNet GL-E750 MCU battery driver

 .../bindings/power/supply/glinet,gl-e750-mcu.yaml  |  37 +++
 MAINTAINERS                                        |   7 +
 drivers/power/supply/Kconfig                       |  13 +
 drivers/power/supply/Makefile                      |   1 +
 drivers/power/supply/gl-e750-mcu.c                 | 352 +++++++++++++++++++++
 5 files changed, 410 insertions(+)
---
base-commit: 5c1c602463d597c5189ddc5a73dece588ba2c57a
change-id: 20261005-gl-e750-mcu-f606ccd66dec

Best regards,
--  
Serv Pol <servpol@tuta.io>

