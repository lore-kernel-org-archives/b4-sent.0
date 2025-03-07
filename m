From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v3 0/2] iommu: apple-dart: Support the ISP DART
Date: Fri, 07 Mar 2025 21:07:44 +0100
Message-Id: <20250307-isp-dart-v3-0-684fe4489591@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABBSy2cC/22Myw6CMBBFf8V0bU1nQARX/odxMdApTCKPtKTRE
 P7dwoqFy3Nzz1lUYC8c1P20KM9RgoxDgux8Uk1HQ8tabGKFBq8G8aYlTNqSn7Urs6KqibipQaX
 75NnJZ089X4k7CfPov3s5wrb+iUTQRkMBXAG73OXFo+1J3pdm7NUWiXgUy4OISTRMtgSqDKM9i
 uu6/gDB3Ik42QAAAA==
X-Change-ID: 20250227-isp-dart-f8369baaecb1
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741378068; l=965;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=aL+XZM/7p7Esweo3/w1A7NMI9JjtTr5G50MAaH4HdCs=;
 b=TymRhGh67bcUCvfAFG+jHbf8FOmhN8c2DfiA24iqbzxriblvi9pdbes4+hbhn2xAcjeQY+Kh0
 8kPtqo0/QtbC3iXPTr7yVkK78hCipfoGXZDbX4wZYDkoP3HBpq6usEo
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ISP block has 3 linked DARTs with mismatched bypass support.
This series adds support for this setup.

(The ISP driver itself is sent as a separate series
https://lore.kernel.org/asahi/20250219-isp-v1-0-6d3e89b67c31@gmail.com/T/ )

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Changes in v3:
- Just added r-b, effectively a resend
- Link to v2: https://lore.kernel.org/r/20250228-isp-dart-v2-0-0ead81a90e2d@gmail.com

Changes in v2:
- Made comments and code a closer match for each other
- Link to v1: https://lore.kernel.org/r/20250227-isp-dart-v1-0-161e91ef4f46@gmail.com

---
Hector Martin (2):
      iommu: apple-dart: Increase MAX_DARTS_PER_DEVICE to 3
      iommu: apple-dart: Allow mismatched bypass support

 drivers/iommu/apple-dart.c | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)
---
base-commit: dd83757f6e686a2188997cb58b5975f744bb7786
change-id: 20250227-isp-dart-f8369baaecb1

