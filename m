From: Dominique Martinet <asmadeus@codewreck.org>
Subject: [PATCH v2 0/2] iterate_folioq bug when offset==size (Was:
 [REGRESSION] 9pfs issues on 6.12-rc1)
Date: Tue, 12 Aug 2025 06:28:00 +0900
Message-Id: <20250812-iot_iter_folio-v2-0-f99423309478@codewreck.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGFgmmgC/3XMQQrCMBCF4auUWRtJUsXElfeQUmoyaQelI5NSl
 dK7G7t3+T943wIZhTDDuVpAcKZMPJawuwrC0I09KoqlwWp71M4YRTy1NKG0iR/EytxO7uCTcwk
 jlNNTMNF7A69N6YHyxPLZ/Nn81r/UbJRW0Qdr6y4mX4dL4IgvwXDfs/TQrOv6BfvAsCqwAAAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1490;
 i=asmadeus@codewreck.org; h=from:subject:message-id;
 bh=dY1PVAFd9XEs8e/MJYNCi7ex0lhE7IhODRbVQ4vJeGI=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBommByYS/YEkj57+WHP3pSNmFCbk5gUi4C/eEcq
 Qz+AJKrqiaJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaJpgcgAKCRCrTpvsapjm
 cM6MD/4lU4rtTTqXPBt8LPIaaV3RWYyUSuJ3w8i5LG0SG27gznjJiWiSut1JeWPBMf14hL93kpj
 WD+w6+GPZAQCd7neQ0twT82jLzyGHHhftQTeC660NweGuy1oTzQwKE8Ggs09IT9BFR9i5mKt/zm
 wp/tGRFAtzgvle3Qk997aLtcKW3d5pAK43HwKVOuVtnRyCP3rycYnIJHuPXDiMno9OSK5AMsOik
 ktASMuTu5+mVjDcRQ4LGVktoBoysVj4iez0+cyTtwWpFBrzpdLcLDl2l7OA6SsXGoDgs52i+Y65
 amDu1gUYZJCZZVnrb9nHX1H1+o0vGi1LiHU3FnHbnjbc2BOYydY+DfCfWW7/dAOytmSn1d1qCF3
 NMn06PXJPTud8n50ojkpxxSKwfid7crUZI9mQqbHGaxN4hx2CotSWmKWRLKrTum3rNIt+UH6nbd
 S74wjVMr/tw/iXHjOpoHry1Dr5JKxjHSIay6VKvKsoF9UpLXejXG7hb4+Q98LggGq7HiP6A3xnY
 5tZF/jJrSoOT3ILP4HSInsnJEIUmBZEqIBXAp8FOOijy7HeeaQ9ok2do58XuH2C4DnTVVZiba4Q
 PTUIjq2iXTy3JqG2M39ECbKe+Qx6DkyyJf88Yi7NebxHjR1/C6g9WVgsuFyTJZ7lBs+NarqtQwO
 oUa4jKvFsnafd5g==
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
Changes in v2:
- Fixed 'remain' being used uninitialized in iterate_folioq when going
  through the goto
- s/forwarded/advanced in commit message
- Link to v1: https://lore.kernel.org/r/20250811-iot_iter_folio-v1-0-d9c223adf93c@codewreck.org

---
Dominique Martinet (2):
      iov_iter: iterate_folioq: fix handling of offset >= folio size
      iov_iter: iov_folioq_get_pages: don't leave empty slot behind

 include/linux/iov_iter.h | 5 ++++-
 lib/iov_iter.c           | 6 +++---
 2 files changed, 7 insertions(+), 4 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250811-iot_iter_folio-1b7849f88fed

Best regards,
-- 
Dominique Martinet <asmadeus@codewreck.org>

