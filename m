From: Angel Lindo <angellindo@gmail.com>
Date: Mon, 05 Oct 2026 15:00:34 -0500
Subject: [PATCH] platform/x86/intel/pmc: Add Sunrise Point-H support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261005-intel-pmc-spt-h-v1-1-78c98e4f4620@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTtJKcjCqxgXtvzIEKxNpxgTw
 t2psPwW762kSAKlW7VSwldUPqGgvlTkx2d4gaUvJmtsVxtzZQkZM8e3Z42ZR27g0Da9Nd3gqFQ
 xYZDfcbw/TuviJvj839C27T9c/ndzAAAA
X-Change-ID: 20261005-intel-pmc-spt-h-3ebe43d206fb
To: Rajneesh Bhardwaj <irenic.rajneesh@gmail.com>, 
 Xi Pardee <xi.pardee@linux.intel.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Angel Lindo <angellindo@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791230443; l=3591;
 i=angellindo@gmail.com; s=20261005; h=from:subject:message-id;
 bh=bkKXvh7aruVV5KEgO6BGxb8rhWigF7LQcSCkmGAYupQ=;
 b=Lmmyyyso6og4rMut9WJnDkBoMcqiPmiSQlWtpoF8GlGuuw2gg7G09tWdGwHt3BAfuNkPwfQcL
 OV2NEw9qYaIAP97jnpGMsGhp8CDtJ8Ya+Ni47csJT0UDafM/SMzlnYD
X-Developer-Key: i=angellindo@gmail.com; a=ed25519;
 pk=9aX9KrUZRFEbzPyCQvHssDnZU0zZ34gcfSUJXYeuIto=
X-Endpoint-Received: by B4 Relay for angellindo@gmail.com/20261005 with auth_id=1118
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spt_core_init() decides between the Sunrise Point and Cannon Point
register maps by looking for the Sunrise Point PMC PCI device, but only
the SPT-LP ID (0x9d21) is listed. On Skylake-H/Kaby Lake-H systems with
a Sunrise Point-H PCH (PMC 8086:a121), pci_dev_present() fails and the
driver takes the Coffee Lake path, using cnp_pmc_dev. That map does not
describe this PCH, so the debugfs output is wrong.

Seen on a MacBookPro14,3 (i7-7820HQ, PCH-H, PMC 8086:a121). With the
stock driver, ltr_show lists Cannon Point IP names (SOUTHPORT_A, CNV,
EVA, ...) and every entry reads RAW 0xffffffff. I was debugging why
the package never goes deeper than PC3 on this machine, and without a
working PMC map there is no way to see which PCH IP blocks it.

Add the SPT-H PMC ID to spt_pmc_pci_id[] so these systems use the
Sunrise Point map.

Tested on MacBookPro14,3 (Apple firmware 529.140.2.0.0), kernel 7.2.5,
with the module built with this ID:
- ltr_show lists the Sunrise Point IP names, and the values match a
  direct read of the PWRMBASE registers through /dev/mem bit for bit.
- pch_ip_power_gating_status follows device state: LPSS reads On while
  the Bluetooth UART (00:1e.0) is bound and turns Off once it is
  unbound and the UART enters D3hot.
- No warnings on load.

Limitations:
- spt_pfear_map is the SPT-LP layout and is reused as is. SPT-H has
  two more PCIe controllers (SPD and SPE). Bits 13 and 21 are RSVD in
  the SPT map but SPD/SPE in the Cannon Point map; I could not verify
  this on PCH-H, so the map is left unchanged.
- slp_s0_residency_usec reads 0 on this machine.

Fixes: 661405bd817b ("platform/x86: intel_pmc_core: Special case for Coffeelake")
Assisted-by: claude-opus-5-5
Signed-off-by: Angel Lindo <angellindo@gmail.com>
---
On the same machine and firmware, macOS reaches PC10 (~81%) at idle,
while Linux never goes deeper than PC3. This patch only fixes the PMC
detection so pch_ip_power_gating_status and ltr_show become usable for
that investigation. With it, the PCH IPs report gating states consistent
with device state (LPSS confirmed by toggling the Bluetooth UART); PC6
and SLP_S0 residency are still 0.
I plan to send a separate report on the PC3 limit to linux-pm.
---
 drivers/platform/x86/intel/pmc/core.h | 1 +
 drivers/platform/x86/intel/pmc/spt.c  | 1 +
 2 files changed, 2 insertions(+)

diff --git a/drivers/platform/x86/intel/pmc/core.h b/drivers/platform/x86/intel/pmc/core.h
index b4c7399f8..5822dbbda 100644
--- a/drivers/platform/x86/intel/pmc/core.h
+++ b/drivers/platform/x86/intel/pmc/core.h
@@ -36,6 +36,7 @@ DEFINE_FREE(pmc_acpi_free, void *, if (_T) ACPI_FREE(_T))
 
 /* Sunrise Point Power Management Controller PCI Device ID */
 #define SPT_PMC_PCI_DEVICE_ID			0x9d21
+#define SPT_H_PMC_PCI_DEVICE_ID			0xa121
 #define SPT_PMC_BASE_ADDR_OFFSET		0x48
 #define SPT_PMC_SLP_S0_RES_COUNTER_OFFSET	0x13c
 #define SPT_PMC_PM_CFG_OFFSET			0x18
diff --git a/drivers/platform/x86/intel/pmc/spt.c b/drivers/platform/x86/intel/pmc/spt.c
index b50534aa2..5c4b8d536 100644
--- a/drivers/platform/x86/intel/pmc/spt.c
+++ b/drivers/platform/x86/intel/pmc/spt.c
@@ -138,6 +138,7 @@ static const struct pmc_reg_map spt_reg_map = {
 
 static const struct pci_device_id spt_pmc_pci_id[] = {
 	{ PCI_VDEVICE(INTEL, SPT_PMC_PCI_DEVICE_ID) },
+	{ PCI_VDEVICE(INTEL, SPT_H_PMC_PCI_DEVICE_ID) },
 	{ }
 };
 

---
base-commit: cf963c9359dd6c5d0bc6af16df5cf1f691bba4f3
change-id: 20261005-intel-pmc-spt-h-3ebe43d206fb

Best regards,
--  
Angel Lindo <angellindo@gmail.com>

