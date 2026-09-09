From: Vincent Jardin <vjardin@free.fr>
Date: Wed, 09 Sep 2026 19:04:40 +0200
Subject: [PATCH v2] bus: fsl-mc: register the object drivers after
 misc_class exists
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-for-upstream-fsl-mc-initcall-order-v2-1-b7a04634fcf1@free.fr>
X-B4-Tracking: v=1; b=H4sIAKeRoWoC/42NSw6CMBBAr0K6dkw/pogr72FYIMzIJEDJFBsN4
 e5W4gFcvrd4b1URhTGqS7EqwcSRw5TBHgrV9s30QOAus7Lael1ZCxQEnnNcBJsRKA4wtsATL20
 zDBCkQwF0znhX6dLYu8qhWZD4tU9udeae4xLkvT+T+dpfXpt/8smAAeeJ8HSm0pfdlQTxSKLqb
 ds+MEjWltIAAAA=
To: Ioana Ciornei <ioana.ciornei@nxp.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: Laurentiu Tudor <laurentiu.tudor@nxp.com>, 
 linuxppc-dev@lists.ozlabs.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable+noautosel@kernel.org, 
 Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788973486; l=3680;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=4w8EyLodWYbpAxy4IdhaZ8kc0Y8HbWHFCMkpK6NuPbI=;
 b=Rid5LvQoK9miq+gA7+YL1kd3AUGRJD8FeSxJ1xg5zimcVvmU64GZjtoDj5sORC46X9N1xjtkj
 HACM4entDAGAiqmRKDC0kGr5rSInrkDPfoIfd+y7zLR9ubxcwGErk7M
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unbinding and re-binding the root DPRC fails with:

  sysfs: cannot create duplicate filename '/dev/char/10:256'
    misc_register / fsl_mc_uapi_create_device_file /
    dprc_setup / dprc_probe

It happens when the fsl-mc bus probe is not deferred, without SMMU:
- the dprc driver is registered at postcore_initcall,
- the DT node is populated at arch_initcall_sync,
- the root DPRC probes right there, before misc_init() has
  registered misc_class at subsys_initcall.

misc_register() still succeeds but the device gets
no class, so misc_deregister() at unbind cannot find it:
the minor is freed while the device and its /sys/dev/char/ link leak,
and then the next bind collides on the same minor.

Let's move the dprc and allocator drivers registration, and
platform_driver_register(), to subsys_initcall_sync, after misc_init()
at subsys_initcall.
bus_register() and the platform-bus notifier stay at postcore_initcall
so that fsl_mc_bus_notifier() still pauses the MC before the SMMU is probed.

Cc: stable+noautosel@kernel.org # niche: root DPRC unbind/rebind only
Fixes: 2cf1e703f066 ("bus: fsl-mc: add fsl-mc userspace support")
Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
Issue found when unbinding/rebinding the root DPRC on an LX2160A.

The failure is silent at bind time and only shows up as a
duplicate /dev/char entry on the second bind.
---
Changes in v2:
- Commit message: the bug needs a non-deferred fsl-mc bus
  probe (no SMMU) - Ioana Ciornei
- No code change
- Link to v1: https://lore.kernel.org/r/20260901-for-upstream-fsl-mc-initcall-order-v1-1-36ffe48f767d@free.fr
---
 drivers/bus/fsl-mc/fsl-mc-bus.c | 40 ++++++++++++++++++++++++----------------
 1 file changed, 24 insertions(+), 16 deletions(-)

diff --git a/drivers/bus/fsl-mc/fsl-mc-bus.c b/drivers/bus/fsl-mc/fsl-mc-bus.c
index 66a4fa73c5b86..7f283844e4500 100644
--- a/drivers/bus/fsl-mc/fsl-mc-bus.c
+++ b/drivers/bus/fsl-mc/fsl-mc-bus.c
@@ -1264,35 +1264,43 @@ static int __init fsl_mc_bus_driver_init(void)
 	error = bus_register(&fsl_mc_bus_type);
 	if (error < 0) {
 		pr_err("bus type registration failed: %d\n", error);
-		goto error_cleanup_cache;
+		return error;
 	}
 
-	error = platform_driver_register(&fsl_mc_bus_driver);
-	if (error < 0) {
-		pr_err("platform_driver_register() failed: %d\n", error);
+	error = bus_register_notifier(&platform_bus_type, &fsl_mc_nb);
+	if (error < 0)
 		goto error_cleanup_bus;
-	}
+
+	return 0;
+
+error_cleanup_bus:
+	bus_unregister(&fsl_mc_bus_type);
+	return error;
+}
+postcore_initcall(fsl_mc_bus_driver_init);
+
+static int __init fsl_mc_bus_drivers_init(void)
+{
+	int error;
 
 	error = dprc_driver_init();
 	if (error < 0)
-		goto error_cleanup_driver;
+		return error;
 
 	error = fsl_mc_allocator_driver_init();
 	if (error < 0)
 		goto error_cleanup_dprc_driver;
 
-	return bus_register_notifier(&platform_bus_type, &fsl_mc_nb);
+	error = platform_driver_register(&fsl_mc_bus_driver);
+	if (error < 0) {
+		pr_err("platform_driver_register() failed: %d\n", error);
+		goto error_cleanup_dprc_driver;
+	}
+
+	return 0;
 
 error_cleanup_dprc_driver:
 	dprc_driver_exit();
-
-error_cleanup_driver:
-	platform_driver_unregister(&fsl_mc_bus_driver);
-
-error_cleanup_bus:
-	bus_unregister(&fsl_mc_bus_type);
-
-error_cleanup_cache:
 	return error;
 }
-postcore_initcall(fsl_mc_bus_driver_init);
+subsys_initcall_sync(fsl_mc_bus_drivers_init);

---
base-commit: 786262be6048deab760f68c8acc2c85607165894
change-id: 20260922-for-upstream-fsl-mc-initcall-order-e3316390712b

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

