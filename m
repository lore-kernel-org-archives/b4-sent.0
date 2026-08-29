From: Sven Peter <sven@kernel.org>
Subject: [PATCH v3 0/7] thunderbolt: Fix DP tunnel teardown while an async
 DPRX read is running
Date: Sat, 29 Aug 2026 10:08:32 +0200
Message-Id: <20260829-b4-tbt-fixes-v3-0-e1fab6ac54fe@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12NQQ7CIBBFr2JYi4Fpi9SV9zAuWhha1LQGkGia3
 l2oMbEuX+a/NxPx6Cx6cthMxGG03o5DgmK7Iapvhg6p1YkJMBBM8oq2JQ1toMY+0dMGhKy5FIw
 LTZJyd7gcknE6f9g/2guqkBt50VsfRvda/kWed9/0fp2OnDKKGjWUgpvKqOMV3YC33eg6ktsRf
 mwo/mxINoiGy6YEoWqzsud5fgNheMK6+QAAAA==
X-Change-ID: 20260815-b4-tbt-fixes-a2689186016d
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: Mika Westerberg <mika.westerberg@linux.intel.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, asahi@lists.linux.dev, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2676; i=sven@kernel.org;
 h=from:subject:message-id; bh=Jd3DvGoMdoyGVq9GftryTd67aUOreF1uZEqmV/84+U0=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9akye2hGXP4d6yIfuciunb65aNrnPdtUDy2uDls1cznJ
 ilHONZKdpSyMIhxMciKKbJs329v+uThG8Glmy69h5nDygQyhIGLUwAmcrODkeFeTKOK3P/bXOd5
 FLcFGS6y+3Q8WLJbT/F/+IsCi9o1t9QZ/ofNua5++2W624KHTlFW6313xwTl3WtdKGXwSDstalK
 BOy8A
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
Changes in v3:
- Take the router references in the HopID allocation/release helpers
- Actually call put_device() via a cleanup action for the KUnit tests
- Link to v2: https://patch.msgid.link/20260823-b4-tbt-fixes-v2-0-26a18a426c9f@kernel.org

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
      thunderbolt: Hold a router reference for each allocated HopID
      thunderbolt: Make the DP tunnel activation callback mandatory
      thunderbolt: Fix domain reference leak when DPRX read is canceled
      thunderbolt: Don't access a DP tunnel after its DPRX read was canceled
      thunderbolt: Mark discovered tunnels as active
      thunderbolt: Tear down inactive DP tunnels when the domain is stopped
      thunderbolt: Drop the DP tunnel activation callback data

 drivers/thunderbolt/switch.c |  9 +++++-
 drivers/thunderbolt/tb.c     | 34 ++++++++++++++-------
 drivers/thunderbolt/test.c   | 58 ++++++++++++++++++++++++++++-------
 drivers/thunderbolt/tunnel.c | 73 ++++++++++++++++++++++++++------------------
 drivers/thunderbolt/tunnel.h | 12 +++-----
 5 files changed, 127 insertions(+), 59 deletions(-)
---
base-commit: 8d3ae59288f1e7d58d76558a6ee96d533bc5019f
change-id: 20260815-b4-tbt-fixes-a2689186016d

Best regards,
--  
Sven Peter <sven@kernel.org>

