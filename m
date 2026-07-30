From: Mayank Rungta <mrungta@google.com>
Subject: [PATCH 0/3] watchdog: qcom: Support NMI pretimeout warnings
Date: Thu, 30 Jul 2026 14:32:46 -0700
Message-Id: <20260730-qcom-wdt-nmi-series-v1-0-3aa86d162914@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP7Ca2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyMT3cLk/Fzd8pQS3bzcTF2IZl0Ds0QTi5RE8yQTQ1MloM6CotS0zAq
 wqdGxtbUAKmScq2UAAAA=
X-Change-ID: 20260724-qcom-wdt-nmi-series-06a48da7b415
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Thomas Gleixner <tglx@kernel.org>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, "Kirill A. Shutemov" <kas@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, 
 Mayank Rungta <mrungta@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785447181; l=2279;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=E00UjiY9NGFXivfMUet7mSE4cZ9O3b+2c5MluuPTLmQ=;
 b=xBPfmoKsQ/I33VuZIsAs6ZyS5mn84msN1YcbFg2FZUvdVLGIogeKQ13E9wuGaA+EGPbkxedtQ
 O8eKW00VAxaBSx8IucQpmg/mCjApdn+ITmCAPonxuNF96QQvGykrDeG
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On ARM64 Qualcomm SoCs, when a system freezes completely due to hard
locked CPUs with standard interrupts disabled, a standard watchdog
pretimeout warning interrupt (bark) fails to fire. To diagnose total
system lockups, we need to transition the Qualcomm hardware watchdog
pretimeout bark interrupt into an NMI (or pseudo-NMI).

Enabling NMI pretimeout handlers within loadable driver module requires
making watchdog pretimeout NMI-safe and unlocking GPL module access to
NMI registration functions.

This 3-patch series achieves NMI pretimeout enablement for qcom-wdt:
 1) Replaces spinlocks in watchdog_notify_pretimeout() with RCU to
    guarantee safe execution from NMI context.
 2) Exports request_nmi(), free_nmi(), enable_nmi(), and
    disable_nmi_nosync() to GPL loadable kernel modules.
 3) Updates qcom-wdt to request its pretimeout bark interrupt as a
    NMI (or pseudo-NMI).

Testing & Verification:
 - Built and tested on ARM64 Qualcomm Snapdragon SoC (Google CoachZ)
   loadable module configurations (CONFIG_QCOM_WDT=m).
 - With GICv3 pseudo-NMI enabled, simulated hard CPU lockups and
   IRQ-disabled hang conditions via lkdtm. Confirmed that qcom-wdt traps
   the watchdog pretimeout bark interrupt as a pseudo-NMI, safely
   executes watchdog_notify_pretimeout() without deadlocks.
 - Verified that runtime transitions between pretimeout governors in
   sysfs execute safely.
 - Booted with pseudo-NMIs disabled and confirmed that qcom-wdt detects
   unsupported NMI and falls back to standard IRQ.

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
Mayank Rungta (3):
      watchdog: pretimeout: Protect governor access with RCU for NMI safety
      genirq: Export NMI APIs
      watchdog: qcom: Register pretimeout interrupt as NMI

 drivers/watchdog/qcom-wdt.c            | 55 +++++++++++++++++++++++++++++++---
 drivers/watchdog/watchdog_pretimeout.c | 47 ++++++++++++++++-------------
 include/linux/watchdog.h               |  2 +-
 kernel/irq/manage.c                    |  4 +++
 4 files changed, 82 insertions(+), 26 deletions(-)
---
base-commit: 3fe08b9796f36ef437ab9328e7dd1e5ff2d66603
change-id: 20260724-qcom-wdt-nmi-series-06a48da7b415

Best regards,
-- 
Mayank Rungta <mrungta@google.com>

