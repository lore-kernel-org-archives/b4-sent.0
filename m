From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/3] cpufreq: mediatek: add mt6572 support
Date: Wed, 23 Sep 2026 10:23:33 +0300
Message-Id: <20260923-6572-cpufreq-v1-0-41f7af6d6d1a@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw5AMBRA0a3IG2vSltZnK2JAvfIMfFpEIvauG
 J7BvRd4dIQeyugChwd5mqcAEUdghmbqkVEXDJJLzQuZMK0yycyyW4crU0KnSuQCdZJCSBaHls5
 vV9W//d6OaLb3Aff9AMBW/VNwAAAA
X-Change-ID: 20260923-6572-cpufreq-51645181e634
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790148240; l=937;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=UaqCiK5kR6zZ6YSdOk5LLGKaESwbOwE2p1co/yqpIaE=;
 b=Y9b3/MY3HkYmoYQloksip6ASc6JC/N8OjZn4qOGxEpd4xxnuaWshSYvG/SkvwRLC5uT+mWD+Z
 y5eumooGZ3FB7/lzch7c5LOl70VYE8jcnxejl0/AHVGdMaA46Vdc7Nh
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for mt6572 SoC frequency scaling.

Since there are (at least) 3 variants of this SoC, first patch adds
support for CPU speedbin. This is also useful for mt67xx family, which
has a lot of SoCs where the only difference is CPU/GPU clock.

Tested on both mt6572m (1 GHz limit) and mt6572w (1.4 GHz).

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Roman Vivchar (3):
      cpufreq: mediatek: add support for CPU speedbin
      cpufreq: mediatek: add mt6572 support
      cpufreq: dt-platdev: block the driver from probing on MediaTek mt6572

 drivers/cpufreq/cpufreq-dt-platdev.c |  1 +
 drivers/cpufreq/mediatek-cpufreq.c   | 59 ++++++++++++++++++++++++++++++++++--
 2 files changed, 58 insertions(+), 2 deletions(-)
---
base-commit: 8d3ae59288f1e7d58d76558a6ee96d533bc5019f
change-id: 20260923-6572-cpufreq-51645181e634

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

