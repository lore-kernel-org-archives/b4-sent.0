From: Xiubo Li <xiubo.li@clyso.com>
Date: Fri, 21 Aug 2026 19:28:51 -0700
Subject: [PATCH] ceph: keep dentry in cache when inode still holds caps
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-b4-b4-ceph-dentry-caps-v1-1-ff9b77511c97@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMBCE4Vche3YTqFWJr2I4lHaA9VCbLhAN4
 d0tmszlO8y/kSILlO7VRhmrqLxiQXOqyE8ujmAJxWRqc61b03Bvj3mkiQPinD/sXVJ2wdrb2Qa
 49kLlnDIGef/Cj+5vXfon/HzUaN+/qvOFhnoAAAA=
X-Change-ID: 20260821-b4-b4-ceph-dentry-caps-ad44734dea85
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787365734; l=2605;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=o87BO+Zj9nfVEH3ZzSUVwdEu9iBuFdqRTUS2c5dkPxI=;
 b=FoUTAS/3UP8HD35Ara5xTQueufclkIvm1HlPU1JRHn7li0/zt04oC63/W1K9csd6RFwlj6YhL
 2Da6n6clfqhBdnGPTnS06T7z6N80pwFROnGDOZHRlT5kPThy9IqlSpp
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_d_delete() drops a dentry once its lease expires, which
releases the inode and destroys its page cache at the last close.
A buffered write that outlasts the dentry lease duration (30s by
default on the MDS side) is flushed and closed, yet the reopen
re-reads everything from the OSDs instead of the page cache, even
though the caps and the pages are still valid.

Keep the dentry when the inode still holds caps: the caps guarantee
the inode object is still valid, and the name linkage is revalidated
against the MDS by ceph_d_revalidate() on the next lookup anyway.

Keeping the dentry also keeps the inode and its page cache around
longer than before.  This is bounded: caps no longer needed by any
open file or by dirty data are released once the delayed release
window expires (caps_wanted_delay_max, 60s by default) via
ceph_check_delayed_caps(), after which the dentry is just an
ordinary cached dentry.  It is also fully reclaimable: ->d_delete()
is only consulted on the last dput (in retain_dentry()), while the
dcache shrinker (shrink_dentry_list() -> __dentry_kill()) does not
call it, so memory pressure frees these dentries like any others.

The check is deliberately racy: i_ceph_lock cannot be taken under
dentry->d_lock, but a false result only means keeping or dropping a
dentry that could have gone the other way, which is safe.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/dir.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/fs/ceph/dir.c b/fs/ceph/dir.c
index f4e0bf244fd2..a7d33ad9d2c7 100644
--- a/fs/ceph/dir.c
+++ b/fs/ceph/dir.c
@@ -2090,6 +2090,20 @@ static int ceph_d_delete(const struct dentry *dentry)
 		if (__dir_lease_try_check(dentry))
 			return 0;
 	}
+	/*
+	 * The lease has expired, but if the inode still holds caps, keep
+	 * the dentry: dropping it would release the inode and destroy its
+	 * page cache (e.g. on the last close after a long write).  The
+	 * caps guarantee the inode itself is still valid, and the name
+	 * linkage is revalidated against the MDS on the next lookup
+	 * anyway.
+	 *
+	 * This is deliberately racy: we can't take i_ceph_lock under
+	 * dentry->d_lock, but a false result only means we keep or drop a
+	 * dentry we could have done the opposite with, which is safe.
+	 */
+	if (__ceph_is_any_real_caps(ceph_inode(d_inode(dentry))))
+		return 0;
 	return 1;
 }
 

---
base-commit: 6a8322d32e2e2d3e364d31fc86c784e0e0105c08
change-id: 20260821-b4-b4-ceph-dentry-caps-ad44734dea85

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

