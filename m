From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH v2 0/2] ceph: GFP_NOFS fix for cap flush writeback
 recursion
Date: Wed, 12 Aug 2026 00:36:24 -0700
Message-Id: <20260812-b4-gfp_nofs-v2-0-9574af8a417d@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NwQ6CMBAFf4Xs2Zq2lBI98R+GGFq2UKMt6SKRE
 P5dwKvHSebNW4AweSS4ZgsknDz5GDaQpwxs34QOmW83Bsml5qXMmVGsc8M9REcMG90KIRtZlBy
 2xZDQ+c9Ru9U/prd5oB33xG70nsaY5uNuErv3vzwJxpnl2iieFwrtpbLPmeLZxhfU67p+AXSMA
 6+4AAAA
X-Change-ID: 20260723-b4-gfp_nofs-ea6d112a2570
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786520227; l=1503;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=lPd1dyt44kJS9TYiygd/17Cai4nHFrY1bP/DIL7DSBw=;
 b=LfxAsEhteWCI0ZT6I2rtSWc2kqYuzyfQW7MgpZAoOLvEDuBPsINPJOQx4yN/iuWaTNIOHsoVw
 xZETUmIzb1tBUKSmY+HdJ6x9dSp3UB755vq8GGn/ByiSC6LwntAvNKt
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These two patches fix GFP flag issues in the filesystem I/O paths
discovered while reviewing Max Kellermann's "ceph: avoid fs reclaim
while using current->journal_info" fix.

The first patch is a real fix: ceph_alloc_cap_flush() is called from
ceph_writepages_start() inside the writeback layer, but uses GFP_KERNEL.
Direct reclaim triggered by this allocation can re-enter the writeback
path via the shrinker, causing recursive writeback and potential stack
overflow.  Fix it to use GFP_NOFS, consistent with other allocations in
the same writepages path.

The second patch is a cleanup: __ceph_pool_perm_get() had five
allocations using GFP_NOFS and one using GFP_KERNEL, despite the
function only being called from user I/O paths where GFP_NOFS is
unnecessary.  Use GFP_KERNEL consistently.

---
Changes in v2:
- Convert the last two GFP_NOFS allocations (rd_req and perm) to GFP_KERNEL, covering all six call sites.
- Correct commit message count: s/four/six/.
- Link to v1: https://patch.msgid.link/20260723-b4-gfp_nofs-v1-0-c06b40354ec9@clyso.com

---
Xiubo Li (2):
      ceph: use GFP_NOFS for cap flush allocation in writeback path
      ceph: use GFP_KERNEL consistently in __ceph_pool_perm_get()

 fs/ceph/addr.c | 10 +++++-----
 fs/ceph/caps.c |  2 +-
 2 files changed, 6 insertions(+), 6 deletions(-)
---
base-commit: 0b79edbeed72d6c75987b5b402edeafceb4d080d
change-id: 20260723-b4-gfp_nofs-ea6d112a2570

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

