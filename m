From: Jez Ng <jez@sfcompute.com>
Date: Wed, 28 Oct 2026 00:14:46 +0000
Subject: [PATCH 2/2] thermal: intel: hfi: Disable HFI left enabled by a
 previous kernel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-hfi-kexec-v1-2-956234dcfb2b@sfcompute.com>
References: <20261028-hfi-kexec-v1-0-956234dcfb2b@sfcompute.com>
In-Reply-To: <20261028-hfi-kexec-v1-0-956234dcfb2b@sfcompute.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Ricardo Neri <ricardo.neri-calderon@linux.intel.com>, 
 Len Brown <len.brown@intel.com>, 
 Stanislaw Gruszka <stanislaw.gruszka@linux.intel.com>
Cc: "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Andrew James <ajames@sfcompute.com>, 
 John Ranzie <jranzie@sfcompute.com>, Jez Ng <jez@sfcompute.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793146828; l=3879;
 i=jez@sfcompute.com; s=20261027; h=from:subject:message-id;
 bh=MFHvCGMUfhFOc56f4vLbDg8eYQ8Wf8YlM3SPBL0W/oY=;
 b=FJFpb2EWq1gVcnPUpk8FY5Wsa6tnVG0gXGdAVE6kOPndaZVq8RYjjKa1x91I8PuEVgSph0pUT
 01u9WWPekmHDMwIpgx962TDfY1uKUTpXwh0FafqaZ/4YKmk63b0E5VJ
X-Developer-Key: i=jez@sfcompute.com; a=ed25519;
 pk=e8QxvBomwv96udVoo4EZvgPDtnl1YbPysb3vNdKi8JA=
X-Endpoint-Received: by B4 Relay for jez@sfcompute.com/20261027 with auth_id=1337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit b33f3d2677b8 ("thermal: intel: hfi: Enable HFI only when
required"), the kernel only programs HFI when a thermal netlink client
subscribes to events. Before that, the first CPU of each package to come
online wrote a fresh table address and enabled HFI, which replaced any
setup a previous kernel left behind.

Now, if the previous kernel left HFI enabled, for example across kexec,
nothing touches it. Hardware keeps writing updates into the previous
kernel's table, which is free memory in this kernel and can be allocated
for anything. On dual-socket Sapphire Rapids systems kexec'ing from a 6.1
kernel into 7.0, these writes corrupted the inode hash table and caused
oopses in find_inode_fast().

When the first CPU of a package comes online, check
MSR_IA32_HW_FEEDBACK_CONFIG and disable HFI if it is already enabled. If
a client subscribes later, HFI is re-enabled with this kernel's table as
before.

This narrows the window but cannot close it. Hardware may still write
to the old table until the package's first CPU reaches the thermal
online callback, which runs from a device initcall. On the systems
above that was about 30 seconds after this kernel started, 21 of which
were spent in acpi_init(). In testing there, hardware wrote the table
once right after HFI was enabled and not again over several minutes,
idle or with every CPU busy, but the rate under other loads is
unknown. The complete fix is for the previous kernel to disable HFI on
shutdown, as "thermal: intel: hfi: Disable HFI on shutdown and kexec"
does; this covers previous kernels that do not.

Also update the kernel-doc of intel_hfi_online(), which still described
it as always enabling HFI.

Fixes: b33f3d2677b8 ("thermal: intel: hfi: Enable HFI only when required")
Cc: stable@vger.kernel.org
Reviewed-by: Andrew James <ajames@sfcompute.com>
Reviewed-by: John Ranzie <jranzie@sfcompute.com>
Signed-off-by: Jez Ng <jez@sfcompute.com>
---
 drivers/thermal/intel/intel_hfi.c | 21 +++++++++++++++------
 1 file changed, 15 insertions(+), 6 deletions(-)

diff --git a/drivers/thermal/intel/intel_hfi.c b/drivers/thermal/intel/intel_hfi.c
index 8ff094eccbaf..b97f8113930c 100644
--- a/drivers/thermal/intel/intel_hfi.c
+++ b/drivers/thermal/intel/intel_hfi.c
@@ -413,13 +413,14 @@ static bool hfi_disable_if_enabled(void)
 }
 
 /**
- * intel_hfi_online() - Enable HFI on @cpu
- * @cpu:	CPU in which the HFI will be enabled
+ * intel_hfi_online() - Set up HFI on @cpu
+ * @cpu:	CPU that is coming online
  *
- * Enable the HFI to be used in @cpu. The HFI is enabled at the package
- * level. The first CPU in the package to come online does the full HFI
- * initialization. Subsequent CPUs will just link themselves to the HFI
- * instance of their package.
+ * The HFI is enabled at the package level. The first CPU in the package to
+ * come online does the full HFI initialization, which includes disabling HFI
+ * if a previous kernel left it enabled. HFI is enabled only when there are
+ * thermal netlink clients. Subsequent CPUs will just link themselves to the
+ * HFI instance of their package.
  *
  * This function is called before enabling the thermal vector in the local APIC
  * in order to ensure that @cpu has an associated HFI instance when it receives
@@ -462,6 +463,14 @@ void intel_hfi_online(unsigned int cpu)
 	if (hfi_instance->hdr)
 		goto enable;
 
+	/*
+	 * A previous kernel may have left HFI enabled across kexec. Hardware
+	 * would keep writing to that kernel's table, in memory this kernel now
+	 * owns.
+	 */
+	if (hfi_disable_if_enabled())
+		pr_info("HFI left enabled on package %u, disabled\n", pkg_id);
+
 	/*
 	 * Hardware is programmed with the physical address of the first page
 	 * frame of the table. Hence, the allocated memory must be page-aligned.

-- 
2.39.5

