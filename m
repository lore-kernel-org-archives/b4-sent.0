From: Mayank Rungta <mrungta@google.com>
Subject: [PATCH 0/2] watchdog: pretimeout: Allow building dump governor as
 module
Date: Thu, 30 Jul 2026 15:00:20 -0700
Message-Id: <20260730-export-cpu-backtrace-apis-v1-0-bace8e1cb817@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHTJa2oC/x3MQQqAIBBA0avErBtIhayuEi3MphqCkrEikO6et
 HyL/xNEEqYIXZFA6ObIx56hygL86vaFkKds0JWuK6sbpCcccqIPF47Ob6c4T+gCR1SmnszYqNZ
 YC7kPQjM//7sf3vcDGP4jOWsAAAA=
X-Change-ID: 20260728-export-cpu-backtrace-apis-136d3b819377
To: Andrew Morton <akpm@linux-foundation.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: Tzung-Bi Shih <tzungbi@kernel.org>, 
 Douglas Anderson <dianders@chromium.org>, linux-kernel@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, Mayank Rungta <mrungta@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785448826; l=1089;
 i=mrungta@google.com; s=20260212; h=from:subject:message-id;
 bh=Wp0mqUPZWVkNcFglphCfVSwxnMXCbJkeE9ADnjkmes4=;
 b=/E/jAWOT7pmfUrBwiAzubVyp2fiDuSunmTZ/EOaZr5j5GFbLW0DexzdLukhaFeT4LArg80Gmx
 1G+T7Mx2MFFBy5sqoEhDO2z0B1pxBsGSBSFVHEsMhkKOYtVCUbcgqOw
X-Developer-Key: i=mrungta@google.com; a=ed25519;
 pk=2Bjwbv/ibL10QnyvK9G7DoKpffXy7z6+M4NawEYgYDI=
X-Endpoint-Received: by B4 Relay for mrungta@google.com/20260212 with auth_id=634
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All other watchdog pretimeout governors (noop, panic) can be built as
loadable modules. However the "dump" pretimeout governor is restricted
to built-in code because it calls trigger_all_cpu_backtrace(), which
relies on arch_trigger_cpumask_backtrace(), an arch specific helper that
is not exported to loadable modules.

This 2-patch series allows building the dump governor as a module (=m):
1) Export cpumask_backtrace() in lib/nmi_backtrace.c.
2) Convert CONFIG_WATCHDOG_PRETIMEOUT_GOV_DUMP from bool to tristate.

Signed-off-by: Mayank Rungta <mrungta@google.com>
---
Mayank Rungta (2):
      nmi: Export CPU backtrace APIs for loadable modules
      watchdog: pretimeout: Convert dump pretimeout governor to tristate

 drivers/watchdog/Kconfig |  4 ++--
 include/linux/nmi.h      | 10 ++++++----
 lib/nmi_backtrace.c      |  7 +++++++
 3 files changed, 15 insertions(+), 6 deletions(-)
---
base-commit: 3fe08b9796f36ef437ab9328e7dd1e5ff2d66603
change-id: 20260728-export-cpu-backtrace-apis-136d3b819377

Best regards,
-- 
Mayank Rungta <mrungta@google.com>

