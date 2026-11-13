From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/3] pmdomain: rockchip: fix the probe error and
 deferral paths
Date: Fri, 13 Nov 2026 08:42:04 +0000
Message-Id: <20261113-pmdomain-rockchip-v3-0-b7039ca30b87@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32PyU7EMBBEfyXyGSOv7SQn/gNx8NYTA1lwMhFoN
 P9OZ+YyB8SlpZKqX1Vd2JprySvrmwureS9rmScS+qlhcfDTKfOSSDMlFEgpBV/GNI++TLzO8SM
 OZeHadM6r7DChZfS31Izl+8Z8fbvr9Rzec9wO0OEYyrrN9ecWusvD9x9/l1xwCB16yMH7Fl5OZ
 Ph8jvPIDv6uHgnqL4Iigo2pM8orndA9Eq73ijV/nWn9du/NFr/Fgbb3TVQoos0BwEqKd8YggDY
 qBbqt9QCtxeDkMSz4NXOijmXrG2eczb4NtgUJQesojMfQOYgokEipSwk0Bqpw/QVhMQgXiAEAA
 A==
X-Change-ID: 20261110-pmdomain-rockchip-3497a2e7fdf5
To: Ulf Hansson <ulfh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Kevin Hilman <khilman@linaro.org>, Caesar Wang <wxt@rock-chips.com>, 
 Elaine Zhang <zhangqing@rock-chips.com>
Cc: linux-pm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Yao Zi <me@ziyao.cc>, Igor Pecovnik <igor@armbian.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794559325; l=2265;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=k1mLNrWfIj7RN8Bh3VsWtx7wapkXv0tU4C3AAvkt4b0=;
 b=Mi0cR6vTMB643sMCpH7Z5f77UEcQyS32zt8DJ8ItoWOMCFw+PtT9juZ6YpgxIR2PZkr0XOrLe
 ZW3cw1yl2tyBacelDOkpFGjTreD09rBGEAKPATbJqP1ns6LkCCxxjAA
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes for a Rockchip power domain controller probe that fails or defers,
for example on a domain clock that is not available yet. They apply on
top of 1/2 of Yao Zi's series [1], which has to go in first; patch 2
replaces 2/2 of [1]. On the pmdomain next branch, 1/2 of [1] conflicts
with "cycle an optional power-domain reset on power-on" in one line.

Tested with v1 on an Orange Pi 5 (RK3588S), v7.3 based kernel, with a
test device tree that makes the PD_FEC clock appear late: no freed
domain left on gpd_list, no -517 errors, and the controller binds later
with all 26 domains. The v2/v3 changes are build-tested only.

[1] https://lore.kernel.org/r/20261105001257.1368266-1-me@ziyao.cc

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v3:
- Split 2/2 into the fix (2/3: deferral, pm_qos error code, callers'
  messages) and a clean-up of the other messages without Fixes tags
  (3/3) (Yao Zi)
- Shorter commit messages and comments (Heiko Stuebner)
- No code change from v2 apart from the comments in 1/3
- Link to v2: https://patch.msgid.link/20261112-pmdomain-rockchip-v2-0-5cd942a23df7@gmail.com

Changes in v2:
- Dropped "pmdomain: rockchip: put only the clocks that were got on
  error" for 1/2 of [1], which fixes the same bug
- 2/2: drop the callers' messages and use dev_err_probe() where the
  errors happen (Sebastian Reichel)
- 2/2: a pm_qos syscon error keeps its own code
- Link to v1: https://patch.msgid.link/20261110-pmdomain-rockchip-v1-0-6b9fa6ebaa86@gmail.com

---
Arun Iyengar (3):
      pmdomain: rockchip: remove subdomain links before the domains on error
      pmdomain: rockchip: don't report probe deferral as an error
      pmdomain: rockchip: use dev_err_probe() for the other probe errors

 drivers/pmdomain/rockchip/pm-domains.c | 131 +++++++++++++++++++--------------
 1 file changed, 76 insertions(+), 55 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261110-pmdomain-rockchip-3497a2e7fdf5
prerequisite-patch-id: c2f0c5eb6651baa744f66342db63485a6685fb71

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

