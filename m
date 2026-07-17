From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] soc/tegra: fuse: Support Tegra210B01 Speedos
Date: Fri, 17 Jul 2026 18:19:39 -0500
Message-Id: <20260717-t210b01-speedo-v1-0-f04a8bd4d997@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avErBNGjYyuEi38mWo2GhoRhHdPW
 n6L914olJkKzN0LmW4unGKD7Dvwh407CQ7NoFCNaOQgLiXRoRTlJApJoNkmH7TT1mpo0Zlp4+c
 fLmutH5NZuWZgAAAA
X-Change-ID: 20260714-t210b01-speedo-07f8cd3b3aa3
To: Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784330387; l=761;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=FbqPy5P9Xc3Z4JsoqF4B+01S7cCgssaMQOs05ToYWP0=;
 b=nFmANYjb4rlcXhedBQuEbeQRxCa1g7KKrvLXdy5WGIVPuNnFIfcj7zHQIPOQqwnOJAH6vbTND
 GK4pRj28ClUCJVb+2h1xY9ixtzBTQJQrfRqVtUznHW1wUCnWif6Rg61
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the b01 fuse revision, then adds speedo
support for known Tegra210B01 sku's.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (2):
      soc/tegra: fuse: Support revision B01
      soc/tegra: fuse: speedo-tegra210: Support revision B01

 drivers/soc/tegra/fuse/fuse-tegra.c      |  1 +
 drivers/soc/tegra/fuse/speedo-tegra210.c | 22 ++++++++++++++--
 drivers/soc/tegra/fuse/tegra-apbmisc.c   | 45 ++++++++++++++++++--------------
 include/soc/tegra/fuse.h                 |  1 +
 4 files changed, 47 insertions(+), 22 deletions(-)
---
base-commit: 1a1757b76427f6201bfe0bf1bea9f7574f332a93
change-id: 20260714-t210b01-speedo-07f8cd3b3aa3

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

