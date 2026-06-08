From: Jia Wang <wangjia@ultrarisc.com>
Subject: [PATCH v3 0/2] pinctrl: ultrarisc: add DP1000 pinctrl support
Date: Mon, 08 Jun 2026 15:50:47 +0800
Message-Id: <20260608-ultrarisc-pinctrl-v3-0-30a09ed74275@ultrarisc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFd0JmoC/23N3QqCMBwF8FeRXbfYh1vaVe8RXcz5Nxemss1Ri
 O/eplAQXh4453dm5MAacOiczchCMM4MfQz8kCHdqv4O2NQxI0aYJJxKPHXeKmucxqPptbcdhkZ
 JYLnOC8JR3I0WGvNazetty26qHqB9glKjNc4P9r2eBpp6my+o2PEDxQRXjRClKEpQhbp8O0c9P
 FH6COynSEL3FBYVclJaUE5UKet/ZVmWD3hde9kOAQAA
X-Change-ID: 20260316-ultrarisc-pinctrl-efa6e24c4803
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jia Wang <wangjia@ultrarisc.com>
X-Mailer: b4 0.15-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780905056; l=2879;
 i=wangjia@ultrarisc.com; s=20260515; h=from:subject:message-id;
 bh=TR9EWDnFRajz+fp+F/iDS8YxrKo4rRALNNn3rqlhyus=;
 b=52L1j+tu4EAMXhYMbjEnV3zO3aWz6RKfCRTMg6KPewwxGj4m5UZT/yh2PmOSWhvMqSp2ZH6h+
 nexCdcSwoB7DWa43VmbM+sMWspvrs0k+LhyxjbcsgAkcFr5tmegPdZq
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

 .../bindings/pinctrl/ultrarisc,dp1000-pinctrl.yaml | 131 ++++++
 MAINTAINERS                                        |   7 +
 drivers/pinctrl/Kconfig                            |   1 +
 drivers/pinctrl/Makefile                           |   1 +
 drivers/pinctrl/ultrarisc/Kconfig                  |  21 +
 drivers/pinctrl/ultrarisc/Makefile                 |   4 +
 drivers/pinctrl/ultrarisc/pinctrl-dp1000.c         | 168 +++++++
 drivers/pinctrl/ultrarisc/pinctrl-ultrarisc.c      | 503 +++++++++++++++++++++
 drivers/pinctrl/ultrarisc/pinctrl-ultrarisc.h      |  63 +++
 .../dt-bindings/pinctrl/ultrarisc,dp1000-pinctrl.h |  63 +++
 10 files changed, 962 insertions(+)
---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260316-ultrarisc-pinctrl-efa6e24c4803

Best regards,
--  
Jia Wang <wangjia@ultrarisc.com>

