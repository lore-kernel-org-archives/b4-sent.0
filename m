From: Sven Peter <sven@kernel.org>
Subject: [PATCH v2 0/7] thunderbolt: Fix DP tunnel teardown while an async
 DPRX read is running
Date: Sun, 23 Aug 2026 18:09:13 +0200
Message-Id: <20260823-b4-tbt-fixes-v2-0-26a18a426c9f@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNQQ7CIBREr9L8td8AabG68h6miwK/LWpaA0g0D
 XcXaly4fJmZNyt4cpY8nKoVHEXr7TJnELsK9NTPI6E1mUEwIVnLG1Q1BhVwsC/y2AvZHnkrGZc
 G8uThaAvy4tJ92T/VlXQojtKYrA+Le29/kZfeT334V0eODMmQEbXkQzPo843cTPf94kboUkof/
 iyIHLsAAAA=
X-Change-ID: 20260815-b4-tbt-fixes-a2689186016d
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, asahi@lists.linux.dev, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2420; i=sven@kernel.org;
 h=from:subject:message-id; bh=SXsFoeeEfcibtEXf8lradzcC9odTvodt9bD65D+EBQM=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1a3tN35H1OSouYdErSLb7aRvf/Lr99llnRhuco5rWyGq
 IWWH6w6SlkYxLgYZMUUWbbvtzd98vCN4NJNl97DzGFlAhnCwMUpABPhEWb4K51ypP/0tt8Gfxyy
 9mYE/nM2lHolU2W0xS6jXn+RjEXkdUaGe64bz22ouD196XHV15ps8TvZv732rtQMz/i1g3OXl8t
 9dgA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series contains a bunch of fixes related to teardown while an async
DPRX read is running. I ran into some of these while bringing up the
Apple Silicon NHI and just haven't implemented DP tunneling support yet
such that the DPRX capabilities read can never complete and will always
time out.

None of it is specific to that hardware though so I figured it
makes sense to already send them out.

Best,

Sven

---
Changes in v2:
- Make the DP tunnel activation callback mandatory. The DPRX
  caps are now always read inside dprx_work which now also happens to
  discovered tunnels when they are activated again after hibernation
  restore.
- Mark discovered tunnels as active
- Add a cleanup commit to drop the callback data that's always the same now
- Tear down DP tunnels that are inactive in tb_stop instead of
  exposing tb_tunnel_cancel_dprx.
- Use "router" instead of "switch" in the subject
- Added comments how these issues can be reproduced
- Link to v1: https://patch.msgid.link/20260817-b4-tbt-fixes-v1-0-eded2461f5fc@kernel.org

To: Andreas Noever <andreas.noever@gmail.com>
To: Mika Westerberg <westeri@kernel.org>
To: Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>
Cc: Konrad Dybcio <konradybcio@kernel.org>
Cc: asahi@lists.linux.dev
Cc: linux-usb@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Sven Peter (7):
      thunderbolt: Hold a router reference for each path hop
      thunderbolt: Make the DP tunnel activation callback mandatory
      thunderbolt: Fix domain reference leak when DPRX read is canceled
      thunderbolt: Don't access a DP tunnel after its DPRX read was canceled
      thunderbolt: Mark discovered tunnels as active
      thunderbolt: Tear down inactive DP tunnels when the domain is stopped
      thunderbolt: Drop the DP tunnel activation callback data

 drivers/thunderbolt/path.c   | 21 +++++++++++++
 drivers/thunderbolt/tb.c     | 34 ++++++++++++++-------
 drivers/thunderbolt/test.c   | 49 ++++++++++++++++++++++-------
 drivers/thunderbolt/tunnel.c | 73 ++++++++++++++++++++++++++------------------
 drivers/thunderbolt/tunnel.h | 12 +++-----
 5 files changed, 131 insertions(+), 58 deletions(-)
---
base-commit: 8d3ae59288f1e7d58d76558a6ee96d533bc5019f
change-id: 20260815-b4-tbt-fixes-a2689186016d

Best regards,
--  
Sven Peter <sven@kernel.org>

