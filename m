From: Mayank Rungta <mrungta@google.com>
Date: Thu, 30 Jul 2026 15:00:22 -0700
Subject: [PATCH 2/2] watchdog: pretimeout: Convert dump pretimeout governor
 to tristate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260730-export-cpu-backtrace-apis-v1-2-bace8e1cb817@google.com>
References: <20260730-export-cpu-backtrace-apis-v1-0-bace8e1cb817@google.com>
In-Reply-To: <20260730-export-cpu-backtrace-apis-v1-0-bace8e1cb817@google.com>
To: Andrew Morton <akpm@linux-foundation.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: Tzung-Bi Shih <tzungbi@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, linux-kernel@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, Mayank Rungta <mrungta@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785448826; l=1193;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=f5W+Lr+D6y/aPDppSlY4If7YQ/lnBLFc82lZnHrC3p8=;
 b=Hf4P9bSr81uHIQQkvhAXzHtv5u6EsLHuPCyFHF87+AgJlZxnV2Im4CKn8mSyruug2su1FpHEp
 56Xv8Y21o6KBAE2X0DCKFqfbZZCLGUxHUf6aOYrJO3wz4BxKCnDqU8q
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 645ad41da8b2 ("watchdog: pretimeout: Add "dump" pretimeout
governor") added the "dump" watchdog pretimeout governor, but restricted
it to built-in code because trigger_all_cpu_backtrace() was not exported
to loadable modules.

Now that CPU backtrace APIs are supported for loadable kernel modules
via cpumask_backtrace(), convert WATCHDOG_PRETIMEOUT_GOV_DUMP to
tristate. This allows kernels to deliver the pretimeout governor as a
loadable kernel module.

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
 drivers/watchdog/Kconfig | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/watchdog/Kconfig b/drivers/watchdog/Kconfig
index 9f013d774897..922741dd837c 100644
--- a/drivers/watchdog/Kconfig
+++ b/drivers/watchdog/Kconfig
@@ -99,8 +99,8 @@ config WATCHDOG_PRETIMEOUT_GOV_SEL
 if WATCHDOG_PRETIMEOUT_GOV
 
 config WATCHDOG_PRETIMEOUT_GOV_DUMP
-	bool "Dump watchdog pretimeout governor"
-	depends on WATCHDOG_CORE=y
+	tristate "Dump watchdog pretimeout governor"
+	depends on WATCHDOG_CORE
 	default WATCHDOG_CORE
 	help
 	  Dump watchdog pretimeout governor, all cpu backtrace is

-- 
2.55.0.508.g3f0d502094-goog

