From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH 0/2] ceph: lazy I/O write and LAZYIO revoke fixes
Date: Sat, 07 Nov 2026 03:51:26 +0100
Message-Id: <20261107-ceph-lazyio-noread-v1-0-d04369c70ab7@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ6DMAxA4asgz7WUMPB3lapD4hgwQglKCqJF3
 J3Qjt/w3gGJo3CCrjgg8iZJgs/QjwJoNH5gFJcNpSorrVWNxMuIs/l+JKAPkY1D1dSusg0RtQ5
 yuETuZf9Nn6+/02onpvd9gvO8AEKrP0x2AAAA
X-Change-ID: 20261107-ceph-lazyio-noread-087d6b8ccc9d
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794019887; l=1322;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=Rt9GdhU0hJ6GKS5DTC/LEiSJ5efVuLlYUtDa5pZErT4=;
 b=ICVt88DiL4mxZcHw9QuGGAJYlGkalcIbfDdszWjbZ6YkG5VG0ZAr9JPN5kR5ziLwlYDwW7oN3
 tEXcY61EEFWCI73DlZTRqcNrN6p/AZJY6JTnqvUJi27r/O9b+iNUalB
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two lazy I/O changes on top of the lazy I/O series already in testing.

Patch 1 stops a buffered lazy I/O write into part of a folio that is
not uptodate from reading the folio in first.  That read is done
synchronously under i_rwsem and serialises every writer of a shared
file on the client; with lazy I/O only the dirty range of the folio
goes out, so the read buys nothing.  16 writers on 4 clients writing
47008-byte records into one shared file go from 0.27 to 0.71 GiB/s.

Patch 2 makes ceph_adjust_caps_used_for_lazyio() move a use to LAZYIO
only when that use is in the used set and its cap is not issued.
Otherwise a file with only clean cached pages holds a LAZYIO revoke
until the delayed cap check, up to 60 s, and a getattr from another
client waits that long.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Xiubo Li (2):
      ceph: don't read a folio in for a partial lazy I/O write
      ceph: do not hold a LAZYIO revoke for pages that CACHE covers

 fs/ceph/addr.c | 163 ++++++++++++++++++++++++++++++++++++++++++++++++++++-----
 fs/ceph/caps.c |  11 +++-
 2 files changed, 159 insertions(+), 15 deletions(-)
---
base-commit: 5dcec86cc31f8144857c0d9bf2a7fa13b6e6f531
change-id: 20261107-ceph-lazyio-noread-087d6b8ccc9d

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

