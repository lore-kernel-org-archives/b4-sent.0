From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 16:53:54 +0000
Subject: [PATCH RFC] watchdog: core: Ignore userspace keepalives once the
 system goes down
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-watchdog-reboot-keepalive-v1-1-c5902d959796@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMTQrCMBQGr1Le2kATVKpbwQN0K13k50v7VJqSp
 FUovbtRlzMws1JCZCQ6VytFLJw4jAXkriI76LGHYFeYVK2OUsqTeOlsBxd6EWFCyOIBTPrJC4R
 3h9rvTaMar6j0U4Tn9+99o/Z6oe4v02zusPl7pW37AN59C/iCAAAA
X-Change-ID: 20261119-watchdog-reboot-keepalive-fd50f4b828f2
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-watchdog@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Primoz Fiser <primoz.fiser@norik.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795107233; l=1792;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=8odbgLzkMjv4qHTEHWFN4RAGFDasNozQ665DspbA17w=;
 b=1rDr9Uz/tDZ9di0LWUyCicF5QfSmb3YYmZIPw4SQUeYUDtf+J6cTiSsiEf2uwfyQtfnpUzVjo
 kKRuVAQfoJECTRQvVUUMYLnkWlYJk1Ac3hTcM96ZL/kyMbrmU3CxEhn
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A watchdog left running through a reboot should reset a system whose
reboot hangs. But a daemon still pinging after reboot(2), such as
systemd after "systemctl reboot -ff", keeps a hang in device_shutdown()
from ever being reset.

Ignore userspace keepalives once system_state is past SYSTEM_RUNNING,
as da9062_wdt and da9063_wdt do since commit 2f61b3a74699 ("watchdog:
da9062: da9063: prevent pings ahead of machine reset").

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
RFC: this changes every driver. A reboot or power-off whose
device_shutdown() outlasts the timeout now ends in a watchdog reset.

Tested on an Orange Pi Zero2 (H616, sunxi_wdt) on 7.3.5 with a test
module that oopses holding a device lock: "systemctl reboot -ff" was
reset after 14 s in 6 of 6 runs. Without the patch there was no reset
within 90 s (one run, older 7.3 build). Other drivers and kexec are
not tested.

Developed with Claude (Anthropic) as a coding assistant, which wrote
the code and the commit message. I reviewed and tested it.
---
 drivers/watchdog/watchdog_dev.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/watchdog/watchdog_dev.c b/drivers/watchdog/watchdog_dev.c
index aad3f1f1b4ce..0f149da49a69 100644
--- a/drivers/watchdog/watchdog_dev.c
+++ b/drivers/watchdog/watchdog_dev.c
@@ -201,6 +201,9 @@ static int watchdog_ping(struct watchdog_device *wdd)
 	if (!watchdog_hw_running(wdd))
 		return 0;
 
+	if (system_state > SYSTEM_RUNNING)
+		return 0;
+
 	set_bit(_WDOG_KEEPALIVE, &wd_data->status);
 
 	wd_data->last_keepalive = ktime_get();

---
base-commit: 865c2d0f1dd3f0937865dd11819eeb59298a814c
change-id: 20261119-watchdog-reboot-keepalive-fd50f4b828f2

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

