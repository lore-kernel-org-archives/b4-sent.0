From: Chris Simpson <chris@nilk.net>
Date: Sat, 17 Oct 2026 16:13:38 -0600
Subject: [PATCH] media: ipu6: Keep psys out of direct-complete on system
 suspend
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-psys-ipu6-v1-1-56e333f6ed04@nilk.net>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0Nz3YLiymLdzIJSM13jRJOkZEOL1DRz8zQloPqCotS0zAqwWdGxtbU
 AbTAk11sAAAA=
X-Change-ID: 20261017-psys-ipu6-3a4bc18ef77f
To: Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Antti Laakso <antti.laakso@linux.intel.com>, 
 "Sapre, Sarang" <sarang.sapre@intel.com>, 
 Divyamani Tripathi <divyamani.tripathi@intel.com>, 
 Manik Bajpai <manik.bajpai@intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Danilo Krummrich <dakr@kernel.org>, linux-media@vger.kernel.org, 
 linux-pm@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Chris Simpson <chris@nilk.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792275242; l=5398;
 i=chris@nilk.net; s=20261017; h=from:subject:message-id;
 bh=RpJEa/l3s3LAaSolDKPx/sHpPb3BursxeLOSSpNbLls=;
 b=Exb1QNu4nWHRU48GmPgf1r/WXUwJNK82Bfaf7uS/0XxOjRKTyes+jHzeluQwoqWtUaj1XxBSh
 QraG6oNjWXgBlTf4E+YGNKUn1MC1Qug0PFITN1a6q45SuD/skEXTbZO
X-Developer-Key: i=chris@nilk.net; a=ed25519;
 pk=bwNSTJdm8iKtfcCRqyaQFQFlAxLuiAxLw4pMXey4Z+o=
X-Endpoint-Received: by B4 Relay for chris@nilk.net/20261017 with auth_id=1225
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit a1fa010b3c9f ("driver core: auxiliary bus: Drop
auxiliary_dev_pm_ops"), the auxiliary bus has no dev_pm_ops. The psys
auxiliary device has no driver in mainline, and its PM domain,
ipu6_bus_pm_domain, has only runtime PM callbacks. So
device_pm_check_callbacks() now sets power.no_pm_callbacks for psys,
and device_prepare() puts it in direct-complete.

A runtime-suspended psys in direct-complete gets its runtime PM
disabled in device_suspend(). Runtime PM is enabled again only in
psys's own device_resume(), which in practice runs after the PCI
device's. Before, it came back in device_resume_early(). ipu6_resume(),
the system resume callback of the PCI device, runtime-resumes psys
before the firmware authentication. That now fails with -EACCES on
every resume:

  auxiliary intel_ipu6.psys.40: Failed to get runtime PM

and ipu6_resume() returns early, skipping ipu6_buttress_authenticate().
In secure mode the firmware is then not re-authenticated after resume,
which matters whenever the IPU has lost power. On s2idle on a Surface
Pro 9 the cameras still work, and the error is logged on every resume.

Add suspend and resume callbacks to ipu6_bus_pm_domain that forward to
the driver. That is what the PM core does without them, so isys is
unaffected, but psys has PM callbacks again and is not left in
direct-complete. This restores the behaviour from before the auxiliary
bus change.

The fix is kept local rather than in the auxiliary bus or the PM core:
it is this driver that runtime-resumes a driverless child from its
parent's ->resume().

Fixes: a1fa010b3c9f ("driver core: auxiliary bus: Drop auxiliary_dev_pm_ops")
Cc: stable@vger.kernel.org # v7.1+
Cc: Rafael J. Wysocki <rafael@kernel.org>
Cc: linux-pm@vger.kernel.org
Assisted-by: LLM sparse smatch coccinelle
Signed-off-by: Chris Simpson <chris@nilk.net>
---
Tested on a Surface Pro 9 (IPU6 in secure mode) running a Fedora-based
7.2.11 kernel with the linux-surface patches (a COPR build), whose only
changes near this code are in ipu-bridge. The patch applies unchanged to
media-committers next. Three s2idle cycles before and thirteen after,
tracing the rpm and power:device_pm_callback_start events for psys:

  before: "Failed to get runtime PM" on every resume. At ipu6_resume()
          time rpm_resume() sees disable_depth 1 and returns -EACCES,
          and psys gets no system sleep callbacks.
  after:  no message. disable_depth is 0 and rpm_resume() returns 0,
          and the domain's suspend and resume run for psys. No new
          kernel warnings, and both cameras capture after resume.
          psys is runtime-suspended again at the end of every cycle.

A suspend attempt with a stream open was also tried. isys still
refuses it with -EBUSY, now through the domain's pm_generic_suspend(),
and the abort unwinds cleanly: no warnings, psys ends suspended, the
stream continues with no gap in frame sequence numbers, and the next
s2idle cycle passes.

Not tested: a resume where the IPU actually loses power, which is where
the skipped authentication matters (s2idle keeps it powered), and
IPU7/IPU8 (no hardware).

On next the ipu6 driver also drives IPU7 (by default,
VIDEO_INTEL_IPU6_IPU7) and IPU8, so this covers those devices there too.
The staging ipu7 driver has the same pattern in ipu7_bus_pm_domain and
ipu7_resume(). I can send the same change for it, but I have no IPU7
hardware to test it on.

Intel's out-of-tree psys driver (intel/ipu6-drivers) has empty
.suspend/.resume callbacks for the same reason. Its comment says they
"are needed to enable runtime PM in IPU PCI device resume".

Rafael, Cc'd as the author of a1fa010b3c9f: a driverless auxiliary
device whose PM domain has only runtime PM callbacks now ends up in
direct-complete. That is consistent PM-core behaviour, and the fix here
is local to ipu6. But any other driver that runtime-resumes such a
child from its parent's ->resume() would see the same failure.

Made with AI assistance. Written by Claude Opus 5.5 (fix, analysis and
text; reviews by Claude Opus subagents), with testing by Claude Opus
5.5, under the direction of Chris Simpson <chris@nilk.net>, who reviewed
and approved it and had it tested on their Surface Pro 9.
---
 drivers/media/pci/intel/ipu6/ipu6-bus.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/media/pci/intel/ipu6/ipu6-bus.c b/drivers/media/pci/intel/ipu6/ipu6-bus.c
index 173616381..1b06e581e 100644
--- a/drivers/media/pci/intel/ipu6/ipu6-bus.c
+++ b/drivers/media/pci/intel/ipu6/ipu6-bus.c
@@ -63,8 +63,16 @@ static int bus_pm_runtime_resume(struct device *dev)
 	return -EBUSY;
 }
 
+/*
+ * The driverless psys device needs system sleep callbacks, or it is put in
+ * direct-complete and its runtime PM is normally still disabled when
+ * ipu6_resume() tries to runtime-resume it. These only forward to the driver,
+ * as the PM core would do without them.
+ */
 static struct dev_pm_domain ipu6_bus_pm_domain = {
 	.ops = {
+		.suspend = pm_generic_suspend,
+		.resume = pm_generic_resume,
 		.runtime_suspend = bus_pm_runtime_suspend,
 		.runtime_resume = bus_pm_runtime_resume,
 	},

---
base-commit: d7e7bca7169873b46e857c025c10f3336c1258d8
change-id: 20261017-psys-ipu6-3a4bc18ef77f

Best regards,
-- 
Chris Simpson <chris@nilk.net>

