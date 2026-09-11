From: =?utf-8?q?Juan_Carlos_Guti=C3=A9rrez_Lavado?= <jcarlosgl96@proton.me>
Subject: [PATCH v2 0/2] Add SPC Glee 10.1 A64 board support
Date: Fri, 11 Sep 2026 15:48:36 +0200
Message-Id: <20260911-b4-spc-glee-a64-v1-v2-0-ed0b7ff02e0b@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ7CIBREr9L8td8AbYm68h6mC2h/W4wCAWw0D
 XeX1r3JbF4yM2+FSMFQhEu1QqDFRONsAXGooJ+VnQjNUBgEE5KdmUTdYPQ9Tg8iVLLBhaMkOWh
 Vn5RqCcrQBxrNez+9dT+OL32nPm1PW2M2Mbnw2a0L33p/BSUMpeDDKHjbUs2vPrjk7PFJ0OWcv
 8IU1QfGAAAA
X-Change-ID: 20260906-b4-spc-glee-a64-v1-6e6dba38aa5e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Juan_Carlos_Guti=C3=A9rrez_Lavado?= <jcarlosgl96@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789134516; l=2744;
 i=jcarlosgl96@proton.me; s=20260906; h=from:subject:message-id;
 bh=lG4KDAp2pMa37LUQNtZbacnmooezoxlM4A7rINK4vpY=;
 b=9cQ8HQazllEZ9I3uWCMPeNw1KeaNAYJ7K67hJqRBiRk3vDkZLO8y0O98Kuiym09Ba9Fr+zhVv
 ihA3uDDYJ0HBtZRMro+NaiR2KP+HnwLY8llpeA3HBQck4uWQtw7cFMw
X-Developer-Key: i=jcarlosgl96@proton.me; a=ed25519;
 pk=2/GzZfrbHAiuUrsA5A4A9ixfHKnypfDfzyE+fToY4Io=
X-Endpoint-Received: by B4 Relay for jcarlosgl96@proton.me/20260906 with auth_id=1008
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add initial support for the SPC Glee 10.1 tablet with Allwinner A64
and AXP803 PMIC. Describe essential supplies, 2 GiB DRAM, microSD,
UART, battery monitoring and USB peripheral mode. Keep unverified
peripherals disabled. The microSD slot uses broken-cd and a conservative
25 MHz limit until its card-detect wiring and faster modes are validated.

Validation against sunxi/for-next base 913f7eda9f3e:
- DTB build, binding checks and full DTB schema validation pass with
  dt-schema 2026.6. W=1 retains three inherited SoC warnings.
- Cold boot from microSD and kexec into Linux 7.3.0-rc1 with the corrected
  DTB reach accessible userspace without regulator_ignore_unused.
- CPUfreq transitions to 648, 816 and 1152 MHz were observed.
- CPU cooling state 7 limits the CPU to 648 MHz. Automatic thermal updates
  were paused briefly to test this actuator, then restored.
- USB supply online/present changed 1 -> 0 -> 1 during cable unplug/replug;
  SSH reconnected after the cable was restored.
- Automatic CPU thermal cooling reduced frequency under load. Two SHA-256
  workers completed 10 minutes, peaking at 78.37 C, with USB/SSH connected.
  Cooling state returned to 0 after removing the load. A four-worker test
  was stopped at a conservative 80 C limit after 27 seconds.

Long-duration stability, sustained full four-core load and broader peripheral
support remain unvalidated.

Signed-off-by: Juan Carlos Gutiérrez Lavado <jcarlosgl96@proton.me>
---
Changes in v2:
- Use the onspc vendor prefix and place its registry entry alphabetically.
- Include CPU OPPs for CPUfreq and CPU thermal cooling.
- Enable the AXP803 USB supply and link it to the USB PHY for VBUS detection.
- Keep ALDO2 (VCC-PL, 1.8 V) and ALDO3 (VCC-PLL/AVCC, 3.0 V) always on.
  These supplies are identified by the stock firmware and match the
  measured baseline settings. Earlier test boots stopped progressing
  without regulator_ignore_unused; the corrected DTB remains responsive.
- Link to v1: https://lore.kernel.org/all/20260906-b4-spc-glee-a64-v1-v1-0-621df2155e31@proton.me/

---
Juan Carlos Gutiérrez Lavado (2):
      dt-bindings: arm: sunxi: Add SPC Glee 10.1 A64
      arm64: dts: allwinner: Add SPC Glee 10.1 A64

 Documentation/devicetree/bindings/arm/sunxi.yaml   |   5 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/allwinner/Makefile             |   1 +
 .../boot/dts/allwinner/sun50i-a64-spc-glee.dts     | 143 +++++++++++++++++++++
 4 files changed, 151 insertions(+)
---
base-commit: 913f7eda9f3e3fb1c67285e144e202494d440049
change-id: 20260906-b4-spc-glee-a64-v1-6e6dba38aa5e

Best regards,
--  
Juan Carlos Gutiérrez Lavado <jcarlosgl96@proton.me>

