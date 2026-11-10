From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH v2 0/2] ceph: lazy I/O write and LAZYIO revoke fixes
Date: Tue, 10 Nov 2026 13:11:51 +0100
Message-Id: <20261110-ceph-lazyio-noread-v2-0-259775214b39@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7ZgWDQVX3MOwKNNRxiAlLRKRc
 HcB9y5f8v77M0QOwhEuyQyBR4niuxXSQwLU2O7OKG5lSFWaaa0MEvcNtvYzicfOB7YOVW5cVud
 EVDhYh33gm7z36LX6cXzVD6ZhK21GI3HwYdpfR715fw9GjQqdOp+ygoyytSmpnaI/kn9CtSzLF
 wj6UGTGAAAA
X-Change-ID: 20261107-ceph-lazyio-noread-087d6b8ccc9d
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794312723; l=2171;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=46MayRn4PkowK9ASiX0DvHBX+OfL5NdVD7YGVyWj/BA=;
 b=GgXnyZE3IzT7VP0izkQ5xcbLu1b+Wh5PGbuTgtvGFEd4S3AjouRpdyV0D32JA0sEuOZ9xQfwX
 gQ/1kobFcL/CcP3RTSikmVyNaaA9XOxFHnjvazRjtD/G29DPYRNvn3p
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
Changes in v2:
- Patch 1: always install the dirty range on a folio that was not read
  in, even if folio_maybe_dma_pinned() reports a pin; a folio that was
  never mapped cannot be pinned, and a refcount false positive sent its
  unread bytes to the OSD (Alex).
- Patch 1: accept and report a short copy into such a folio instead of
  returning 0; the copied bytes could already have replaced bytes of an
  earlier write in the dirty range, and a failing retry wrote them back
  without reporting them (Alex).
- Link to v1: https://patch.msgid.link/20261107-ceph-lazyio-noread-v1-0-d04369c70ab7@clyso.com

To: Ilya Dryomov <idryomov@gmail.com>
To: Alex Markuze <amarkuze@redhat.com>
To: Xiubo Li <xiubo.li@clyso.com>
To: Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Xiubo Li (2):
      ceph: don't read a folio in for a partial lazy I/O write
      ceph: do not hold a LAZYIO revoke for pages that CACHE covers

 fs/ceph/addr.c | 179 ++++++++++++++++++++++++++++++++++++++++++++++++++++-----
 fs/ceph/caps.c |  11 +++-
 2 files changed, 174 insertions(+), 16 deletions(-)
---
base-commit: 5dcec86cc31f8144857c0d9bf2a7fa13b6e6f531
change-id: 20261107-ceph-lazyio-noread-087d6b8ccc9d

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

