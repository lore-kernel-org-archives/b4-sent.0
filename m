From: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
Subject: [PATCH 0/2] Add support for Gunyah Watchdog
Date: Wed, 03 Sep 2025 19:33:58 +0000
Message-Id: <20250903-gunyah_watchdog-v1-0-3ae690530e4b@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACaYuGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSwNj3fTSvMrEjPjyxJLkjJT8dF2jFCMzE0sTY4tUI0sloK6CotS0zAq
 widGxtbUAB4BPbWEAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756928065; l=1783;
 i=hrishabh.rajput@oss.qualcomm.com; s=20250903; h=from:subject:message-id;
 bh=DnLt/SBMSfTZBgk5JWHNT9RMOyUX2bInZRqm44ui51g=;
 b=XfShsxJHzpWyLh8U+wdwsMZp+lUR39UftpyXcbGXlJCSLDWuRvECb2OHQJI4v/e7bkdo904ft
 opn6k/cpcYBBAwwkPc/Ntqekh16g1Xcy97UMuJnKkeYuFAOMfxuEqYv
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
provided by the Gunyah Hypervisor. The driver supports start/stop
operations, timeout and pretimeout configuration, pretimeout interrupt
handling and system restart via watchdog.

This series is tested on SM8750 platform.

[1]
https://lore.kernel.org/all/20240222-gunyah-v17-0-1e9da6763d38@quicinc.com/

[2]
https://github.com/quic/gunyah-hypervisor

Signed-off-by: Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>
---
Hrishabh Rajput (2):
      dt-bindings: Add binding for gunyah watchdog
      watchdog: Add driver for Gunyah Watchdog

 .../bindings/watchdog/qcom,gh-watchdog.yaml        |  76 ++++++
 MAINTAINERS                                        |   3 +
 drivers/watchdog/Kconfig                           |  13 +
 drivers/watchdog/Makefile                          |   1 +
 drivers/watchdog/gunyah_wdt.c                      | 268 +++++++++++++++++++++
 include/linux/gunyah_errno.h                       |  77 ++++++
 6 files changed, 438 insertions(+)
---
base-commit: 038d61fd642278bab63ee8ef722c50d10ab01e8f
change-id: 20250903-gunyah_watchdog-2d2649438e29

Best regards,
-- 
Hrishabh Rajput <hrishabh.rajput@oss.qualcomm.com>

