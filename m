From: Dominique Martinet <asmadeus@codewreck.org>
Subject: [PATCH v3 0/2] iterate_folioq bug when offset==size (Was:
 [REGRESSION] 9pfs issues on 6.12-rc1)
Date: Wed, 13 Aug 2025 15:04:54 +0900
Message-Id: <20250813-iot_iter_folio-v3-0-a0ffad2b665a@codewreck.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAYrnGgC/3XM0QrCIBTG8VcJrzP0uJh21XtEjKXH7VDM0GHF2
 LvndhVFl/8Pvt/EEkbCxA6biUXMlCgMJdR2w2zfDh1ycqUZCNgLLSWnMDY0Ymx8uFHg8lLryni
 tPTpWTveInp4reDqX7imNIb5WP8tl/UtlyQV3xgKo1nmj7NEGh4+I9roLsWMLl+GTgB8CCuGNq
 UApYapafxPzPL8Bkoi6wPMAAAA=
X-Change-ID: 20250811-iot_iter_folio-1b7849f88fed
To: "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Christian Brauner <brauner@kernel.org>, David Howells <dhowells@redhat.com>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: Maximilian Bosch <maximilian@mbosch.me>, Ryan Lahfa <ryan@lahfa.xyz>, 
 Christian Theune <ct@flyingcircus.io>, Arnout Engelen <arnout@bzzt.net>, 
 linux-kernel@vger.kernel.org, linux-block@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, Dominique Martinet <asmadeus@codewreck.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=1818;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=07bYQurcwe4/P0VNBE1yzZCXDX+X9mzCfoRDaUlb8gI=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBonCsPBj9gaG4feijqs3EEQSR6TtPma7iIu7xrL
 utRtgTk7YiJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaJwrDwAKCRCrTpvsapjm
 cAtAD/9CWzj+FBEEa30FyW0OaONRs4W9MKZciPtUYn3DEB6NA/gJ20yiis9TfvOJz/tJ3ju3N5m
 MqftahWtlEKr6k8K05aDtlz8XUPJ4OPyI6B1L0Qw8yWFRcCNSFeJRyeVO3MNM2MqLdK8Lpd9PM9
 xsVR0Ldzkk8UDiVdyjSa3D//zKpcOvJU592y90j/wRdMJXexEW4hMyWP9qjYANQIp4srH4x1GjD
 b1QBqq8WNyhnS2cYMibpupZCetLmkSx0NpY+btpg1PC8vHVWLzPWFQsMJQhWry/GOEqrov8GfyC
 Yc2QMPUMSvezHCA6OyvD2oRq1XJtFCkG/6bGRJbIcHNQmZyXZIj2a+awR9yTV/7/ZzpFpTLXBEc
 ADVtTkyzzV7SWQoOx/WNLWqWdJRJ8qHcOZJ78BwWoPy1mjzz3w3m6KIpBlSR86QtqlNc3O5D7zX
 I8jArKS0Y5OuVLYucx3rUyxc5+CrVsLGPGdnQHWswTVQnY09vbDfdpgmCyVJtt/wLlLEZFq7RrX
 nAf2pkwN1/zgPKb4ekEq6wmhhPm9aRGi0CSJHo09feJA34zSVgU4n2xeGF5bbFj9FGi7hhFX6yS
 QfRbB0d6cQ5DfJCJEEtGb1z++31aY2X7V+utiE9ME5TyRt3LCHlyQLquRycamho0myXOirgUzRx
 Mn48f6TI4R7K8vw==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

So we've had this regression in 9p for.. almost a year, which is way too
long, but there was no "easy" reproducer until yesterday (thank you
again!!)

It turned out to be a bug with iov_iter on folios,
iov_iter_get_pages_alloc2() would advance the iov_iter correctly up to
the end edge of a folio and the later copy_to_iter() fails on the
iterate_folioq() bug.

Happy to consider alternative ways of fixing this, now there's a
reproducer it's all much clearer; for the bug to be visible we basically
need to make and IO with non-contiguous folios in the iov_iter which is
not obvious to test with synthetic VMs, with size that triggers a
zero-copy read followed by a non-zero-copy read.

Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
Changes in v3:
- convert 'goto next' to a big "if there is valid data in current folio"
Future optimizations can remove it again after making sure this (iov iter
advanced to end of folio) can never happen.
- Link to v2: https://lore.kernel.org/r/20250812-iot_iter_folio-v2-0-f99423309478@codewreck.org

Changes in v2:
- Fixed 'remain' being used uninitialized in iterate_folioq when going
  through the goto
- s/forwarded/advanced in commit message
- Link to v1: https://lore.kernel.org/r/20250811-iot_iter_folio-v1-0-d9c223adf93c@codewreck.org

---
Dominique Martinet (2):
      iov_iter: iterate_folioq: fix handling of offset >= folio size
      iov_iter: iov_folioq_get_pages: don't leave empty slot behind

 include/linux/iov_iter.h | 20 +++++++++++---------
 lib/iov_iter.c           |  6 +++---
 2 files changed, 14 insertions(+), 12 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250811-iot_iter_folio-1b7849f88fed

Best regards,
-- 
Dominique Martinet <asmadeus@codewreck.org>

