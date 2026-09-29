From: Shuming Fan <shumingf@realtek.com>
Date: Tue, 29 Sep 2026 16:24:06 +0800
Subject: [PATCH v3] soundwire: intel_auxdevice: add rt766/rt767 codec to
 wake_capable_list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-rt766-wake-v3-1-09c0b82c72a6@realtek.com>
X-B4-Tracking: v=1; b=H4sIAKV1u2oC/22Nyw6CMBBFf4XM2hpok6F15X8YFn2MUlFq2lo1h
 H8XcOvyJOeeO0Gi6CnBoZogUvHJh3EBsavA9nq8EPNuYeA1x1pxxWJuEdlLD8QcSmecwlYoAcv
 gEens31vs1P04Pc2VbF4Lq9H7lEP8bG9FrN7fcBGsYRJb1zhpZKP5MZK+ZRr2Ntyhm+f5C7YBJ
 HK4AAAA
X-Change-ID: 20260929-rt766-wake-d68dbd967393
To: vkoul@kernel.org
Cc: flove@realtek.com, oder_chiou@realtek.com, linux-kernel@vger.kernel.org, 
 linux-sound@vger.kernel.org, jack.yu@realtek.com, derek.fang@realtek.com, 
 Shuming Fan <shumingf@realtek.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790670278; l=1046;
 i=shumingf@realtek.com; s=20260924; h=from:subject:message-id;
 bh=CuWXA0osMnyNhJR4bA+pYYv+p0CVTA4+P+MOPg7CqKE=;
 b=jACE0ZSkVju5HVgsQDQUKvR/DEXCCQziF3kLiEEmLhLqp2yUduvmFVauLnRsZDFigP15+U5jF
 TFulc/IHDM+Cn8E6M+q5F/eV5Fg7zVVVhNCM7OSZbzHCCQHDeqnvib2
X-Developer-Key: i=shumingf@realtek.com; a=ed25519;
 pk=ZM8Pg7tEJ0SDXQeBw6SfvcYyqXU9nF88DuTyxzf9utE=
X-Endpoint-Received: by B4 Relay for shumingf@realtek.com/20260924 with auth_id=1053
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rt766/rt767 have wake capability. Add it to the wake_capable_list.

Signed-off-by: Shuming Fan <shumingf@realtek.com>
---
Changes in v4:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v3: https://patch.msgid.link/20260929-rt766-wake-v3-1-867d1d8b81a2@realtek.com
---
 drivers/soundwire/intel_auxdevice.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/soundwire/intel_auxdevice.c b/drivers/soundwire/intel_auxdevice.c
index 901a71262094..24fff33a9093 100644
--- a/drivers/soundwire/intel_auxdevice.c
+++ b/drivers/soundwire/intel_auxdevice.c
@@ -73,6 +73,8 @@ static struct wake_capable_part wake_capable_list[] = {
 	{0x025d, 0x717},
 	{0x025d, 0x721},
 	{0x025d, 0x722},
+	{0x025d, 0x766},
+	{0x025d, 0x767},
 	{0x04b3, 0x9356},
 	{0x0102, 0x5572},
 	{0x0102, 0x5682},

---
base-commit: 90b63b309fd6c0f192337659e73e3047a67df99f
change-id: 20260929-rt766-wake-d68dbd967393

Best regards,
--  
Shuming Fan <shumingf@realtek.com>

