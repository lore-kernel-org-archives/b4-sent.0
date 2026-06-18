From: Alberto Ruiz <aruiz@redhat.com>
Subject: [PATCH RFC 0/2] RFC: erofs: memory-backed mount for
 non-page-aligned ranges
Date: Thu, 18 Jun 2026 17:13:43 +0100
Message-Id: <20260618-erofs-memback-v1-0-5aa7006a241a@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDM0Nz3dSi/LRi3dzU3KTE5Gxdg8RUIxMTi6REo+RkJaCegqLUtMwKsHn
 RSkFuzkqxEMHi0qSs1OQSkElKtbUAXYGDhHYAAAA=
X-Change-ID: 20260617-erofs-memback-0ae2448ba2cc
To: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>, 
 Yue Hu <zbestahu@gmail.com>, Jeffle Xu <jefflexu@linux.alibaba.com>, 
 Sandeep Dhavale <dhavale@google.com>, Hongbo Li <lihongbo22@huawei.com>, 
 Chunhai Guo <guochunhai@vivo.com>
Cc: linux-kernel@vger.kernel.org, linux-erofs@lists.ozlabs.org, 
 Javier Martinez Canillas <javierm@redhat.com>, 
 Brian Masney <bmasney@redhat.com>, Eric Curtin <ericcurtin17@gmail.com>, 
 Alberto Ruiz <aruiz@redhat.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781799229; l=2698;
 i=aruiz@redhat.com; s=20260612; h=from:subject:message-id;
 bh=u1QwI1AOpH0D8IvOYk4BtAtb0C1h3NOndIlroKuUmmA=;
 b=0HNeFSvZBySZaDmAoh7zOYZD283faaBQL1pVldiPpNOMZn83Wgwawpurj9yk/z6wf4qeoBfTU
 FbNGZoPmudFBFuyzRlQQqx9DtP1JYkt7pCdRVbE+qe5Y+yJIcX1kR44
X-Developer-Key: i=aruiz@redhat.com; a=ed25519;
 pk=d1doFQwve1B/jU9nG5oPl1W5d+t+iFrjkkwk/hD97Ow=
X-Endpoint-Received: by B4 Relay for aruiz@redhat.com/20260612 with auth_id=818
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a memory-backed ("memback") mode to EROFS that
allows mounting an EROFS image directly from a kernel memory region
without going through the block layer.

I am sending this as an RFC to get EROFS maintainer feedback on
this approach before building the full initramfs series on top of
it.  The memback mode may also be useful for other use cases beyond
initramfs where EROFS images need to be served directly from
memory, though it may need further hardening for more general use
cases.

Previous review feedback on the initramfs patches raised concerns
about the block layer dependency — this series addresses that by
providing a direct memory-backed path.  It also adds support for
non-page-aligned memory ranges, which is the common case for
initramfs images packed at arbitrary cpio boundaries.  Supporting
non-page-aligned ranges is essential for true zero-copy access —
requiring page alignment would force a copy into an aligned buffer
before the data can be used, defeating the purpose.

The full initramfs integration (init/ changes) that wires up the
EROFS initrd detection and layered mount is available for reference
here[0]. It implements support for interleaved cpio and EROFS
layers, it supports cpio CPU microcode update prefix, and uses
overlayfs+tmpfs for write support.

This series was developed with the assistance of Claude Opus 4.6.
All patches carry an Assisted-by tag. I am providing the kunit
testing and I have tested this change against the initramfs series
to boot an EROFS initramfs. I welcome feedback on the approach and
implementation.

Patch 1 adds the core memback implementation.
Patch 2 adds a KUnit test that mounts a compressed EROFS image at a
non-page-aligned offset and verifies decompressed file contents.

[0] https://github.com/aruiz/linux/tree/wip/erofs-initramfs-memback

Signed-off-by: Alberto Ruiz <aruiz@redhat.com>
---
Alberto Ruiz (2):
      erofs: add memory-backed mode for non-page-aligned mount
      erofs: add KUnit test for memory-backed compressed mount

 fs/erofs/Kconfig        |  11 ++++
 fs/erofs/Makefile       |   2 +
 fs/erofs/data.c         |  33 +++++++++-
 fs/erofs/internal.h     |  53 +++++++++++----
 fs/erofs/memback.c      | 169 ++++++++++++++++++++++++++++++++++++++++++++++++
 fs/erofs/memback_test.c | 151 ++++++++++++++++++++++++++++++++++++++++++
 fs/erofs/super.c        |  38 +++++++++--
 fs/erofs/zdata.c        |  16 +++--
 8 files changed, 447 insertions(+), 26 deletions(-)
---
base-commit: 6b5a2b7d9bc156e505f09e698d85d6a1547c1206
change-id: 20260617-erofs-memback-0ae2448ba2cc

Best regards,
--  
Alberto Ruiz <aruiz@redhat.com>

