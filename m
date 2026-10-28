From: Jez Ng <jez@sfcompute.com>
Subject: [PATCH 0/2] thermal: intel: hfi: Stop hardware writing to freed
 memory after kexec
Date: Wed, 28 Oct 2026 00:14:44 +0000
Message-Id: <20261028-hfi-kexec-v1-0-956234dcfb2b@sfcompute.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHQ+4WoC/yXM0QpAMBiG4VvRf2zFwuRW5MDmGz+FNqTk3g2HT
 729F3k4hqcqusjhYM/LHJDGEZmhnXsI7oJJJrJIE6nEYFlMOGEElMm0snmZaVDoVwfL5/eqm99
 +1yPM9g7ovh/8KbM0bQAAAA==
X-Change-ID: 20261027-hfi-kexec-e7c4b7f584be
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793146828; l=3133;
 i=jez@sfcompute.com; s=20261027; h=from:subject:message-id;
 bh=Q35Ngjcsidz/Av1fy+wnmQitU+ZbicSO+I9WZ2tM750=;
 b=+KBJozgnpPCuPVlgyuw7GVpttKhbd1B1UkcoLr6T/hB4ZH/VHKiVtKh4xfpgpVlldAaF4QLbE
 skjnuMuefbkAJwSab7sOmc4GTCkzw9naIBsm5wI5dSRTTzxrJWHK8qE
X-Developer-Key: i=jez@sfcompute.com; a=ed25519;
 pk=e8QxvBomwv96udVoo4EZvgPDtnl1YbPysb3vNdKi8JA=
X-Endpoint-Received: by B4 Relay for jez@sfcompute.com/20261027 with auth_id=1337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HFI hardware writes updates to a table at a physical address the kernel
programs. Nothing disables HFI on shutdown, and since commit b33f3d2677b8
("thermal: intel: hfi: Enable HFI only when required") a kernel that
starts without thermal netlink clients does not touch HFI at all. So
after a kexec, hardware keeps writing into the previous kernel's table,
which the new kernel treats as free memory.

We hit this on dual-socket Sapphire Rapids hosts (Xeon Platinum 8462Y+)
that boot a Debian 6.1 kernel and kexec into a 7.0 kernel. The new
kernel crashed in find_inode_fast() when the inode hash table landed on
one of the old table pages. Reading MSR 0x17d0 on the running 7.0
kernel showed both packages still pointing at the 6.1 kernel's tables,
and the corruption had the HFI table layout: a timestamp, a changed
flag, then one row per CPU.

Patch 1 disables HFI in a syscore shutdown callback, which covers
reboot, power off and kexec, and keeps it disabled afterwards: on kexec,
user space runs until machine_shutdown(), so a new thermal netlink
client could otherwise enable HFI again. Patch 2 makes a starting kernel
disable HFI if the previous kernel left it enabled. Patch 2 can only
narrow the window: hardware can still write between kernel start and
the moment the package's first CPU reaches the thermal online callback,
which was about 30 seconds into boot on these hosts.

This is the kexec counterpart of the hibernation corruption fixed by
commit 97566d09fd02 ("thermal: intel: hfi: Add syscore callbacks for
system-wide PM"), which disables HFI for suspend and hibernation but not
for shutdown.

Tested on one of the hosts above with both patches applied to this base,
alternating 100 kexecs (kexec_file_load + reboot(LINUX_REBOOT_CMD_KEXEC))
between the patched kernel and an unpatched 7.0 kernel. Before each
kexec, a thermal netlink subscriber enabled HFI on both packages. All
100 passed:

 - Patch 1: after each of the 50 kexecs out of the patched kernel, the
   unpatched kernel read HW_FEEDBACK_CONFIG = 0 on both packages.

 - Patch 2: after each of the 50 kexecs into the patched kernel, it
   logged "HFI left enabled on package N, disabled" for both packages
   and read HW_FEEDBACK_CONFIG = 0.

A test-only 5 second sleep after the shutdown callback, with a thermal
netlink client subscribing during it, showed that patch 1 keeps HFI
disabled. Without the hfi_shutdown_done check, the next kernel found HFI
enabled again.

Thanks to Andrew James and John Ranzie for reviewing.

The investigation and testing were done via Opus 5.5, as were the
drafting of the patches and changelogs. I reviewed all of it.

---
Jez Ng (2):
      thermal: intel: hfi: Disable HFI on shutdown and kexec
      thermal: intel: hfi: Disable HFI left enabled by a previous kernel

 drivers/thermal/intel/intel_hfi.c | 71 ++++++++++++++++++++++++++++++++++-----
 1 file changed, 63 insertions(+), 8 deletions(-)
---
base-commit: 70f331d89564126fdcaaa37f25194fe391d8f3fa
change-id: 20261027-hfi-kexec-e7c4b7f584be

Best regards,
--  
Jez Ng <jez@sfcompute.com>

