From: Tjerk Kusters <tkusters@aweta.nl>
Date: Wed, 04 Nov 2026 07:34:41 +0100
Subject: [PATCH net] igb: do not let a VF set other VMOLR bits through its
 frame size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-igb-vf-rlpml-v1-1-729621b60eee@aweta.nl>
X-B4-Tracking: v=1; b=H4sIAADS6moC/yWMzQqDMBAGX0W+swuJxR98FfHQ6EZXNEqSSkF89
 6btcQZmLgT2wgFtdsHzKUF2l0DnGYb56SYmGROjUEWltXqQTIZOS349tpUaq6qSbVmPRiMlh2c
 r79+ug+OI/i/Dyyw8xO8I9/0BsR7w0nUAAAA=
X-Change-ID: 20261103-igb-vf-rlpml-8f065ef57db1
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexander Duyck <alexander.h.duyck@intel.com>
Cc: intel-wired-lan@lists.osuosl.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Tjerk Kusters <tkusters@aweta.nl>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793774082; l=2997;
 i=tkusters@aweta.nl; s=20260619; h=from:subject:message-id;
 bh=gJ/6Nb2DFZwQG8IMxy1R6SsS7T1wEalj9eb88cFYTSI=;
 b=lzQKI79dVW+WwBE1gL8azTYfgurUMIbjVTwexkCXObrI6VvUApkNYTHe9K8XyzJQaCm0589h4
 gN7vJgU9+4/DZLJptI9Gg0g3ja8nV816Ec83FI7bhsctJOaxaZ6MQhz
X-Developer-Key: i=tkusters@aweta.nl; a=ed25519;
 pk=JYRpYQ3+LrphEabgnxcbiOUpwvNP8WDDMcLzz+cwKsk=
X-Endpoint-Received: by B4 Relay for tkusters@aweta.nl/20260619 with auth_id=831
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

igb_set_vf_rlpml() gets the maximum frame size from the VF's
E1000_VF_SET_LPE mailbox message and takes it as a signed int. A value
with bit 31 set is negative, so it passes the "size >
MAX_JUMBO_FRAME_SIZE" clamp, and it is then ORed into the VF pool's
VMOLR without masking. Its upper bits set other bits of that register,
such as AUPE and ROPE.

A VF whose port VLAN was set by the PF has AUPE cleared, so that it only
receives frames tagged with that VLAN. Through this message it can set
AUPE again and receive untagged frames. It can also set ROPE, so that its
pool accepts unicast frames that match the Unicast Table Array; while the
PF fills that table, in promiscuous mode or when it has more unicast
addresses than receive address registers, that is all unicast traffic.
igb_set_vf_promisc() does not offer this to VFs.

Take the size as u32, so that such values are clamped to
MAX_JUMBO_FRAME_SIZE, which fits in the RLPML field.

Tested on an I350 with two VFs and kernel 7.3.1. VF 0 got port VLAN 100,
and a test build of igbvf sent its frame size with bits 31, 26 and 24
set. Before this patch, AUPE, ROPE and STRCRC were then set in that VF
pool's VMOLR (0x8f010bce); with it they stay clear, and the size is
clamped to 9728. The normal igbvf still sets its size (3022 at VF MTU
3000) as before.

This was found by the Sashiko AI review of another igb patch.

Link: https://lore.kernel.org/all/179370458190.488856.17697539789438631896@kernel.org/
Fixes: 4ae196dfd61d ("igb: Add support for enabling VFs to PF driver.")
Cc: stable@vger.kernel.org
Signed-off-by: Tjerk Kusters <tkusters@aweta.nl>
---
The Sashiko AI review reported this as a pre-existing issue on v4 of my
igb Rx timestamp series:
https://lore.kernel.org/all/179370458190.488856.17697539789438631896@kernel.org/

The patch and its description were prepared with the help of an AI
coding assistant (Claude). I reviewed them and ran the test described in
the commit message on my test bench.
---
 drivers/net/ethernet/intel/igb/igb_main.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/intel/igb/igb_main.c b/drivers/net/ethernet/intel/igb/igb_main.c
index d4a897a8c82c..d808ad37041c 100644
--- a/drivers/net/ethernet/intel/igb/igb_main.c
+++ b/drivers/net/ethernet/intel/igb/igb_main.c
@@ -4663,12 +4663,13 @@ void igb_setup_rctl(struct igb_adapter *adapter)
 	wr32(E1000_RCTL, rctl);
 }
 
-static inline int igb_set_vf_rlpml(struct igb_adapter *adapter, int size,
+static inline int igb_set_vf_rlpml(struct igb_adapter *adapter, u32 size,
 				   int vfn)
 {
 	struct e1000_hw *hw = &adapter->hw;
 	u32 vmolr;
 
+	/* size comes from the VF, keep it within the RLPML field */
 	if (size > MAX_JUMBO_FRAME_SIZE)
 		size = MAX_JUMBO_FRAME_SIZE;
 

---
base-commit: c3e67bd82b9b9b1a5118f09a429ccefe2aab0741
change-id: 20261103-igb-vf-rlpml-8f065ef57db1

Best regards,
--  
Tjerk Kusters <tkusters@aweta.nl>

