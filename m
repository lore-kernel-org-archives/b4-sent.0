From: Igor Velkov <iav@iav.lv>
Subject: [PATCH v2 0/2] watchdog: orion_wdt: stop the watchdog during
 system suspend
Date: Mon, 12 Oct 2026 03:46:55 +0300
Message-Id: <20261012-orion-wdt-suspend-v2-0-f13cf71443ba@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAuzGoC/32NTQ7CIBCFr9LMWgxMDFhX3qPpAstgJzHQQEVNw
 93FHsC81ffyfjbIlJgyXLoNEhXOHEMDPHQwzTbcSbBrDChRK6lQxNQS4uVWkZ95oeCEPHs02lp
 v1Qlab0nk+b1vDmPjmfMa02e/KOrn/lsrSjRpo6eb6Ql7urItx0eBsdb6BdABR9yvAAAA
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: Chris Packham <chris.packham@alliedtelesis.co.nz>, 
 Gregory CLEMENT <gregory.clement@bootlin.com>, 
 linux-watchdog@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1555; i=iav@iav.lv;
 h=from:subject:message-id; bh=QvXw4q3YNI7WdpHXkrsI3WgjEitXRqf5xOTiIc/VBxQ=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFln9Nj9d6nW/eisXd70bIXfhBj/HwX/dSM3+xUGuDcb/
 OuvCRPqKGFhEONikBVTZJlwSONWxpKrf/09zB/AzGFlAhnCwMUpABNJ5mb4MdX5QmxOiwiTb+H2
 7ZafC8VuWsx7/OaBrBjvrIKUee+tGf4KfRS3/7pjg9gK66t9r5qM/WIO/3K/smnVpLx0sykV0aZ
 8AA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The watchdog keeps counting across system suspend while the userspace
that pings it is frozen, so a Kobol Helios4 (Armada 388) resets 60 s
into s2idle. Patch 2 stops the timer on suspend and restarts it on
resume. Patch 1 fixes the Armada XP pretimeout that Sashiko spotted on
the restart path of v1; the same bug hits every start since
7a6b3d8a432d.

Tested on a Helios4 (v7.2.9). Unpatched, the board resets 60 s into
s2idle. With patch 2:
- watchdog daemon: three 120 s s2idle cycles, no reset;
- systemd RuntimeWatchdogSec=60s: one 120 s s2idle and one 120 s
  standby cycle, no reset;
- the watchdog still fires after resume: freezing the daemon (SIGSTOP)
  after the s2idle cycles reset the board in 61 s, a panic after
  standby in 54 s.
Patch 1 is compile-tested only; I have no Armada XP.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Changes in v2:
- Add patch 1, the Armada XP pretimeout reload (Sashiko).
- Keep pm_sleep_ptr(): it is the pairing for DEFINE_SIMPLE_DEV_PM_OPS()
  (1a3c7bb08826).
- Link to v1: https://lore.kernel.org/r/20261012-orion-wdt-suspend-v1-1-1676cb79e29e@iav.lv

---
Igor Velkov (2):
      watchdog: orion_wdt: load the pretimeout counter on Armada 370/XP start
      watchdog: orion_wdt: stop the watchdog during system suspend

 drivers/watchdog/orion_wdt.c | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)
---
base-commit: 8b5a9f09037e3c372c4e9f2fbda85fcfbf5ea5f0
change-id: 20261012-orion-wdt-suspend-08f276aafa14

Best regards,
-- 
Igor Velkov <iav@iav.lv>

