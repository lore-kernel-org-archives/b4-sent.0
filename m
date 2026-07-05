From: Liz Fong-Jones <lizf@honeycomb.io>
Date: Sun, 05 Jul 2026 10:11:43 -0700
Subject: [PATCH] PCI: Fix BAR resize for devices on a root bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-pci-rebar-root-bus-v1-1-55df70cbdd88@honeycomb.io>
X-B4-Tracking: v=1; b=H4sIAE6QSmoC/yXMQQqEMAxA0atI1gbaOih4FXFha6pxYSXRYUC8u
 3VcvsX/JygJk0JbnCD0ZeW0ZtiygDAP60TIYzY442rTmA9ugVHID4KS0o7+UIyVdVUka2JoIIe
 bUOTff9r1r/XwC4X9OcF13R/1e3F2AAAA
X-Change-ID: 20260704-pci-rebar-root-bus-f3123fe10fc7
To: Bjorn Helgaas <bhelgaas@google.com>
Cc: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 regressions@lists.linux.dev, amd-gfx@lists.freedesktop.org, 
 Jon Nettleton <jon@solid-run.com>, Jon Nettleton <jon.nettleton@gmail.com>, 
 stable@vger.kernel.org, Liz Fong-Jones <lizf@honeycomb.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4287; i=lizf@honeycomb.io;
 s=gpg; h=from:subject:message-id;
 bh=WjhPR946S5kQ2MM+7TqB/nQbZuHdNxuSaUo3YEdJ1dU=;
 b=owEBbQGS/pANAwAKAaXO1OOXra/CAcsmYgBqSpBT2VQkT7xS0DBT4bFs/PNduIzCpXSUdbhlx
 +BUdSUWfm+JATMEAAEKAB0WIQSfW1LPQ0gyJmoTHwelztTjl62vwgUCakqQUwAKCRClztTjl62v
 wuU9B/43wnUMX1r7OFzOUOLhs7jAFwO76sMfFglIIx4+jiZsAeECwbTO6vJ/B7uxJqWNBjoDBU5
 +qBnydr+Zy8aNRAgrClef7W2QitCPB9JyGuOSMQn6nlhA/9LSJvt2shilGGo28Ekw8JbeRehZE3
 YfEAbYPDNj6y66wpKdNAANSXa+Saj4YnmX5piKeTE2qv+qJwpMy7HZ69ov+iOg2lzmwHkjhTj9l
 TRcjq86rbWran3ghttXJsjZ77jyY2Iw22zBQfFrlX6QV/4purUnKtLqcQ0Wih9PW7OZ5veO0vYG
 QM53tH07CgWLmOwRFMHiVToYw4a/ZvH3h0+/9gm3H3ssJXYV
X-Developer-Key: i=lizf@honeycomb.io; a=openpgp;
 fpr=1F7714D7EC3441D2CECC24606A3F8B00FBDDD2A4
X-Endpoint-Received: by B4 Relay for lizf@honeycomb.io/gpg with auth_id=854
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pci_do_resource_release_and_resize() releases the device BARs that
share a bridge window with the BAR being resized, but when the device
sits directly on a root bus (pdev->bus->self == NULL) it then skips
resource assignment entirely and returns success, leaving the BARs it
just released unassigned (IORESOURCE_UNSET).

Skipping pbus_reassign_bridge_resources() is correct in that case --
there is no bridge window to adjust -- but the device BARs still have
to be reassigned. Before the BAR release was consolidated into the PCI
core, this case worked for amdgpu because the driver released the BARs
itself and then called pci_assign_unassigned_bus_resources()
unconditionally after the resize, which assigns unassigned device BARs
also on a root bus. Commit db92e3fef53e ("drm/amdgpu: Remove driver
side BAR release before resize") removed that call, so nothing assigns
the released BARs anymore.

This breaks amdgpu completely on the SolidRun HoneyComb LX2 (NXP
LX2160A, arm64, ACPI), where the GPU endpoint is enumerated directly
on the root bus of its segment (there is no root port device, so
pdev->bus->self is NULL):

  amdgpu 0004:01:00.0: BAR 0 [mem 0xa400000000-0xa40fffffff 64bit pref]: releasing
  amdgpu 0004:01:00.0: BAR 2 [mem 0xa410000000-0xa4101fffff 64bit pref]: releasing
  amdgpu 0004:01:00.0: sw_init of IP block <gmc_v8_0> failed -19
  amdgpu 0004:01:00.0: amdgpu_device_ip_init failed
  amdgpu 0004:01:00.0: Fatal error during GPU init

No error is logged because the resize path reports success; amdgpu
then finds BAR0 IORESOURCE_UNSET and bails out with -ENODEV.

Assign the released BARs directly from the root bus windows when there
is no upstream bridge. On failure, roll back through the existing
restore path exactly as in the bridged case.

The root bus path also had a locking bug that any fix here necessarily
touches: the old "goto out" jumped to up_read(&pci_bus_sem) without a
matching down_read() (as does the "goto restore" taken when
pci_dev_res_add_to_list() fails in the release loop). Take pci_bus_sem
before the BAR release loop so every path through the function holds
it exactly once.

Fixes: 337b1b566db0 ("PCI: Fix restoring BARs on BAR resize rollback path")
Cc: stable@vger.kernel.org # v6.19+
Signed-off-by: Liz Fong-Jones <lizf@honeycomb.io>
---
#regzbot introduced: 337b1b566db0

Observed at runtime on Ubuntu's linux-hwe-7.0 (7.0.0-14, broken) vs
linux-hwe-6.17 (working), but nothing here is distro-specific: Ubuntu
carries this code unmodified, and the affected function is identical
to current mainline. By source inspection the regression window is
v6.18 (old code paths) to v6.19 (consolidation). Workaround for
affected users: amdgpu.rebar=0.
---
 drivers/pci/setup-bus.c | 25 +++++++++++++++++++------
 1 file changed, 19 insertions(+), 6 deletions(-)

diff --git a/drivers/pci/setup-bus.c b/drivers/pci/setup-bus.c
index c0a949f2c995..9db1951f6e5c 100644
--- a/drivers/pci/setup-bus.c
+++ b/drivers/pci/setup-bus.c
@@ -2397,6 +2397,8 @@ int pci_do_resource_release_and_resize(struct pci_dev *pdev, int resno, int size
 	if (ret)
 		return ret;
 
+	down_read(&pci_bus_sem);
+
 	pci_dev_for_each_resource(pdev, r, i) {
 		if (i >= PCI_BRIDGE_RESOURCES)
 			break;
@@ -2415,13 +2417,24 @@ int pci_do_resource_release_and_resize(struct pci_dev *pdev, int resno, int size
 
 	pci_resize_resource_set_size(pdev, resno, size);
 
-	if (!bus->self)
-		goto out;
+	if (bus->self) {
+		ret = pbus_reassign_bridge_resources(bus, res, &saved);
+		if (ret)
+			goto restore;
+	} else {
+		/*
+		 * A device on a root bus has no bridge windows to adjust.
+		 * Assign the BARs released above directly from the root bus
+		 * windows.
+		 */
+		list_for_each_entry(dev_res, &saved, list) {
+			i = pci_resource_num(pdev, dev_res->res);
 
-	down_read(&pci_bus_sem);
-	ret = pbus_reassign_bridge_resources(bus, res, &saved);
-	if (ret)
-		goto restore;
+			ret = pci_assign_resource(pdev, i);
+			if (ret)
+				goto restore;
+		}
+	}
 
 out:
 	up_read(&pci_bus_sem);

---
base-commit: 7404ce51637231382873d0b55edabc2f3b841a9d
change-id: 20260704-pci-rebar-root-bus-f3123fe10fc7

Best regards,
--  
Liz Fong-Jones <lizf@honeycomb.io>

