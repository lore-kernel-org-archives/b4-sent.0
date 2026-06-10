From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH v4 0/2] pinctrl: ultrarisc: add DP1000 pinctrl support
Date: Wed, 10 Jun 2026 13:29:54 +0800
Message-Id: <20260610-ultrarisc-pinctrl-v4-0-b7e9b2a8ed84@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFL2KGoC/23NSw6CMBgE4KuQrq3pG3DlPYyLUn6kBoG0QDSEu
 9tCosawnGTmmxl5cBY8OiUzcjBZb7s2BHFIkKl1ewNsy5ARI0wRThUem8FpZ73BvW3N4BoMlVb
 AhBEZ4SjsegeVfa7m5bplPxZ3MEOEYqO2fujcaz2daOxtvqRyx58oJriopMxlloPO9PnTOZrug
 eLHxL6KInRPYUEhqTaScqJzVe4p/FfJ9hQelLAnOZSpYKn8V5ZleQPNn8BFVAEAAA==
X-Change-ID: 20260316-ultrarisc-pinctrl-efa6e24c4803
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781069395; l=3342;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=apdwZ7rou12zXbDIPX+MxhDBa1i7yNhr4u5YXE2irHU=;
 b=u8fdlGbzSH3DKWPq1UBQO53LJssEw+Pff8FDcAyaV86JMk+oELpmcxZd25salpVyWdojlGe4q
 Q/IWv2s7cQlCrCP9TD32es4nRRQkRBtqqVWkIEuk70gHQBlF+6zwpMK
X-Developer-Key: i=wangjia@ultrarisc.com; a=ed25519;
 pk=wGVm18siRScehKOkOz0WKxgxDy7IezHEszhnN4/TUCY=
X-Endpoint-Received: by B4 Relay for wangjia@ultrarisc.com/20260515 with auth_id=779
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the devicetree schema and the pinctrl driver for the
DP1000 controller using generic pinctrl bindings.

Compared with v1, this series is narrowed down to the pinctrl binding
and driver only. v1 patches 1, 2, 3, 5, 7, 8, and 9 (vendor prefix,
CPU/SoC bindings, DTS files, and defconfig update) are not included in
v2 and will be sent separately.

Note:
- ARCH_ULTRARISC support is being reviewed separately:
  * Link: https://lore.kernel.org/lkml/20260427-ultrarisc-pcie-v4-1-98935f6cdfb5@ultrarisc.com/

Testing:
- dt_binding_check and yamllint
- Kernel build for RISC-V and boot-tested on DP1000 (Milk-V Titan and
  Rongda M0)

Signed-off-by: Jia Wang <wangjia@ultrarisc.com>
---
Changes in v4:
- Drop the public DT binding header and document the numeric pin IDs
  directly in the binding schema and examples.
- Drop the unnecessary GPIOLIB select from the pinctrl Kconfig.
- Replace the open-coded raw_spin_lock_irqsave()/unlock_irqrestore()
  pairs with scoped guards.
- Add comments for ur_find_group_route().
- Remove the CONFIG_GENERIC_PINCONF ifdef around the generic pinconf
  ops fields.
- Link to v3: https://patch.msgid.link/20260608-ultrarisc-pinctrl-v3-0-30a09ed74275@ultrarisc.com

Changes in v3:
- Re-add the DT binding header and use numeric pin IDs in the binding.
- Replace instance-specific mux names with generic function names.
- Tighten the schema constraints for A-D and LPC pins.
- Switch the driver to pinctrl_generic_pins_function_dt_node_to_map()
  and resolve mux routes from the pins + function combination.
- Link to v2: https://patch.msgid.link/20260601-ultrarisc-pinctrl-v2-0-07ac5130a96d@ultrarisc.com

Changes in v2:
- Split the vendor prefix, CPU binding, SoC binding, DTS, and defconfig
  patches out of this series for separate submission.
- Drop the legacy DT node format from both the binding and the driver,
  and switch to the generic pinctrl interface with
  pinconf_generic_dt_node_to_map_all().
- Drop the DT binding header from the series.
- Replace the generic func0/func1 mux names with named hardware functions
  in the binding and driver.
- Wire the driver through CONFIG_PINCTRL_ULTRARISC and add COMPILE_TEST
  coverage.
- Restrict function selection to valid pins in the driver.
- Link to v1: https://patch.msgid.link/20260515-ultrarisc-pinctrl-v1-0-bf559589ea8a@ultrarisc.com

---
Jia Wang (2):
      dt-bindings: pinctrl: Add UltraRISC DP1000 pinctrl controller
      pinctrl: ultrarisc: Add UltraRISC DP1000 pinctrl driver

 .../bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml | 130 ++++++
 MAINTAINERS                                        |   7 +
 drivers/pinctrl/Kconfig                            |   1 +
 drivers/pinctrl/Makefile                           |   1 +
 drivers/pinctrl/ultrarisc/Kconfig                  |  20 +
 drivers/pinctrl/ultrarisc/Makefile                 |   4 +
 drivers/pinctrl/ultrarisc/pinctrl-dp1000.c         | 168 +++++++
 drivers/pinctrl/ultrarisc/pinctrl-ultrarisc.c      | 517 +++++++++++++++++++++
 drivers/pinctrl/ultrarisc/pinctrl-ultrarisc.h      |  63 +++
 9 files changed, 911 insertions(+)
---
base-commit: 2d3090a8aeb596a26935db0955d46c9a5db5c6ce
change-id: 20260316-ultrarisc-pinctrl-efa6e24c4803

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

