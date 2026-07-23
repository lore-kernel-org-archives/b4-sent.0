From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH 0/2] ceph: GFP_NOFS fix for cap flush writeback recursion
Date: Thu, 23 Jul 2026 13:47:41 +0800
Message-Id: <20260723-b4-gfp_nofs-v1-0-c06b40354ec9@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyNj3SQT3fS0gvi8/LRi3dREsxRDQ6NEI1NzAyWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgDljxfdbwAAAA==
X-Change-ID: 20260723-b4-gfp_nofs-ea6d112a2570
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784785666; l=1233;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=h3jAjWv4f2VBSaEsrzynmnPKzRILrDbo1m+jK1ogilU=;
 b=sWjGhZ0x9rbGaHxjfOGNqZQuehGz8fj+ExQSVkUdBgNQ6WoousUrHkMOVDLKH/wQZ9UrVyOTC
 1Q+3bmG5frwC14Er5A8TvH8Pe1QtwfAvqPzupQT9D0fSTeRSXbt+Vb5
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

The second patch is a cleanup: __ceph_pool_perm_get() had three
allocations using GFP_NOFS and one using GFP_KERNEL, despite the
function only being called from user I/O paths where GFP_NOFS is
unnecessary.  Use GFP_KERNEL consistently.

---
Xiubo Li (2):
      ceph: use GFP_NOFS for cap flush allocation in writeback path
      ceph: use GFP_KERNEL consistently in __ceph_pool_perm_get()

 fs/ceph/addr.c | 6 +++---
 fs/ceph/caps.c | 2 +-
 2 files changed, 4 insertions(+), 4 deletions(-)
---
base-commit: 0b79edbeed72d6c75987b5b402edeafceb4d080d
change-id: 20260723-b4-gfp_nofs-ea6d112a2570

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

