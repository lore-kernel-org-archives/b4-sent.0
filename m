From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH 0/2] ceph: fix UAF bugs in cap flushing and MDS session
 handling
Date: Tue, 14 Jul 2026 16:13:42 +0800
Message-Id: <20260714-ceph-uaf-fixes-v1-0-5c7603c181d5@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBCF4VeRWXcgCV6oryJdmHii48JKpoogv
 nvTuvw4/OckRRIotcVJCbuovJcM+ygoTP0ygmXIJmdcbRpbcsA68dZHjnJA2WOIMNF5Wz0pR2v
 Cf8hN97qtm58RPr8Xuq4vuHfyfXIAAAA=
X-Change-ID: 20260714-ceph-uaf-fixes-bedfe0f2b159
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784016823; l=995;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=PNV5jE9fdgiPSWMSUeFErNMwYv2w094cTzcaHlc1R/U=;
 b=xJSmvVNxGoP7MXON55glnzjJGHw5spBRmzKlRy9bQ2ADZpiSP13RKVc6nwX2xXEcthyr2I/Cc
 3Myo6/w0bEqC0pQAdCCTt9jgztdxqsR395j3HomMmuG8jGW9DEr5KjL
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These two patches fix use-after-free bugs:

Patch 1 fixes __kick_flushing_caps(), which drops i_ceph_lock during
list_for_each_entry() iteration.  A concurrent handle_cap_flush_ack()
can free the current cf entry, making the loop's next-pointer advance
read freed memory.

Patch 2 fixes check_new_map(), where three code paths drop mdsc->mutex
and access the session pointer without taking a reference, opening a
window for another thread to unregister and free the session.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Xiubo Li (2):
      ceph: fix UAF in __kick_flushing_caps() on cf entry freed during unlock
      ceph: fix UAF in check_new_map() on session freed during unlock

 fs/ceph/caps.c       | 11 +++++++++--
 fs/ceph/mds_client.c |  6 ++++++
 2 files changed, 15 insertions(+), 2 deletions(-)
---
base-commit: fc67edb66b3c9924c4e0bb366a92b32ea13c526a
change-id: 20260714-ceph-uaf-fixes-bedfe0f2b159

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

