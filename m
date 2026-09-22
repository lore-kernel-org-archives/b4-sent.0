From: Jaidev Shastri <jaidevshastri@vt.edu>
Subject: [PATCH 0/2] soc: xilinx: zynqmp_power: order callback state
 against probe
Date: Mon, 21 Sep 2026 21:02:32 -0400
Message-Id: <20260921-mb-zynqmp-power-v1-0-de6f2eee3f23@vt.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKjTsWoC/yXMzQ6CMBAE4Fche3YN/YlEX8VwaMsqNaHUraJAe
 HdbPH6TmVkhEXtKcKlWYJp88mPIEIcKXG/CndB32SBrearPUuBgcZnDc4gYxw8xKt0ZoRqplRa
 QV5Hp5r/747X9O73tg9yr3JSGNYnQsgmuL9HOqTkqZKdh236nOJXRkwAAAA==
X-Change-ID: 20260921-mb-zynqmp-power-34da13724341
To: Michal Simek <michal.simek@amd.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790038966; l=1347;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=eLnNgO/rDS2qwwxL5yTUq+zocopo2r2OBj3hkKd83qc=;
 b=q8wOvkA78pAcCFPujvVLwMILLMubgB/JO4Yfq1mjtANaMC4ZsHUSNsbkRpbm0mTwRLTxEnb4D
 j+OoJd891a/BIFw199Mgl2/xgfz3jWLpGFGZ0Cx7iLoMLtZon4Ws5jB
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

zynqmp_pm_probe() registers the event manager callbacks and the mailbox rx
callback before it has finished storing the state those callbacks read.

The first patch closes a real window. mbox_request_channel_byname() starts
the channel before it returns, so a message the firmware already has pending
is delivered while rx_chan is still NULL and the IPI is never acknowledged.
The mailbox API gives the callback no way to reach the channel from its
struct mbox_client, so the channel is stored under a spinlock shared with the
callback and the acknowledgement is deferred until probe has published it.

The second orders the two work-struct pointers that the event manager and
mailbox callbacks dereference as soon as they run.

Found with MBCheck, a static herd7-based memory consistency checker.
Compile-tested on arm64 with W=1, no new warnings.

---
Jaidev Shastri (2):
      soc: xilinx: zynqmp_power: do not use rx_chan before probe has stored it
      soc: xilinx: zynqmp_power: publish the callback work pointers

 drivers/soc/xilinx/zynqmp_power.c | 113 +++++++++++++++++++++++++++-----------
 1 file changed, 81 insertions(+), 32 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20260921-mb-zynqmp-power-34da13724341

Best regards,
--  
Jaidev Shastri <jaidevshastri@vt.edu>

