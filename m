From: Vincent Choiniere <choiniere.vincent@hydroquebec.com>
Date: Mon, 26 Oct 2026 09:30:22 -0400
Subject: [PATCH iwl-net] ice: fix NULL dereference after disabling RDMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-ice-deinit-rdma-null-v1-1-7d2130d1809a@hydroquebec.com>
X-B4-Tracking: v=1; b=H4sIAO1V32oC/yWMwQrCMBAFf6Xs2YUmwQr+inhokxddiaskaRVK/
 92ox2GYWakgCwodu5UyFiny0AZm15G/jnoBS2hMtreD6e2exYMDRKVyDveRdU6JB+OimeBcPFh
 q6TMjyvu3PZG8Eisqnf+izNMNvn6ntG0fbZLQUIEAAAA=
X-Change-ID: 20261025-ice-deinit-rdma-null-613f1be33f72
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Michal Swiatkowski <michal.swiatkowski@linux.intel.com>, 
 intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Vincent Choiniere <choiniere.vincent@hydroquebec.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793021421; l=3312;
 i=choiniere.vincent@hydroquebec.com; s=20261016; h=from:subject:message-id;
 bh=k9KyR/hu9YHlPLJ6ekmbRPgwMefAd5BueodKK2/VMpU=;
 b=8bwOLo9nJW2N0lkprTPvo4m7YK3bCgAvaOdITw89TeFZE4NqbPiFYxMcXYABPUonNi9ZXkF/N
 SSg99Pxr0XBDc4xD+agc0rCZRcm5RqV9IGR1Q9in27Ko8MdWDYYRiTp
X-Developer-Key: i=choiniere.vincent@hydroquebec.com; a=ed25519;
 pk=MctQE067DucsZOaNqb+sjY7aQ+urhztuURanagEW3+8=
X-Endpoint-Received: by B4 Relay for choiniere.vincent@hydroquebec.com/20261016 with auth_id=1210
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ice_deinit_rdma() checks ice_is_rdma_ena() before dereferencing
pf->cdev_info. While the enable_rdma devlink driverinit parameter is
registered, that helper returns the parameter value. Once the parameter
is unregistered, it falls back to ICE_FLAG_RDMA_ENA.

When enable_rdma is set to false and applied by a devlink reload,
ice_init_rdma() returns early, leaving pf->cdev_info NULL. During driver
removal, ice_remove() calls ice_deinit_devlink() before ice_unload().
The parameters are therefore unregistered before ice_deinit_rdma()
runs. On an RDMA-capable device, ice_is_rdma_ena() then returns true,
allowing ice_deinit_rdma() to dereference the NULL pointer.

This can cause a panic during reboot, module removal or PCI unbind.
Reproduced on an E810 PF with Ubuntu kernel 7.0.0-14 (PREEMPT_RT):

 devlink dev param set pci/0000:02:00.0 name enable_rdma value false \
         cmode driverinit
 devlink dev reload pci/0000:02:00.0 action driver_reinit
 systemctl reboot

 BUG: kernel NULL pointer dereference, address: 0000000000000018
 RIP: 0010:ice_deinit_rdma+0x30/0x60 [ice]
  ice_unload+0x3f/0x150 [ice]
  ice_remove+0xb5/0x1d0 [ice]
  ice_shutdown+0x1b/0x60 [ice]
  pci_device_shutdown
  device_shutdown
  kernel_restart
 Kernel panic - not syncing: Attempted to kill init!

Check pf->cdev_info before dereferencing it, as
ice_rdma_update_vsi_filter() already does. This preserves the existing
enable_rdma semantics without changing other ice_is_rdma_ena() callers.

Fixes: 87181cd6985f ("ice: enable_rdma devlink param")
Cc: stable@vger.kernel.org
Signed-off-by: Vincent Choiniere <choiniere.vincent@hydroquebec.com>
---
Testing was performed on an E810 PF passed through to a KVM guest,
using Ubuntu kernel 7.0.0-38 (PREEMPT_RT). Two kernels differing only
by this patch were compared. Each test set enable_rdma=false and
applied it with devlink reload driver_reinit before the removal step.

  Removal path      Without patch           With patch
  reboot (x3)       NULL deref, panic (3/3) clean (3/3)
  rmmod ice         NULL deref              clean
  PCI unbind        NULL deref              clean

Additional checks on the patched kernel:
  - Reboot without a preceding devlink reload completed cleanly.
  - irdma devices returned after PCI unbind/bind.
  - irdma devices returned after an enable_rdma false -> true reload
    cycle.

No KASAN or kmemleak testing was performed.

The exact target tree (net, 7076f684d5132e6a) was not built or tested.
ice_deinit_rdma() and ice_is_rdma_ena() are unchanged there compared
with the tested code.
---
 drivers/net/ethernet/intel/ice/ice_idc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/intel/ice/ice_idc.c b/drivers/net/ethernet/intel/ice/ice_idc.c
index 102d63c30..09dfcffeb 100644
--- a/drivers/net/ethernet/intel/ice/ice_idc.c
+++ b/drivers/net/ethernet/intel/ice/ice_idc.c
@@ -454,7 +454,7 @@ int ice_init_rdma(struct ice_pf *pf)
  */
 void ice_deinit_rdma(struct ice_pf *pf)
 {
-	if (!ice_is_rdma_ena(pf))
+	if (!ice_is_rdma_ena(pf) || !pf->cdev_info)
 		return;
 
 	xa_erase(&ice_aux_id, pf->aux_idx);

---
base-commit: 7076f684d5132e6a6145e1da2fa74771ecd052e5
change-id: 20261025-ice-deinit-rdma-null-613f1be33f72

