From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/2] soc/tegra: fuse: Support Tegra210B01 Speedos
Date: Mon, 27 Jul 2026 20:57:34 -0500
Message-Id: <20260727-t210b01-speedo-v2-0-4f287a3dab72@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/13MQQqDMBCF4avIrJsyiaHRrrxHcRGTUQeqkUSkR
 bx7U6GbLv8H79shUWRKcC92iLRx4jDnUJcC3GjngQT73KBQ3dBILVYlsUMp0kLkg0DTV86XXWl
 tCfm0ROr5dYKPNvfIaQ3xffqb/K4/yvxTmxQoetS26rz2dW2aYbL8vLowQXscxwdzp6wNrAAAA
 A==
X-Change-ID: 20260714-t210b01-speedo-07f8cd3b3aa3
To: Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, Alex Frid <afrid@nvidia.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785203864; l=1069;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=sucxWG+FGkB/UcRT5g1uTsrL3dbtoJG+IwUqs67kd08=;
 b=of7N7+BLErWv73vCutehIo2yjVamM/b6LM1yjUWCe/euC+UMFWdsEJm8ykUYcFVQy4UcfLKnP
 oIWH5CmZsZICf7SAvBgEWgYywQ4ljxxIGDpIfbjfO2GJ9rgdBWydsRV
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the b01 fuse revision, then adds speedo
support for known Tegra210B01 sku's.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Update patch 1 commit messag to be more descriptive
- Update patch 1 to set unknown revision in the major revision B code
  path if minor revision is not 1.
- Add based-on tags to patch 2
- Link to v1: https://lore.kernel.org/r/20260717-t210b01-speedo-v1-0-f04a8bd4d997@gmail.com

---
Aaron Kling (2):
      soc/tegra: fuse: Support revision B01
      soc/tegra: fuse: speedo-tegra210: Support revision B01

 drivers/soc/tegra/fuse/fuse-tegra.c      |  1 +
 drivers/soc/tegra/fuse/speedo-tegra210.c | 22 ++++++++++++--
 drivers/soc/tegra/fuse/tegra-apbmisc.c   | 51 +++++++++++++++++++-------------
 include/soc/tegra/fuse.h                 |  1 +
 4 files changed, 53 insertions(+), 22 deletions(-)
---
base-commit: 1a1757b76427f6201bfe0bf1bea9f7574f332a93
change-id: 20260714-t210b01-speedo-07f8cd3b3aa3

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

