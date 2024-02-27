From: Bjorn Andersson <quic_bjorande@quicinc.com>
Date: Mon, 26 Feb 2024 17:49:57 -0800
Subject: [PATCH] pmdomain: qcom: rpmhpd: Fix enabled_corner aggregation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240226-rpmhpd-enable-corner-fix-v1-1-68c004cec48c@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAMQ/3WUC/x2MwQqDMBAFf0X27EIMbWz9FfEQ40tdaGPYgBTEf
 zd4nIGZgwpUUGhoDlLsUmRLFbq2obD69AHLUpmssQ9jrWPNvzUvjOTnLzhsmqAc5c/hCdNH9PP
 75ajmWVH1vR6n87wAZf/r0WoAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, 
 Ulf Hansson <ulf.hansson@linaro.org>, Stephen Boyd <swboyd@chromium.org>, 
 Johan Hovold <johan+linaro@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Johan Hovold <johan@kernel.org>, 
 stable@vger.kernel.org, Bjorn Andersson <quic_bjorande@quicinc.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=3004;
 i=quic_bjorande@quicinc.com; h=from:subject:message-id;
 bh=8TOgtVhYO01rdpfAVMwK9WI6pflXIuB4DQQcEbm8Zmw=;
 b=owEBgwJ8/ZANAwAIAQsfOT8Nma3FAcsmYgBl3T/r3KXQprzkHna4SseXUKD0ooMTxVhZKDW9m
 mWQ0+8CJmiJAkkEAAEIADMWIQQF3gPMXzXqTwlm1SULHzk/DZmtxQUCZd0/6xUcYW5kZXJzc29u
 QGtlcm5lbC5vcmcACgkQCx85Pw2ZrcUW4w//YlZS5dc2FBsqrTddOHzidbibnEQwzDs1tWPmyqH
 jKcngixr+2OP4XYmR/HEBprSaEe/UXls884Ema6ucg5EQtpOIrMqfxWHEptQljfkVwuhHxiav5y
 hR9pSDgBfIkmZYnlp+AI8VM+pQyqQB3nTZ0mgu1YTxtEIomgOZ8ifzTXMPvSrtWtU0pEXDpzE8y
 amaeZShoEQMs238EpgfWhbFTKWqPlUKCdVmjyjIZ/TAnE4haRDpKnCInDvpGaTXJSeK+X1cdzAu
 Iduu4QSFutGx/mTaLJF3I4UqWzUrFmEy/apAtGhOGnpNTkrAjR/euygJQY9OREp0OEvM+FEfjzj
 yn0Xi/zNqMBnEzn5vd7340NM6wSq6oHBJp9dmzLyIAimCcN9A5z769c8SZ+hacWXEZlNqdizJ34
 Wv8iaWi/Rkzc7XUG/Tlx+jtdEqS1313uA1f3HPDfr3VtQ+mN4t7Ex3z4qLFKaslXbunA4AEBLK9
 INzGCitwuDBUSh2NtR0fu5ZOAiQCb7g+gIMON1aDQcD39lbnwfX8rMxYv9zNYZvtnr7z4NbUkAF
 0G/5IeNCRrIoQ42hHlRhVCkG5WnjZRGZbgLEIxHyxLHVUnNPXs+bCCftycKzr4BIUDfIK9W4TGz
 /ltQREquxuqJMmPH8tYwmHjE2s2CdDyeBQHzWutRavxA=
X-Developer-Key: i=quic_bjorande@quicinc.com; a=openpgp;
 fpr=05DE03CC5F35EA4F0966D5250B1F393F0D99ADC5
X-Endpoint-Received: by B4 Relay for quic_bjorande@quicinc.com/default with auth_id=118
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 'e3e56c050ab6 ("soc: qcom: rpmhpd: Make power_on actually enable
the domain")' aimed to make sure that a power-domain that is being
enabled without any particular performance-state requested will at least
turn the rail on, to avoid filling DeviceTree with otherwise unnecessary
required-opps properties.

But in the event that aggregation happens on a disabled power-domain, with
an enabled peer without performance-state, both the local and peer
corner are 0. The peer's enabled_corner is not considered, with the
result that the underlying (shared) resource is disabled.

One case where this can be observed is when the display stack keeps mmcx
enabled (but without a particular performance-state vote) in order to
access registers and sync_state happens in the rpmhpd driver. As mmcx_ao
is flushed the state of the peer (mmcx) is not considered and mmcx_ao
ends up turning off "mmcx.lvl" underneath mmcx. This has been observed
several times, but has been painted over in DeviceTree by adding an
explicit vote for the lowest non-disabled performance-state.

Fixes: e3e56c050ab6 ("soc: qcom: rpmhpd: Make power_on actually enable the domain")
Reported-by: Johan Hovold <johan@kernel.org>
Closes: https://lore.kernel.org/linux-arm-msm/ZdMwZa98L23mu3u6@hovoldconsulting.com/
Cc:  <stable@vger.kernel.org>
Signed-off-by: Bjorn Andersson <quic_bjorande@quicinc.com>
---
This issue is the root cause of a display regression on SC8280XP boards,
resulting in the system often resetting during boot. It was exposed by
the refactoring of the DisplayPort driver in v6.8-rc1.
---
 drivers/pmdomain/qcom/rpmhpd.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/pmdomain/qcom/rpmhpd.c b/drivers/pmdomain/qcom/rpmhpd.c
index 3078896b1300..47df910645f6 100644
--- a/drivers/pmdomain/qcom/rpmhpd.c
+++ b/drivers/pmdomain/qcom/rpmhpd.c
@@ -692,6 +692,7 @@ static int rpmhpd_aggregate_corner(struct rpmhpd *pd, unsigned int corner)
 	unsigned int active_corner, sleep_corner;
 	unsigned int this_active_corner = 0, this_sleep_corner = 0;
 	unsigned int peer_active_corner = 0, peer_sleep_corner = 0;
+	unsigned int peer_enabled_corner;
 
 	if (pd->state_synced) {
 		to_active_sleep(pd, corner, &this_active_corner, &this_sleep_corner);
@@ -701,9 +702,11 @@ static int rpmhpd_aggregate_corner(struct rpmhpd *pd, unsigned int corner)
 		this_sleep_corner = pd->level_count - 1;
 	}
 
-	if (peer && peer->enabled)
-		to_active_sleep(peer, peer->corner, &peer_active_corner,
+	if (peer && peer->enabled) {
+		peer_enabled_corner = max(peer->corner, peer->enable_corner);
+		to_active_sleep(peer, peer_enabled_corner, &peer_active_corner,
 				&peer_sleep_corner);
+	}
 
 	active_corner = max(this_active_corner, peer_active_corner);
 

---
base-commit: b401b621758e46812da61fa58a67c3fd8d91de0d
change-id: 20240226-rpmhpd-enable-corner-fix-c5e07fe7b986

Best regards,
-- 
Bjorn Andersson <quic_bjorande@quicinc.com>

