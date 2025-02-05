From: Krishanth Jagaduri <Krishanth.Jagaduri@sony.com>
Date: Wed, 05 Feb 2025 08:32:14 +0530
Subject: [PATCH] Documentation/no_hz: Remove description that states boot
 CPU cannot be nohz_full
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250205-send-oss-20250129-v1-1-d404921e6d7e@sony.com>
X-B4-Tracking: v=1; b=H4sIALXUomcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDQyNL3eLUvBTd/OJiXbiIcbKJUUpymomZcWqSElBfQVFqWmYF2Mzo2Np
 aANx8/qJjAAAA
X-Change-ID: 20250129-send-oss-20250129-3c42dcf463eb
To: Thomas Gleixner <tglx@linutronix.de>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Atsushi Ochiai <Atsushi.Ochiai@sony.com>, 
 Daniel Palmer <Daniel.Palmer@sony.com>, Oleg Nesterov <oleg@redhat.com>, 
 stable@vger.kernel.org, Krishanth Jagaduri <Krishanth.Jagaduri@sony.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738724552; l=2701;
 i=Krishanth.Jagaduri@sony.com; s=20250122; h=from:subject:message-id;
 bh=E835T3tqOhFIcn/Jm6X5qlETpMAWcMeplxvdOyEAeTk=;
 b=arldPplnu5QfSI/nuErJEq7UekxDqNZEtHWhOuNB63444+4wrmK/5cLfNDHZOvmrYyCnN/vOn
 GO55gjfsmhvDDyu1ZDrKcb7qOBtL1+NorXtzZGYZXpdTPdiNYzmlqQ0
X-Developer-Key: i=Krishanth.Jagaduri@sony.com; a=ed25519;
 pk=lx2tvWPqsnFN2XCeuuKdm7G2bXm/Grq1a1KTsSpFZSk=
X-Endpoint-Received: by B4 Relay for Krishanth.Jagaduri@sony.com/20250122 with auth_id=326
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Oleg Nesterov <oleg@redhat.com>

[ Upstream commit 5097cbcb38e6e0d2627c9dde1985e91d2c9f880e ]

Documentation/timers/no_hz.rst states that the "nohz_full=" mask must not
include the boot CPU, which is no longer true after:

  commit 08ae95f4fd3b ("nohz_full: Allow the boot CPU to be nohz_full").

Apply changes only to Documentation/timers/no_hz.rst in stable kernels.

Signed-off-by: Oleg Nesterov <oleg@redhat.com>
Cc: stable@vger.kernel.org # 5.4+
Signed-off-by: Krishanth Jagaduri <Krishanth.Jagaduri@sony.com>
---
Hi,

Before kernel 6.9, Documentation/timers/no_hz.rst states that
"nohz_full=" mask must not include the boot CPU, which is no longer
true after commit 08ae95f4fd3b ("nohz_full: Allow the boot CPU to be
nohz_full").

This was fixed upstream by commit 5097cbcb38e6 ("sched/isolation: Prevent
boot crash when the boot CPU is nohz_full").

While it fixes the document description, it also fixes issue introduced
by another commit aae17ebb53cd ("workqueue: Avoid using isolated cpus'
timers on queue_delayed_work").

It is unlikely that it will be backported to stable kernels which does
not contain the commit that introduced the issue.

Could Documentation/timers/no_hz.rst be fixed in stable kernels 5.4+?
---
 Documentation/timers/no_hz.rst | 7 ++-----
 1 file changed, 2 insertions(+), 5 deletions(-)

diff --git a/Documentation/timers/no_hz.rst b/Documentation/timers/no_hz.rst
index 065db217cb04fc252bbf6a05991296e7f1d3a4c5..16bda468423e88090c0dc467ca7a5c7f3fd2bf02 100644
--- a/Documentation/timers/no_hz.rst
+++ b/Documentation/timers/no_hz.rst
@@ -129,11 +129,8 @@ adaptive-tick CPUs:  At least one non-adaptive-tick CPU must remain
 online to handle timekeeping tasks in order to ensure that system
 calls like gettimeofday() returns accurate values on adaptive-tick CPUs.
 (This is not an issue for CONFIG_NO_HZ_IDLE=y because there are no running
-user processes to observe slight drifts in clock rate.)  Therefore, the
-boot CPU is prohibited from entering adaptive-ticks mode.  Specifying a
-"nohz_full=" mask that includes the boot CPU will result in a boot-time
-error message, and the boot CPU will be removed from the mask.  Note that
-this means that your system must have at least two CPUs in order for
+user processes to observe slight drifts in clock rate.) Note that this
+means that your system must have at least two CPUs in order for
 CONFIG_NO_HZ_FULL=y to do anything for you.
 
 Finally, adaptive-ticks CPUs must have their RCU callbacks offloaded.

---
base-commit: 219d54332a09e8d8741c1e1982f5eae56099de85
change-id: 20250129-send-oss-20250129-3c42dcf463eb

Best regards,
-- 
Krishanth Jagaduri <Krishanth.Jagaduri@sony.com>

