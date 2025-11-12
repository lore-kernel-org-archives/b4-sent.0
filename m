From: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
Subject: [PATCH v6 0/2] Add support for Gunyah Watchdog
Date: Wed, 12 Nov 2025 19:35:19 +0000
Message-Id: <20251112-gunyah_watchdog-v6-0-38ad01f8dac0@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHfhFGkC/3XPwWrDMAwG4FcpPs9Fsmyn7mnvMcawYzUxrPEWt
 9lKybvP7WErZLkIfoE+8V9F4TFxEfvNVYw8pZLyUIN92oi290PHMsWahQJlwAHJ7jxcfP/25U9
 tH3MnVVRWO007Vk7Uq4+RD+n7Lr681tyncsrj5f5gwtt23ZpQgiTP1oEhYB2ecynbz7N/b/Pxu
 K1D3MhJ/TIIYJeMkiiDc1Fj1EYbWGHogVG7JUOVYRuRfa0XMK4w+oEhXDK6lmp8CMiMSGhWGPP
 HIDRLxlRGt5bpECwHbP5h5nn+AaaCTfrRAQAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Pavan Kondeti <pavan.kondeti@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762976127; l=4082;
 i=hrishabh.rajput@oss.qualcomm.com; s=20250903; h=from:subject:message-id;
 bh=8lTGsGlCbLKIsPiwLyp46Bav7NCNyZ5/nO8VhCopaLU=;
 b=0XLbKa2eIfHYXJ1aQ6JX5xlLJZACFU1zMQLEHK98LwxER/WMS6/l0S+VCUDXcoEwGC3MNxibi
 c5Y+uCEdTXWC+0zUM80Z21t0UwPTv5cGAOPcL1P3kHrWwkHSP7rW/Et
X-Developer-Key: i=hrishabh.rajput@oss.qualcomm.com; a=ed25519;
 pk=syafMitrjr3b/OYAtA2Im06AUb3fxZY2vJ/t4iCPmgw=
X-Endpoint-Received: by B4 Relay for hrishabh.rajput@oss.qualcomm.com/20250903 with auth_id=509
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Gunyah is a Type-I hypervisor which was introduced in the patch series
[1]. It is an open source hypervisor. The source repo is available at
[2].

The Gunyah Hypervisor doesn't allow its Virtual Machines to directly
access the MMIO watchdog. It either provides the fully emulated MMIO
based watchdog interface or the SMC-based watchdog interface depending
on the hypervisor configuration.
The SMC-based watchdog follows ARM's SMC Calling Convention (SMCCC)
version 1.1 and uses Vendor Specific Hypervisor Service Calls space.

This patch series adds support for the SMC-based watchdog interface
provided by the Gunyah Hypervisor.

This series is tested on SM8750 platform.

[1]
https://lore.kernel.org/all/20240222-gunyah-v17-0-1e9da6763d38@quicinc.com/

[2]
https://github.com/quic/gunyah-hypervisor

Signed-off-by: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
---
Changes in v6:
- Fix build issues reported by the kernel test robot on PowerPC and RISC-V
  architectures by adding IS_ENABLED(CONFIG_HAVE_ARM_SMCCC_DISCOVERY) check
  before calling arm_smccc_hypervisor_has_uuid().
- Link to v5: https://lore.kernel.org/r/20251107-gunyah_watchdog-v5-0-4c6e3fb6eb17@oss.qualcomm.com

Changes in v5:
- Move the gunyah_wdt device registration from the SMEM driver to the
  SCM driver. Add additional logic to check if we're running under the
  Gunyah Hypervisor.
- Implement .remove() for gunyah_wdt driver to make it not persistent.
- Link to v4: https://lore.kernel.org/r/20251031-gunyah_watchdog-v4-0-7abb1ee11315@oss.qualcomm.com

Changes in v4:
- Move the contents of gunyah_wdt_init() to qcom_smem_probe() to make
  sure we're registering the watchdog only on the Qualcomm devices.
- Link to v3: https://lore.kernel.org/r/20251028-gunyah_watchdog-v3-1-e6d1ea438b1d@oss.qualcomm.com

Changes in v3:
- Move back to platform driver model. In module init, determine if we're
  running on a Qualcomm device and there is no supported memory-mapped
  watchdog present. Then proceed to register platform device and driver
  for SMC-based Gunyah watchdog.
- To determine if we're running on a Qualcomm device we're checking the
  presence of "qcom,smem" compatible devicetree node. As an alternative,
  we also tried using socinfo for the same purpose. When both
  gunyah_wdt and socinfo drivers were made built-in, it couldn't be
  ensured that the socinfo driver probed successfully before gunyah_wdt
  init was called. Hence, we resorted to the devicetree node approach.
- Limit the errors listed in gunyah_error to the ones that can be
  produced by the driver.
- Link to v2: https://lore.kernel.org/r/20251006-gunyah_watchdog-v2-1-b99d41d45450@oss.qualcomm.com

Changes in v2:
- Move away from platform driver model since the devicetree overlay does
  not happen by default.
  See https://lore.kernel.org/all/91002189-9d9e-48a2-8424-c42705fed3f8@quicinc.com/
- Only when MMIO-based watchdog device is absent in the devicetree,
  proceed to detect SMC-based watchdog using GUNYAH_WDT_STATUS SMC and
  initialize if SMC returns success.
- Implement pm notifiers as gunyah_wdt is no longer a platform driver so
  dev_pm_ops cannot be used.
- Pretimeout IRQ is no longer supported.
- Remove struct gunyah_wdt since it is not required.
- Move the contents of gunyah_errno.h to gunyah_wdt.c.
- Link to v1: https://lore.kernel.org/r/20250903-gunyah_watchdog-v1-0-3ae690530e4b@oss.qualcomm.com

---
Hrishabh Rajput (2):
      firmware: qcom: scm: Register gunyah watchdog device
      watchdog: Add driver for Gunyah Watchdog

 MAINTAINERS                      |   1 +
 drivers/firmware/qcom/qcom_scm.c |  53 ++++++++
 drivers/watchdog/Kconfig         |  13 ++
 drivers/watchdog/Makefile        |   1 +
 drivers/watchdog/gunyah_wdt.c    | 260 +++++++++++++++++++++++++++++++++++++++
 5 files changed, 328 insertions(+)
---
base-commit: 6146a0f1dfae5d37442a9ddcba012add260bceb0
change-id: 20250903-gunyah_watchdog-2d2649438e29

Best regards,
-- 
Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>

